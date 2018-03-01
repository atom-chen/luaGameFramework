--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- sprite封装
--

-- require "view.shader"

globals.CSprite = class("CSprite", cc.Node)

CSprite.Types = {
	ARMATURE = 1, -- cocos studio 1.6制作的动画，已经废弃不用了
	SPRITE = 2, -- 普通的sprite
	SPINE = 3, -- spine json
	SPINEBIN = 4, -- spine skel
	PLIST = 5, -- plist粒子
}

local type = tolua and tolua.type or type
local findLast = string.findlastof
local cache = cache

--
-- globals
--

function globals.createCCSprite(...)
	return cc.Sprite:create(...)
end

function globals.newCSprite(...)
	local sprite = CSprite.new(...)
	sprite.id = cache.addCSprite(sprite)
	return sprite
end

function globals.newAutoReleaseCSprite(...)
	local sprite = CSprite.new(...)
	sprite.id = cache.addCSprite(sprite, true)
	return sprite
end

function globals.removeCSprite(spriteID)
	return cache.removeCSprite(spriteID)
end

--
-- locals
--

local function parseResString(aniRes)
	if aniRes == nil or aniRes == "" then return end
	local argsStr = nil
	local aniStr = nil
	local pos_ = string.find(aniRes,'%[')
	if pos_ ~= nil then
		aniStr = string.sub(aniRes,1,pos_ - 1)
		argsStr = string.sub(aniRes,pos_+1,string.len(aniRes)-1)
	else
		aniStr = aniRes
	end
	aniStr = string.gsub(aniStr, '\\', function(c)
        return '/'
    end)
    aniStr = string.gsub(aniStr, "//", function(c)
        return '/'
    end)
	return aniStr, argsStr
end

local function getResTypeAndPath(res)
	local aniStr, argsStr = parseResString(res)
	local typ, aniStr2
	local pos = string.find(aniStr, "%.skel")
	if pos then
		typ = CSprite.Types.SPINEBIN
		aniStr2 = string.sub(aniStr, 1, pos-1)..".atlas"
	end
	if typ == nil then
		pos = string.find(aniStr, "%.json")
		if pos then
			typ = CSprite.Types.SPINE
			aniStr2 = string.sub(aniStr, 1, pos-1)..".atlas"
		end
	end
	if typ == nil then
		pos = string.find(aniStr, "%.png") or string.find(aniStr, "%.jpg")
		if pos then
			typ = CSprite.Types.SPRITE
		end
	end
	if typ == nil then
		local pos = string.find(aniStr, "%.ExportJson")
		if pos then
			typ = CSprite.Types.ARMATURE
			local prePos = findLast(aniStr, "/")
			aniStr2 = string.sub(aniStr, prePos+1, pos-1)
		end
	end
	if typ == nil then
		pos = string.find(aniStr, "%.plist")
		if pos then
			typ = CSprite.Types.PLIST
		end
	end

	return typ, argsStr, aniStr, aniStr2
end

function CSprite:init(argsStr)
	if argsStr == nil or self.ani == nil then return end
	local posbs = string.find(argsStr, "bs")
	local posrotate = string.find(argsStr, "rotate")
	local posalpha = string.find(argsStr, "alpha")
	local poshsl = string.find(argsStr, "hsl")
	local poshscc = string.find(argsStr, "hscc")  --命名中不能包含hsl 不然上面的poshsl也会有值
	--poshsl , poshscc = nil,nil
	if posbs ~= nil then
		local T = {}
		for arg in argsStr:sub(posbs):gmatch("[-.%d]+") do
			table.insert(T, tonumber(arg))
			if #T >= 2 then break end
		end
		if #T ~= 2 then return end
		self.ani:setScale(T[1],T[2])
	end
	if posrotate ~= nil then
		for arg in argsStr:sub(posrotate):gmatch("[-.%d]+") do
			self.ani:setRotation(tonumber(arg))
			break
		end
	end
	if posalpha ~= nil then
		for arg in argsStr:sub(posalpha):gmatch("[-.%d]+") do
			self.ani:setOpacity(tonumber(arg) * 255)
			break
		end
	end
	if poshsl ~= nil then
		local T = {}
		for arg in argsStr:sub(poshsl):gmatch("[-.%d]+") do
			table.insert(T, tonumber(arg))
			if #T >= 3 then break end
		end
		if #T ~= 3 then return end
		local shader = getHSLShader(self)
		self.inHSLShader = true
		self:setGLProgram("normal", shader)
		shader:setUniformFloat("fhue", T[1])
		shader:setUniformFloat("saturation", T[2])
		shader:setUniformFloat("brightness", T[3])
		shader:setUniformInt("programSwitch", 1)
	end
	if poshscc ~= nil then
		local T = {}
		for arg in argsStr:sub(poshscc):gmatch("[-.%d]+") do
			table.insert(T, tonumber(arg))
			if #T >= 3 then break end
		end
		if #T ~= 3 then return end
		local shader = getHSLShader(self)
		self.inHSLShader = true
		self:setGLProgram("normal", shader)
		shader:setUniformFloat("fhue", T[1])
		shader:setUniformFloat("saturation", T[2])
		shader:setUniformFloat("brightness", T[3])
		shader:setUniformInt("programSwitch",2)
	end
