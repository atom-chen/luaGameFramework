--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 界面美化相关辅助函数
--
local beauty = {}
globals.beauty = beauty


-- tableview布局模式 gird, center
-- @param layout: grid 按照最大完整格子显示 center 尽量居中
function beauty.tableMargin(size, cellSize, count, layout)
	layout = layout or "grid"
	-- grid
	local maxColumnSize = math.floor(size.width / cellSize.width)
	local maxRowSize = math.floor(size.height / cellSize.height)
	local lines = math.ceil(count / maxColumnSize)
	local xMargin = 0
	if maxColumnSize > 1 then
		xMargin = math.floor((size.width - maxColumnSize * cellSize.width) / (maxColumnSize - 1))
	end
	local yMargin = 0
	if lines > 1 then
		yMargin = math.floor((size.height - lines * cellSize.height) / (lines - 1))
	end
	-- center
	local rate = 0.618
	local leftPadding, topPadding
	if layout == "center" then
		local y = yMargin == 0 and cellSize.height or yMargin
		if y > cellSize.height * rate then
			yMargin = math.floor(cellSize.height * rate)
			y = size.height - yMargin * (lines - 1) - cellSize.height * lines
			topPadding = math.floor(y / 2)
		end
		if count < maxColumnSize then
			local x = count > 1 and math.floor((size.width - count * cellSize.width) / (count - 1)) or cellSize.width
			if x > cellSize.width * rate then
				xMargin = math.floor(cellSize.width * rate)
				x = size.width - xMargin * (count - 1) - cellSize.width * count
				leftPadding = math.floor(x / 2)
			end
		end
	end
	return lines, maxColumnSize, xMargin, yMargin, leftPadding, topPadding
end
