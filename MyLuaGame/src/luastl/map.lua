--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
local _strformat = string.format
local _abs = math.abs
local _isRef = isRef
local _insert = table.insert
local _sort = table.sort

local CMap = class("CMap", require("luastl.stlbase"))
globals.CMap = CMap

--map的key最好不要是table，常规的就是number以及string
function CMap:ctor(weak)
	self:clear(weak)
end

function CMap:clear(weak)
	if self.m then
		for k, v in pairs(self.m) do
			if _isRef(v) then
				v:release()
			end
		end
	end

	self.m = weak and setmetatable({}, {__mode = weak}) or {}
	self.msize = weak and -1 or 0
	self.order = nil
	self.ordercmp = nil
end

function CMap:size()
	if self.msize < 0 then
		-- weak table may auto erase
		local ret = 0
		for k, v in pairs(self.m) do
			ret = ret + 1
		end
		return ret
	end
	return self.msize
end

function CMap:empty()
	return self:size() == 0
end

function CMap:insert(key, value)
	if _isRef(value) then
		value:retain()
	end
	local oldVal = self.m[key]
	if oldVal ~= nil then
		if _isRef(oldVal) then
			oldVal:release()
		end
	end
	if self.msize >= 0 and oldVal == nil then
		self.msize = self.msize + 1
	end
	self.m[key] = value
	self.order = nil
end

function CMap:assign(t)
	self:clear()
	if type(t) ~= "table" then
		-- allow nil to assign, equal clear
		-- error("CMap:assign need table")
		return
	end
	for k, v in pairs(t) do
		if _isRef(v) then
			v:retain()
		end
		self.m[k] = v
		self.msize = self.msize + 1
	end
end

-- notice the value's life time
function CMap:erase(key)
	if self.m[key] ~= nil then
		local ret = self.m[key]
		if _isRef(ret) then
			ret:release()
		end
		self.m[key] = nil
		if self.msize >= 0 then self.msize = self.msize - 1 end
		self.order = nil
		return ret
	end
	return nil
end
CMap.pop = CMap.erase

function CMap:count(key)
	if self.m[key] ~= nil then
		return 1
	end
	return 0
end

function CMap:find(key, defval)
	if self.m[key] ~= nil then
		return self.m[key]
	end
	return defval
end

function CMap:data()
	return self.m
end

function CMap:pairs()
	return pairs(self.m)
end

function CMap:__eq(rhs)
	if self.msize ~= rhs.msize then
		return false
	end
	for k, v in pairs(self.m) do
		if v ~= rhs:find(k) then
			return false
		end
	end
	return true
end

function CMap:order_pairs(cmp)
	if self.order == nil or cmp ~= self.ordercmp then
		local order = {}
		-- map be t is CMap
		for k, v in pairs(self.m) do
			table.insert(order, k)
		end
		local f = cmp
		if type(cmp) == "string" then
			f = function(v1, v2)
				return v1[cmp] < v2[cmp]
			end
		end
		if f then
			local ff = f
			f = function(k1, k2)
				return ff(self.m[k1], self.m[k2])
			end
		end
		table.sort(order, f)
		self.order = order
		self.ordercmp = cmp
	end

	local order = self.order
	local data = self.m
	local i = 0
	return function()
		i = i + 1
		local idx = order[i]
		return idx, data[idx]
	end
end
return CMap