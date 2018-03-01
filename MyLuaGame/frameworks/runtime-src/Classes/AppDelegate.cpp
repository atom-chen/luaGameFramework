#include "AppDelegate.h"
#include "cocos2d.h"
#include "LuaExceptionHandler.h"
#include "ymextra/crypto/CCCrypto.h"
#include "assets-manager/VersionUtils.h"
// #include "assets-manager/AssetsManager.h"
#include "assets-manager/AssetsManagerEx.h"
#include "scripting/lua-bindings/manual/CCLuaEngine.h"

// #define USE_AUDIO_ENGINE 1
// #define USE_SIMPLE_AUDIO_ENGINE 1

#if USE_AUDIO_ENGINE && USE_SIMPLE_AUDIO_ENGINE
#error "Don't use AudioEngine and SimpleAudioEngine at the same time. Please just select one in your game!"
#endif

#if USE_AUDIO_ENGINE
#include "audio/include/AudioEngine.h"
using namespace cocos2d::experimental;
#elif USE_SIMPLE_AUDIO_ENGINE
#include "audio/include/SimpleAudioEngine.h"
using namespace CocosDenshion;
#endif


USING_NS_CC;
USING_NS_CC_EXT;
USING_NS_YM_EXTRA;
using namespace std;

const char* kCompanyShortName = "TianJi";
const char* kCompanyName = "TianJi Information Technology Inc.";

static AssetsManagerEx* assetsManager = nullptr;

AppDelegate::AppDelegate()
{
}

AppDelegate::~AppDelegate()
{
#if USE_AUDIO_ENGINE
    AudioEngine::end();
#elif USE_SIMPLE_AUDIO_ENGINE
    SimpleAudioEngine::end();
#endif

#if (COCOS2D_DEBUG > 0) && (CC_CODE_IDE_DEBUG_SUPPORT > 0)
    // NOTE:Please don't remove this call if you want to debug with Cocos Code IDE
    RuntimeEngine::getInstance()->end();
#endif

}

// if you want a different context, modify the value of glContextAttrs
// it will affect all platforms
void AppDelegate::initGLContextAttrs()
{
    // set OpenGL context attributes: red,green,blue,alpha,depth,stencil
    GLContextAttrs glContextAttrs = {8, 8, 8, 8, 24, 8};

    GLView::setGLContextAttrs(glContextAttrs);
}

// if you want to use the package manager to install more packages,
// don't modify or remove this function
// static int register_all_packages()
// {
//     return 0; //flag for packages manager
// }

bool AppDelegate::applicationDidFinishLaunching()
{
    // set default FPS
    Director::getInstance()->setAnimationInterval(1.0 / 60.0f);

	//pvr.ccz的key
	// 37e2e2bc0953acedc06c1c75ff4fee3b
	ZipUtils::setPvrEncryptionKey(0x37e2e2bc, 0x0953aced, 0xc06c1c75, 0xff4fee3b);

#if (CC_TARGET_PLATFORM != CC_PLATFORM_WIN32)
	// libbugrpt
	LuaExceptionHandler::registerLuaExceptionHandler("A001968155");
#endif // #if (CC_TARGET_PLATFORM != CC_PLATFORM_WIN32)

	// update
	prepareUpdate();

#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	FILE* noupdateFp = fopen(".noupdate", "rb");
	if (noupdateFp)
	{
		CCLOG("update closed mode in win32");
		fclose(noupdateFp);
		// 延迟2帧
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([=]() {
			Director::getInstance()->getScheduler()->performFunctionInCocosThread([=]() {
				this->updateSuccessCallBack();
			});
		});
	}
	else
	{
		didUpdateAndRun();
	}
#else
	didUpdateAndRun();
#endif
	return true;
}

// This function will be called when the app is inactive. Note, when receiving a phone call it is invoked.
void AppDelegate::applicationDidEnterBackground()
{
    Director::getInstance()->stopAnimation();

#if USE_AUDIO_ENGINE
    AudioEngine::pauseAll();
#elif USE_SIMPLE_AUDIO_ENGINE
    SimpleAudioEngine::getInstance()->pauseBackgroundMusic();
    SimpleAudioEngine::getInstance()->pauseAllEffects();
#endif
}

// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground()
{
    Director::getInstance()->startAnimation();

#if USE_AUDIO_ENGINE
    AudioEngine::resumeAll();
#elif USE_SIMPLE_AUDIO_ENGINE
    SimpleAudioEngine::getInstance()->resumeBackgroundMusic();
    SimpleAudioEngine::getInstance()->resumeAllEffects();
#endif
}



//////////////////////////////////////////////////////////////////////////
using namespace cocos2d::network;

static char _toConfuse(char ch)
{
	if (ch >= 'a' && ch <= 'z') return ch - 'a' + 'A';
	else if (ch == '_') return '+';
	else if (ch == '.' || ch == '6') return ';';
	return ch;
}

