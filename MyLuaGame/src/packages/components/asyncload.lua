--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- AsyncLoading 异步加载相关
-- 使用协程
--
local AsyncLoading = class("AsyncLoading")

local EXPORTED_METHODS = {
	"asyncFor",
	"overFor",
	"pauseFor",
	"resumeFor",
	"isPreloadOK",
	"preloadOverFor",
}

function AsyncLoading:init_()
	self.loading = false
	self.pause = false
	self.data = nil
end

function AsyncLoading:bind(target)
	self:init_()
	cc.setmethods(target, self, EXPORTED_METHODS)
	self.target_ = target
	self.oldUpdate_ = target.onUpdate_
	target.onUpdate_ = function(...)
		self:onAsyncUpdate_(...)
		return self.oldUpdate_(...)
	end
end

function AsyncLoading:unbind(target)
	if self.loading and self.data.cb_over then
		self.data.cb_over()
	end
	cc.unsetmethods(target, EXPORTED_METHODS)
	self:init_()
	target.onUpdate_ = self.oldUpdate_
end

-- cb_over避免涉及view相关操作
function AsyncLoading:asyncFor(cb_start, cb_over, preload)
	if self.loading then
		--一个view只能一个async在工作
		self:overFor()
	end
	local co = coroutine.create(function ()
		xpcall(cb_start, __G__TRACKBACK__)
	end)
	self.data = {co = co, cb_over = cb_over, cb_preload = nil, preload = preload or 0}
	self.pause = false
	self.loading = true
end

function AsyncLoading:onAsyncUpdate_()
	local v = self.data
	if v == nil then return end
	if self.pause and v.preload <= 0 then return end

	local first = true
	while v.preload > 0 or first do
		local ret, err = coroutine.resume(v.co)
		if ret == nil or ret == false then
			self:overFor()
			break
		end
		v.preload = v.preload - 1
		first = false
	end

	if v.cb_preload_over and v.preload <= 0 then
		v.cb_preload_over()
		v.cb_preload_over = nil
	end
end

function AsyncLoading:overFor()
	if self.loading then
		local v = self.data
		self.loading = false
		self.data = nil
		if v and v.cb_preload_over then
			v.cb_preload_over()
		end
		if v and v.cb_over then
			v.cb_over()
		end
	end
end

function AsyncLoading:pauseFor()
	self.pause = true
end

function AsyncLoading:resumeFor()
	self.pause = false
end

function AsyncLoading:isPreloadOK()
	return self.data.preload <= 0
end

function AsyncLoading:preloadOverFor(cb_preload_over)
	if self.data == nil or self.data.preload <= 0 then
		if self.data == nil then
			printError('!!! 检查弹框创建是否在协程创建之前')
		end
		cb_preload_over()
	else
		self.data.cb_preload_over = cb_preload_over
	end
end

return AsyncLoading