--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
local ArenaGames = {
	"tank",
	"tank",
	"tank",
	"tank",
	"tank",
	"tank",
}

local IconSize = 128
local IconName = string.format("icon%d.png", IconSize)

local LobbyView = class("LobbyView", cc.load("mvc").ViewBase)

LobbyView.RESOURCE_FILENAME = "lobby.json"
LobbyView.RESOURCE_BINDING = {
	["leftPanel.heroPanel.name"] = {
		binds = {
			-- 例子1：通过bind，实现功能参数化
			event = "text",
			idler = bindHelper.model("account", "name"),
		},
	},
	["leftPanel.heroPanel.fightingNum"] = {
		binds = {
			-- 例子2：参数化进阶，可灵活处理
			event = "text",
			idler = bindHelper.model("account", "score"),
			method = function(val)
				return math.floor(val)
			end
		},
	},
	["gameContainer"] = {
		varname = "gameContainer",
		binds = {
			-- 例子3：通过bind.extend，实现功能扩展
			event = "extend",
			class = "tableview",
			props = {
				-- 例子4：通过props，实现风格和数据属性化
				data = bindHelper.self("games"),
				columnSize = bindHelper.self("maxColumnSize"),
				leftPadding = bindHelper.self("leftPadding"),
				topPadding = bindHelper.self("topPadding"),
				item = bindHelper.self("listTemp"),
				cell = bindHelper.self("cellTemp"),
				onCell = function(list, node, k, v)
					print("onCell", list, node, k, v, string.format("ui/%s/%s", v, IconName))
					local res = string.format("ui/%s/%s", v, IconName)
					-- node:loadTextures(res, res, res)
				end,
				onCellClick = function(list, node, k, v)
					print("onCellClick", list, node, k, v)
				end,
			},
		}
	},
}

function LobbyView:onCreate()
	cc.Sprite:create("img/new_dljm_01.jpg")
		:move(display.visibleCenter)
		:addTo(self, -1)

	local count = #ArenaGames
	local containerSize = self.gameContainer:getContentSize()
	local rows, columns, xMargin, yMargin, leftPadding, topPadding = beauty.tableMargin(containerSize, cc.size(IconSize, IconSize), count, "center")

	self.games = {}
	for i = 1, count do
		local rowIdx = math.ceil(i / columns)
		local row = self.games[rowIdx]
		if row == nil then
			row = {}
			self.games[rowIdx] = row
		end
		table.insert(row, ArenaGames[i])
	end

	-- 例子4：通过props，实现风格和数据属性化
	self.maxColumnSize = columns
	self.leftPadding = leftPadding
	self.topPadding = topPadding
	self.gameContainer:setItemsMargin(yMargin)

	-- 例子5：通过clone的模板来实现相关风格
	self.listTemp = self.gameContainer:getChildByName("iconList"):clone()
	self.listTemp:addTo(self):hide() -- 隐藏后放在self里面，无需手动维护retain和release
	self.listTemp:setContentSize(cc.size(containerSize.width, iconSize))
	self.listTemp:setItemsMargin(xMargin)
	self.listTemp:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)

	self.cellTemp = ccui.Button:create("ui/lobby/" .. IconName)
	self.cellTemp:addTo(self):hide()

	self.gameContainer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)

	gGameModel.account:syncFrom({score = 12345})

end


return LobbyView
