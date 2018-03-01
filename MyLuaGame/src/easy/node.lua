--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- cc.Node原生类的扩展
--
local Node = cc.Node

local nodetools_get = nodetools.get

function Node:get(...)
	return nodetools_get(self, ...)
end

function Node:listenIdler(pathOrIdler, f)
	local idler = pathOrIdler
	if type(pathOrIdler) == "string" then
		idler = self[pathOrIdler]
	end
	if idler == nil then return end

	local key = tostring(self)
	idler:addListener(function(idler, val, oldval)
		return f(val, oldval, idler, self)
	end, key)

	local oldExit = self:onNodeEvent("exit", function(...)
		idler:delListener(key)
		return oldExit and oldExit(...)
	end)
end