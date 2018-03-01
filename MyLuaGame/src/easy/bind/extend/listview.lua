--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.ListView的react形式的扩展
--
local helper = require "easy.bind.helper"

local listview = class("listview", cc.load("mvc").ViewBase)

listview.defaultProps = {
	-- onXXXX 响应函数
	-- 数据 array table, function
	data = nil,
	-- 数量 nil 自动
	size = nil,
	-- item模板
	item = nil,
	-- 异步加载, nil 不使用异步加载, >=0 预加载数量
	asyncPreload = nil,
}

function listview:initExtend()
	if self.asyncPreload then
		self:enableAsyncload()
	end

	local data, idler, idlers = helper.dataOrIdler(self.data)
	self.data = data
	if idlers then
		idlers:addListener(function(msg, idlers, val)
			if msg.event == "init" then
				local next, tb, init = idlers:ipairs()
				self.data = itertools.iter(next, tb, init, function(k, v)
					return k, v and v()
				end)
				self:buildExtend()

			elseif msg.event == "add" then
				val = msg.idler()
				self:makeItem(msg.key, val)

			elseif msg.event == "remove" then
				local item = self.itemNodes[msg.key]
				self:removeItem(self:getIndex(item))
				self.itemNodes[msg.key] = nil

			elseif msg.event == "update" then
				self:onItem(self.itemNodes[msg.key], msg.key, val)
			end
		end)

	elseif idler then
		idler:addListener(function(data)
			self.data = data
			if self.itemNodes then
				self:onRebuild()
			end
			self:buildExtend()
		end)

	else
		self:buildExtend()
	end
	return self
end

function listview:buildExtend()
	self:onBeforBuild()
	self:removeAllChildren()
	self.itemNodes = {}

	local function building()
		local cnt = 0
		self.size = self.size or 999999
		itertools.each(self.data, function(k, v)
			if cnt >= self.size then return end

			cnt = cnt + 1
			self:makeItem(k, v)
			if self.asyncPreload then
				coroutine.yield()
			end
		end)
	end

	if self.asyncPreload then
		self:asyncFor(building, handler(self, self.onAfterBuild), self.asyncPreload)
	else
		building()
		self:onAfterBuild()
	end
	return self
end

function listview:makeItem(k, v)
	local item = self.item:clone()
	self.itemNodes[k] = item
	self:onItem(item, k, v)
	if self.onItemClick then
		item:onClick(function(event)
			-- self:setCurSelectedIndex(self:getIndex(item))
			return self:onItemClick(item, k, v)
		end)
	end
	local idx = self:onItemIndex(k, v)
	if idx then
		self:insertCustomItem(item, idx)
	else
		self:pushBackCustomItem(item)
	end
	return item:show()
end

function listview:onRebuild()
end

function listview:onBeforBuild()
end

function listview:onAfterBuild()
end

function listview:onItem(node, k, v)
end

-- @return: nil表示pushback
function listview:onItemIndex(k, v)
end

-- function listview:onItemClick(node, k, v)
-- end

return listview
