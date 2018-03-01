--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 处理RichText和自定义格式字符串
--

local rich = {}
globals.rich = rich

--@param blackEnd: 时候文本结束后恢复为黑色
function rich.color(color, text, blackEnd)
	if blackEnd == nil then
		blackEnd = true
	end
	return {text = text, color = color, blackEnd = blackEnd}
end

function rich.font(size, text)
	return {text = text, fontSize = size}
end

--@param fontSize: 默认24
local function _generateRichTexts(array, fontSize, deltaSize)
	deltaSize = deltaSize or 0
	fontSize = fontSize or 24

	local elems = {}
	local tag = 1 --先写死
	local ttf = ui.FONT_PATH
	local opacity = 255 --这个先写死 看需求是否需要
	local color = cc.c3b(255, 255, 255)
	for k, t in ipairs(array) do
		if t.type == "color" then -- 颜色
			color = t.color

		elseif t.type == "font" then -- 字体
			fontSize = t.size + deltaSize

		elseif t.type == "image" then -- 图片
			local element = ccui.RichElementImage:create(0, cc.c3b(255, 255, 255), 255, t.path)
			table.insert(elems, {element, resPath})

		elseif t.type == "text" then
			local element = ccui.RichElementText:create(tag, color, opacity, t.text, ttf, fontSize)
			table.insert(elems, {element, {color, opacity, t.text, ttf, fontSize}})
		end
	end
	return elems
end

local function _getRichTextsByStr(str, fontSize, deltaSize)
	local nstr = string.gsub(str, "\\n", function(c)
		return "\n"
	end)
	local T = {}
	local start = 1
	while true do
		local l, r, ss = nstr:find('#([CFTI][^#]+)#', start)
		if l == nil then break end
		if l > start then
			table.insert(T, {s=nstr:sub(start, l - 1)})
		end
		table.insert(T, {s=ss, format=true})
		start = r + 1
	end
	if start < #nstr then
		table.insert(T, {s=nstr:sub(start)})
	end

	local T2 = {}
	for k, t in ipairs(T) do
		local v = t.s
		local t2 = {}
		if t.format then
			if string.sub(v,1,1) == 'C' then -- 颜色
				local num = tonumber(string.sub(v,2))
				if num == nil then
					t2 = {type="text", text=tostring(v)}
				else
					t2 = {type="color", color=cc.c3b(math.floor(num/65536), math.floor(num/256%256), num%256)}
				end

			elseif string.sub(v,1,1) == 'F' then -- 字体
				local size = tonumber(string.sub(v,2))
				if size == nil or size > 100 or size < 0 then
					t2 = {type="text", text=tostring(v)}
				else
					t2 = {type="font", size=size}
				end

			elseif string.sub(v,1,1) == 'T' then -- 头衔
				local num = tonumber(string.sub(v,2))
				if num == nil or csv.title[num] == nil then
				else
					local resPath = csv.title[num].res
					if cc.FileUtils:getInstance():isFileExist(resPath) then
						t2 = {type="image", path=resPath}
					end
				end

			elseif string.sub(v,1,1) == 'I' then -- 图片
				local resPath = string.sub(v,2)
				if cc.FileUtils:getInstance():isFileExist(resPath) then
					t2 = {type="image", path=resPath}
				end
			end
		else
			t2 = {type="text", text=tostring(v)}
		end

		if next(t2) then
			table.insert(T2, t2)
		end
	end

	return _generateRichTexts(T2, fontSize, deltaSize)
end

local function _getRichTextsByArray(array, fontSize, deltaSize)
	local T2 = {}
	for _, t in ipairs(array) do
		if type(t) == "table" then
			if t.color then
				table.insert(T2, {type="color", color=t.color})
				table.insert(T2, {type="text", text=t.text})
				if t.blackEnd then
					table.insert(T2, {type="color", color=cc.c3b(255, 255, 255)})
				end

			elseif t.fontSize then
				table.insert(T2, {type="font", size=t.fontSize})
				table.insert(T2, {type="text", text=t.text})
			end
		else
			table.insert(T2, {type="text", text=t})
		end
	end

	return _generateRichTexts(T2, fontSize, deltaSize)
end

local function round(f)
	local n = math.floor(f)
	local e = f - n
	if e < 0.5 then
		return n
	else
		return n + 1
	end
end

local function ltrim(s)
	return s:gsub("^%s*(.-)", "%1")
end

local function _binarySearchSplit(richTextTest, params, lineWidth)
	local tag = 1 --先写死
	local color, opacity, s, ttf, fontSize = unpack(params)
	local l, r = 1, #s + 1
	while l < r do
		local mid = math.floor((l + r) / 2)
		local left = s:sub(1, mid)
		local elem = ccui.RichElementText:create(tag, color, opacity, left, ttf, fontSize)
		richTextTest:pushBackElement(elem)
		richTextTest:formatText()
		local size = richTextTest:getContentSize()
		if size.width > lineWidth then
			r = mid
		else
			l = mid + 1
		end
		richTextTest:removeElement(elem)
	end
	local split = r - 1
	while 0 < split and split < #s do
		if s:byte(split) == 32 then
			break
		else
			split = split - 1
		end
	end
	return split
end

