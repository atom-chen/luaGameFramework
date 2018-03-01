--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- bind辅助函数
--
local insert = table.insert

--------------------------------
-- helper为bind内部使用
local helper = {}

-- @return partial(method, view, node)
function helper.method(view, node, b, name, raw)
	local f
	if b.methods then
		local fOrName = b.methods[name]
		if fOrName == nil then return end
		if type(fOrName) == "function" or helper.isHelper(fOrName) then
			f = fOrName
		else
			f = view[fOrName]
		end
	else
		if type(b.method) == "function" or helper.isHelper(b.method) then
			f = b.method
		else
			f = view[b.method]
		end
	end

	if f then
		return raw and f or functools.partial(f, view, node)
	end
end

-- bind内部listen转换封装
function helper.listen(view, node, b, method)
	local f = helper.method(view, node, b, nil, true)
	local idler = b.idler
	if idler then
		-- 有b.method是对idler结果做处理
		if f then
			bind.listen(view, node, {idler=idler, method=function(view, node, val, ...)
				return method(view, node, f(val), ...)
			end})
		else
			bind.listen(view, node, {idler=idler, method=method})
		end
	end
end

function helper.isHelper(t)
	return type(t) == "table" and t.__bindHelper == true
end

helper.isIdler = isIdler
helper.isIdlers = isIdlers

function helper.propVal(prop)
	if type(prop) ~= "table" then
		return prop
	elseif helper.isIdler(prop) then
		return prop()
	end
	return prop
end

-- unfold the bindHelper wrap
local function arrayHelperUnfold(view, node, t)
	if t == nil then return nil end
	if #t == 0 then return t end
	local ret = {}
	for i, v in ipairs(t) do
		if helper.isHelper(v) then
			v = v(view)
		end
		insert(ret, v)
	end
	return ret
end

local function mapHelperUnfold(view, node, t)
	if t == nil then return nil end
	if itertools.isempty(t) then return t end
	local ret = {}
	for k, v in pairs(t) do
		if helper.isHelper(v) then
			v = v(view)
		end
		ret[k] = v
	end
	return ret
end

-- 转换作为args参数的bindHelper
function helper.args(view, node, args)
	return unpack(arrayHelperUnfold(args))
end

helper.props = mapHelperUnfold
helper.handlers = mapHelperUnfold

-- @return: data, idler, idlers
function helper.dataOrIdler(t)
	if helper.isIdlers(t) then
		return nil, nil, t
	elseif helper.isIdler(t) then
		return nil, t
	end
	return t
end

--------------------------------
-- bind时候view和node都没有创建
-- bindHelper就是为了再创建onCreate后进行延迟绑定的
-- bindHelper为应用上层使用

local bindHelper = {}
globals.bindHelper = bindHelper

local function bindHelperToString(t)
	return string.format("%s(%s%s)", t.__raw and "bindraw" or "bind", t.__method, t.__name and ("." .. t.__name) or "")
end

-- @param raw: 是否原值返回，针对function
local parentMeta = {__call = function(t, view, ...)
	local parent = view.parent_
	local val = parent[t.__name]
	if type(val) == "function" and not t.__raw then
		-- 如果是函数，则先运行获取返回值
		return val(parent, ...)
	else
		-- 延迟获取self的变量
		return val
	end
end, __tostring = bindHelperToString}
function bindHelper.parent(methodOrVar, raw)
	return setmetatable({__bindHelper = true, __method = "parent", __name = methodOrVar, __raw = raw}, parentMeta)
end

local selfMeta = {__call = function(t, view, ...)
	local val = view[t.__name]
	if type(val) == "function" and not t.__raw then
		-- 如果是函数，则先运行获取返回值
		return val(view, ...)
	else
		-- 延迟获取self的变量
		return val
	end
end, __tostring = bindHelperToString}
function bindHelper.self(methodOrVar, raw)
	return setmetatable({__bindHelper = true, __method = "self", __name = methodOrVar}, selfMeta)
end

local modelMeta = {__call = function(t, view, ...)
	local model = gGameModel[t.__method]
	if t.__raw then
		return model[t.__name]
	else
		return model:getIdler(t.__name)
	end
end, __tostring = bindHelperToString}
-- @param model: string, model名字
-- @param raw: 这里含义不同，raw表示非idler，默认返回GameModelBase:getIdler
function bindHelper.model(model, name, raw)
	return setmetatable({__bindHelper = true, __method = model, __name = name}, modelMeta)
end

local deferMeta = {__call = function(t, view, ...)
	return t.__f(view)
end, __tostring = bindHelperToString}
function bindHelper.defer(f)
	return setmetatable({__bindHelper = true, __method = "defer", __f = f}, deferMeta)
end

return helper