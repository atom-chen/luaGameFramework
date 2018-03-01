/****************************************************************************
 Copyright (c) 2014 cocos2d-x.org

 http://www.cocos2d-x.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/
#include "AssetsManagerEx.h"
#include "CCEventListenerAssetsManagerEx.h"
#include "VersionUtils.h"
#include "Difflist.h"
#include "base/ccUTF8.h"
#include "base/CCDirector.h"
#include "base/CCAsyncTaskPool.h"

#include <stdio.h>
#include <string.h>
#include "ymextra/crypto/CCCrypto.h"

#ifdef MINIZIP_FROM_SYSTEM
#include <minizip/unzip.h>
#else // from our embedded sources
#include "unzip.h"
#endif

NS_CC_EXT_BEGIN

#define TEMP_PACKAGE_SUFFIX     "_temp"
#define VERSION_FILENAME        "version.diff"
//#define TEMP_MANIFEST_FILENAME  "project.diff.temp"
//#define MANIFEST_FILENAME       "123/filelist"

#define BUFFER_SIZE    8192
#define MAX_FILENAME   512

#define DEFAULT_CONNECTION_TIMEOUT 30

#define SAVE_POINT_INTERVAL 0.1

// char*, dest
// int, destLen
// const char* src
// int, srcLen
static int tjDecompress(const char* src, int srcLen, char*& dest)
{
	src += 2;
	int destLen = *((int*)src);
	dest = (char*)malloc(destLen);
	destLen = LZ4_decompress_safe(src, dest, srcLen, destLen);
	if (destLen <= 0)
	{
		free(dest);
		dest = nullptr;
		return -1;
	}
	return destLen;
}

static int isTJCompressed(const char* src, int srcLen)
{
	if (srcLen > 2 + 4 && *src == 't' && *(src + 1) == 'j')
		return true;
	return false;
}

const std::string AssetsManagerEx::VERSION_ID = "@version";
//const std::string AssetsManagerEx::MANIFEST_ID = "@manifest";

static AssetsManagerEx* instance = nullptr;

// Implementation of AssetsManagerEx

AssetsManagerEx::AssetsManagerEx(const std::string& storagePath)
: _updateState(State::UNCHECKED)
, _assets(nullptr)
, _storagePath("")
, _tempVersionPath("")
, _remoteManifest(nullptr)
, _updateEntry(UpdateEntry::NONE)
, _percent(0)
, _percentByFile(0)
, _totalSize(0)
, _totalToDownload(0)
, _totalWaitToDownload(0)
, _sizeCollected(0)
, _nextSavePoint(0.0)
, _maxConcurrentTask(32)
, _currConcurrentTask(0)
, _versionCompareHandle(nullptr)
, _verifyCallback(nullptr)
, _inited(false)

, _patch(0)
, _initPackPatch(0)
, _downloadRetry(3)
{
    // Init variables
    _eventDispatcher = Director::getInstance()->getEventDispatcher();
    std::string pointer = StringUtils::format("%p", this);
    _eventName = EventListenerAssetsManagerEx::LISTENER_ID + pointer;
    _fileUtils = FileUtils::getInstance();

    network::DownloaderHints hints =
    {
        static_cast<uint32_t>(_maxConcurrentTask),
        DEFAULT_CONNECTION_TIMEOUT,
        ".tmp"
    };
    _downloader = std::shared_ptr<network::Downloader>(new network::Downloader(hints));
    _downloader->onTaskError = std::bind(&AssetsManagerEx::onError, this, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3, std::placeholders::_4);
    _downloader->onTaskProgress = [this](const network::DownloadTask& task,
                                         int64_t /*bytesReceived*/,
                                         int64_t totalBytesReceived,
                                         int64_t totalBytesExpected)
    {
        this->onProgress(totalBytesExpected, totalBytesReceived, task.requestURL, task.identifier);
    };
    _downloader->onFileTaskSuccess = [this](const network::DownloadTask& task)
    {
        this->onSuccess(task.requestURL, task.storagePath, task.identifier);
    };

    setStoragePath(storagePath);
    _tempVersionPath = _tempStoragePath + VERSION_FILENAME;

	auto utils = FileUtils::getInstance();
	//第一次读大版本以及patch需要读原始目录下的
	ValueMap vm = utils->getValueMapFromFile("res/version.plist");
	_initPackPatch = atoi(vm["patch"].asString().c_str());

	//重新打包大版本更新后直接下载下来 不会把原有旧的用户信息目录全删了，这样会导致
	//UserDefault还是旧的保存在那里 ，这样里面保存的patch等信息就会有问题
	//刚开启客户端检测下UserDefault里的app_version与version.plist里的app_version是否一致，不一致就把UserDefault里的个别信息重置
	//还有种情况，玩家当前版本更新了一个版本后 不删掉重新去下载覆盖，这样是没问题的，因为本地文件原来的 更新包 userdefault(在ios下改名了，在library下)等文件都不会删掉
	VersionPlistInfo versionPlist = getLocalVersion();
	unsigned int appVersionInUserDefault = getIntValueByAppVersion(versionPlist.app_version.c_str());
	unsigned int appVersion = getIntValueByAppVersion(vm["app_version"].asString().c_str());
	if (appVersion != appVersionInUserDefault)
	{
        destroyDownloadedVersion();
		auto userDefault = UserDefault::getInstance();
		userDefault->setStringForKey(keyWithHash(KEY_OF_APPVERSION), vm["app_version"].asString());
		userDefault->setStringForKey(keyWithHash(KEY_OF_VERSION), vm["patch"].asString());
        userDefault->flush();
	}

	// 添加所有patch的路径
	setLocalSearchPath(false);

	// 取最新版本里的version url
	versionPlist = getLocalVersion();
	_versionUrl = versionPlist.versionUrl;
	_appVersion = versionPlist.app_version;
	_patch = atoi(versionPlist.patch.c_str());

    initManifests();
}

