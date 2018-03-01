--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- table的扩展
--

-- t = defaulttable(defaulttable(function() return "123" end))
-- print(t[1], t[1][2])
-- =>
-- table "123"
function table.defaulttable(default)
	return setmetatable({}, {__index = function(t, k)
		local v = rawget(t, k)
		if v then return v end
		v = default()
		rawset(t, k, v)
		return v
	end,
	__call = function()
		return table.defaulttable(default)
	end})
end

function table.clear(t)
	for k, v in pairs(t) do
		t[k] = nil
	end
end