--@param onlyElems: true 返回richtext中间格式，false 返回组装好的ccui.RichText
local function _getRichTextsWordLineFeed(strOrArray, size, deltaSize, lineWidth, onlyElems)
	onlyElems = onlyElems or false

	local tag = 1 --先写死
	local richText = onlyElems or ccui.RichText:create()
	local richTextTest = ccui.RichText:create()
	richTextTest:ignoreContentAdaptWithSize(true)

	local retElems = {}
	local elems
	if type(strOrArray) == "table" then
		elems = _getRichTextsByArray(strOrArray, size, deltaSize)
	else
		elems = _getRichTextsByStr(strOrArray, size, deltaSize)
	end

	local lineElems = {}
	for _, t in ipairs(elems) do
		local elem, params = t[1], t[2]
		richTextTest:pushBackElement(elem)
		richTextTest:formatText()
		local size = richTextTest:getContentSize()
		-- print("width=", size.width, size.width > lineWidth, params[3])
		while size.width > lineWidth do
			richTextTest:removeElement(elem)
			-- split
			if type(elem) == "ccui.RichElementText" then
				local color, opacity, s, ttf, fontSize = unpack(params)
				-- 默认是英文
				local split = _binarySearchSplit(richTextTest, params, lineWidth)
				-- print(size.width, split, 'left=', s:sub(1, split))
				if split == 0 and #lineElems == 0 then
					-- error("could not split word")
					-- 一段无法分割的字会有纰漏，多余自动换行的没有计算长度
					break
				end
				local left = s:sub(1, split) .. "\n"
				table.insert(lineElems, {ccui.RichElementText:create(tag, color, opacity, left, ttf, fontSize), {color, opacity, left, ttf, fontSize}})
				local right = ltrim(s:sub(split + 1))
				-- print('right=', right)
				elem = ccui.RichElementText:create(tag, color, opacity, right, ttf, fontSize)
				params[3] = right
			end
			-- fill line
			for _, t2 in ipairs(lineElems) do
				if onlyElems then
					table.insert(retElems, t2)
				else
					richText:pushBackElement(t2[1])
				end
			end
			lineElems = {}
			richTextTest = ccui.RichText:create()
			richTextTest:ignoreContentAdaptWithSize(true)
			-- right
			richTextTest:pushBackElement(elem)
			richTextTest:formatText()
			size = richTextTest:getContentSize()
		end
		table.insert(lineElems, {elem, params})
	end
	for _, t2 in ipairs(lineElems) do
		if onlyElems then
			table.insert(retElems, t2)
		else
			richText:pushBackElement(t2[1])
		end
	end
	return onlyElems and retElems or richText
end

-------------------
-- 导出函数

--@param array: 使用rich.相关函数创建的数组
function rich.createByArray(array, size, deltaSize)
	local richText = ccui.RichText:create()
	local elems = _getRichTextsByArray(array, size, deltaSize)
	for _, t in ipairs(elems) do
		local elem = t[1]
		richText:pushBackElement(elem)
	end
	return richText
end

--@desc #C代表color  #F代表字体大小 其他就是要显示的字符串
--@param deltaSize: 偏移量，用在city中聊天缩略窗口，需要调整大小，小于聊天界面的字体
--@example str = "#C0xffffff##F24#dfsagfeif23df#C0xf45fff##F32#grgfgsf#F24#哈哈哈dfs  #C0xffffff#Inksu#C0xff22ff##F1##F12##C0xFFFFFF#恭喜#C0xFFEE2C#Inky#C0xFFFFFF#历尽艰辛后，达到数码试炼50层，希望ta百尽竿头，更进一步！#T1#T2#T3#T##T1rank"
function rich.createByStr(str, size, deltaSize)
	local richText = ccui.RichText:create()
	local elems = _getRichTextsByStr(str, size, deltaSize)
	for _, t in ipairs(elems) do
		local elem = t[1]
		richText:pushBackElement(elem)
	end
	return richText
end

-- 固定宽度
function rich.adjustWidth(richText, fixedWidth)
	richText:ignoreContentAdaptWithSize(false)
	richText:setContentSize(cc.size(fixedWidth , 0))
	richText:formatText()
	return richText:getContentSize()
end

-- 获取固定宽度的richtext控件
--@desc 相比调用getRichTextsByStr和adjustRichTextWidth，getRichTextWithWidth能进行英文按单词换行
--@desc 如果是array，不允许里面的srting有类似#C这类格式字符串存在
function rich.createWithWidth(strOrArray, size, deltaSize, lineWidth)
	local richText
	if LOCAL_LANGUAGE ~= "cn" and LOCAL_LANGUAGE ~= "tw" then
		richText = _getRichTextsWordLineFeed(strOrArray, size, deltaSize, lineWidth)
	else
		if type(strOrArray) == "table" then
			richText = rich.createByArray(strOrArray, size, deltaSize)
		else
			richText = rich.createByStr(strOrArray, size, deltaSize)
		end
	end
	rich.adjustWidth(richText, lineWidth)
	return richText
end

-- 获取richtext格式信息
-- 现在只提供给SRichText使用
function rich.createElemsWithWidth(strOrArray, size, deltaSize, lineWidth)
	if LOCAL_LANGUAGE ~= "cn" and LOCAL_LANGUAGE ~= "tw" then
		return _getRichTextsWordLineFeed(strOrArray, size, deltaSize, lineWidth, true)
	else
		if type(strOrArray) == "table" then
			return _getRichTextsByArray(strOrArray, size, deltaSize)
		else
			return _getRichTextsByStr(strOrArray, size, deltaSize)
		end
	end
end