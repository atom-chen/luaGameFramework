--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 主要是进行多语言版本的UI工程适配
--

local type = type

local config = {
	cn = require "app.defines.adapter.cn",
	-- en = require "app.defines.adapter.en",
}

local internalFuncMap

-- @param node: cocos2dx node
-- @param res: resource path for key match
function globals.adaptUI(node, res)
	if config[LOCAL_LANGUAGE] == nil or config[LOCAL_LANGUAGE][res] == nil then
		return
	end
	local uiConfig = config[LOCAL_LANGUAGE][res]
	for op, t in pairs(uiConfig) do
		local memo = {}
		local f = internalFuncMap[op]
		for _, params in ipairs(t) do
			f(node, params, memo)
		end
	end
end

local function _getMemo(memo, key)
	if memo == nil then
		return
	end
	if memo[key] then
		return memo[key][1]
	end
end

local function _setMemo(memo, key, node)
	if memo == nil then
		return node
	end
	if node ~= nil then
		if memo[key] then
			return node, memo[key][2]
		end
		local nextMemo = {}
		memo[key] = {node, nextMemo}
		return node, nextMemo
	end
end

-- node:get('a.b.c')
-- node:get(112)
local function _getChild(node, key, memo)
	if type(key) == 'number' then
		local nextNode = _getMemo(memo, key)
		if nextNode == nil then
			nextNode = node:getChildByTag(key)
		end
		node, memo = _setMemo(memo, key, nextNode)
	else
		for k in key:gmatch("([^.]+)") do
			local ik = tonumber(k)
			local nextNode = _getMemo(memo, ik or k)
			if nextNode == nil then
				if ik then
					nextNode = node:getChildByTag(ik)
				else
					nextNode = node:getChildByName(k)
				end
			end
			node, memo = _setMemo(memo, ik or k, nextNode)
			if node == nil then return end
		end
	end
	return node, memo
end

--@return 可能是cdx或者{cdx1, cdx2, ...}
local function _getChilds(node, keys, memo)
	local ret
	if type(keys) == "string" then
		return _getChild(node, keys, memo)
	else
		ret = {}
		for _, name in ipairs(keys) do
			local w = _getChild(node, name, memo)
			if w == nil then
				error('can not found child [' .. name .. '], check ui adapter config!')
			end
			table.insert(ret, w)
		end
		return ret
	end
end

--@desc 获取widget 的相关信息
local function _getWidgetInfo(widget)
	local size = widget:getContentSize()
	local x, y = widget:getPosition()
	local scaleX = widget:getScaleX()
	local scaleY = widget:getScaleY()
	local anchorPoint = widget:getAnchorPoint()
	return cc.size(size.width * scaleX, size.height * scaleY), cc.p(x,y), anchorPoint
end

-- 对齐适配
--@desc 函数不处理旋转控件
--@param widget1: cdx 中心控件为基准
--@param widgets: cdx1 or {cdx1, cdx2, ...}
--@param align: left widget1, cdx1, cdx2, ...
--				right ..., cdx2, cdx1, widget1
local function _oneLinePos(widget1, widgets, space, align)
	space = space or cc.p(0,0)
	align = align or "left"

	local size1, p1, anchor1 = _getWidgetInfo(widget1)
	if type(widgets) ~= "table" then
		widgets = {widgets}
	end
	for _, widget2 in ipairs(widgets) do
		local size2, p2, anchor2 = _getWidgetInfo(widget2)
		local targetX
		if align == "left" then
			targetX = p1.x + space.x + (1 - anchor1.x) * size1.width + anchor2.x * size2.width
		else
			targetX = p1.x - space.x - anchor1.x * size1.width - (1 - anchor2.x) * size2.width
		end
		local targetY = p2.y + space.y
		widget2:setPosition(cc.p(targetX, targetY))
		-- next
		size1, p1, anchor1 = _getWidgetInfo(widget2)
	end
end

-- 居中对齐
local function _oneLineCenter(widget1, lefts, rights, space)
	_oneLinePos(widget1, lefts, space, "right")
	_oneLinePos(widget1, rights, space, "left")