AssetsManagerEx::~AssetsManagerEx()
{
    _downloader->onTaskError = (nullptr);
    _downloader->onFileTaskSuccess = (nullptr);
    _downloader->onTaskProgress = (nullptr);
    CC_SAFE_RELEASE(_remoteManifest);
    
    instance = nullptr;
}

AssetsManagerEx* AssetsManagerEx::create(SuccessCallback successCallback, const std::string& storagePath)
{
    AssetsManagerEx* ret = new (std::nothrow) AssetsManagerEx(storagePath);
    if (ret)
    {
        ret->_appOnSuccess = successCallback;
        
        ret->autorelease();
        instance = ret;
    }
    else
    {
        CC_SAFE_DELETE(ret);
    }
    return ret;
}

AssetsManagerEx* AssetsManagerEx::getInstance()
{
    if (!instance)
    {
        CCASSERT(instance, "FATAL: No AssetsManagerEx");
    }
    return instance;
}

void AssetsManagerEx::initManifests()
{
    _inited = true;
	// Init and load temporary manifest

	// Init remote manifest for future usage
	_remoteManifest = new (std::nothrow) Difflist();
	if (!_remoteManifest)
	{
		_inited = false;
	}

    if (!_inited)
    {
        CC_SAFE_RELEASE(_remoteManifest);
        _remoteManifest = nullptr;
    }
}

std::string AssetsManagerEx::basename(const std::string& path) const
{
    size_t found = path.find_last_of("/\\");

    if (std::string::npos != found)
    {
        return path.substr(0, found);
    }
    else
    {
        return path;
    }
}

std::string AssetsManagerEx::get(const std::string& key) const
{
    auto it = _assets->find(key);
    if (it != _assets->cend()) {
        return _storagePath + it->second.path;
    }
    else return "";
}

const Manifest* AssetsManagerEx::getRemoteManifest() const
{
    return _remoteManifest;
}

const std::string& AssetsManagerEx::getStoragePath() const
{
    return _storagePath;
}

void AssetsManagerEx::setStoragePath(const std::string& storagePath)
{
	// xxx/patch/
    _storagePath = storagePath;
    adjustPath(_storagePath);
    _fileUtils->createDirectory(_storagePath);

	// xxx/patch_temp/
    _tempStoragePath = _storagePath;
    _tempStoragePath.insert(_storagePath.size() - 1, TEMP_PACKAGE_SUFFIX);
    _fileUtils->createDirectory(_tempStoragePath);
}

void AssetsManagerEx::adjustPath(std::string &path)
{
    if (path.size() > 0 && path[path.size() - 1] != '/')
    {
        path.append("/");
    }
}

