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

function ConsensusManager:new()
	local this = {
		newsDecisions = {},
        serversHistory = ServersHistory:new(),
        newsManager = nil,
        serversLimit = 0,
        parentServer = nil
	}

	return setmetatable(this, ConsensusManager)
end

function ConsensusManager:setNewsManager(newsManager)
	self.newsManager = newsManager
end

function ConsensusManager:setServerLimit(limit)
	self.serversLimit = limit
end

function ConsensusManager:setParentServer(parentServer)
	self.parentServer = parentServer
end

function ConsensusManager:isFinished(newsName)
	if self.newsDecisions[newsName] and self.newsDecisions[newsName].status then
		return true
	end
	return false
end

function ConsensusManager:tryEstablishConsensus(newsName)
	local currentQuantity = #self.newsDecisions[newsName].serversDecisions
	if currentQuantity >= ((self.serversLimit * 2) / 3) + 1 then
		local totalTrue = 0
		for key, value in self.newsDecisions[newsName].serversDecisions do
			if key ~= "this" and not self.serversHistory:itsTrustable(key) then
				currentQuantity = currentQuantity - 1
			else
				if value then
					totalTrue = totalTrue + 1
				end
			end
		end
		local decision = false
		if totalTrue >= ((currentQuantity * 2) / 3) + 1 then
			self.newsDecisions[newsName].status = true
			decision = true
		elseif currentQuantity - totalTrue >= ((currentQuantity * 2) / 3) + 1 then
			self.newsDecisions[newsName].status = true
		end
		if self.newsDecisions[newsName].status then
			local file = io.open("../notifications.csv", "w+")
			file:write(newsName .. " is a " .. (decision and "Fake News" or "True") .. "\n")
		end
	end
end

function ConsensusManager:stage(message)
	local stage = message:match("<.+>"):gsub("<", ""):gsub(">", "")
	if stage == "start" then
		local newsName = message:match(":.+"):gsub(":", "")
		if not self:isFinished(newsName) then
			if not self.newsDecisions[newsName] then
				self.newsDecisions[newsName] = {status = false, serversDecisions = {this = self.newsManager:decisionAbout(newsName)}}
				self.parentServer:sendInformations("consensus<decision>:" .. newsName .. ")(" .. self.parentServer.host .. "@" .. tostring(self.newsDecisions[newsName].serversDecisions.this))
			end
		end
	end
	if stage == "decision" then
		local newsName = self:receivingDecisions(message:match(":.+"):gsub(":", ""))
		self:tryEstablishConsensus(newsName)
	end
end

function ConsensusManager:receivingDecisions(message)
	-- Here will split the message into newsName and originAddress
	local newsName = message:match(".+%)"):gsub("%)", "")
	local serverAddress = message:match("%d+%.%d+%.%d+%.%d+[:%d+]?")
	local decision = message:match("@.+"):gsub("@", "") == "true"
	self.newsDecisions[newsName].serversDecisions[serverAddress] = decision
	self.serversHistory:updateInformations(serverAddress, {id = newsName, decision = decision})
	return newsName
end

return ConsensusManager
