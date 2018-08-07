--[[
Autor:João Victor Oliveira Couto

Componente Curricular: Concorrência e Conectividade

Concluido em: 04/08/2018

Declaro que este código foi elaborado por mim de forma individual e não contém nenhum
trecho de código de outro colega ou de outro autor, tais como provindos de livros e
apostilas, e páginas ou documentos eletrônicos da Internet. Qualquer trecho de código
de outra autoria que não a minha está destacado com uma citação para o autor e a fonte
do código, e estou ciente que estes trechos não serão considerados para fins de avaliação.
--]]

local ServersHistory = require "models.business.ServersHistory" --import ServersHistory object class

local ConsensusManager = {}

ConsensusManager.__index = ConsensusManager

function ConsensusManager:new() --class that have all consensus decisions
	local this = { --iternal object for class
		newsDecisions = {}, --table that stores decisions about news
        serversHistory = ServersHistory:new(), --reference to serversHistory instance
        newsManager = nil, --reference to newsManager object instance
        serversLimit = 0, --number to known limit of existing servers
        parentServer = nil --reference to parent server class object
	}

	return setmetatable(this, ConsensusManager)
end

function ConsensusManager:setNewsManager(newsManager) --method to set reference to newsManager
	self.newsManager = newsManager
end

function ConsensusManager:setServerLimit(limit) --method to set number of total servers existing
	self.serversLimit = limit
end

function ConsensusManager:setParentServer(parentServer) --method to set reference to parent server
	self.parentServer = parentServer
end

function ConsensusManager:isFinished(newsName) --verify if consensus for the news has finished
	if not self.newsDecisions[newsName] then --if doens't exist consensus about this news, create it
		self.newsManager:addNews(newsName) --try to add news to file
		self.newsDecisions[newsName] = {status = false, serversDecisions = {this = self.newsManager:decisionAbout(newsName)}, amount = 1} --create decision object
	end
	return self.newsDecisions[newsName].status
end

function ConsensusManager:tryEstablishConsensus(newsName) --protocol to try to establish the consensus
	local currentQuantity = self.newsDecisions[newsName].amount --stores currentQuantity of trustable servers
	print("Entering Consensus", newsName, currentQuantity, ((self.serversLimit * 2) / 3) + 1)
	if currentQuantity >= ((self.serversLimit * 2) / 3) + 1 then --if 2/3 + 1 servers online and sended decisions
		local totalTrue = 0 --counter for number of true decisions
		for key, value in pairs(self.newsDecisions[newsName].serversDecisions) do
			if key ~= "this" and not self.serversHistory:itsTrustable(key) then --if isn't self server
				currentQuantity = currentQuantity - 1 --if server it's not trustable decrements servers to try connection
			elseif value then
				totalTrue = totalTrue + 1 --if server decision is true, add it in total
			end
		end
		local decision = false --current decision maked for the news
		if totalTrue >= ((currentQuantity * 2) / 3) + 1 then --verify if can have a decision for consensus
			self.newsDecisions[newsName].status = true
			decision = true
		elseif currentQuantity - totalTrue >= ((currentQuantity * 2) / 3) + 1 then --verify if can have a decision for consensus
			self.newsDecisions[newsName].status = true
		end
		print("Decision:", decision, "Status:", self.newsDecisions[newsName].status)
		if self.newsDecisions[newsName].status then --if have a decision finished
			print("Opened file to write")
			local file = io.open("../notifications.csv", "a+") --stores decision in a file
			file:write(newsName .. " is a " .. (decision and "True" or "Fake News") .. "\n")
		end
	end
end

function ConsensusManager:receivingDecisions(message)
	-- Here will split the message into newsName and originAddress
	local newsName = message:match(".+%)"):gsub("%)", "")
	local serverAddress = message:match("%d+%.%d+%.%d+%.%d+[:%d+]?")
	local decision = message:match("@.+"):gsub("@", "") == "true"
	print(newsName, serverAddress, decision)
	if not self.newsDecisions[newsName].serversDecisions[serverAddress] then
		self.newsDecisions[newsName].amount = self.newsDecisions[newsName].amount + 1
	end
	self.newsDecisions[newsName].serversDecisions[serverAddress] = decision
	self.serversHistory:updateInformations(serverAddress, {id = newsName, decision = decision})
	return newsName
end

function ConsensusManager:stage(message) --method to verify consensus stage
	local stage = message:match("<.+>"):gsub("<", ""):gsub(">", "")
	if stage == "start" then
		local newsName = message:match(":.+"):gsub(":", "")
		if not self:isFinished(newsName) then --only start consensus if it is not finished
			self.parentServer:sendInformations("consensus<decision>:" .. newsName .. ")(" .. self.parentServer.host .. "@" .. tostring(self.newsDecisions[newsName].serversDecisions.this))
		end
	end
	if stage == "decision" then
		local newsName = self:receivingDecisions(message:match(":.+"):gsub(":", ""))
		if not self:isFinished(newsName) then
			self:tryEstablishConsensus(newsName)
		end
	end
end

return ConsensusManager