bool AssetsManagerEx::decompress(const std::string &zip)
{
    // Find root path for zip file
    size_t pos = zip.find_last_of("/\\");
    if (pos == std::string::npos)
    {
        CCLOG("AssetsManagerEx : no root path specified for zip file %s\n", zip.c_str());
        return false;
    }
    const std::string rootPath = zip.substr(0, pos+1);

    // Open the zip file
    unzFile zipfile = unzOpen(FileUtils::getInstance()->getSuitableFOpen(zip).c_str());
    if (! zipfile)
    {
        CCLOG("AssetsManagerEx : can not open downloaded zip file %s\n", zip.c_str());
        return false;
    }

    // Get info about the zip file
    unz_global_info global_info;
    if (unzGetGlobalInfo(zipfile, &global_info) != UNZ_OK)
    {
        CCLOG("AssetsManagerEx : can not read file global info of %s\n", zip.c_str());
        unzClose(zipfile);
        return false;
    }

    // Buffer to hold data read from the zip file
    char readBuffer[BUFFER_SIZE];
    // Loop to extract all files.
    uLong i;
    for (i = 0; i < global_info.number_entry; ++i)
    {
        // Get info about current file.
        unz_file_info fileInfo;
        char fileName[MAX_FILENAME];
        if (unzGetCurrentFileInfo(zipfile,
                                  &fileInfo,
                                  fileName,
                                  MAX_FILENAME,
                                  NULL,
                                  0,
                                  NULL,
                                  0) != UNZ_OK)
        {
            CCLOG("AssetsManagerEx : can not read compressed file info\n");
            unzClose(zipfile);
            return false;
        }
        const std::string fullPath = rootPath + fileName;

        // Check if this entry is a directory or a file.
        const size_t filenameLength = strlen(fileName);
        if (fileName[filenameLength-1] == '/')
        {
            //There are not directory entry in some case.
            //So we need to create directory when decompressing file entry
            if ( !_fileUtils->createDirectory(basename(fullPath)) )
            {
                // Failed to create directory
                CCLOG("AssetsManagerEx : can not create directory %s\n", fullPath.c_str());
                unzClose(zipfile);
                return false;
            }
        }
        else
        {
            // Create all directories in advance to avoid issue
            std::string dir = basename(fullPath);
            if (!_fileUtils->isDirectoryExist(dir)) {
                if (!_fileUtils->createDirectory(dir)) {
                    // Failed to create directory
                    CCLOG("AssetsManagerEx : can not create directory %s\n", fullPath.c_str());
                    unzClose(zipfile);
                    return false;
                }
            }
            // Entry is a file, so extract it.
            // Open current file.
            if (unzOpenCurrentFile(zipfile) != UNZ_OK)
            {
                CCLOG("AssetsManagerEx : can not extract file %s\n", fileName);
                unzClose(zipfile);
                return false;
            }

            // Create a file to store current file.
            FILE *out = fopen(FileUtils::getInstance()->getSuitableFOpen(fullPath).c_str(), "wb");
            if (!out)
            {
                CCLOG("AssetsManagerEx : can not create decompress destination file %s (errno: %d)\n", fullPath.c_str(), errno);
                unzCloseCurrentFile(zipfile);
                unzClose(zipfile);
                return false;
            }

            // Write current file content to destinate file.
            int error = UNZ_OK;
            do
            {
                error = unzReadCurrentFile(zipfile, readBuffer, BUFFER_SIZE);
                if (error < 0)
                {
                    CCLOG("AssetsManagerEx : can not read zip file %s, error code is %d\n", fileName, error);
                    fclose(out);
                    unzCloseCurrentFile(zipfile);
                    unzClose(zipfile);
                    return false;
                }

                if (error > 0)
                {
                    fwrite(readBuffer, error, 1, out);
                }
            } while(error > 0);

            fclose(out);
        }

        unzCloseCurrentFile(zipfile);

        // Goto next entry listed in the zip file.
        if ((i+1) < global_info.number_entry)
        {
            if (unzGoToNextFile(zipfile) != UNZ_OK)
            {
                CCLOG("AssetsManagerEx : can not read next file for decompressing\n");
                unzClose(zipfile);
                return false;
            }
        }
    }

    unzClose(zipfile);
    return true;
}

void AssetsManagerEx::decompressDownloadedZip(const std::string &customId, const std::string &storagePath)
{
    struct AsyncData
    {
        std::string customId;
        std::string zipFile;
        bool succeed;
    };

    AsyncData* asyncData = new AsyncData;
    asyncData->customId = customId;
    asyncData->zipFile = storagePath;
    asyncData->succeed = false;

    std::function<void(void*)> decompressFinished = [this](void* param) {
        auto dataInner = reinterpret_cast<AsyncData*>(param);
        if (dataInner->succeed)
        {
            fileSuccess(dataInner->customId, dataInner->zipFile);
        }
        else
        {
            std::string errorMsg = "Unable to decompress file " + dataInner->zipFile;
            // Ensure zip file deletion (if decompress failure cause task thread exit anormally)
            _fileUtils->removeFile(dataInner->zipFile);
            dispatchUpdateEvent(EventAssetsManagerEx::EventCode::ERROR_DECOMPRESS, "", errorMsg);
            fileError(dataInner->customId, errorMsg);
        }
        delete dataInner;
    };
    AsyncTaskPool::getInstance()->enqueue(AsyncTaskPool::TaskType::TASK_OTHER, decompressFinished, (void*)asyncData, [this, asyncData]() {
        // Decompress all compressed files
        if (decompress(asyncData->zipFile))
        {
            asyncData->succeed = true;
        }
        _fileUtils->removeFile(asyncData->zipFile);
    });
}

