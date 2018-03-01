--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- sdk相关全局变量
--
local sdk = {}
globals.sdk = sdk

-- 回调在渠道后台固定配置
sdk.ORDER_URL = "http://123.207.108.22:28081"
sdk.ORDER_SIGN_SECRET = 'tianji'


local FinalSDK = class("FinalSDK")
globals.FinalSDK = FinalSDK

-- 当前运行平台
local targetPlatform = cc.Application:getInstance():getTargetPlatform()

local callPlatformFunc = function(funcName, bundle, callback)
	if ((cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform)) then
		local luaoc = require "cocos.cocos2d.luaoc"
		luaoc.callStaticMethod("SDKCommon","master",{
			funcName = funcName,
			bundle = bundle,
			callback = callback
		})
	else
		local luaj = require "cocos.cocos2d.luaj"
		luaj.callStaticMethod("www/tianji/finalsdk/MessageHandler","msgFromLua",{
			[1] = funcName,
			[2] = bundle,
			[3] = callback
		})
	end
end

function FinalSDK.login()
	callPlatformFunc("login", "data", function(info)
		print("callback info = ", info)
	end)
end

-- 订单的创建也转移到 java 那一层
function FinalSDK.pay(cpOrderId,extInfo,amount,cb, rechargeID)
end

function FinalSDK.isHiddenLoginButton()
	callPlatformFunc("isHiddenLoginButton", "", function(info)
		if info == "true" then
		end
	end)
end