end

function CSprite:ctor(aniRes, raw)
	self.ani = nil
	self.aniType = nil
	self.inHSLShader = false
	self.aniRes = aniRes
	if aniRes == nil then
		if raw ~= nil then
			self.ani = raw
			self.aniType = CSprite.Types.SPRITE
			self:addChild(self.ani)
		else
			-- CSprite只是当个cc.Node来使用
			-- CSprite.Types.SPRITE只能使用cc.Node提供的接口来实现相关功能
			-- 如果后续有要用到cc.Sprite特定功能，aniType就需要做分离
			self.ani = self
			self.aniType = CSprite.Types.SPRITE
		end
		return
	end

	local typ, argsStr, aniStr, aniStr2 = getResTypeAndPath(aniRes)
	self.aniType = typ

	-- print('!!!! CSprite', aniRes, typ, argsStr, aniStr, aniStr2)
	if typ == CSprite.Types.SPINE or typ == CSprite.Types.SPINEBIN then
		--改为A4后 内存压力确实小了很多，以后内存不是瓶颈的话，战斗开始和结束可以缓存着，到达一定量再释放!!!
		local atlas = aniStr2
		self.ani = sp.SkeletonAnimation:create(aniStr, atlas)

		-- 注册到resCache管理释放
		-- g_resCache:registerSpine(self.ani, aniStr)

	elseif typ == CSprite.Types.SPRITE then
		self.ani = createCCSprite(aniStr)

	elseif typ == CSprite.Types.ARMATURE then
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(aniStr)
		self.ani = ccs.Armature:create(aniStr2)

	elseif typ == CSprite.Types.PLIST then
		self.ani = cc.ParticleSystemQuad:create(aniStr)
	end
	-- cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)

	if self.ani then
		self:addChild(self.ani)
	end

	--处理动画指令
	self:init(argsStr)
end

--预加载
function CSprite.preLoad(aniRes, retain)
	if aniRes == nil or aniRes == "" then return end
	local texCache = cc.Director:getInstance():getTextureCache()
	local typ, argsStr, aniStr, aniStr2 = getResTypeAndPath(aniRes)

	local ret
	if typ == CSprite.Types.SPINE or typ == CSprite.Types.SPINEBIN then
		--改为A4后 内存压力确实小了很多，以后内存不是瓶颈的话，战斗开始和结束可以缓存着，到达一定量再释放!!!
		ret = sp.SkeletonAnimation:create(aniStr, aniStr2)

	elseif typ == CSprite.Types.ARMATURE then
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(aniStr)

	elseif typ == CSprite.Types.SPRITE then
		texCache:addImage(aniStr) --以后有loading条的话 就用异步加载

	elseif typ == CSprite.Types.PLIST then
		cc.ParticleSystemQuad:create(aniStr)
	end

	if retain then
		ret:retain()
	end
	-- g_loadingScene:toYield()
	return ret
end

function CSprite:isArmature()
	return self.aniType ==self.Types.ARMATURE
end

function CSprite:isSpine()
	return self.aniType == self.Types.SPINE or self.aniType == self.Types.SPINEBIN
end

