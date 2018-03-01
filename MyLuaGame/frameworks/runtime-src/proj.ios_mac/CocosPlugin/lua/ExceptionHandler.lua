--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2015/7/24
-- Time: 16:27
-- To change this template use File | Settings | File Templates.
--

cc.exports.EXCEPTION_TAG = "cocos-lua"

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

cc.exports.LuaJavaSendReport = LuaJavaSendReport_

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

cc.exports.LuaObjectCSendReport = LuaObjectCSendReport_

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

local function handleLuaException_(msg)
    if msg == nil then return end

    print("handleLuaException begin")

    if (isPlatformSupportJavaBridge() == true) then
        --call java function
        LuaJavaSendReport(tostring(msg), debug.traceback())
    elseif (isPlatformSupportOCBridge() == true) then
        --call oc function
        LuaObjectCSendReport(tostring(msg), debug.traceback())
    end

    print("handleLuaException end")
end

cc.exports.handleLuaException = handleLuaException_

function __G__TRACKBACK__(msg)
    print("track begin")
    handleLuaException(msg)
    print("track end")
    return msg
end