--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- CSprite缓存
--

local CSpriteCache = class("CSpriteCache")

local spriteCounter = 0

local insert = table.insert

function CSpriteCache:ctor()
	-- 所有创建的资源，包括spine, sprite, plist
	self.autoRelease = {}
	self.lifeMap = {} -- {id={tick, lifetime}}
	self.all = CMap.new()
end

function CSpriteCache:insert(sprite, autoRelease)
	spriteCounter = spriteCounter + 1
	local spriteID = spriteCounter
	sprite:retain()
	self.all:insert(spriteID, sprite)
	if autoRelease or false then
		insert(self.autoRelease, spriteID)
	end
	return spriteID
end

function CSpriteCache:erase(spriteID)
	local sprite = self.all:find(spriteID)
	if sprite then
		insert(self.autoRelease, spriteID)
	end
end

function CSpriteCache:clear()
	spriteCounter = 0
	self.autoRelease = {}
	self.lifeMap = {}
	for k, v in self.all:pairs() do
		v:release()
	end
	self.all:clear()
end

function CSpriteCache:setLifeTime(spriteID, time)
	local t = self.lifeMap[spriteID]
	if t == nil then
		t = {0, time}
		self.lifeMap[spriteID] = t
	end
	t[2] = time
end

function CSpriteCache:update(delta)
	if #self.autoRelease > 0 then
		for _, k in ipairs(self.autoRelease) do
			local sprite = self.all:erase(k)
			if sprite then
				sprite:removeSelf():release()
			end
		end
		self.autoRelease = {}
	end

	for k, v in pairs(self.lifeMap) do
		v[1] = v[1] + delta
		if v[1] >= v[2] then -- tick >= time
			insert(self.autoRelease, spriteID)
			self.lifeMap[k] = nil
		end
	end
end

return CSpriteCache