void AssetsManagerEx::dispatchUpdateEvent(EventAssetsManagerEx::EventCode code, const std::string &assetId/* = ""*/, const std::string &message/* = ""*/, int curle_code/* = CURLE_OK*/, int curlm_code/* = CURLM_OK*/)
{
    switch (code)
    {
        case EventAssetsManagerEx::EventCode::ERROR_UPDATING:
        //case EventAssetsManagerEx::EventCode::ERROR_PARSE_MANIFEST:
        case EventAssetsManagerEx::EventCode::ERROR_NO_LOCAL_MANIFEST:
        case EventAssetsManagerEx::EventCode::ERROR_DECOMPRESS:
        case EventAssetsManagerEx::EventCode::ERROR_DOWNLOAD_MANIFEST:
        case EventAssetsManagerEx::EventCode::UPDATE_FAILED:
        case EventAssetsManagerEx::EventCode::UPDATE_FINISHED:
        case EventAssetsManagerEx::EventCode::ALREADY_UP_TO_DATE:
            _updateEntry = UpdateEntry::NONE;
            break;
		case EventAssetsManagerEx::EventCode::UPDATE_CHECK:
			break;
        case EventAssetsManagerEx::EventCode::UPDATE_PROGRESSION:
            break;
        case EventAssetsManagerEx::EventCode::ASSET_UPDATED:
            break;
        case EventAssetsManagerEx::EventCode::NEW_VERSION_FOUND:
            if (_updateEntry == UpdateEntry::CHECK_UPDATE)
            {
                _updateEntry = UpdateEntry::NONE;
            }
            break;
        default:
            break;
    }

    EventAssetsManagerEx event(_eventName, this, code, _percent, _percentByFile, assetId, message, curle_code, curlm_code);
	event.setExtraInfo(_totalSize, _totalToDownload);
    _eventDispatcher->dispatchEvent(&event);
}

AssetsManagerEx::State AssetsManagerEx::getState() const
{
    return _updateState;
}

void AssetsManagerEx::downloadVersion()
{
    if (_updateState > State::PREDOWNLOAD_VERSION)
        return;

    // std::string versionUrl = _localManifest->getVersionFileUrl();

#if CC_64BITS
    const char* arch = "x64";
#else
    const char* arch = "x86";
#endif
    
	ChannelPlistInfo channelPlist = getChannelAndTag();
	char buf[256];
	sprintf(buf, "?arch=%s&app=%s&min_patch=%d&patch=%d&channel=%s&tag=%s&t=%.2f", arch, _appVersion.c_str(), _initPackPatch, _patch, channelPlist.channel.c_str(), channelPlist.tag.c_str(), (float)time(NULL));
	std::string versionUrl = _versionUrl + buf;

    if (versionUrl.size() > 0)
    {
        _updateState = State::DOWNLOADING_VERSION;
        // Download version file asynchronously
        _downloader->createDownloadFileTask(versionUrl, _tempVersionPath, VERSION_ID);
    }
}

void AssetsManagerEx::parseVersion()
{
    if (_updateState != State::VERSION_LOADED)
        return;

	_remoteManifest->parse(_tempVersionPath);

    if (!_remoteManifest->isVersionLoaded())
    {
        CCLOG("AssetsManagerEx : Fail to parse version file, step skipped\n");
//         _updateState = State::PREDOWNLOAD_MANIFEST;
//         downloadManifest();
		_updateState = State::FAIL_TO_UPDATE;
    }
    else
    {
        if (_remoteManifest->getAssets().empty() || _remoteManifest->isUpdateClose())
        {
            _fileUtils->removeDirectory(_tempStoragePath);
			// 5. Set update state
			_updateState = State::UP_TO_DATE;
			// 6. Notify finished event
			dispatchUpdateEvent(EventAssetsManagerEx::EventCode::ALREADY_UP_TO_DATE);
		}
		else
        {
            _updateState = State::NEED_UPDATE;

            // Wait to update so continue the process
            if (_updateEntry == UpdateEntry::DO_UPDATE)
            {
                // dispatch after checking update entry because event dispatching may modify the update entry
                dispatchUpdateEvent(EventAssetsManagerEx::EventCode::NEW_VERSION_FOUND);

				startUpdate();
            }
            else
            {
                dispatchUpdateEvent(EventAssetsManagerEx::EventCode::NEW_VERSION_FOUND);
            }
        }
    }
}

