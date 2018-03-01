--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 内置编辑器
--

local ButtonNormal = "img/editor/btn_1.png"
local ButtonClick = "img/editor/btn.png"

local editor = {}
local iupeditor

function editor:init(scene)
	print('editor:init')
	if self.node == nil then
		-- self.scene = g_gameUI.gameScene
		self.scene = scene
		local node = cc.Node:create()
		self.scene:addChild(node, 99999999)
		self.node = node
		self.itemIndex = 1
		self:initUI()
		self:initLuaLoaded()

		local ffi = require("ffi")
		if ffi.os == "Windows" then
			iupeditor = require("editor.win32.builder")
			iupeditor:init(scene)
		end
	end
end

function editor:getNextFlowPosition()
	local size = cc.size(0, 0)
	local maxHeight = 0
	for i = 1, self.itemIndex - 1 do
		local item = self.node:getChildByTag(i)
		local itemSize = item:getContentSize()
		itemSize.width = itemSize.width * item:getScaleX()
		itemSize.height = itemSize.height * item:getScaleY()
		maxHeight = math.max(maxHeight, size.height + itemSize.height)
		size.width = size.width + itemSize.width
		if size.width > display.width then
			size.width = 0
			size.height = maxHeight
		end
	end
	return size.width, -size.height
end

function editor:addButton(txt, handleName, doubleClickDuration)
	local btn = ccui.Button:create(ButtonNormal, ButtonClick)
	btn:setTitleText(txt)
	btn:setTitleFontSize(20)
	btn:setOpacity(100)
	btn:setPressedActionEnabled(true)
	local lastClickTime = 0
	btn:addClickEventListener(function()
		local function callback()
			print('editor:' .. handleName)
			self[handleName](self)
		end
		if doubleClickDuration and false then
			local nowTime = os.time()
			if nowTime - lastClickTime > doubleClickDuration then
				lastClickTime = nowTime
				self:addTipLabel(string.format("%d秒内再次点击生效", doubleClickDuration), "_reloadlua_draw_")
			else
				lastClickTime = 0
				callback()
			end
		else
			callback()
		end
	end)

	local x, y = self:getNextFlowPosition()
	x, y = x + self.uiOffest.x, y + self.uiOffest.y
	local size = btn:getContentSize()
	local node = cc.Node:create()
	node:addChild(btn)
	node:setScale(0.8)
	node:setPosition(x + size.width/2, display.height + y - size.height/2)
	node:setContentSize(size.width, size.height)
	self.node:addChild(node, 0, self.itemIndex)
	self.itemIndex = self.itemIndex + 1
	return btn
end

function editor:initUI()
	self.uiOffest = cc.p(100, 0)
	self:addButton("CSV刷新", "onReloadCsv", 5)
	self:addButton("LUA热更新", "onReloadLua")
	self:addButton("Node定位", "onNodeLocate")

	self.uiOffest = cc.p(100, -50)
	self.itemIndex = 1
	-- self:addButton("保存战斗", "onBattleSave")
	-- self:addButton("加载战斗", "onBattleLoad")
end


function editor:visitChangedFiles(dir, cb)
	local fs = require "editor.fs"
	local files = fs.listAllFiles(dir, function (name)
		return name:match("%.lua$")
	end, true)

	for name, time in pairs(files) do
		local old = self.luaModifyTimes[name]
		if old == nil or old[1] ~= time[1] or old[2] ~= time[2] then
			self.luaModifyTimes[name] = time
			cb(name)
		end
	end
end

function editor:initLuaLoaded()
	if self.luaModifyTimes then return end
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if cc.PLATFORM_OS_WINDOWS ~= targetPlatform then return end
	self.luaModifyTimes = {}

	package.path = string.format("%s%s?.lua;%s?.lua", package.path, 'src/', 'cocos/')
	self:visitChangedFiles("./src", function() end)
end

