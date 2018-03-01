--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.

--


local _strformat = string.format
local _tinsert = table.insert
local _tremove = table.remove
local _abs = math.abs
local _isRef = isRef

local CVector = class("CVector", require("luastl.stlbase"))
globals.CVector = CVector

function CVector:ctor(weak)
	self:clear(weak)
end

function CVector:clear(weak)
	if self.m then
		for i = 1, #self.m do
			if _isRef(self.m[i]) then
				self.m[i]:release()
			end
		end
	end
	self.m = weak and setmetatable({}, {__mode = weak}) or {}
end

function CVector:push_back(val)
	if _isRef(val) then
		val:retain()
	end
	_tinsert(self.m, val)
	-- self.m[1 + #self.m] = val
end

function CVector:pop_back()
	if _isRef(self.m[#self.m]) then
		self.m[#self.m]:release()
	end
	return _tremove(self.m)
	-- self.m[#self.m] = nil
end

function CVector:push_front(val)
	if _isRef(val) then
		val:retain()
	end
	_tinsert(self.m,1,val)
	-- for i = #self.m, 1, -1 do
	-- 	self.m[1 + i] = self.m[i]
	-- end
	-- self.m[1] = val
end

function CVector:pop_front()
	if _isRef(self.m[1]) then
		self.m[1]:release()
	end
	return _tremove(self.m, 1)
	-- for i = 1, #self.m-1 do
	-- 	self.m[i] = self.m[i + 1]
	-- end
	-- self.m[#self.m] = nil
end

-- find
-- @param val 	need to find
-- @return 		table index
function CVector:find(val)
	for i = 1, #self.m do
		if self.m[i] == val then
			return i
		end
	end
	return 0
end

-- at
-- @param val 	table index
-- @return 		value
function CVector:at(index)
	return self.m[index]
end
function CVector:back()
	if self:empty() then return nil end
	return self.m[#self.m]
end

function CVector:size()
	return #self.m
end

function CVector:empty()
	return #self.m == 0
end

-- insert
-- @param index 	table index
-- @param val 		need to insert
-- @comment 		[1 .. index-1], val, [index .. #]
function CVector:insert(index, val)
	if _isRef(val) then
		val:retain()
	end
	_tinsert(self.m,index,val)
	-- for i = #self.m, index do
	-- 	self.m[i + 1] = self.m[i]
	-- end
	-- self.m[index] = val
end

function CVector:erase(index)
	if index < 1 or index > #self.m then
		return false
	end
	local ret = _tremove(self.m, index)

	-- for i = index, #self.m - 1 do
	-- 	self.m[i] = self.m[i + 1]
	-- end
	-- local ret = self.m[#self.m]
	-- self.m[#self.m] = nil
	if _isRef(ret) then
		ret:release()
	end
	return ret
end
function CVector:eraseList(list)
	if list == nil then return end
	for k,v in pairs(list) do
		if #self.m >= v and self.m[v] then
			if _isRef(self.m[v]) then
				self.m[v]:release()
			end
			self.m[v] = nil
		end
	end
	local idx = 1
	for k,v in pairs(self.m) do
		if v ~= nil then
			self.m[idx] = v
			if k ~= idx then self.m[k] = nil end
			idx = idx + 1
		end
	end
end

function CVector:assign(t)
	if type(t) ~= "table" then
		error("CVector:assign need table")
		return
	end
	self:clear()
	for k, v in pairs(t) do
		if _isRef(v) then
			v:retain()
		end
		_tinsert(self.m, v)
	end
end

function CVector:pairs()
	return ipairs(self.m)
end

function CVector:ipairs()
	return ipairs(self.m)
end

function CVector:data()
	return self.m
end

function CVector:__eq(rhs)
	if #self.m ~= #rhs.m then
		return false
	end
	for k, v in ipairs(self.m) do
		if v ~= rhs.m[k] then
			return false
		end
	end
	return true
end

-- slice
-- @param startIndex
-- @param endIndex
-- @param step
-- @return 		new CVector
-- @comment 	like python list slice 
function CVector:slice(startIndex, endIndex, step)
	local ret = CVector.new()
	if #self.m == 0 or step == 0 then
		return ret
	end
	if step == nil then
		step = (endIndex - startIndex >= 0) and 1 or -1
	end

	-- reverse visit, change to forward visit
	if (endIndex - startIndex) * step < 0 then
		local len = _abs(endIndex - startIndex)
		len = #self.m - len
		endIndex = (step > 0 and startIndex + len) or startIndex - len
		if startIndex * endIndex < 0 then
			--if 0 will be visited, walk one more
			endIndex = endIndex + ((step > 0 and 1) or -1)
		end
	end

	for i = startIndex, endIndex, step do
		if i < 0 then
			ret:push_back(self.m[1 + (i % #self.m)])
		elseif i > 0 then
			ret:push_back(self.m[1 + ((i - 1) % #self.m)])
		end
	end
	return ret
end

return CVector