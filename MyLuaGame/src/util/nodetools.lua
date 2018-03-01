--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- node相关库函数
local nodetools = {}
globals.nodetools = nodetools

-- get('a.b.c')
-- get(112)
-- get('a', 112, 'c')
function nodetools.get(node, ...)
	local vargs = {...}
	local only = #vargs == 1
	for _, path in ipairs(vargs) do
		if type(path) == 'number' then
			node = node:getChildByTag(path)
		else
			if only then
				local flag = false
				for k in path:gmatch("([^.]+)") do
					local ik = tonumber(k)
					if ik then
						node = node:getChildByTag(ik)
					else
						node = node:getChildByName(k)
					end
					if node == nil then return nil end
					flag = true
				end
				node = flag and node or nil
			else
				node = node:getChildByName(path)
			end
		end
		if node == nil then return nil end
	end
	return node
end