function editor:onReloadCsv()
	os.execute("cd ..\\..\\tools\\csv2lua\\ && python csv2lua.py")
	os.execute("xcopy ..\\..\\tools\\csv2lua\\config\\*.* .\\src\\config\\ /e /y")
	self:onRefreshCsv()
end

function editor:onRefreshCsv()
	for k, v in pairs(package.loaded) do
		if string.find(k, "^config") then
			package.loaded[k] = nil
		end
	end
	package.loaded["base.config"] = nil
	local backupYunying = clone(csv.yunying)
	require"base.config"
	csv.yunying = backupYunying
end

local preStack
function editor:onNodeLocate()
	local eventDispatcher = display.director:getEventDispatcher()
	self.locateEnabled = not self.locateEnabled
	if not self.locateEnabled and iupeditor then
		iupeditor:hideNodesStack()
	end
	if self.locateListner then
		self.node:removeChildByName("_locate_draw_")
		return
	end

	local function dfs(deep, node, pos)
		local all = {}
		local childs = node:getChildren()
		for i = #childs, 1, -1 do
			local child = childs[i]
			if child ~= self.node and child:isVisible() then
				local ret, path = dfs(deep + 1, child, pos)
				if ret then
					-- all = itertools.merge({all, path})
					table.insert(path, node)
					return true, path
				end
			end
		end

		-- ignore cc.Node and cc.Layer and ccui.Layout
		local ty = tolua.type(node)
		if ty == "cc.Node" or ty == "cc.Layer" or ty == "ccui.Layout" then
			return false
			-- return true, all
		end

		if node.hitTest and node:hitTest(pos) then
			-- print('!!! hit', deep, node:getLocalZOrder(), tostring(node), tolua.type(node))
			return true, {node}
		elseif node:getParent() then
			local box = node:getBoundingBox()
			local lpos = node:getParent():convertToNodeSpace(pos)
			if cc.rectContainsPoint(box, lpos) then
				-- print('!!! inbox', deep, node:getLocalZOrder(), tostring(node), tolua.type(node), lpos.x, lpos.y, box.x, box.y, box.width, box.height)
				return true, {node}
				-- return true, itertools.merge({all, {node}})
			end
		end
		return false
		-- return true, all
	end

	local listener = cc.EventListenerMouse:create()
	local stack = ""
	listener:registerScriptHandler(function(event)
		if not self.locateEnabled then return end
		-- print('------move')
		local x, y = event:getCursorX(), event:getCursorY()
		local ret, path = dfs(1, self.scene, cc.p(x, y))
		self.node:removeChildByName("_locate_draw_")
		if ret then
			local node = cc.Node:create()
			self.node:addChild(node, 0, "_locate_draw_")
			stack = ""
			for i = 1, #path - 1 do
				local child = path[i]
				local draw = self:getDebugBox(child, string.format("%d", i), cc.c4f(1 - i / #path, i / #path, 0, 1 - i / #path))

				stack = stack .. string.format("%d_%s_%s_%s\n", i, tolua.type(child), child:getTag(), child:getName())
				node:addChild(draw, #path - i)
			end

			-- local label = cc.Label:createWithTTF(stack, FONT_PATH, 16)
			-- label:setTextColor(cc.c4b(255, 255, 255, 50))
			-- label:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			-- label:setAnchorPoint(0, 0)
			-- node:addChild(label)

			if iupeditor and stack ~= preStack then
				iupeditor:showNodesStack(path, function()
					self.locateEnabled = false
					if self.locateListner then
						self.node:removeChildByName("_locate_draw_")
						return
					end
				end, function(idx)
					local child = path[idx]
					self.node:removeChildByName("_highlight_draw_")
					local draw = self:getDebugBox(child, string.format("%d", idx), cc.c4f(1, 1, 1, 1), 4)
					self.node:addChild(draw, 0, "_highlight_draw_")
					draw:runAction(cc.Sequence:create(
						cc.DelayTime:create(2),
						cc.CallFunc:create(function()
							draw:removeFromParent()
						end)
					))
				end)
			end
			preStack = stack
		end
	end, cc.Handler.EVENT_MOUSE_MOVE)

	listener:registerScriptHandler(function(event)
		local statusLines = string.split(stack, "\n")
		local genString = "self.node."
		local name = ""
		for i = 1, #statusLines do
			local line = statusLines[#statusLines + 1 - i]
			if string.find( line, "name:" ) and not string.find(line, ".json") then
				_, _, name = string.find(line, "name:(.-) ")
				genString = genString..name.."."
			end
		end
		genString = string.sub(genString, 1, -2)
		local handle = io.popen("set /p=\""..genString.."\"<nul | clip")
		handle:close()
	end, cc.Handler.EVENT_MOUSE_UP)

	eventDispatcher:addEventListenerWithFixedPriority(listener, -1)
	self.locateListner = listener
end


function editor:onReloadLua()
	local changed = {}
	self:visitChangedFiles("./src", function(name)
		local luaname = name:sub(7, #name-4):gsub("/", ".")
		table.insert(changed, luaname)
	end)

	local list = ""
	local csvChanged =false
	for i, path in ipairs(changed) do
		print(i, path, package.loaded[path], package.preload[path], 'lua changed!!!')
		-- 删除src.zip时用的preload默认加载器，否则require不会读取本地文件
		package.preload[path] = nil
		if package.loaded[path] then
			if not path:find("^config") then
				package.loaded[path] = nil
				require(path)
			else
				csvChanged = true
			end
			list = list .. string.format("%2d %s\n", i, path)
		end
	end
	if csvChanged then
		self:onRefreshCsv()
	end

	self:addTipLabel(list, "_reloadlua_draw_")
end

function editor:addTipLabel(txt, tagName)
	self.node:removeChildByName(tagName)
	if txt == "" then return end

	local label = cc.Label:createWithTTF(txt, ui.FONT_PATH, 30)
	label:setPosition(display.width / 2, display.height / 2)
	label:setTextColor(cc.c4b(255, 0, 0, 100))
	label:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	self.node:addChild(label, 0, tagName)
	performWithDelay(label, function()
		self.node:removeChildByName(tagName)
	end, 6)
end


function editor:getDebugBox(child, text, color)
	local draw = cc.DrawNode:create()
	local p = child:getParent():convertToWorldSpace(cc.p(child:getPosition()))
	local ax, ay = p.x, p.y
	local rect = child:getContentSize()
	local box = child:getBoundingBox()
	local anchor = child:getAnchorPoint()
	local x, y = ax - box.width * anchor.x, ay - box.height * anchor.y
	-- print(i, tostring(child), tolua.type(child), child:getTag(), child:getName(), x, y, 'world', p.x, p.y, 'box', box.width, box.height, 'rect', rect.width, rect.height, 'anchor', anchor.x, anchor.y)

	draw:drawSegment(cc.p(0, 0), cc.p(box.width, 0), 1, color)
	draw:drawSegment(cc.p(box.width, 0), cc.p(box.width, box.height), 1, color)
	draw:drawSegment(cc.p(box.width, box.height), cc.p(0, box.height), 1, color)
	draw:drawSegment(cc.p(0, box.height), cc.p(0, 0), 1, color)
	draw:drawSegment(cc.p(0, 0), cc.p(box.width, box.height), 1, color)
	draw:drawDot(cc.p(box.width * anchor.x, box.height * anchor.y), 6, color)
	draw:setPosition(x, y)

	local label = cc.Label:createWithTTF(text, ui.FONT_PATH, 20)
	label:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	label:setPosition(box.width * anchor.x, box.height * anchor.y)
	draw:addChild(label)

	return draw
end

-- local battleModule = require "editor.battle"
-- for k, v in pairs(battleModule) do
-- 	editor[k] = v
-- end

return editor