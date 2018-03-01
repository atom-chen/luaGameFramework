--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ViewBase bind touch触摸点击相关
--
local helper = require "easy.bind.helper"

-- touch
-- @param method: view关联函数
-- @param methods: view关联函数,接受消息映射 {ended=XXX, began=XXX}
-- @param sound: 点击音效ID
-- @param clicksafe: 一般有服务器响应的 不需要调用保护 因为本身服务器响应会把全部界面响应禁了
-- @param scaletype: 缩放效果 1: 先放大后正常 2：先缩小再正常 0:不放大也不缩小
-- @param bounce: 位移效果，更强烈的点击感
-- @param args: 现在只有Layer:onTouch用
function bind.touch(view, node, b)
	local scale
	if b.scaletype == 1 then
		scale = 1.1
	elseif b.scaletype == 2 then
		scale = 0.9
	end

	local bouncex, bouncey
	local posx, posy
	if b.bounce then
		local size = node:getContentSize()
		posx, posy = node:getPosition()
		bouncex, bouncey = size.width*0.05, size.height*0.05
	end

	local function callback(recv)
		-- 缩放效果
		if scale then
			transition.scaleTo(node, {time = 0.1, scale = (recv.name == "began" and scale or 1)})
		end

		-- 位移效果
		if bouncex then
			if recv.name == "began" then
				node:setPosition(bouncex+posx, bouncey+posy)
			else
				node:setPosition(posx, posy)
			end
		end

		-- 消息过滤
		local f = helper.method(view, node, b, recv.name)
		if not f then return end

		-- 点击音效
		if b.sound and recv.name == "ended" then
			-- TODO: no SOUND_LIST
			AudioEngine.playEffect(SOUND_LIST[b.sound or 1])
		end

		-- 点击保护
		if b.clicksafe and recv.name == "ended" then
			local delay = 0.5
			node:setEnabled(false)
			performWithDelay(node, function()
				node:setEnabled(true)
			end, delay)
			transition.executeParallel(node)
				:func(function()
					f(recv)	--这里可能会清除node的操作，所以要放在最后处理
				end)
			return
		end

		return f(recv)
	end

	node:onTouch(callback, unpack(b.args or {}))
end


-- click
-- @param method: view关联函数
-- @param sound: 点击音效ID
-- @param clicksafe: 一般有服务器响应的 不需要调用保护 因为本身服务器响应会把全部界面响应禁了
function bind.click(view, node, b)
	local function callback(recv)
		local f = helper.method(view, node, b)

		-- 点击音效
		if b.sound then
			-- TODO: no SOUND_LIST
			AudioEngine.playEffect(SOUND_LIST[b.sound or 1])
		end

		-- 点击保护
		if b.clicksafe then
			local delay = 0.5
			node:setEnabled(false)
			performWithDelay(node, function()
				node:setEnabled(true)
			end, delay)
			transition.executeParallel(node)
				:func(function()
					f(recv)	--这里可能会有清除所有的uiNode的操作，所以要放在最后处理
				end)
			return
		end

		return f(recv)
	end

	node:onClick(callback)
end

