--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- widget辅助函数
--

local widget = {}
globals.widget = widget

--在ui widget下附带特效
function widget.addAnimation(ui, aniRes, action, zOrder)
	return widget.addAnimationByKey(ui, aniRes, aniRes, action, zOrder)
end

--@param key: 相同key不可重复添加，nil表示无限
function widget.addAnimationByKey(ui, aniRes, key, action, zOrder)
	--防止反复add
	local sprite
	if key then
		sprite = ui:getChildByName(key)
		if sprite then return sprite end
	end

	sprite = CSprite.new(aniRes)
	sprite:play(action or "effect")
	ui:addChild(sprite, zOrder or 0, aniRes)
	return sprite
end

--在ui widget下附带cdxobj
function widget.addChild(ui, child, childName, zOrder)
	local node = widget:getChildByName(childName) --防止反复add
	if node then return node end

	widget:addChild(child, zOrder or 0, childName)
	return child
end