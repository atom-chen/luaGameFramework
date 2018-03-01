--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local insert = table.insert

-- 参考Python相关库函数
local functools = {}
globals.functools = functools

-- function f(p1,p2) return {p1,p2} end
-- g = partial(f, "a")
-- g("b")
-- => {"a","b"}
function functools.partial(f, ...)
	-- select('#', ...) != #args when ... had nil tail
	local nargs = select('#', ...)
	if nargs <= 4 then
		local upv1, upv2, upv3, upv4 = select(1, ...)
		if nargs == 1 then
			return function(...)
				return f(upv1, ...)
			end
		elseif nargs == 2 then
			return function(...)
				return f(upv1, upv2, ...)
			end
		elseif nargs == 3 then
			return function(...)
				return f(upv1, upv2, upv3, ...)
			end
		elseif nargs == 4 then
			return function(...)
				return f(upv1, upv2, upv3, upv4, ...)
			end
		end
		return f
	end
	local args = {...}
	local ff = f
	for i = 1, nargs do
		local f, upv = ff, args[i]
		ff = function(...)
			return f(upv, ...)
		end
	end
	return ff
end

-- function f(p1,p2) return {p1,p2} end
-- g = functools.shrink(f, 1)
-- g(1,2,3)
-- => {2,3}
function functools.shrink(f, left, right)
	right = right or 0
	return function(...)
		if right == 0 then
			return f(select(left + 1, ...))
		end
		local nargs = select('#', ...)
		local args, part = {...}, {}
		right = nargs - right
		for i = left + 1, right do
			insert(part, args[i])
		end
		return f(unpack(part))
	end
end

-- hello = function(name)
--   return "hello: "..name
-- end
-- hello = wrap(hello, function(func, ...)
--   return "before, "..func(...)..", after"
-- end)
-- hello('moe')
-- => before, hello: moe, after
function functools.wrap(f, w)
	return function(...)
		return w(f, ...)
	end
end

-- @comment:  In math terms, composing the functions f(), g(), and h() produces f(g(h())).
-- greet = function(name)
--   return "hi: "..name
-- end
-- exclaim = function(statement)
--   return statement.."!"
-- end
-- welcome = compose(print, greet, exclaim)
-- welcome('moe')
-- => hi: moe!
function functools.compose(...)
	local args = {...}
	local ff = function(...)
		return ...
	end
	for i, cf in ipairs(args) do
		local f, upv = ff, cf
		ff = function(...)
			return f(upv(...))
		end
	end
	return ff
end

-- touch = function(ui, arg)
--   print(ui, "touch "..arg)
-- end
-- text = function(ui, arg)
--   print(ui, "text "..arg)
-- end
-- chaincall({touch=touch, text=text}, ui):touch("123"):text("abc"):touch("456")
-- => touch 123
-- text abc
-- touch 456
function functools.chaincall(m, ...)
	local t = {}
	local args = {...}
	return setmetatable(t, {
		__index = function(t, k)
			local pf = m[k]
			if #args > 0 then
				pf = functools.partial(m[k], unpack(args))
			end
			local function cf(t, ...)
				pf(...)
				return t
			end
			t[k] = cf
			return cf
		end
	})
end

-- chainself(ui):touch("123"):text("abc"):touch("456")
function functools.chainself(self)
	local t = {}
	return setmetatable(t, {
		__index = function(t, k)
			local pf = self[k]
			local function cf(t, ...)
				pf(self, ...)
				return t
			end
			t[k] = cf
			return cf
		end
	})
end

-- the last param can be explicit nil
-- local add = curry(function (a,b,c)
-- 	return a+b+c
-- end)
-- print(add(1,2,3))
-- print(add(11))
-- print(add(11)(22))
-- print(add(11)(22)(33))
-- => 6
-- function 0x0CAFC090
-- function 0x0CAFC5F0
-- 66
function functools.curry(f, nparams)
	if nparams == nil then
		local info = debug.getinfo(f)
		if info.isvararg then
			error("curry not support varg function")
		end
		nparams = info.nparams
	end

	return function(...)
		local nargs = select('#', ...)
		if nargs >= nparams then
			return f(...)
		end
		local ff = functools.partial(f, ...)
		return functools.curry(ff, nparams - nargs)
	end
end

return functools