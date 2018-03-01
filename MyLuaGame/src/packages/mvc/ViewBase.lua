--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 一个UI工程对应一个ViewBase
--
local ViewBase = class("ViewBase", cc.Node)

-- @param parent: parent only be saved, no addChild
function ViewBase:ctor(app, parent, handlers)
	self.app_ = app
	self.parent_ = parent -- parent ViewBase
	if handlers then
		for k, v in pairs(handlers) do
			self[k] = v
		end
	end

	-- check CSB resource file
	local res = self.__class and rawget(self.__class, "RESOURCE_FILENAME")
	if res then
		self:createResourceNode(res)
	end

	local binding = self.__class and rawget(self.__class, "RESOURCE_BINDING")
	if res and binding then
		self.deferBinds_ = {}
		self:createResourceBinding(binding)
	end

	self:enableNodeEvents()
		:scheduleUpdate(function(...)
			-- 不能作为闭包缓存onUpdate_，可能会有component重载
			return self:onUpdate_(...)
		end)
end

function ViewBase:init(...)
	self:onCreate_(...)
	return self
end

function ViewBase:getApp()
	return self.app_
end

function ViewBase:getResourceNode(path)
	if path then
		return nodetools.get(self.resourceNode_, path)
	else
		return self.resourceNode_
	end
end

-- function ViewBase:getParentView()
-- 	return self.parent_
-- end

-- function ViewBase:getParentVar(varname)
-- 	return self.parent_[varname]
-- end

function ViewBase:createResourceNode(resourceFilename)
	if self.resourceNode_ then
		self.resourceNode_:removeSelf()
		self.resourceNode_ = nil
	end
	self.resource_ = resourceFilename
	self.resourceNode_ = cache.createWidget(resourceFilename)
	self:addChild(self.resourceNode_)
end

function ViewBase:createResourceBinding(binding)
	assert(self.resourceNode_, "ViewBase:createResourceBinding() - not load resource node")
	bindUI(self, self.resourceNode_, binding)
end

function ViewBase:createChildView(name)
	local child = self.app_:createView(name, self)
	self:addChild(child)
	return child
end

function ViewBase:deferUntilCreated(f)
	return table.insert(self.deferBinds_, f)
end

function ViewBase:onCreate_(...)
	if self.onCreate then
		self:onCreate(...)
	end
	-- 延迟绑定
	if self.deferBinds_ then
		for _, f in pairs(self.deferBinds_) do
			f()
		end
		self.deferBinds_ = nil
	end
end

function ViewBase:onUpdate_(delta)
	if self.onUpdate then
		return self:onUpdate(delta)
	end
end

function ViewBase:onEnter()
end

function ViewBase:onExit()
	-- clear components
	local names = table.keys(cc.components(self))
	if #names > 0 then
		cc.unbind(self, unpack(names))
	end
end

function ViewBase:onCleanup()
end

-- easy for bind.XXXX
-- view:bind("button_1"):touch(...):text(...)
function ViewBase:bindEasy(pathOrNode)
	local node = pathOrNode
	if type(pathOrNode) == "string" then
		node = nodetools.get(self.resourceNode_, path)
	end
	if node == nil then return end

	return functools.chaincall(bind, self, node)
end

-- easy for node listen idler
-- importance is when view close, auto unlisten idler
function ViewBase:nodeListenIdler(pathOrNode, pathOrIdler, f)
	local node = pathOrNode
	if type(pathOrNode) == "string" then
		node = nodetools.get(self.resourceNode_, path)
	end
	if node == nil then return end

	-- idler in ViewBase
	local idler = pathOrIdler
	if type(pathOrIdler) == "string" then
		idler = self[pathOrIdler]
	end
	if idler == nil then return end

	return node:listenIdler(idler, f)
end

local supportComponents = {
	"schedule",
	"asyncload",
}
for _, name in ipairs(supportComponents) do
	local capname = string.caption(name)
	-- enableSchedule()
	ViewBase[string.format("enable%s", capname)] = function(self)
		local components = cc.components(self)
		if not components[name] then
			cc.bind(self, name)
		end
		return self
	end

	-- disableSchedule()
	ViewBase[string.format("disable%s", capname)] = function(self)
		local components = cc.components(self)
		if components[name] then
			cc.unbind(self, name)
		end
		return self
	end

	-- isScheduleEnabled()
	ViewBase[string.format("is%sEnabled", capname)] = function(self)
		local components = cc.components(self)
		return components[name] ~= nil
	end
end

return ViewBase
