--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

myMath = myMath or {}

function myMath.linerDistance(sx, sy, dx, dy)
	return math.sqrt((dx-sx)*(dx-sx) + (dy-sy)*(dy-sy))
end

function myMath.speedVector(sx, sy, dx, dy, step)
	local dis = linerDistance(sx, sy, dx, dy)
	if dis <= step then return {x = dx - sx, y = dy - sy, dis = dis} end
	local rate = step / dis
	return {x = (dx - sx) * rate, y = (dy - sy) * rate, dis = rate * dis}
end

function myMath.getAngle(_start, _end)
	local pos = cc.pSub(_end, _start)
	return cc.pGetAngle(cc.p(0,0), pos)
end

function myMath.isRectCollideCircle(pos1,length,width,pos2,r) --pos都是两个中心点
	--不精准，把圆当成正方形来判了
	if math.abs(pos2.x - pos1.x) <= length + r and
		math.abs(pos2.y - pos1.y) <= width + r then
		return true
	end
	return false
end

-- 限制val在min和max之间：如果value小于min，返回min；如果value大于max，返回max；否则返回value
function myMath.clamp(val, min, max)
	if val < min then return min end
	if val > max then return max end
	return val
end