--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- GameApp
--

local GameApp = class("GameApp", cc.load("mvc").AppBase)

local function addSearchPath(path)
	local pathL10n = getL10nField(path)
	if path ~= pathL10n then
		cc.FileUtils:getInstance():addSearchResolutionsOrder(pathL10n)
		print('addSearchPath', pathL10n)
	end
	cc.FileUtils:getInstance():addSearchResolutionsOrder(path)
	print('addSearchPath', path)
end

function GameApp:onCreate()
	math.newrandomseed()

	cc.FileUtils:getInstance():addSearchResolutionsOrder("res")
	addSearchPath("res/Resources")
	addSearchPath("res/uijson")
	addSearchPath("res/spine")
	addSearchPath("res/sound")
	addSearchPath("res/video")

	self.ui = require("app.game_ui").new(self)
	self.model = require("app.models.game").new(self)
	self.net = require("net.manager").new(self)

	self.net:setHTTPUrl("http://" .. LOGIN_SERVRE_HOSTS_TABLE[1])

	-- LuaCov is a simple coverage analyzer for Lua scripts
	if LUACOV_ENABLE then
		print('------ LuaCov init ------')
		LuaCovRunner = require("luacov.runner")
		LuaCovRunner.init()
		print('------------')
	end

	if CC_SHOW_FPS then
		cc.Director:getInstance():setDisplayStats(true)
	end
end

function GameApp:enterScene(sceneName, transition, time, more)
	local view = self.ui:enterScene(sceneName, transition, time, more)

	self.scene = self.ui.scene
	self.scene:scheduleUpdate(handler(self, self.onUpdate))

	if EDITOR_ENABLE then
		print('------ Editor init ------')
		local editor = require("editor.builder")
		editor:init(self.scene)
		print('------------')
	end
	return view
end


-- view和app的update是分离的
-- 逻辑上使用app
function GameApp:onUpdate(delta)
end

function GameApp:onUpdateWhenPaused(delta)
end


function globals.pausedUpdate()
	globals.app:onUpdateWhenPaused(0.25)
end

return GameApp
