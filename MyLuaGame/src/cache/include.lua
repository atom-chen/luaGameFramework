--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 各种缓存的导出接口
--

local cache = {}
globals.cache = cache

local widgetCache = require("cache.widget").new()
local cspriteCache = require("cache.sprite").new()

--
-- widget
--

function cache.createWidget(res)
	return widgetCache:getWidget(res)
end

--
-- formula
--

local formulaCache = {}
function cache.createFormula(s, key)
	if s == nil then return nil end
	local formula = key and formulaCache[key]
	if formula == nil then
		formula = assert(loadstring("return ".. s))
		if key then
			formulaCache[key] = formula
		end
	end
	return formula
end

--
-- CSprite
--

function cache.addCSprite(sprite, autoRelease)
	return cspriteCache:insert(sprite, autoRelease)
end

function cache.removeCSprite(sprite)
	cspriteCache:erase(sprite.id)
end

function cache.setCSpriteLifeTime(sprite, time)
	cspriteCache:setLifeTime(sprite.id, time)
end


--
-- common
--

function cache.onBattleClear()
	-- CSprite现在只用于战斗
	cspriteCache:clear()
end

function cache.onUpdate(delta)
	cspriteCache:update(delta)
end