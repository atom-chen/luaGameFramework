--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- Date: 2014-07-22 17:07:59
--
require 'json'

-- local _url = require('3rd.url')
-- local urlencode = _url.escape
-- local urluncode = _url.unescape

local _lz4 = require('util.lz4')
local zcompress = _lz4.compress
local zuncompress = _lz4.uncompress

local _msgpack = require('3rd.msgpack')
_msgpack.set_string('binary')
_msgpack.set_number('double')
local msgpack = _msgpack.pack
local msgunpack = _msgpack.unpack


local NetManager = class("NetManager")

-- member method
function NetManager:ctor(game)
	globals.gNet = self

	self.game = game

	self.httpURL = 'http://192.168.1.222:8080'
	self.httpHost = '192.168.1.222'
	self.httpPort = 8080
end

function NetManager:init(host, port, userName, pwdMD5, deviceId, appVersion, patchVersion, cb)
end

function NetManager:setHTTPUrl(url)
	self.httpURL = url
	self.httpHost, self.httpPort = string.gmatch(url, 'http://([-a-z0-9A-Z.]+):(%d+)')()
	self.httpPort = tonumber(self.httpPort)
end

function NetManager:sendHttpRequest(reqType, reqUrl, reqBody, resType, cb)
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = resType
	-- xhr.timeout = 5
	xhr:open(reqType, reqUrl)
	if reqType == 'GET' then
		xhr:setRequestHeader("Accept-Encoding", "gzip")
	end
	local function _onReadyStateChange(...)
		local encode = string.match(xhr:getAllResponseHeaders(), "Content%-Encoding:%s*(gzip)")
		if encode == 'gzip' then
			xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_BLOB
			xhr.response = zuncompress(xhr.response)
		end
		cb(xhr)
	end
	if cb then xhr:registerScriptHandler(_onReadyStateChange) end
	if reqBody then xhr:send(reqBody)
	else xhr:send() end
end

function NetManager:doPost(reqUrl, reqBody, cb)
	reqUrl = string.format("%s%s", self.httpURL, reqUrl)
	log.post(reqUrl)
	print_r(reqBody)
	local reqBlob = "tianji" .. zcompress(msgpack(reqBody))
	return self:sendHttpRequest("POST", reqUrl, reqBlob, cc.XMLHTTPREQUEST_RESPONSE_BLOB, function(xhr)
		if xhr.status == 200 then
			local result = msgunpack(zuncompress(xhr.response))
			gGameModel:syncFromServer(result)
			cb(result)
		else
			if #xhr.response > 0 then
				local result = msgunpack(zuncompress(xhr.response))
				cb(result)
			else
				logf.post('err %s %s', xhr.status, xhr.statusText)
				cb(nil, xhr.statusText)
			end
		end
	end)
end

return NetManager