void AssetsManagerEx::startUpdate()
{
    if (_updateState != State::NEED_UPDATE)
        return;

    _updateState = State::UPDATING;
    // Clean up before update
    _failedUnits.clear();
    _downloadUnits.clear();
    _totalWaitToDownload = _totalToDownload = 0;
    _nextSavePoint = 0;
    _percent = _percentByFile = _sizeCollected = _totalSize = 0;
    _downloadedSize.clear();
    _totalEnabled = false;
  
    // Temporary manifest exists, resuming previous download
    if (_remoteManifest && _remoteManifest->isLoaded())
    {
		std::string msg = StringUtils::format("%d files need be check.", _remoteManifest->getAssets().size());
		dispatchUpdateEvent(EventAssetsManagerEx::EventCode::UPDATE_CHECK, "", msg);
        _remoteManifest->genResumeAssetsList(&_downloadUnits);
        if (_downloadUnits.size() == 0)
        {
            updateSucceed();
            return;
        }
        _totalWaitToDownload = _totalToDownload = (int)_downloadUnits.size();
        this->batchDownload();

        msg = StringUtils::format("%d files need be download.", _totalToDownload);
        dispatchUpdateEvent(EventAssetsManagerEx::EventCode::UPDATE_PROGRESSION, "", msg);
    }
    else
    {
        _updateState = State::FAIL_TO_UPDATE;
    }
}

void AssetsManagerEx::updateSucceed()
{
    std::string downloadPatch = _remoteManifest->getPatch();

    // 2. merge temporary storage path to storage path so that temporary version turns to cached version
    if (_fileUtils->isDirectoryExist(_tempStoragePath))
    {
		std::string patchStoragePath = _storagePath + downloadPatch + "/";
		_fileUtils->removeDirectory(patchStoragePath);
        bool mv = _fileUtils->renameFile(_tempStoragePath, patchStoragePath);
        if (!mv || _fileUtils->isDirectoryExist(_tempStoragePath))
        {
            // Merging all files in temp storage path to storage path
            
            _fileUtils->createDirectory(patchStoragePath);
            std::vector<std::string> files;
            _fileUtils->listFilesRecursively(_tempStoragePath, &files);
            int baseOffset = (int)_tempStoragePath.length();
            std::string relativePath, dstPath;
            for (std::vector<std::string>::iterator it = files.begin(); it != files.end(); ++it)
            {
                relativePath.assign((*it).substr(baseOffset));
                dstPath.assign(patchStoragePath + relativePath);
                // Create directory
                if (relativePath.back() == '/')
                {
                    _fileUtils->createDirectory(dstPath);
                }
                // Copy file
                else
                {
                    if (_fileUtils->isFileExist(dstPath))
                    {
                        _fileUtils->removeFile(dstPath);
                    }
                    _fileUtils->renameFile(*it, dstPath);
                }
            }
        }
        
        // Remove temp storage path
        _fileUtils->removeDirectory(_tempStoragePath);
    }
    
    // 4. save version to local userdefault
    auto userDefault = UserDefault::getInstance();
    userDefault->setStringForKey(keyWithHash(KEY_OF_VERSION), downloadPatch);
    userDefault->flush();
    
    // 5. Set update state
    _updateState = State::UP_TO_DATE;
    // 6. Notify finished event
    dispatchUpdateEvent(EventAssetsManagerEx::EventCode::UPDATE_FINISHED);
}

void AssetsManagerEx::update()
{
    if (_updateEntry != UpdateEntry::NONE)
    {
        CCLOGERROR("AssetsManagerEx::update, updateEntry isn't NONE");
        return;
    }

    if (!_inited)
	{
        CCLOG("AssetsManagerEx : Manifests uninited.\n");
        dispatchUpdateEvent(EventAssetsManagerEx::EventCode::ERROR_NO_LOCAL_MANIFEST);
        return;
    }


    _updateEntry = UpdateEntry::DO_UPDATE;

    switch (_updateState) {
        case State::UNCHECKED:
        {
            _updateState = State::PREDOWNLOAD_VERSION;
        }
        case State::PREDOWNLOAD_VERSION:
        {
            downloadVersion();
        }
            break;
        case State::VERSION_LOADED:
        {
            parseVersion();
        }
            break;
        case State::FAIL_TO_UPDATE:
        case State::NEED_UPDATE:
        {
            // Manifest not loaded yet
            if (!_remoteManifest->isLoaded())
            {
                 _updateState = State::PREDOWNLOAD_VERSION;
                 downloadVersion();
            }
            else
            {
                startUpdate();
            }
        }
            break;
        case State::UP_TO_DATE:
        case State::UPDATING:
        case State::UNZIPPING:
            _updateEntry = UpdateEntry::NONE;
            break;
        default:
            break;
    }
}

