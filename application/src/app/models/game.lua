--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- GameModel
--
local GameModel = class("GameModel")

function GameModel:ctor()
	globals.gGameModel = self

	self.account = nil
end

function GameModel:syncFromServer(t)
	if not t.model then return end

	-- model init
	if t.model then
		print_r(t.model)

		if t.model.account then
			self.account = self:_initModel(self.account, require("app.models.arena.account"), t.model.account)
		end
		t.model = nil
	end

	-- model sync
	if t.sync then
		for model, data in pairs(t.sync) do
			self[model]:syncFrom(data)
		end
		t.sync = nil
	end
end

function GameModel:_initModel(model, cls, t)
	if model then
		mode:syncFrom(t)
	else
		model = cls.new(t)
	end
	return model
end

return GameModel
