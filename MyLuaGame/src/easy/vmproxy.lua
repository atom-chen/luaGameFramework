--
-- 代理对象
-- 用于连接model和view
-- 方便逻辑调用和隔离
--

--
-- ViewProxy
--
-- model -> view
-- 反作弊时屏蔽view操作
--

globals.ViewProxy = class('ViewProxy')

function ViewProxy:ctor(view)
	self.v = view
	self.vproxy = nil
	if view == nil then
		self:modelOnly()
	end
end

local proxy
local proxyfunc
function ViewProxy:modelOnly()
	self.vproxy = setmetatable({}, {
		__index = function (t, k)
			return proxyfunc
		end,
		__newindex = function (t, k, v)
		end
	})
end

function ViewProxy:raw()
	return self.v
end

-- @comment: 可以直接调用view的函数
function ViewProxy:proxy()
	return self.vproxy or self.v
end

-- @comment: 通过onViewProxyNotify来进行广播
function ViewProxy:notify(...)
	if self.vproxy == nil and self.v.onViewProxyNotify then
		return self.v:onViewProxyNotify(...) -- for tail call, no return
	end
end

-- @comment: 通过onViewProxyCall来返回ViewProxy
function ViewProxy:getProxy(...)
	if self.vproxy == nil and self.v.onViewProxyCall then
		return ViewProxy.new(self.v:onViewProxyCall(...))
	end
	return proxy
end

proxy = ViewProxy.new()
proxyfunc = function( ... )
	return proxy
end


--
-- readOnlyProxy
--
-- view -> model
-- 防止view修改model数据
-- 可用于object和table的readOnly保护
--

local _readOnlyProxy
local isObject = isObject
local isClass = isClass

-- @param t: table
local function _readOnlyTable(t, proxy)
	local mt = getmetatable(t)
	if mt then
		error(string.format("only for no-meta table! %s, %s", tostring(t), tostring(mt)))
	end
	local tstr = tostring(t)
	proxy = proxy or {}
	proxy.__proxy = true
	return setmetatable(t, {
		__index = function(t, k)
			if proxy[k] then
				return proxy[k]
			end
			return _readOnlyProxy(rawget(t, k))
		end,
		__newindex = function(t, k, v)
			error(string.format("%s read only! do not set %s!", tstr, k))
		end,
		__tostring = function(t)
			return string.format("readonly(%s)", tstr)
		end
	})
end

-- @param obj: instance of lua class
local function _readOnlyObject(obj, proxy)
	proxy = proxy or {}
	proxy.__proxy = true
	proxy.__class = obj.__class
	proxy.__cid = obj.__cid
	return setmetatable(proxy, {
		__index = function(proxy, k)
			return _readOnlyProxy(obj[k])
		end,
		__newindex = function(proxy, k, v)
			error(string.format("%s read only! do not set %s!", tostring(obj), k))
		end,
		__tostring = function(proxy)
			return string.format("readonly(%s)", tostring(obj))
		end
	})
end

_readOnlyProxy = function(objOrTable, proxy)
	if objOrTable == nil then return nil end
	if type(objOrTable) == "table" then
		if objOrTable.__proxy then
			return objOrTable
		end
		if isObject(objOrTable) then
			-- if it is object type, but proxy have different address with obj
			return _readOnlyObject(objOrTable, proxy)
		elseif isClass(objOrTable) then
			-- if it is class type, just return and use it
			return objOrTable
		end
		-- if it is table type
		return _readOnlyTable(objOrTable, proxy)
	end
	return objOrTable
end

function globals.readOnlyProxy(objOrTable, proxy)
	local ret = _readOnlyProxy(objOrTable, proxy)
	if not ret then
		error(string.format("can not proxy with %s!", tostring(objOrTable)))
	end
	return ret
end

