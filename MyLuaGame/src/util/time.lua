--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- time相关
--
local time = {}
globals.time = time

time.SERVER_TIMEKEY = "dayTime"

-- 根据时间戳，获取对应服务器时区时间的table
function time.getDate(timestamp)
	return os.date('!*t', timestamp + UNIVERSAL_TIMEDELTA)
end

-- 获取当前服务器时区时间的table
function time.getNowDate()
	return os.date('!*t', time.getTime() + UNIVERSAL_TIMEDELTA)
end

-- 根据服务器时间时区，delta是时间偏移，获取相应时间的table
function time.getDeltaDate(delta)
	return os.date('!*t', time.getTime() + delta + UNIVERSAL_TIMEDELTA)
end

-- 根据服务器时间的table，获取时间戳
function time.getTimestamp(t)
	local lt = os.time(t)
    -- 不使用手机设置的时区
    local now = os.time()
    local ldelta = os.difftime(now, os.time(os.date("!*t", now)))
    return lt - UNIVERSAL_TIMEDELTA + ldelta
end

-- 根据服务器时间，获得对应格式的值
function time.getFormatValue(format, delta)
	delta = delta or 0
	return tonumber(os.date('!' .. format, time.getTime() + delta + UNIVERSAL_TIMEDELTA))
end

--time.dayTime = {flag=1,baseTime=0,isLoop=false} --游戏的day时间
--flag 1:正计时; 2:倒计时 . baseTime:基准时间 . isLoop:是否循环，一般用于倒计时
--倒计时的话 比如5分钟,现在还剩4分钟,basetime=4*60; recordTime=5*60
function time.registerTime(key,flag,baseTime,isLoop,recordTime)
	time[key] = {}
	time[key].flag = flag
	if flag == 1 then
		time[key].baseTime = baseTime - os.time()
	elseif flag == 2 then
		time[key].baseTime = baseTime + os.time()
		time[key].isLoop = isLoop
		if isLoop then
			time[key].record = recordTime --多少时间循环一次
		end
	end
end

--返回os.date,返回0表示倒计时结束
function time.getTimeTable(key,_noupdate)
	local info = time[key]
	if info == nil then return nil end
	local curTime = os.time()
	if info.flag == 1 then
		local time = math.floor(info.baseTime + curTime)
		return time.getDate(time)
	elseif info.flag == 2 then
		local time = math.floor(info.baseTime - curTime)
		if time <= 0 then
			if info.isLoop and _noupdate == nil then
				info.baseTime = info.baseTime + info.record
			end
			return 0
		else
			return {hour=math.floor(time/3600),min=math.floor((time%3600)/60),sec=time%60}
		end
	end
end

--返回没处理过的时间
function time.getTime(key)
	key = key or time.SERVER_TIMEKEY
	local info = time[key]
	if info == nil then return nil end
	local curTime = os.time()
	if info.flag == 1 then
		local time = math.floor(info.baseTime + curTime)
		return time
	elseif info.flag == 2 then
		local time = math.floor(info.baseTime - curTime)
		return time
	end
end

-- 自然日
function time.getTodayStr() --20150612
	local T = time.getTimeTable()
	return string.format("%04d%02d%02d",T.year,T.month,T.day)
end

-- 默认5点刷新时间
function time.getTodayStrInClock(freshHour) --20150612
	freshHour = freshHour or 5
	local T = time.getTimeTable()
	if T.hour >= freshHour then
		return string.format("%04d%02d%02d",T.year,T.month,T.day)
	else
		local t = os.time(T) - 24*3600
		T = time.getDate(t)
		return string.format("%04d%02d%02d",T.year,T.month,T.day)
	end
end

--获取倒计时
local day,hour,min,sec
--@Param type 1 ret:hour:min:sec
function time.getCutDown(time)

	day = math.floor(time / 86400)
	hour = math.floor((time % 86400 ) / 3600)
	min = math.floor((time % 3600 ) / 60)
	sec = math.floor(time % 60)

	local str = string.format("%02d:%02d:%02d",hour,min,sec)
	return {day = day,hour = hour,min = min,sec = sec,str = str}
end

--获取活动开放日期,以前的不用修改，接口主要提供给以后活动
function time.getActivityOpenDate(controllerC,activityID)
	local cfg = csv.yunying.yyhuodong[activityID]

	local date = ""

	if cfg.openType == 0 or cfg.openType == 1 or cfg.openType == 2 then

		local StartHour = time.getHourAndMin(cfg.beginTime)
		local endHour = time.getHourAndMin(cfg.endTime)

		date = string.format(gLanguageCsv.time_string,string.sub(cfg.beginDate,5,6),string.sub(cfg.beginDate,7,8),StartHour).."-"..
			  string.format(gLanguageCsv.time_string,string.sub(cfg.endDate,5,6),string.sub(cfg.endDate,7,8),endHour)

	elseif cfg.openType == 3 or cfg.openType == 4 then

		local endTime = controllerC:getActiveEndTime(activityID)

		local startTime = (cfg.relativeDayRange[2] - cfg.relativeDayRange[1] + 1) * 24 * 3600

		local date1 = time.getDate(startTime)
		local date2 = time.getDate(endTime)

		date = string.format(gLanguageCsv.time_string,string.format("%02d",date1.month),string.format("%02d",date1.day),date1.hour).."-"..
			   string.format(gLanguageCsv.time_string, string.format("%02d",date2.month),string.format("%02d",date2.day),date2.hour)
	end

	return date
end

--获取小时分钟
function time.getHourAndMin(timeStr)
	return math.floor(timeStr / 100), timeStr % 100
end

-- 将20150612数字转成时间戳
function time.getNumTimestamp(time)
	local t = {
		year = math.floor(time/10000),
		month = math.floor((time%10000)/100),
		day = math.floor(time%100),
		hour = 0,
		min = 0,
		sec = 0
	}
	return time.getTimestamp(t)
end
