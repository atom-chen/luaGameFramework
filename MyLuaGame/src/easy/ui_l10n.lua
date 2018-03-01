--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 主要是进行多语言版本的UI本地化翻译
--
local config = {
	-- en = require "easy.l10n.en_config",
	-- vn = require "easy.l10n.vn_config",
}


-- @param node: cocos2dx node
function globals.translateUI(node)
	if config[LOCAL_LANGUAGE] == nil or config[LOCAL_LANGUAGE] == nil then
		return
	end
	local l10nConfig = config[LOCAL_LANGUAGE]
	local function translateStr(object, getMethod, setMethod)
		if getMethod then
			local val = l10nConfig[getMethod(object)]
			if val then
				setMethod(object, val)
			end
		end
	end

	local function translateAll(object)
		for _, child in pairs(object:getChildren()) do
			translateStr(child, child.getString, child.setString)
			translateStr(child, child.getStringValue, child.setText)
			translateStr(child, child.getPlaceHolder, child.setPlaceHolder)
			translateStr(child, child.getTitleText, child.setTitleText)
			translateAll(child)
		end
	end
	translateAll(node)
end
