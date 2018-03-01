--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.ListView组装成tableview的形式
-- 老版本studio没有ccui.TableView，只能拿二维ccui.ListView来模拟
--
local listview = require "easy.bind.extend.listview"
local inject = require "easy.bind.extend.inject"
local helper = require "easy.bind.helper"

local tableview = class("tableview", listview)

tableview.defaultProps = {
	-- onXXXX 响应函数
	-- 数据 array table, function
	data = nil,
	-- 列数
	columnSize = 1,
	-- 行数 nil 自动
	rowSize = nil,
	-- item模板
	item = nil,
	-- cell模板
	cell = nil,
	-- 左右间距，nil 不改变
	xMargin = nil,
	-- 上下间距，nil 不改变
	yMargin = nil,
	-- 左边填充，nil 不改变
	leftPadding = nil,
	-- 上边填充，nil 不改变
	topPadding = nil,
	-- 异步加载, nil 不使用异步加载, >=0 预加载数量
	asyncPreload = nil,
}

function tableview:buildExtend()
	self.size = self.rowSize
	local cellProps = {
		data = nil,
		size = self.columnSize,
		item = self.cell,
		asyncPreload = nil,
		onItem = self.onCell,
		onItemIndex = self.onCellIndex,
		onItemClick = self.onCellClick,
	}
	self.cellProps = cellProps
	self.asyncPreloadLeft = self.asyncPreload or 0
	if self.yMargin then
		self:setItemsMargin(self.yMargin)
	end
	if self.topPadding then
		self.containerSize = self:getContentSize()
		self:setContentSize(cc.size(self.containerSize.width, self.containerSize.height - self.topPadding))
	end
	if self.leftPadding then
		self.containerPosX = self:getPositionX()
		self:setPositionX(self.containerPosX + self.leftPadding)
	end
	return listview.buildExtend(self)
end

-- for each listview
function tableview:makeItem(k, v)
	if type(v) ~= "table" then
		error("tableview need 2d table")
	end

	local view = self.parent_
	local node = self.item:clone()
	local props = clone(self.cellProps)
	props.data = v
	if self.asyncPreloadLeft > 0 then
		-- 第一次预加载已经完毕，后续不再预加载
		props.asyncPreload = self.asyncPreloadLeft
	end

	-- TODO: tableview need pass handlers to sub-listview
	local item = inject(listview, view, node, helper.handlers(view, node, nil), helper.props(view, node, props))
		:initExtend()

	self.itemNodes[k] = item
	self:onItem(item, k, v)
	local idx = self:onItemIndex(k, v)
	if idx then
		self:insertCustomItem(item, idx)
	else
		self:pushBackCustomItem(item)
	end

	if self.xMargin then
		item:setItemsMargin(self.xMargin)
	end
	return item:show()
end

-- function tableview:onCell(node, k, v)
-- end

-- function tableview:onCellIndex(k, v)
-- end

-- function tableview:onCellClick(node, k, v)
-- end


return tableview