void AssetsManagerEx::updateAssets(const DownloadUnits& assets)
{
    if (!_inited)
	{
        CCLOG("AssetsManagerEx : Manifests uninited.\n");
        dispatchUpdateEvent(EventAssetsManagerEx::EventCode::ERROR_NO_LOCAL_MANIFEST);
        return;
    }

    if (_updateState != State::UPDATING && _remoteManifest->isLoaded())
    {
        _updateState = State::UPDATING;
        _downloadUnits.clear();
        _downloadedSize.clear();
        _percent = _percentByFile = _sizeCollected = _totalSize = 0;
        _totalWaitToDownload = _totalToDownload = (int)assets.size();
        _nextSavePoint = 0;
        _totalEnabled = false;
        if (_totalToDownload > 0)
        {
            _downloadUnits = assets;
            this->batchDownload();
        }
        else if (_totalToDownload == 0)
        {
            onDownloadUnitsFinished();
        }
    }
}

const DownloadUnits& AssetsManagerEx::getFailedAssets() const
{
    return _failedUnits;
}

void AssetsManagerEx::downloadFailedAssets()
{
    CCLOG("AssetsManagerEx : Start update %lu failed assets.\n", static_cast<unsigned long>(_failedUnits.size()));
    updateAssets(_failedUnits);
}

void AssetsManagerEx::fileError(const std::string& identifier, const std::string& errorStr, int errorCode, int errorCodeInternal)
{
    auto unitIt = _downloadUnits.find(identifier);
    // Found unit and add it to failed units
    if (unitIt != _downloadUnits.end())
    {
        _totalWaitToDownload--;

        DownloadUnit unit = unitIt->second;
        _failedUnits.emplace(unit.customId, unit);
    }
    dispatchUpdateEvent(EventAssetsManagerEx::EventCode::ERROR_UPDATING, identifier, errorStr, errorCode, errorCodeInternal);
    _remoteManifest->setAssetDownloadState(identifier, Manifest::DownloadState::UNSTARTED);

    _currConcurrentTask = MAX(0, _currConcurrentTask-1);
    queueDowload();
}

void AssetsManagerEx::fileSuccess(const std::string &customId, const std::string &storagePath)
{
    // Set download state to SUCCESSED
    _remoteManifest->setAssetDownloadState(customId, Manifest::DownloadState::SUCCESSED);

    auto unitIt = _failedUnits.find(customId);
    // Found unit and delete it
    if (unitIt != _failedUnits.end())
    {
        // Remove from failed units list
        _failedUnits.erase(unitIt);
    }

    unitIt = _downloadUnits.find(customId);
    if (unitIt != _downloadUnits.end())
    {
        // Reduce count only when unit found in _downloadUnits
        _totalWaitToDownload--;

        _percentByFile = 100 * (float)(_totalToDownload - _totalWaitToDownload) / _totalToDownload;
        // Notify progression event
        dispatchUpdateEvent(EventAssetsManagerEx::EventCode::UPDATE_PROGRESSION, "");
    }
    // Notify asset updated event
    dispatchUpdateEvent(EventAssetsManagerEx::EventCode::ASSET_UPDATED, customId);

    _currConcurrentTask = MAX(0, _currConcurrentTask-1);
    queueDowload();
}

void AssetsManagerEx::onError(const network::DownloadTask& task,
                              int errorCode,
                              int errorCodeInternal,
                              const std::string& errorStr)
{
    if (task.identifier == VERSION_ID)
    {
        CCLOG("AssetsManagerEx : Fail to download version file, retry %d\n", _downloadRetry);
        --_downloadRetry;
        
//         _updateState = State::PREDOWNLOAD_MANIFEST;
//         downloadManifest();
		if (_downloadRetry < 0)
		{
			_updateState = State::FAIL_TO_UPDATE;
            // wait for next download by user manually
            _downloadRetry = 3;
            
            dispatchUpdateEvent(EventAssetsManagerEx::EventCode::ERROR_DOWNLOAD_MANIFEST, task.identifier, errorStr, errorCode, errorCodeInternal);
			return;
		}

		_updateState = State::UNCHECKED;
		downloadVersion();
    }
    else
    {
        fileError(task.identifier, errorStr, errorCode, errorCodeInternal);
    }
}

