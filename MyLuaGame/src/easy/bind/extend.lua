--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ViewBase bind extend类相关
--
local helper = require "easy.bind.helper"
local inject = require "easy.bind.extend.inject"

-- extend
-- @param class: 关联类；string
function bind.extend(view, node, b)
	if b.class then
		-- 延迟绑定，类名
		view:deferUntilCreated(function()
			logf.bind("%s - %s extend %s %s, %s", tostring(view), tostring(node), b.class, dumps(b.handlers), dumps(b.props))
			local cls = require("easy.bind.extend." .. b.class)
			inject(cls, view, node, helper.handlers(view, node, b.handlers), helper.props(view, node, b.props))
				:initExtend()
		end)
	end
end