end

-- 根据给定位置居中对齐
local function _oneLineCenterPos(centerPos, widgets, space)
	space = space or cc.p(0,0)
	if type(widgets) ~= "table" then
		widgets = {widgets}
	end
	local len = (#widgets - 1) * space.x
	for _, widget in ipairs(widgets) do
		local size = widget:getContentSize()
		len = len + size.width
	end

	local x, y = centerPos.x - len / 2, centerPos.y
	for _, widget in ipairs(widgets) do
		local size, p, anchor = _getWidgetInfo(widget)
		widget:setPosition(cc.p(x + anchor.x * size.width, y))
		x = x + size.width + space.x
		y = y + space.y
	end
end

-- 屏幕边缘适配
local function _dockWithScreen(widget1, xAlign, yAlign)
	xAlign = xAlign or ""
	yAlign = yAlign or ""
	if xAlign == "left" then
		widget1:setPositionX(widget1:getPositionX() + display.left)
	elseif xAlign == "right" then
		widget1:setPositionX(widget1:getPositionX() + display.right - CC_DESIGN_RESOLUTION.width)
	elseif xAlign == "center" then
		local offest = widget1:getPositionX() - CC_DESIGN_RESOLUTION.width / 2
		widget1:setPositionX(offest + display.cx)
	end

	if yAlign == "down" then
		widget1:setPositionY(widget1:getPositionY() + display.bottom)
	elseif yAlign == "up" then
		widget1:setPositionY(widget1:getPositionY() + display.top - CC_DESIGN_RESOLUTION.height)
	elseif yAlign == "center" then
		local offest = widget1:getPositionY() - CC_DESIGN_RESOLUTION.height / 2
		widget1:setPositionX(offest + display.cy)
	end
end

--@desc aux for adaptUI
--@param params: {widget1, ...}
local function _auxAdaptWidgetParamsFunc(func)
	return function (parent, params, memo)
		local name1 = params[1]
		local widget1 = _getChild(parent, name1, memo)
		if widget1 == nil then
			local str = name1 .. " is nil"
			error('can not found child, check ui adapter config!\n' .. str)
		end
		-- unpack not same between lua and luajit
		-- luajit unpack until the param was nil
		func(widget1, unpack(params, 2))
	end
end

--@desc aux for adaptUI
--@param params: {widget1, widget2, ...}
local function _auxAdapt2WidgetParamsFunc(func)
	return function (parent, params, memo)
		local name1, name2 = params[1], params[2]
		local widget1 = _getChild(parent, name1, memo)
		local widget2 = _getChilds(parent, name2, memo)
		if widget1 == nil or widget2 == nil then
			local str = (widget1 == nil and name1 or name2) .. " is nil"
			error('can not found child, check ui adapter config!\n' .. str)
		end
		func(widget1, widget2, unpack(params, 3))
	end
end

--@desc aux for adaptUI
--@param params: {widget1, widget2, widget3, ...}
local function _auxAdapt3WidgetParamsFunc(func)
	return function (parent, params, memo)
		local name1, name2, name3 = params[1], params[2], params[3]
		local widget1 = _getChild(parent, name1, memo)
		local widget2 = _getChilds(parent, name2, memo)
		local widget3 = _getChilds(parent, name3, memo)
		if widget1 == nil or widget2 == nil or widget3 == nil then
			local str = (widget1 == nil and name1 or (widget2 == nil and name2 or name3)) .. " is nil"
			error('can not found child, check ui adapter config!\n' .. str)
		end
		func(widget1, widget2, widget3, unpack(params, 4))
	end
end

--@desc aux for adaptUI
--@param params: {centerPos, widgets, ...}
local function _auxAdapt4WidgetParamsFunc(func)
	return function (parent, params, memo)
		local pos, name = params[1], params[2]
		local widget = _getChilds(parent, name, memo)
		if widget == nil then
			error('can not found child, check ui adapter config!\n' .. name .. " is nil")
		end
		func(pos, widget, unpack(params, 3))
	end
end

internalFuncMap = {
	oneLinePos = _auxAdapt2WidgetParamsFunc(_oneLinePos),
	oneLineCenter = _auxAdapt3WidgetParamsFunc(_oneLineCenter),
	oneLineCenterPos = _auxAdapt4WidgetParamsFunc(_oneLineCenterPos),
	dockWithScreen = _auxAdaptWidgetParamsFunc(_dockWithScreen),
}

------------
-- adapt导出

local adapt = {
	oneLinePos = _oneLinePos,
	oneLineCenter = _oneLineCenter,
	oneLineCenterPos = _oneLineCenterPos,
	dockWithScreen = _dockWithScreen,
}

------------
-- adaptContext导出
local adaptContext = {}


function adaptContext.clone(node, cb)
	return {node=node, cb=cb}
end

function adaptContext.noteText(startID, endID)
	return {startID=startID, endID=endID, csv=true}
end

function adaptContext.func(func, ...)
	return {func=func, params={...}}
end

function adaptContext.oneLinePos(name, other, space, align)
	return {adapt=internalFuncMap.oneLinePos, params={name, other, space, align}}
end

function adaptContext.oneLineCenter(name, lefts, rights, space)
	return {adapt=internalFuncMap.oneLineCenter, params={name, lefts, rights, space}}
end

-- 将当前listView换成widget
--@desc 辅助函数，不支持链式调用
local easyEnterFuncMap = {
	oneLinePos = adaptContext.oneLinePos,
	oneLineCenter = adaptContext.oneLineCenter,
}
function adaptContext.easyEnter(name)
	return setmetatable({}, {
		__index = function (t, fname)
			local f = easyEnterFuncMap[fname]
			return function (t, ...)
				local context = f(...)
				return {enter=name, context=context}
			end
		end
	})
end

--@desc 填充规则面板，使用限制
--@param contextTable: {context,...}
--		context = {noteStartID, noteEndID}
--				= funciton
--				= {ccui.Layout, tagName or function}
--@param asyncCount: nil为一次性全部加载本函数内加载，>0值协程加载
function adaptContext.setToList(view, listView, contextTable, asyncCount)
	listView:removeAllChildren()
	local fixedWidth = listView:getContentSize().width

	local function contextHandle(curView, curMemo, context, eachCB)
		if curView == nil then
			error('curView was nil, check ui adapter context!')
		end

		local cType = type(context)
		if cType == "string" then
			local richText = getRichTextWithWidth(context, nil, nil, fixedWidth)
			curView:pushBackCustomItem(richText)

		elseif cType == "function" then
			context()

		elseif cType == "table" then
			-- noteText
			if context.csv then
				for i = context.startID, context.endID do
					local richText = getRichTextWithWidth(csv.note[i].fmt, nil, nil, fixedWidth)
					curView:pushBackCustomItem(richText)
					eachCB()
				end

			-- clone
			elseif context.node then
				-- 本接口一般用于规则面板，clone不重复使用
				local item = context.node:clone(string.format("setContextToList_%f_%f", os.clock(), math.random()))
				item:setVisible(true)
				curView:pushBackCustomItem(item)
				if context.cb then
					context.cb(item)
				end

			-- func
			elseif context.func then
				context.func(unpack(context.params))

			-- oneLinePos
			-- oneLineCenter
			elseif context.adapt then
				context.adapt(curView, context.params, curMemo)

			-- easyEnter
			elseif context.enter then
				local nextView, nextMemo = _getChild(curView, context.enter, curMemo)
				contextHandle(nextView, nextMemo, context.context, eachCB)
			end
		end
	end

	local function asyncFunc()
		local function yield()
			if asyncCount ~= nil then
				coroutine.yield()
			end
		end

		for _, v in ipairs(contextTable) do
			contextHandle(listView, {}, v, yield)
			yield()
		end
	end
	view:enableAsyncload()
	view:asyncFor(asyncFunc, nil, asyncCount)
end

globals.adapt = adapt
globals.adaptContext = adaptContext
