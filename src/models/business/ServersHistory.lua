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

local ServersHistory = {}

ServersHistory.__index = ServersHistory

function ServersHistory:new() --class to save history of all servers decisions
	local this = {
		binser = require "binser", --loads library to serialize table 
		history = {} --table to load history
	}

	local file = io.open("server_history.bin", "r") --open file to load previous content
	if file then
		this.history = this.binser.deserialize(file:read("*all")) --deserialize file if it exists
		file:close()
	end

	return setmetatable(this, ServersHistory)
end

function ServersHistory:updateInformations(serverAddress, information) --method to update informations about server
	if not self.history[serverAddress] then self.history[serverAddress] = {} end
	self.history[serverAddress][information.id] = information.decision
	local serialized = self.binser.serialize(self.history)
	local file = io.open("server_history.bin", "w") --save information in saved table
	file:write(serialized) --write serialized table
	file:close()
end

function ServersHistory:itsTrustable(serverAddress) --method to verify if a server is trustable
	return true
	--[[local totalCorrect = 0
	local total = 0
	for key, value in pairs(self.history[serverAddress]) do --run out all of servers histories
		local amountTrue = 0
		local amountFalse = 0
		for server, history in pairs(self.history) do --run all decisions in the server history
			if server ~= serverAddress then
				if history[key].decision then
					amountTrue = amountTrue + 1
				else
					amountFalse = amountFalse + 1
				end
			end
		end
		if (value.decision and amountTrue > amountFalse) or (amountTrue < amountFalse and not value.decision) then
			totalCorrect = totalCorrect + 1
		end
		total = total + 1
	end
	if totalCorrect >= ((total * 2)/3) + 1 then
		return true
	end
	return false--]]
end

return ServersHistory