static std::string _toLuaPwd(std::string version)
{
	// for code confusion
	// 1. a = _toConfuse("hello"+kCompanyShortName+",world"+kCompanyName)
	// 2. b = MD5(a) + string("6A"+version+kCompanyShortName)
	// 3. c = _toConfuse(b)
	// 4. d = reverse(c)
	// 5. e = MD5(d)
	int pos = version.find_last_of('.'); //把最后一位舍掉了
	std::string confusion = "hello" + std::string(kCompanyShortName) + ",world" + kCompanyName;
	std::transform(confusion.begin(), confusion.end(), confusion.begin(), _toConfuse);
	std::string updatePass = ymextra::CCCrypto::MD5String((void*)confusion.c_str(), confusion.length());
	updatePass += "6A" + version.substr(0, pos) + kCompanyShortName;
	std::transform(updatePass.begin(), updatePass.end(), updatePass.begin(), _toConfuse);
	std::reverse(updatePass.begin(), updatePass.end());
	return ymextra::CCCrypto::MD5String((void*)updatePass.c_str(), updatePass.length());
}


// update flow:
// get remote version.conf            +------------+
//          +                         | updater.lua|
//          |                         +------------+
//          v     yes                 |            |
//       app old?+--->exit,           |     UI     |
//          +         update in store |            |
//          |                         |            |
//          v         no              |            |
//     version old?+------+           |            |
//          +             |           |            |
//          |             |           |            |
//          v             |  callback |            |
//  download and update+---------------->  55%     |
//          +             |           |            |
//          |             |           |            |
//          v             |           |            |
//  set path and reload   |           |            |
//          +             |           |            |
//          |             |           |            |
//          v             |           |            |
//      run game <--------+           +------------+
//
bool AppDelegate::didUpdateAndRun()
{
	// while (true)
	assetsManager->update();

	return true;
}

void AppDelegate::prepareUpdate()
{
	_initSearchPaths = FileUtils::getInstance()->getSearchPaths();
	
	std::string storagePath = FileUtils::getInstance()->getWritablePath() + "patch/";
	// shuma项目旧的更新方式，按patch版本号顺序下载zip包
// 	auto assertManager = AssetsManager::create("", "", storagePath.c_str(),
// 		CC_CALLBACK_1(AppDelegate::updateErrCallBack, this),
// 		CC_CALLBACK_4(AppDelegate::updateProgressCallBack, this),
// 		CC_CALLBACK_0(AppDelegate::updateSuccessCallBack, this));

	// 新项目方式，按diff server返回的文件列表来下载增量更新
	// http://wiki.tianji-game.com:8090/pages/viewpage.action?pageId=5013655
	assetsManager = AssetsManagerEx::create(CC_CALLBACK_0(AppDelegate::updateSuccessCallBack, this), storagePath);
	assetsManager->retain();
	// assetsManager->setConnectionTimeout(8);

	auto engine = LuaEngine::getInstance();
	ScriptEngineManager::getInstance()->setScriptEngine(engine);

	VersionPlistInfo versionPlist = getLocalVersion();
	std::string pwd = _toLuaPwd(versionPlist.app_version); //要取大版本号
	engine->getLuaStack()->setXXTEAKeyAndSign(pwd.c_str(), pwd.length(), kCompanyShortName, strlen(kCompanyShortName));

#if CC_64BITS
	engine->getLuaStack()->addSearchPath("cocos_x64");
	engine->getLuaStack()->addSearchPath("updater_x64");
#else
	engine->getLuaStack()->addSearchPath("cocos");
	engine->getLuaStack()->addSearchPath("updater");
#endif

	// load updater screen
	if (engine->executeString("require 'main'"))
	{
	}

}

void AppDelegate::updateSuccessCallBack()
{
	// remove old lua engine
	ScriptEngineManager::getInstance()->removeScriptEngine();

	// new lua engine and run
	auto engine = LuaEngine::getInstance();
	ScriptEngineManager::getInstance()->setScriptEngine(engine);

	// rebuild search path
	auto utils = FileUtils::getInstance();
	utils->setSearchPaths(_initSearchPaths);
	assetsManager->setLocalSearchPath(true);

	// load lua
	VersionPlistInfo versionPlist = getLocalVersion();
	std::string pwd = _toLuaPwd(versionPlist.app_version); //要取大版本号
	engine->getLuaStack()->setXXTEAKeyAndSign(pwd.c_str(), pwd.length(), kCompanyShortName, strlen(kCompanyShortName));

#if CC_64BITS
	engine->getLuaStack()->addSearchPath("cocos_x64");
	engine->getLuaStack()->addSearchPath("src_x64");
#else
	engine->getLuaStack()->addSearchPath("cocos");
	engine->getLuaStack()->addSearchPath("src");
#endif

	assetsManager->autorelease();

	// pop updater screen
	Director::getInstance()->popToSceneStackLevel(0);

	// run lua
	if (engine->executeString("require 'main'"))
	{
	}
}