function CSprite:setGLProgram(programStr,hslProgram)
	if self.ani == nil then return end
	local shader = nil
	local programIdx = proramStrHash[programStr]
	if hslProgram then
		shader = hslProgram

	elseif self.inHSLShader == false then
		if programStr == "normal" then
			if self:isSpine() then
				programStr = "spine_normal"
				programIdx = proramStrHash[programStr]
			end
		end
		shader = cc.GLProgramState:getOrCreateWithGLProgram(shaderMap:find(programIdx))
	end

	if self.aniType == self.Types.SPRITE then
		if shader and self.ani:getGLProgramState() ~= shader then --优化
			self.ani:setGLProgramState(shader)
			for k,v in pairs(self.ani:getChildren()) do
				--用cast是强转，甚至把v都转了，有问题！
				if iskindof(v, "cc.Sprite") then
					v:setGLProgramState(shader)
				end
			end
		end

	elseif self.aniType == self.Types.ARMATURE then
		if shader and self.ani:getGLProgramState() ~= shader then --优化
			self.ani:setGLProgramState(shader)
			for k,v in pairs(self.ani:getChildren()) do
				if type(v) == "ccs.Bone" then
					local nodeList = v:getDisplayNodeList()  --默认都是sprite类型
					for k1,v1 in pairs(nodeList) do
						v1:setGLProgramState(shader)
					end
				end
			end
		end

	elseif self:isSpine() then
		if shader and self.ani:getGLProgramState() ~= shader then --优化
			self.ani:setGLProgramState(shader)
		end
	end

	if self.inHSLShader then --子骨骼等共用同一个program，所以只需设置一次就ok
		self.ani:getGLProgramState():setUniformInt("programIdx",programIdx)
	end
end

function CSprite:setTextureRect(size,rotated)
	if self.ani == nil then return end
	if self.aniType == self.Types.SPRITE then
		for k,v in pairs(self.ani:getChildren()) do
			if iskindof(v, "cc.Sprite") then
				local rect = v:getTextureRect()
				local _size = {}
				if size.width < rect.width then _size.width = size.width
				else _size.width = rect.width end
				if size.height < rect.height then _size.height = size.height
				else _size.height = rect.height end
				v:setTextureRect(cc.rect(rect.x,rect.y,_size.width,_size.height),rotated,_size)
			end
		end

	elseif self.aniType == self.Types.ARMATURE then
		for k,v in pairs(self.ani:getChildren()) do
			if iskindof(v, "ccs.Bone") then
				local nodeList = v:getDisplayNodeList()  --默认都是sprite类型
				for k1,v1 in pairs(nodeList) do
					local rect = v1:getTextureRect()
					local _size = {}
					if size.width < rect.width then _size.width = size.width
					else _size.width = rect.width end
					if size.height < rect.height then _size.height = size.height
					else _size.height = rect.height end
					v1:setTextureRect(cc.rect(rect.x,rect.y,_size.width,_size.height),rotated,_size)
				end
			end
		end
	end
end

function CSprite:setLifeTime(time)
	return cache.setCSpriteLifeTime(self, time)
end

function CSprite:pause()
	if self.ani == nil then return end
	if self.aniType == self.Types.ARMATURE then
		self.ani:getAnimation():pause()

	elseif self:isSpine() then
		self.ani:pause()
	end
end

function CSprite:resume()
	if self.ani == nil then return end
	if self.aniType == self.Types.ARMATURE then
		self.ani:getAnimation():resume()

	elseif self:isSpine() then
		self.ani:resume()
	end
end

function CSprite:play(action)
	if self.aniType == CSprite.Types.ARMATURE then
		if action then
			self.ani:getAnimation():play(action)
		else
			self.ani:getAnimation():playWithIndex(0)
		end

	elseif self:isSpine() then
		self.ani:setToSetupPose()
		if action:find("_loop") then
			self.ani:setAnimation(0, action, true)
		else
			local ok = self.ani:setAnimation(0, action, false)
			if not ok and action == "effect" then
				ok = self.ani:setAnimation(0, "effect_loop", true)
			end
		end
	end
end

function CSprite:removeSelf()
	self.ani:removeFromParent()
	self:removeFromParent()
	return self
end

function CSprite:setAnimationSpeedScale(speedScale)
	if self.aniType == CSprite.Types.ARMATURE then
		self.ani:getAnimation():setSpeedScale(speedScale)

	elseif self:isSpine() then
		self.ani:setTimeScale(speedScale)
	end
end

function CSprite:setSpriteEventHandler(handler)
	if self:isSpine() then
		for k, v in pairs(sp.EventType) do
			self.ani:unregisterSpineEventHandler(v)
			self.ani:registerSpineEventHandler(function (event)
				handler(v, event)
			end, v)
		end
	end
end
