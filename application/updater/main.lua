--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- updater入口
--

print("Updater UI working...")

require "defines"
require "cocos_init"
require "l10n"

local scene = nil
local curTime = 0
local delayTime = 2

local loading = nil
local label = nil
local function createLayer()
	local layer = cc.Layer:create()
	local bk = cc.Sprite:create("img/loading_bg.jpg")
	bk:setPosition(display.visibleCenter)

	loading = cc.ControlSlider:create("img/updater/patch_loading_bar_bg.png", "img/updater/patch_loading_bar.png", "img/updater/patch_loading_light.png")
	loading:setMaximumValue(100)
	loading:setMinimumValue(0)
	loading:setValue(0)
	loading:setEnabled(false)
	loading:setPosition(cc.p(display.width/2, 100))
	loading:setVisible(false)

	label = cc.Label:createWithTTF(Language.checkUpdate, "font/youmi.ttf", 20)
	label:setColor(cc.c3b(0, 0, 0))
	label:setAnchorPoint(cc.p(0,0.5))
	label:setPosition(cc.p(270,125))


	layer:addChild(bk)
	--layer:addChild(sprite)
	layer:addChild(loading)
	layer:addChild(label)
	return layer
end

local function showErrorPanel(errStr, close_cb)
	-- local panel = ccs.GUIReader:getInstance():widgetFromJsonFile("ERROR_1.json")
	-- panel:getChildByTag(1707):setString(errStr)
	-- panel:getChildByTag(1730):setVisible(false)
	-- panel:getChildByTag(1703):addTouchEventListener(function(sender, eventType)
	-- 	if eventType == ccui.TouchEventType.ended then
	-- 		scene:removeChildByName("error")
	-- 		if close_cb then
	-- 			close_cb()
	-- 		end
	-- 	end
	-- end)
	-- scene:addChild(panel,9999999,"error")
end

local TIP_STATUS = 0 -- 大包下载时，给予提示，0 未弹框 1 弹框中 2 弹框已关闭
function globals.progressCallBack(patchIdx,patchCount,nowDownloaded,totalToDownload)
	print("progressCallBack", patchIdx,patchCount,nowDownloaded,totalToDownload)

	if totalToDownload == 0 or patchCount == 0 then return end
	local percent = nowDownloaded*100 / totalToDownload  --单个包的百分比
	--local percentAll = (percent + (patchIdx-1)*100) / patchCount --全部包的百分比
	if totalToDownload > 100000 then
		if TIP_STATUS == 0 then
			TIP_STATUS = 1
			loading:setVisible(false)
			label:setVisible(false)
			showErrorPanel(Language.wifiTip, function()
				loading:setVisible(true)
				label:setVisible(true)
				TIP_STATUS = 2
				return
			end)
		end
		patchIdx = math.floor(percent / 20) + patchIdx
		percent = percent * 5 % 100
		patchCount = patchCount + 5
		if TIP_STATUS <= 1 then
			return
		end
	end
	loading:setVisible(true)
	loading:setValue(percent)
	if nowDownloaded >= totalToDownload then
		label:setString(Language.umcompress)
	else
		label:setString(string.format(Language.downloading,
			patchIdx,patchCount,nowDownloaded,totalToDownload))
	end
end

local ErrorCode = {
	CREATE_FILE = 0, --归到UNCOMPRESS了，可能会进来多次，因为有多次retry
	NETWORK = 1, --归到UNCOMPRESS了，可能会进来多次，因为有多次retry
	NO_NEW_VERSION = 2,
	UNCOMPRESS = 3, --这个只会进来一次
	CHECK_NOT_APP_VERSION = 4,
	CHECK_INITCURL = 5, --curl 初始化不成功
	CHECK_NETWORK = 6,
	CHECK_CONNECT = 7, --本地网络设置没打开，也可能服务器挂了.如果瞬间就响应回来，基本就是本地网络问题，否则就是后者
	CHECK_VERSION_ERROR = 8, --小版本异常 本地版本比服务器的版本还大
}
local ErrorCodeStr = {}
for k, v in pairs(ErrorCode) do
	ErrorCodeStr[v] = k
