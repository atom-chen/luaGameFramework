--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- GameUI
--
local GameUI = class("GameUI")

function GameUI:ctor(app)
	globals.gGameUI = self
	globals.gRootViewProxy = ViewProxy.new()

	self.app = app
	self.scene = nil
	self.modal = nil
	self.modalOldPos = nil
	self.modalOldParent = nil
	self.modalLayer = cc.LayerColor:create(cc.c4b(120, 120, 120, 200), display.width, display.height)
	self.outSceneNode = nil

	self:onCreate()
end

function GameUI:onCreate()
	self.modalLayer:retain()
	self.modalLayer:setVisible(false)
	self.modalLayer:setTouchMode(cc.TOUCHES_ONE_BY_ONE)
	self.modalLayer:setSwallowsTouches(true)
	self.modalLayer:setTouchEnabled(false)
	self.modalLayer:setLocalZOrder(99999999)
	self.modalLayer:registerScriptTouchHandler(function(...) return true end)

	-- 上下黑边
	if CC_DESIGN_RESOLUTION.autoscale == "SHOW_ALL" then
		self.outSceneNode = cc.Node:create()
		display.director:setNotificationNode(self.outSceneNode)

		local scaleX, scaleY = display.sizeInPixels.width / display.size.width, display.sizeInPixels.height / display.size.height
		local scale = math.min(scaleX, scaleY)
		local heightInPixels = (display.sizeInPixels.height - scale * display.size.height) / 2
		local backBoard1 = cc.LayerColor:create(cc.c4b(0, 0, 255, 255), display.width, heightInPixels / scaleY)
		local backBoard2 = cc.LayerColor:create(cc.c4b(255, 0, 0, 255), display.width, heightInPixels / scaleY)
		backBoard2:setPositionY((heightInPixels + scale * display.size.height) / scaleY)
		self.outSceneNode:addChild(backBoard1)
		self.outSceneNode:addChild(backBoard2)
	end
end

function GameUI:switchUI(name, ...)
	if self.uiRoot then
		self.uiRoot:removeSelf()
		self.uiRoot = nil
	end

	local view = self:createView(name)
	self.uiRoot = view
	self:showWithScene(view)
	gRootViewProxy = ViewProxy.new(self.uiRoot)
	view:init(...)
	return view
end

-- 将AppBase相关实现转移到GameUI
function GameUI:enterScene(sceneName, transition, time, more)
	self.uiRoot = self:createView(sceneName)
	self.scene = self:showWithScene(self.uiRoot, transition, time, more)
	gRootViewProxy = ViewProxy.new(self.uiRoot)
	self.uiRoot:init()
	return self.uiRoot
end

function GameUI:showWithScene(view, transition, time, more)
	local scene = self.scene
	if scene == nil then
		scene = display.newScene(tostring(view))
		display.runScene(scene, transition, time, more)

		self.modalLayer:removeFromParent()
		scene:addChild(self.modalLayer)
	end

	view:setVisible(true)
	scene:addChild(view)
	return scene
end

function GameUI:createView(name, parent, handlers)
	local view = self.app:createView(name, parent, handlers)
	-- ScrollView控件需要onEnter之后才能正常绑定
	if parent then
		view:addTo(parent)
	end
	return view
end

-- @comment 非ViewBase继承类的对象，但基础功能相似
local simpleView = class("simpleView", cc.load("mvc").ViewBase)
function GameUI:createSimpleView(t, parent, handlers)
	simpleView.RESOURCE_FILENAME = t.RESOURCE_FILENAME
	simpleView.RESOURCE_BINDING = t.RESOURCE_BINDING
	local view = simpleView:create(self.app, parent, handlers)
	if parent then
		view:addTo(parent)
	end
	return view
end

-- @comment 现在modal是唯一的，后续考虑stack
function GameUI:doModal(node, bgColor)
	if self.modal then return end

	local parent = node:getParent()
	self.modal = node
	self.modalOldParent = parent
	local x, y = node:getPosition()
	self.modalOldPos = cc.p(x, y)

	node:retain()
	node:removeFromParent()
	if parent then
		local wpos = parent:convertToWorldSpace(self.modalOldPos)
		node:setPosition(wpos)
	end
	node:release()

	self.modalLayer:setVisible(true)
	self.modalLayer:setTouchEnabled(true)
	self.modalLayer:addChild(node)
end

function GameUI:unModal(node)
	if node ~= self.modal then
		error(string.format('modal missmatch %s %s !!!', tostring(node), tostring(self.modal)))
	end

	node:retain()
	node:removeSelf()
		:move(self.modalOldPos)
	if self.modalOldParent then
		self.modalOldParent:addChild(node)
	end
	node:release()

	self.modal = nil
	self.modalOldParent = nil
	self.modalOldPos = nil
	self.modalLayer:setVisible(false)
	self.modalLayer:setTouchEnabled(false)
end

function GameUI:showDialog(str, closeCallback)
	local view = self:createSimpleView({
		RESOURCE_FILENAME = "error_dlg.json",
		RESOURCE_BINDING = {
			[1707] = "lblContent",
			[1703] = "btnOK",
			[1730] = "btnQuit",
		},
	})
	local old = closeCallback
	closeCallback = function()
		self:unModal(view)
		if old then old() end
	end

	view.lblContent:setString(str)
	view:bindEasy(view.btnOK):click({method=closeCallback})
	view:bindEasy(view.btnQuit):click({method=closeCallback})
	-- view:bindEasy(view:getResourceNode()):click({method=closeCallback})

	self:doModal(view)
end

return GameUI