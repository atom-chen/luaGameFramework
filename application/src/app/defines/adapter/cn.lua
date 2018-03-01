--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
local config = {}

-- 大厅界面
config["lobby.json"] = {
	dockWithScreen = {
		{"leftPanel", "left"},
		{"rightPanel", "right"},
		{"leftPanel.leftDownPanel", "", "down"},
		{"rightPanel.rightUpPanel", "", "up"},
		-- {"gameContainer", "center", "center"},
	},
}

return config