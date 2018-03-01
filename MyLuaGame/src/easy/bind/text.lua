--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ViewBase bind text文本相关
--
local helper = require "easy.bind.helper"

-- text
-- @param text: 静态文本
-- @param idler: 惰性求值器，返回值为文本；如果是字符串，则绑定ui上的变量
-- @param method: 对idler触发时进行数据处理
function bind.text(view, node, b)
	if b.text then
		node:setString(b.text)

	elseif b.idler then
		helper.listen(view, node, b, function(view, node, val)
			node:setString(val)
		end)
	end
end

-- color
-- @param color: 静态颜色
-- @param idler: 惰性求值器，返回值为颜色；如果是字符串，则绑定view上的变量
-- @param method: 对idler触发时进行数据处理
function bind.color(view, node, b)
	if b.color then
		node:setColor(b.color)

	elseif b.idler then
		helper.listen(view, node, b, function(view, node, val)
			node:setColor(val)
		end)
	end
end

