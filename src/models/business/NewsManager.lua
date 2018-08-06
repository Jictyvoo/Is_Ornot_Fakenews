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

local NewsManager = {}
NewsManager.__index = NewsManager

function NewsManager:new(filename)
	local this = {
		lfs = require "lfs",
		filename = filename or "",
		lastModification = 0,
		newsInformation = {},
		addedNews = {},
		canStart = {}, -- list to news that can start the consensus
		consensusManager = nil
	}
	return setmetatable(this, NewsManager)
end

function NewsManager:setFilename(filename)
	self.filename = filename or self.filename
	self.lastModification = 0
end

function NewsManager:setConsensusManager(consensusManager)
	self.consensusManager = consensusManager
end

function NewsManager:readFile()
	for line in io.lines(self.filename) do
		local name = ""
		local info = {}
		for divided in string.gmatch(line, "%S+") do
			name = name .. " " .. divided
			if name:find(";") then
				table.insert(info, name:match("[^;]+"))
				name = ""
			end
		end
		table.insert(info, name)
		if not self.newsInformation[info[1]] then
			table.insert(self.addedNews, info[1])
		end
		self.newsInformation[info[1]] = {tonumber(info[2]), tonumber(info[3]:match("%d%.?%d+$"))}
		if not self.consensusManager:isFinished(info[1]) and self.newsInformation[info[1]][1] >= 30 then
			table.insert(self.canStart, info[1])
		end
	end
end

function NewsManager:asFileModified()
	local attributes = self.lfs.attributes(self.filename)
	if attributes.modification > self.lastModification then
		self.lastModification = attributes.modification
		self:readFile()
		return true
	end
	return false
end

function NewsManager:addNews(newsName)
	self.newsInformation[newsName] = self.newsInformation[newsName] or {0, 0}
end

function NewsManager:decisionAbout(newsName)
	return self.newsInformation[newsName] and (self.newsInformation[newsName][2] >= 3 and self.newsInformation[newsName][1] >= 30) or false
end

function NewsManager:__iterator(attribute)
	return function()
		if #self[attribute] > 0 then
			local value = self[attribute][#self[attribute]]
			table.remove(self[attribute], #self[attribute])
			return value
		end
		return nil
	end
end

function NewsManager:iterateCanStartConsensus()
	return self:__iterator("canStart")
end

function NewsManager:iterateAddedNews()
	return self:__iterator("addedNews")
end

return NewsManager