end

function globals.errorCallBack(errCode)
	print("errorCallBack", errCode, ErrorCodeStr[errCode])
	if errCode == ErrorCode.NO_NEW_VERSION then  --更新成功
		local nowTime = os.time()
		local delta = nowTime - curTime > delayTime and 0 or delayTime - (nowTime - curTime)
		if delta < 0 then delta = 0 end
		performWithDelay(scene, function()
			cc.AssetsManager:getInstance():seccessOver()
		end, delta)

	elseif errCode == ErrorCode.CHECK_CONNECT then
		showErrorPanel(Language.noConnected,function()
			cc.AssetsManager:getInstance():update()
		end)

	elseif errCode == ErrorCode.CHECK_INITCURL or
		errCode == ErrorCode.CHECK_NETWORK then
		showErrorPanel(Language.reConnect,function()
			cc.AssetsManager:getInstance():update()
		end)

	elseif errCode == ErrorCode.UNCOMPRESS then
		showErrorPanel(Language.unzipFailed,function()
			cc.AssetsManager:getInstance():update()
		end)

	elseif errCode == ErrorCode.CHECK_NOT_APP_VERSION then --大版本对不上
		--需要引导去appStore去下载最新的客户端
		showErrorPanel(Language.oldApp,function()
		end)

	elseif errCode == ErrorCode.CHECK_VERSION_ERROR then --小版本异常 本地版本比服务器的版本还大
		--把userdefault里的patch版本重置为最小版本
		cc.AssetsManager:getInstance():resetSomething() --这个一定要调用，不然有问题会永远残留
		-- local minPatch = cc.AssetsManager:getInstance():getPatchMinVersion()
		-- -- patch
		-- local PATCHKEY = '0ee265de8929e92360337fcdeb426b8d'
		-- cc.UserDefault:getInstance():setStringForKey(PATCHKEY,tostring(minPatch))
		showErrorPanel(Language.loginUpdating,function()
			cc.AssetsManager:getInstance():update()
		end)
	end
end

local function main()
	-- avoid memory leak
	collectgarbage("setpause", 100)
	collectgarbage("setstepmul", 5000)
	collectgarbage("stop")

	local director = cc.Director:getInstance()
	cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_AUTO)

	scene = cc.Scene:create()
	cc.FileUtils:getInstance():addSearchResolutionsOrder("res")
	for _, lang in ipairs({"_vn", "_en", "_tw", "_th", ""}) do
		cc.FileUtils:getInstance():addSearchResolutionsOrder("res/Resources" .. lang)
	end
	cc.Director:getInstance():setDisplayStats(false)
	scene:addChild(createLayer())
	director:runWithScene(scene)
	-- AudioEngine.playMusic("sound/login.mp3", true)

	local nbk = cc.Sprite:create("img/updater/splash.jpg")
	nbk:setPosition(display.visibleCenter)
	nbk:runAction(cc.Sequence:create(cc.DelayTime:create(delayTime-0.2), cc.FadeOut:create(0.2)))
	scene:addChild(nbk, 999999999)

	curTime = os.time()

	local manager = cc.AssetsManagerEx:getInstance()
	local function onEvent(event)
		print('onEvent ------------------')
		print('getAssetId', event:getAssetId())
		print('getCURLECode', event:getCURLECode())
		print('getCURLMCode', event:getCURLMCode())
		print('getMessage', event:getMessage())
		print('getEventCode', event:getEventCode())
		print('getPercent', event:getPercent(), event:getTotalBytes())
		print('getPercentByFile', event:getPercentByFile(), event:getTotalFiles())

		local code = event:getEventCode()
		if code == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
			print('no new version')
			manager:onLuaSuccess()
		elseif code == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
			print('updated ok')
			manager:onLuaSuccess()
		elseif code == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST then
			print('download diff error')
			manager:update()
		elseif code == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
			manager:downloadFailedAssets()
		end
	end

	local listener = cc.EventListenerAssetsManagerEx:create(manager, onEvent)
	cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, scene)
	print('listen', manager)
end


xpcall(main, __G__TRACKBACK__)

