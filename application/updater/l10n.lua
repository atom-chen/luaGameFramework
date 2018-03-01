
local languagePlist = cc.FileUtils:getInstance():getValueMapFromFile('res/language.plist')
globals.LOCAL_LANGUAGE = languagePlist.localization or 'cn'
print('LOCAL_LANGUAGE', LOCAL_LANGUAGE)

globals.LanguageTexts = {
	cn = {
		checkUpdate = '检查更新中...',
		downloading = '正在下载安装中... 包序列:%d / %d  包大小:%dK / %dK',
		-- noConnected = '无法连接，QQ群283206793',
		noConnected = '无法连接',
		reConnect = '请重新连接',
		unzipFailed = '解压失败',
		oldApp = '版本过旧\n需要重新下载最新的客户端',
		loginUpdating = '登陆服务器正在更新中，请稍等',
		umcompress = '正在解压中，请稍等',
		wifiTip = '资源较大，请在wifi环境下下载资源 土豪请随意',
	},
	tw = {
		checkUpdate = '检查更新中...',
		downloading = '正在下载安装中... 包序列:%d / %d  包大小:%dK / %dK',
		noConnected = '无法连接',
		reConnect = '请重新连接',
		unzipFailed = '解压失败',
		oldApp = '版本过旧\n需要重新下载最新的客户端',
		loginUpdating = '登陆服务器正在更新中，请稍等',
		umcompress = '正在解壓中，請稍等',
		wifiTip = '資源較大，請在wifi環境下下載資源 土豪請隨意',
	},
	en = {
		checkUpdate = 'checking update...',
		downloading = 'downloading... patch:%d / %d  size:%dK / %dK',
		noConnected = 'no network',
		reConnect = 'please retry connect',
		unzipFailed = 'uncompress failed',
		oldApp = 'old client version\nplease download new client',
		loginUpdating = 'server updateing, please wait a moment',
		umcompress = 'Extracting, please wait a moment',
		wifiTip = 'Extracting, please wait a moment',
	},
	vn = {
		checkUpdate = 'Chi?n ??u ?i th??ng 50 l?n',
		downloading = 'Chi?n ??u ?i th??ng 50 l?n',
		noConnected = 'Chi?n ??u ?i th??ng 50 l?n',
		reConnect = 'Chi?n ??u ?i th??ng 50 l?n',
		unzipFailed = 'Chi?n ??u ?i th??ng 50 l?n',
		oldApp = 'Chi?n ??u ?i th??ng 50 l?n',
		loginUpdating = 'Chi?n ??u ?i th??ng 50 l?n',
		umcompress = 'Chi?n ??u ?i th??ng 50 l?n',
		wifiTip = 'Chi?n ??u ?i th??ng 50 l?n',
	},
}
globals.Language = LanguageTexts[LOCAL_LANGUAGE]
if Language == nil then
	Language = LanguageTexts.cn
end
Language = setmetatable(Language, {__index = function()
	return "text_placeholder"
end})