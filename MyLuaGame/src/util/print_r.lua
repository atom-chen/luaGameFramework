--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--


local lua_print = print
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local type = type
local tostring = tostring
local next = next
local format = string.format

local tapcnt = 0
function globals.print_(...)
	if tapcnt == 0 then
		lua_print(...)
	else
		lua_print(srep("| ", tapcnt), ...)
	end
end

function globals.print_begin(...)
	lua_print(srep("| ", tapcnt) .. '+------------------------------')
	tapcnt = tapcnt + 1
	print_(...)
end

function globals.print_end(...)
	print_(...)
	tapcnt = tapcnt - 1
	lua_print(srep("| ", tapcnt) .. '+------------------------------')
end

function globals.print_r(root, lvl)
	lvl = lvl or 2
	if DEBUG < lvl then return end
	local cache = {[root] = "."}
	local function _dump(t,space,name)
		local temp = {}
		for k,v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
			elseif type(v) == "function" then
				tinsert(temp,"+" .. key .. " [".. tostring(v).."]")
			else
				tinsert(temp,"+" .. key .. " [".. type(v) .. " " .. tostring(v).."]")
			end
		end
		return tconcat(temp,"\n"..space)
	end
	local tb = string.split(debug.traceback("", 2), "\n")
	local str = _dump(root, "","")
	lua_print("dump from: " .. string.trim(tb[3]) .. "\n" .. str)
end

function globals.print_hex(s)
	local function hexadump(s)
		return (s:gsub('.', function (c) return format('%02X ', c:byte()) end))
	end
	lua_print(hexadump(s))
end