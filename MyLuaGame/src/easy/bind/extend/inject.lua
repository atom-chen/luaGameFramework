--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 注入扩展
--
-- 1. 希望有ViewBase的组件和onXXX
-- 2. 不希望额外加cc.Node，因为直接使用外部传入的node

-- like setmetatableindex_, but more priority
local setmetatableindex_
setmetatableindex_ = function(t, index)
	if lua_type(t) == "userdata" then
		local peer = tolua.getpeer(t)
		if not peer then
			peer = {}
			tolua.setpeer(t, peer)
		end
		setmetatableindex_(peer, index)
	else
		local mt = getmetatable(t)
		if not mt then
			-- if mt is nil, and index is table
			if lua_type(index) == "table" and index.__index then
				setmetatable(t, index)
				return
			end
			mt = {}
		end
		-- mt will be DIRTY!!!
		if not mt.__index then
			mt.__index = index
			setmetatable(t, mt)
		elseif mt.__index ~= index then
			-- first index, second mt.__index
			local oldindex = mt.__index
			mt.__index = function(t, k)
				local v = index[k]
				if v then return v end
				return oldindex[k]
			end
		end
	end
end

-- 现在props支持function，但function只作为值不会进行求值
-- 支持idler，直接获取idler存储的值，但listen需要自己绑定
local function inject(cls, view, node, handlers, props)
	logf.bind.inject("%s - %s inject %s %s, %s", tostring(view), tostring(node), tostring(cls), dumps(handlers), dumps(props))
	-- node must be userdata
	setmetatableindex_(node, cls)
	-- no super(cc.Node) create
	node:ctor(view:getApp(), view, handlers)
	-- copy defaultProps
	-- local nodeProps = clone(props)
	for k, v in pairs(cls.defaultProps) do
		-- if nodeProps[k] == nil then
		-- 	nodeProps[k] = v
		-- end
		node[k] = v
	end
	-- may be replace the original function
	if props then
		for k, v in pairs(props) do
			node[k] = v
		end
	end
	-- node.__props = nodeProps
	return node
end

return inject

