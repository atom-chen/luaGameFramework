--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 惰性求值
--
local type = type

local idlerListenerCnt = 1
local idler = {__idler = true}
globals.idler = idler
idler.__index = idler

function globals.isIdler(t)
	return type(t) == "table" and t.__idler == true
end

function idler.new(init, cmp)
	local obj = setmetatable({
		listeners = {},
		eval = init,
		oldval = init,
		cmp = cmp,
		working = false,
	}, idler)

	if type(init) == "function" then
		obj.oldval = init()
	else
		obj.eval = function()
			return obj.oldval
		end
	end
	return obj
end

function idler.combine(filter, callback, ...)
	local objs = {...}
	local mark = {}
	local self = idler.new()
	for _, obj in ipairs(objs) do
		obj:addListener(function(val, oldval)
			mark[obj] = {val, oldval}
			if filter(mark, #objs) then
				callback(mark)
				mark = {}
			end
		end, tostring(self))
	end
	return self
end

function idler:__call()
	return self:changed_(self.eval(), self.oldval, self.cmp)
end

function idler:set(val)
	return self:changed_(val, self.oldval, self.cmp)
end

function idler:rawset(val)
	self.oldval = val
end

-- @param callback: callback(val, oldval, idler)
-- @notice: the callback dont invoke any cc.Node, if you want it, use Node:listenIdler
function idler:addListener(callback, key, noInit)
	self:changed_(self.eval(), self.oldval, self.cmp)
	if key == nil then
		key = idlerListenerCnt
		idlerListenerCnt = idlerListenerCnt + 1
	end
	self.listeners[key] = callback
	if not noInit then
		callback(self.oldval, self.oldval, self)
	end
end

-- @param obj: obj is also idler
function idler:listen(obj, callback, noInit)
	obj:addListener(callback, self, noInit)
end

function idler:delListener(key)
	self.listeners[key] = nil
end

function idler:unlisten(obj)
	obj:delListener(self)
end

function idler:shutup()
	self.listeners = {}
end

function idler:notify()
	return self:changed_(self.eval(), self.oldval, self.cmp, true)
end

function idler:changed_(val, oldval, cmp, force)
	if not force then
		if val == oldval then
			return val
		elseif cmp and cmp(val, oldval) == 0 then
			return val
		end
	end
	if self.working then error('idler call in loop') end

	self.working = true
	for _, callback in pairs(self.listeners) do
		callback(val, oldval, self)
	end
	self.working = false
	self.oldval = val
	return val
end

--------------------------------

local idlerfilter = {}
globals.idlerfilter = idlerfilter

function idlerfilter.all(mark, n)
	return n == itertools.size(mark)
end

function idlerfilter.any(mark, n)
	return not itertools.isempty(mark)
end

--------------------------------

local idlercmp = {
	table = itertools.equal
}
globals.idlercmp = idlercmp

--------------------------------

local idlers = {__idlers = true}
globals.idlers = idlers
idlers.__index = idlers

function globals.isIdlers(t)
	return type(t) == "table" and t.__idlers == true
end

function idlers.new()
	local obj = setmetatable({
		listeners = {},
		idlers = {},
		working = false,
	}, idlers)

	return obj
end

function idlers.newWithIdlerTable(t)
	local obj = idlers.new()
	for k, obj2 in pairs(t) do
		obj:add(k, obj2)
	end
	return obj
end

function idlers.newWithTable(t, cmp)
	local obj = idlers.new()
	for k, v in pairs(t) do
		local vcmp = cmp
		if type(v) == "table" then vcmp = vcmp or idlercmp.table end
		local obj2 = idler.new(v, vcmp)
		obj:add(k, obj2)
	end
	return obj
end

function idlers:add(k, idler)
	local old = self.idlers[k]
	if old then
		old:delListener(self)
		self:notify({event="remove", key=k, idler=old})
	end
	self.idlers[k] = idler
	self:notify({event="add", key=k, idler=idler})
	idler:addListener(functools.partial(self.notify, self, {event="update", key=k, idler=idler}), self, true)
end

function idlers:remove(k)
	local old = self.idlers[k]
	self.idlers[k] = nil
	if old then
		old:delListener(self)
		self:notify({event="remove", key=k, idler=old})
	end
end

function idlers:at(k)
	return self.idlers[k]
end

function idlers:ipairs()
	return ipairs(self.idlers)
end

function idlers:pairs()
	return pairs(self.idlers)
end

-- @param callback: callback(msg, idlers)
function idlers:addListener(callback, key, noInit)
	if key == nil then
		key = idlerListenerCnt
		idlerListenerCnt = idlerListenerCnt + 1
	end
	self.listeners[key] = callback
	if not noInit then
		callback({event="init"}, self)
	end
end

function idlers:delListener(key)
	self.listeners[key] = nil
end

function idlers:notify(msg, ...)
	if self.working then error('idlers call in loop') end

	self.working = true
	for _, callback in pairs(self.listeners) do
		callback(msg, self, ...)
	end
	self.working = false
end

function idlers:shutup()
	self.listeners = {}
end