void AssetsManagerEx::onProgress(double total, double downloaded, const std::string& /*url*/, const std::string &customId)
{
    if (customId == VERSION_ID /*|| customId == MANIFEST_ID*/)
    {
        _percent = 100 * downloaded / total;
        // Notify progression event
        dispatchUpdateEvent(EventAssetsManagerEx::EventCode::UPDATE_PROGRESSION, customId);
        return;
    }
    else
    {
        // Calculate total downloaded
        bool found = false;
        double totalDownloaded = 0;
        for (auto it = _downloadedSize.begin(); it != _downloadedSize.end(); ++it)
        {
            if (it->first == customId)
            {
                it->second = downloaded;
                found = true;
            }
            totalDownloaded += it->second;
        }
        // Collect information if not registed
        if (!found)
        {
            // Set download state to DOWNLOADING, this will run only once in the download process
            _remoteManifest->setAssetDownloadState(customId, Manifest::DownloadState::DOWNLOADING);
            // Register the download size information
            _downloadedSize.emplace(customId, downloaded);
            // Check download unit size existance, if not exist collect size in total size
            if (_downloadUnits[customId].size == 0)
            {
                _totalSize += total;
                _sizeCollected++;
                // All collected, enable total size
                if (_sizeCollected == _totalToDownload)
                {
                    _totalEnabled = true;
                }
            }
        }

        if (_totalEnabled && _updateState == State::UPDATING)
        {
            float currentPercent = 100 * totalDownloaded / _totalSize;
            // Notify at integer level change
            if ((int)currentPercent != (int)_percent) {
                _percent = currentPercent;
                // Notify progression event
                dispatchUpdateEvent(EventAssetsManagerEx::EventCode::UPDATE_PROGRESSION, customId);
            }
        }
    }
}

void AssetsManagerEx::onSuccess(const std::string &/*srcUrl*/, const std::string &storagePath, const std::string &customId)
{
    if (customId == VERSION_ID)
    {
        _updateState = State::VERSION_LOADED;
        
        // mac/ios NSURLRequest will be ungzip auto
#if (CC_TARGET_PLATFORM == CC_PLATFORM_MAC || CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
        parseVersion();
#else
        unsigned char* data;
        int size = ZipUtils::inflateGZipFile(_tempVersionPath.c_str(), &data);
        if (size > 0)
        {
            Data cdata;
            cdata.fastSet(data, size);
            _fileUtils->writeDataToFile(cdata, _tempVersionPath);
            parseVersion();
        }
        else
        {
            _updateState = State::FAIL_TO_UPDATE;
        }
#endif
        
		
    }
    else
    {
        bool ok = true;
        auto &assets = _remoteManifest->getAssets();
        auto assetIt = assets.find(customId);
        if (assetIt != assets.end())
        {
            Manifest::Asset asset = assetIt->second;
			Data cdata = _fileUtils->getDataFromFile(storagePath);
			if (isTJCompressed((char*)cdata.getBytes(), cdata.getSize()))
			{
				char* buf;
				int len = tjDecompress((char*)cdata.getBytes(), cdata.getSize(), buf);
				if (len <= 0)
				{
					ok = false;
				}
				else
				{
					cdata.clear();
					cdata.fastSet((unsigned char*)buf, len);
					_fileUtils->writeDataToFile(cdata, storagePath);
				}
			}
			// size and md5 verify
            // size and md5 are base on raw data(inflate with tjDecompress)
            if (ok)
			{
                if (cdata.getSize() == asset.size)
                {
                    std::string md5str = ymextra::CCCrypto::MD5String((void*)cdata.getBytes(), cdata.getSize());
                    ok = (md5str == asset.md5);
                }
				else
                {
                    ok = false;
                }
			}
            if (ok && _verifyCallback != nullptr)
            {
                ok = _verifyCallback(storagePath, asset);
            }
        }

        if (ok)
        {
            bool compressed = assetIt != assets.end() ? assetIt->second.compressed : false;
            if (compressed)
            {
                decompressDownloadedZip(customId, storagePath);
            }
            else
            {
                fileSuccess(customId, storagePath);
            }
        }
        else
        {
            fileError(customId, "Asset file verification failed after downloaded");
        }
    }
}

void AssetsManagerEx::destroyDownloadedVersion()
{
    _fileUtils->removeDirectory(_storagePath);
    _fileUtils->removeDirectory(_tempStoragePath);
}

