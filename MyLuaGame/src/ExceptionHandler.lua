--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2015/7/24
-- Time: 16:27
-- To change this template use File | Settings | File Templates.
--

globals.EXCEPTION_TAG = "cocos-lua"

local function LuaJavaSendReport_(msg,trace)
	print("Android begin")
	local info = msg.."\r\n"..trace
	local tag = EXCEPTION_TAG
	local args = { info,tag }
	local sigs = "(Ljava/lang/String;Ljava/lang/String;)Z"
	local className = "com/netease/nis/bugrpt/CrashHandler"
	local luaj = require "cocos.cocos2d.luaj"
	local ok,ret = luaj.callStaticMethod(className,"sendReportsBridge",args,sigs)
	if not ok then
		print("luaj error:", ret)
	else
		print("The ret is:", ret)
	end
	print("Android end")
end

globals.LuaJavaSendReport = LuaJavaSendReport_

local function LuaObjectCSendReport_(msg,trace)
	print("IOS begin")
	local params = {
		name = msg,
		stack = trace
	}
	local className = "NTESBugrptInternalInterface"
	local luaoc = require "cocos.cocos2d.luaoc"
	local ok,ret = luaoc.callStaticMethod(className,"sendLuaReportsToServer",params)
	if not ok then
		print("luaj error:", ret)
	else
		print("The ret is:", ret)
	end
	print("IOS end")
end

globals.LuaObjectCSendReport = LuaObjectCSendReport_

local function isPlatformSupportOCBridge()
	local supportObjectCBridge  = false
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_MAC == targetPlatform)  then
		supportObjectCBridge = true
	end
	return supportObjectCBridge
end

local function isPlatformSupportJavaBridge()
	local supportJavaBridge = false
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if (cc.PLATFORM_OS_ANDROID == targetPlatform) then
		supportJavaBridge = true
	end
	return supportJavaBridge
end

local function post2TJCrashCollector(msg, trace)
	-- TODO: host url be read in config
	local reqUrl = string.format("%s/exception?app=%s&patch=%d&min_patch=%d&lang=%s&channel=%s&tag=%s&account=&server=&role=&", "http://0.0.0.0:1234", APP_VERSION, PATCH_VERSION, PATCH_MIN_VERSION, LOCAL_LANGUAGE, APP_CHANNEL, APP_TAG)
	local reqBlob = json.encode({msg = msg, traceback = trace})
	return gNet:sendHttpRequest("POST", reqUrl, reqBlob, cc.XMLHTTPREQUEST_RESPONSE_BLOB, function(xhr)
		if xhr.status == 200 then
		else
		end
	end)
end

local function handleLuaException_(msg)
	if msg == nil then return end

	print("handleLuaException begin", isPlatformSupportJavaBridge(), isPlatformSupportOCBridge())

	if (isPlatformSupportJavaBridge() == true) then
		--call java function
		LuaJavaSendReport(tostring(msg), debug.traceback())
	elseif (isPlatformSupportOCBridge() == true) then
		--call oc function
		LuaObjectCSendReport(tostring(msg), debug.traceback())
	end

	--call my function
	post2TJCrashCollector(tostring(msg), debug.traceback())

	print("handleLuaException end")
end

globals.handleLuaException = handleLuaException_
globals.post2TJCrashCollector = post2TJCrashCollector
