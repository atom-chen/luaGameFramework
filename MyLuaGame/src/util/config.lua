--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- conifg.csv数据转换处理
--

require "config.csv"

local strsub = string.sub
local strfind = string.find
local strformat = string.format

-- @desc 处理本地化语言选择，数据是由服务器传输，如yunying
function globals.setRemoteL10nConfig(t)
	for k, v in pairs(t) do
		if type(k) == 'string' and type(v) == 'table' then
			if strsub(k, 1, 2) ~= '__' then
				setRemoteL10nConfig(v)
			end
		elseif type(k) == 'number' and type(v) == 'table' then
			for kk, vv in pairs(v) do
				-- 语言转换
				local kk2 = strformat('%s_%s', kk, LOCAL_LANGUAGE)
				if v[kk2] then
					-- print(k, kk, v[kk], kk2, v[kk2])
					v[kk] = v[kk2]
				end
			end
		end
	end
end

-- @desc 处理本地化语言选择
local function _setL10nConfig(t)
	local map = {}
	if t.__default then
		local suffix = string.format('_%s', LOCAL_LANGUAGE)
		local def = t.__default
		local fields = clone(def.__index)
		local cnt = 5 -- 探测5个
		for k, v in pairs(t) do
			if type(k) == 'number' then
				for kk, vv in pairs(v) do
					fields[kk] = vv
				end
				cnt = cnt - 1
				if cnt < 0 then
					break
				end
			end
		end
		for k, v in pairs(fields) do
			local kL10n = getL10nField(k)
			if fields[kL10n] then
				map[k] = kL10n
			elseif strfind(k, suffix) then
				kL10n = k
				k = strsub(k, 1, #k - #suffix)
				map[k] = kL10n
			end
		end

		-- print('---fields')
		-- for k,v in pairs(fields) do print(k,v) end
		-- print('---map')
		-- for k,v in pairs(map) do print(k,v) end
	end

	for k, v in pairs(t) do
		if type(k) == 'string' and type(v) == 'table' then
			if strsub(k, 1, 2) ~= '__' then
				-- print('!!! _setL10nConfig', k, v)
				_setL10nConfig(v)
			end
		elseif next(map) and type(k) == 'number' and type(v) == 'table' then
			for kk, kk2 in pairs(map) do
				-- 语言转换
				-- print(k, kk, v[kk], kk2, v[kk2])
				v[kk] = v[kk2]
			end
		end
	end
end

globals.gMonsterCsv = {}
if csv.monster_scenes then
	for k,v in csvPairs(csv.monster_scenes) do
		if gMonsterCsv[v.scene_id] == nil then gMonsterCsv[v.scene_id] = {} end
		gMonsterCsv[v.scene_id][v.round] = v
	end
end
-- 默认是简体中文
-- 现在只有内网才有多语言，发布版本通过csv2lua直接覆盖无需再转换
if LOCAL_LANGUAGE ~= 'cn' then
	_setL10nConfig(csv)
end
