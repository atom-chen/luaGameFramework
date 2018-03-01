--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 应用相关全局变量
--


--
-- versionPlist
--
local versionPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/version.plist')
-- "http://192.168.1.125/game01/version_fake.conf" 控制读取服务器列表的url
globals.VERSION_CONF_URL = versionPlist.versionUrl
-- "http://um-game.com/game01/serv.conf" --控制读取服务器列表的url
globals.SERVER_CONF_URL = versionPlist.serverUrl
globals.LOGIN_SERVRE_HOSTS_TABLE = {}
for i = 1, 10 do
	if versionPlist[string.format("loginServer%d",i)] then
		table.insert(LOGIN_SERVRE_HOSTS_TABLE, versionPlist[string.format("loginServer%d",i)])
	end
end
if next(LOGIN_SERVRE_HOSTS_TABLE) then
	globals.IPV6_TEST_HOST = string.gmatch(LOGIN_SERVRE_HOSTS_TABLE[1], '([-a-z0-9A-Z.]+):(%d+)')()
end

--userdefault里保存的app版本 只对前三位维护
globals.APP_VERSION = versionPlist.app_version

local assets = cc.AssetsManagerEx:getInstance()
globals.PATCH_MIN_VERSION = assets:getPatchMinVersion()
globals.PATCH_VERSION = assets:getPatchVersion()
print('APP_VERSION', APP_VERSION)
print('PATCH_MIN_VERSION', PATCH_MIN_VERSION)
print('PATCH_VERSION', PATCH_VERSION)

--
-- languagePlist
--

-- 地区码参考
-- http://www.lingoes.cn/zh/translator/langcode.htm
-- 简化定义参考csv_language.py
local languagePlist = cc.FileUtils:getInstance():getValueMapFromFile('res/language.plist')
globals.LOCAL_LANGUAGE = languagePlist.localization or 'cn'
print('LOCAL_LANGUAGE', LOCAL_LANGUAGE)

--默认东八区时间
globals.UNIVERSAL_TIMEDELTA = 8 * 3600
if LOCAL_LANGUAGE == 'en' then
	--西五区时间
	UNIVERSAL_TIMEDELTA = -5 * 3600
elseif LOCAL_LANGUAGE == 'vn' then
	--东七区时间
	UNIVERSAL_TIMEDELTA = 7 * 3600
end

--
-- channelPlist
--
local channelPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/channel.plist')
globals.APP_CHANNEL = channelPlist.channel
globals.APP_TAG = channelPlist.tag

--
-- app key
--

-- AppVersion
globals.APPVERSIONKEY = 'ccc6ee8fa966b092400d9bfbe4a1ad3b'
-- patch
globals.PATCHKEY = '0ee265de8929e92360337fcdeb426b8d'

-- 缓存localServerAppVersion
globals.SERVERAPPVERSIONKEY = '461ab4f8436296e39db1ecb0e84efb88'
-- 缓存localServerPatch
globals.SERVERPATCHKEY = '7bafbfccdf62bfb58a7e0c681960b8df'

