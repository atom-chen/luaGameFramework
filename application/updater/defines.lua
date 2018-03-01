
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = true

-- disable create unexpected global variable
CC_DISABLE_GLOBAL = true

-- for module display
local width = 1136
local height = 640
CC_DESIGN_RESOLUTION = {
	width = width,
	height = height,
	autoscale = "FIXED_HEIGHT",
	callback = function(display, framesize)
		local ratio = framesize.width / framesize.height

		--战斗逻辑中不能使用这函数里的变量，只给view使用
		local scaleX = framesize.width / width
		local scaleY = framesize.height / height
		local tmp1 = (width - framesize.width/scaleY) / 2
		if scaleY < 1 then scaleY = height / framesize.height end
		local tmp2 = (width - framesize.width*scaleY) / 2
		local x, y = 0, 0
		if tmp1 > 0 and tmp2 > 0 then x = tmp1 < tmp2 and tmp1 or tmp2
		elseif tmp1 > 0 and tmp1 <= math.abs(tmp2) then x = tmp1
		elseif tmp2 > 0 and tmp2 <= math.abs(tmp1) then x = tmp2 end
		-- 与cocos的Origin含义不同,慎用
		display.visibleOrigin = cc.p(x,0)
		display.visibleCenter = cc.p(width/2, height/2) --可以用在逻辑里面

		display.fightLower = 150
		display.fightUpper = 470
		display.fightHeight = display.fightUpper - display.fightLower  --战斗层下限Y坐标一定0，上限是display.fightHeight

		-- Sets a 2D projection (orthogonal projection).
		display.director:setProjection(cc.DIRECTOR_PROJECTION_2D) --改为正交投影 改善资源 字体 模糊

		if ratio <= 1.34 then
			-- iPad 768*1024(1536*2048) is 4:3 screen
			return {autoscale = "SHOW_ALL"}
		end
	end
}
