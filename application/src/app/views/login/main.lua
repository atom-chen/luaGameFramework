--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
local LoginView = class("LoginView", cc.load("mvc").ViewBase)

local input = {}
input.RESOURCE_FILENAME = "login.json"
input.RESOURCE_BINDING = {
	["TextField_159"] = "txtAccount",
	["TextField_159_0"] = "txtPassword",
	[1819] = {
		varname = "btnLogin",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.parent("onLoginClick")},
			scaletype = 2,
			bounce = true,
		},
	},
}

function LoginView:onCreate()
	cc.Sprite:create("img/new_dljm_01.jpg")
		:move(display.visibleCenter)
		:addTo(self, -1)

	self.inputWidget = gGameUI:createSimpleView(input, self)
	widget.addAnimation(self.inputWidget.btnLogin, "login/denglu.json")
		:move(105, 105)

	-- local sprite = widget.addAnimation(self, "testnewspine/lianyetongzi.json")
	-- sprite:move(display.visibleCenter):play("hit")
end

function LoginView:onLoginClick(node, event)
	local name = self.inputWidget.txtAccount:getString()
	local pass = self.inputWidget.txtPassword:getString()
	local isascii = true
	for _, ch in pairs({pass:byte(1, #pass)}) do
		if ch < 0 or ch > 127 then isascii = false end
	end

	if name == '' then
		gGameUI:showDialog('name_can_not_empty')
	elseif pass == '' then
		gGameUI:showDialog('pw_can_not_empty')
	elseif not isascii then
		gGameUI:showDialog('pw_desc')
	else
		self:onSDKLoginOK(name, pass)
	end
end


function LoginView:onSDKLoginOK(name, pass)
	gNet:doPost("/arena/login", {name = name, pwd = md5(pass)}, function(result, err)
		if result.ret then
			gGameUI:showDialog(string.format("欢迎 %s 回来", gGameModel.account.nick_name), function()
				gGameUI:switchUI("login.lobby"):init()
			end)
		else
			gGameUI:showDialog(result.err)
		end
	end)
end


return LoginView
