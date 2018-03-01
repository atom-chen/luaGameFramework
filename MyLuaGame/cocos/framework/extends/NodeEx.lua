--[[

Copyright (c) 2014-2017 Chukong Technologies Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local Node = cc.Node

function Node:add(child, zorder, tag)
	if tag then
		self:addChild(child, zorder, tag)
	elseif zorder then
		self:addChild(child, zorder)
	else
		self:addChild(child)
	end
	return self
end

function Node:addTo(parent, zorder, tag)
	if tag then
		parent:addChild(self, zorder, tag)
	elseif zorder then
		parent:addChild(self, zorder)
	else
		parent:addChild(self)
	end
	return self
end

function Node:removeSelf()
	self:removeFromParent()
	return self
end

function Node:align(anchorPoint, x, y)
	self:setAnchorPoint(anchorPoint)
	return self:move(x, y)
end

function Node:show()
	self:setVisible(true)
	return self
end

function Node:hide()
	self:setVisible(false)
	return self
end

function Node:move(x, y)
	if y then
		self:setPosition(x, y)
	else
		self:setPosition(x)
	end
	return self
end

function Node:moveTo(args)
	transition.moveTo(self, args)
	return self
end

function Node:moveBy(args)
	transition.moveBy(self, args)
	return self
end

function Node:fadeIn(args)
	transition.fadeIn(self, args)
	return self
end

function Node:fadeOut(args)
	transition.fadeOut(self, args)
	return self
end

function Node:fadeTo(args)
	transition.fadeTo(self, args)
	return self
end

function Node:rotate(rotation)
	self:setRotation(rotation)
	return self
end

function Node:rotateTo(args)
	transition.rotateTo(self, args)
	return self
end

function Node:rotateBy(args)
	transition.rotateBy(self, args)
	return self
end

function Node:scaleTo(args)
	transition.scaleTo(self, args)
	return self
end

function Node:scheduleUpdate(callback)
	self:scheduleUpdateWithPriorityLua(callback, 0)
	return self
end

function Node:onNodeEvent(eventName, callback)
	local old
	if "enter" == eventName then
		old = self.onEnterCallback_
		self.onEnterCallback_ = callback
	elseif "exit" == eventName then
		old = self.onExitCallback_
		self.onExitCallback_ = callback
	elseif "enterTransitionFinish" == eventName then
		old = self.onEnterTransitionFinishCallback_
		self.onEnterTransitionFinishCallback_ = callback
	elseif "exitTransitionStart" == eventName then
		old = self.onExitTransitionStartCallback_
		self.onExitTransitionStartCallback_ = callback
	elseif "cleanup" == eventName then
		old = self.onCleanupCallback_
		self.onCleanupCallback_ = callback
	end
	self:enableNodeEvents()
	return old
end

function Node:enableNodeEvents()
	if self.isNodeEventEnabled_ then
		return self
	end

	self:registerScriptHandler(function(state)
		if state == "enter" then
			return self:onEnter_()
		elseif state == "exit" then
			return self:onExit_()
		elseif state == "enterTransitionFinish" then
			return self:onEnterTransitionFinish_()
		elseif state == "exitTransitionStart" then
			return self:onExitTransitionStart_()
		elseif state == "cleanup" then
			return self:onCleanup_()
		end
	end)
	self.isNodeEventEnabled_ = true

	return self
end

function Node:disableNodeEvents()
	self:unregisterScriptHandler()
	self.isNodeEventEnabled_ = false
	return self
end


function Node:onEnter()
end

function Node:onExit()
end

function Node:onEnterTransitionFinish()
end

function Node:onExitTransitionStart()
end

function Node:onCleanup()
end

function Node:onEnter_()
	if not self.onEnterCallback_ then
		return self:onEnter()
	end
	self:onEnter()
	return self:onEnterCallback_()
end

function Node:onExit_()
	if not self.onExitCallback_ then
		return self:onExit()
	end
	self:onExit()
	return self:onExitCallback_()
end

function Node:onEnterTransitionFinish_()
	if not self.onEnterTransitionFinishCallback_ then
		return self:onEnterTransitionFinish()
	end
	self:onEnterTransitionFinish()
	return self:onEnterTransitionFinishCallback_()
end

function Node:onExitTransitionStart_()
	if not self.onExitTransitionStartCallback_ then
		return self:onExitTransitionStart()
	end
	self:onExitTransitionStart()
	return self:onExitTransitionStartCallback_()
end

function Node:onCleanup_()
	if not self.onCleanupCallback_ then
		return self:onCleanup()
	end
	self:onCleanup()
	return self:onCleanupCallback_()
end

