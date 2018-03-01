--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local tinsert = table.insert
local tconcat = table.concat

function globals.dumps(t)
	if t == nil then return "nil" end
	local cache = {[t] = "."}
	local function _dump(t,name)
		if type(t) ~= "table" then return tostring(t) end
		local mt = getmetatable(t)
		if mt and mt.__tostring then
			return tostring(t)
		end
		local temp = {}
		for k,v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				tinsert(temp,key .. "={" .. cache[v].."}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				tinsert(temp,key .. "=".. _dump(v,new_key))
			else
				tinsert(temp,key .. "=".. tostring(v))
			end
		end
		return "{" .. tconcat(temp,", ") .. "}"
	end
	return _dump(t,"")
end