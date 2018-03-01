--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 主入口
--
print("Game Main working...")

require "lib"

function __G__TRACKBACK__(msg)
	print("----------------------------------------")
	print("LUA ERROR: " .. tostring(msg) .. "\n")
	print(debug.traceback())
	print("----------------------------------------")
	handleLuaException(msg)
end


local function main()
	-- for debug log
	cc.FileUtils:getInstance():setPopupNotify(true)
	if device.platform == "windows" then
		DEBUG = 2
		CC_SHOW_FPS = true
	else
		EDITOR_ENABLE = false
		log.disable()
	end

	-- log.xxx.yyyy("hello")
	-- log.xxx("hello")

	-- post2TJCrashCollector("hello crash collect", debug.traceback())

	require("app.game_app"):create():run("login.main")

	-- FinalSDK.login()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
	print(msg)
end
