--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 这里的log都是调试用，release时都将无效
-- log = print
-- logf = print(format)
--

local upper = string.upper
local format = string.format

local disable = false
local log, logf, lazylog, lazylogf = {__tag = ""}, {__tag = ""}, {__tag = ""}, {__tag = ""}
globals.log, globals.logf, globals.lazylog, globals.lazylogf = log, logf, lazylog, lazylogf

-- custom ignore by youself
local ignoreTags = {
	effect = true,
	sprite = true,
	battle = true,
	objcect = true,
}
local tmp = {}
for k, v in pairs(ignoreTags) do
	tmp[upper(k)] = true
end
ignoreTags = tmp

local nulltb = {}
setmetatable(nulltb, {
	__index = function(t, k)
		rawset(log, k, nulltb)
		return nulltb
	end,
	__call = function(...)
	end
})

local function logDisable()
	disable = true
	local mods = {log, logf, lazylog, lazylogf}
	for _, l in ipairs(mods) do
		for k, v in pairs(l) do
			l[k] = nil
		end
	end
	for _, l in ipairs(mods) do
		setmetatable(l, {__index = function(t, k)
			rawset(l, k, nulltb)
			return nulltb
		end})
	end
end
log.disable, logf.disable, lazylog.disable, lazylogf.disable = logDisable, logDisable, logDisable, logDisable

-- lazy dumps(v), help some cost-heavy string cast
local lazytb = {__lazydumps = true}
function globals.lazydumps(v, f)
	if disable then return "" end
	f = f or dumps
	return setmetatable(lazytb, {__tostring = function()
		return f(v)
	end})
end

local function logIndex(setmeta)
	return function(t, k)
		local tag = upper(k)
		local tagPath = tag
		if #t.__tag > 0 then
			tagPath = format("%s %s", t.__tag, tag)
		end
		local taglog = setmeta({__tag = tagPath})
		if ignoreTags[tag] then
			taglog = nulltb
		end
		rawset(t, tag, taglog)
		return taglog
	end
end

local function setLogMeta(t)
	return setmetatable(t, {
		__index = logIndex(setLogMeta),
		__call = function(t, ...)
			print(format("<%s>", t.__tag), ...)
		end
	})
end

local function setLogfMeta(t)
	return setmetatable(t, {
		__index = logIndex(setLogfMeta),
		__call = function(t, fmt, ...)
			-- local vargs = {...}
			-- for i, v in ipairs(vargs) do
			-- 	if type(v) == "table" and v.__lazydumps then
			-- 		vargs[i] = tostring(v)
			-- 	end
			-- end
			-- print(format("<%s> %s", t.__tag, format(fmt, unpack(vargs))))

			-- luajit支持format("%s", {}), lua不支持
			print(format("<%s> %s", t.__tag, format(fmt, ...)))
		end
	})
end

local function setLazyLogMeta(t)
	return setmetatable(t, {
		__index = logIndex(setLazyLogMeta),
		__call = function(t, ...)
			local vargs = {...}
			for i, v in ipairs(vargs) do
				if type(v) == "function" then
					vargs[i] = v()
				end
			end
			print(format("<%s>", t.__tag), unpack(vargs))
		end
	})
end

local function setLazyLogfMeta(t)
	return setmetatable(t, {
		__index = logIndex(setLazyLogfMeta),
		__call = function(t, fmt, ...)
			local vargs = {...}
			for i, v in ipairs(vargs) do
				if type(v) == "function" then
					vargs[i] = v()
				end
			end
			print(format("<%s> %s", t.__tag, format(fmt, unpack(vargs))))
		end
	})
end

setLogMeta(log)
setLogfMeta(logf)
setLazyLogMeta(lazylog)
setLazyLogfMeta(lazylogf)
