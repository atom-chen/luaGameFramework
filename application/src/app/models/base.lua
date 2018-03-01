--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- GameModelBase
--

local GameModelBase = class("GameModelBase")

function GameModelBase:ctor(t)
	self.__idlerMap = {}
	for k, v in pairs(t) do
		self[k] = v
	end
end

function GameModelBase:getIdler(name)
	local idl = self.__idlerMap[name]
	if idl == nil then
		idl = idler.new(self[name])
		self.__idlerMap[name] = idl
	end
	return idl
end

function GameModelBase:syncFrom(t)
	local idlerMap = self.__idlerMap
	for k, v in pairs(t) do
		self[k] = v

		local idler = idlerMap[k]
		if idler then
			idler:set(v)
		end
	end
end

return GameModelBase