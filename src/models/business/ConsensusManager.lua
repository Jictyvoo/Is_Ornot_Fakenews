local ServersHistory = require "server.models.business.ServersHistory" --import ServersHistory object class

local ConsensusManager = {}

ConsensusManager.__index = ConsensusManager

function ConsensusManager:new()
	local this = {
		newsDecisions = {},
        serversHistory = ServersHistory:new()
	}

	return setmetatable(this, ConsensusManager)
end

function ConsensusManager:isFinished(newsName)
	if self.newsDecisions.status then
		return true
	end
	return false
end

function ConsensusManager:stage(message)
	local stage = message:match("[^<%w+>]")
	print(stage)
end

function ConsensusManager:receivingDecisions(message)
	-- Here will split the message into newsName and originAddress
	local newsName_originAddress = message:match("[^consensus:<>]+[%S, %d]+")
end

return ConsensusManager