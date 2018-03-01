--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- Widget缓存
--
local WidgetCache = class("WidgetCache")

function WidgetCache:ctor()
	self.cdxGUIReader = ccs.GUIReader:getInstance()
	self.cdxTextureCache = display.director:getTextureCache()
end

function WidgetCache:getWidget(res)
	-- cc.CSLoader:createNode(resourceFilename)
	-- cocos studio 1.6
	local widget = self.cdxGUIReader:widgetFromJsonFile(res)
	adaptUI(widget, res)
	translateUI(widget)
	return widget
end

return WidgetCache