--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 字符串辅助函数
--
-- 首字母大写
function string.caption(s)
	return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