void AssetsManagerEx::batchDownload()
{
    _queue.clear();
    for(auto iter : _downloadUnits)
    {
        const DownloadUnit& unit = iter.second;
        if (unit.size > 0)
        {
            _totalSize += unit.size;
            _sizeCollected++;
        }

        _queue.push_back(iter.first);
    }
    // All collected, enable total size
    if (_sizeCollected == _totalToDownload)
    {
        _totalEnabled = true;
    }

    queueDowload();
}

void AssetsManagerEx::queueDowload()
{
    if (_totalWaitToDownload == 0)
    {
        this->onDownloadUnitsFinished();
        return;
    }

    while (_currConcurrentTask < _maxConcurrentTask && _queue.size() > 0)
    {
        std::string key = _queue.back();
        _queue.pop_back();

        _currConcurrentTask++;
        DownloadUnit& unit = _downloadUnits[key];
        _fileUtils->createDirectory(basename(unit.storagePath));
        _downloader->createDownloadFileTask(unit.srcUrl, unit.storagePath, unit.customId);

        _remoteManifest->setAssetDownloadState(key, Manifest::DownloadState::DOWNLOADING);
    }
}

void AssetsManagerEx::onDownloadUnitsFinished()
{
    // Finished with error check
    if (_failedUnits.size() > 0)
    {
        // Save current download manifest information for resuming
        _remoteManifest->saveToFile(_tempVersionPath);

        _updateState = State::FAIL_TO_UPDATE;
        dispatchUpdateEvent(EventAssetsManagerEx::EventCode::UPDATE_FAILED);
    }
    else if (_updateState == State::UPDATING)
    {
        updateSucceed();
    }
}

void AssetsManagerEx::setLocalSearchPath(bool inMain)
{
	char buf[256];
	VersionPlistInfo versionPlist = getLocalVersion();
	int localPatch = atoi(versionPlist.patch.c_str());
    int localExistedPatch = _initPackPatch;
    std::vector<string> localVersionPath;
	std::set<string> patchSearchPath;
	std::string majorVersion = getAppMajorVersion(versionPlist.app_version);

	for (int i = _initPackPatch + 1; i <= localPatch; ++i)
	{
		sprintf(buf, "%s%d/", _storagePath.c_str(), i);
		std::string path = buf;
		std::string filelistPath = path + VERSION_FILENAME;

		// 这里的filelist其实就是diff server返回的json
		if (_fileUtils->isFileExist(filelistPath))
		{
            localExistedPatch = i;
			localVersionPath.push_back(path);
			if (inMain)
			{
				std::string data = _fileUtils->getStringFromFile(filelistPath);
				DiffInfo info;
				if (parseDiff(data, info))
				{
					for (auto it = info.files.begin(); it != info.files.end(); it++)
						_fileUtils->addPatchSearchPath(it->name, path);
					patchSearchPath.insert(path);
				}
				else
				{
					CCLOG("%s data error", filelistPath.c_str());
				}
			}
		}
	}
    
    // userdefault里存的patch版本号，找不到相关目录下的version.diff
    if (localExistedPatch != localPatch)
    {
        CCLOG("%d local patch error, existed %d", localPatch, localExistedPatch);
        
        localPatch = localExistedPatch;
        sprintf(buf, "%d", localPatch);
        auto userDefault = UserDefault::getInstance();
        userDefault->setStringForKey(keyWithHash(KEY_OF_VERSION), buf);
        userDefault->flush();
    }

    std::vector<string> searchPaths = _fileUtils->getSearchPaths();
	searchPaths.insert(searchPaths.begin(), localVersionPath.rbegin(), localVersionPath.rend());
	// 0代表分包，优先级最低，并且不参与slim search
	if (inMain)
	{
		searchPaths.push_back(_storagePath + getMicroPathInStorage());
	}

	vector<string> slimSearchPaths;
	if (!patchSearchPath.empty())
	{
		for (auto it = searchPaths.begin(); it != searchPaths.end(); it++)
		{
			if (patchSearchPath.count(*it) > 0)
				CCLOG("patch %s search path ignore", it->c_str());
			else
				slimSearchPaths.push_back(*it);
		}
	}
	_fileUtils->setSearchPaths(searchPaths);
	if (!slimSearchPaths.empty())
		_fileUtils->setSlimSearchPaths(slimSearchPaths);

	vector<string> searchResolutionsOrders;
	searchResolutionsOrders.clear();
	_fileUtils->setSearchResolutionsOrder(searchResolutionsOrders);
}

void AssetsManagerEx::onLuaSuccess()
{
    Director::getInstance()->getScheduler()->performFunctionInCocosThread([=] {
        this->_appOnSuccess();
        //this->release();
    });
}

NS_CC_EXT_END

