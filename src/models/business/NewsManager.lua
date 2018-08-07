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

function NewsManager:new(filename) --constructor for the object
	local this = { -- internal object table
		lfs = require "lfs", --load library for verify file info
		filename = filename or "", --filename for news storage
		lastModification = 0, --time from last modification 
		newsInformation = {}, --table to storage information about news
		addedNews = {}, --table to storage added news from modified file
		canStart = {}, -- list to news that can start the consensus
		consensusManager = nil
	}
	return setmetatable(this, NewsManager)
end

function NewsManager:setFilename(filename) --method to set filename for file
	self.filename = filename or self.filename
	self.lastModification = 0
end

function NewsManager:setConsensusManager(consensusManager) --method to set consensus manager object
	self.consensusManager = consensusManager
end

function NewsManager:readFile() --method to read news file
	for line in io.lines(self.filename) do --open file and read every line in it
		local name = "" --temporary string that stores readed information
		local info = {} --table to stores complete line information
		for divided in string.gmatch(line, "%S+") do --divide string and read it
			name = name .. divided .. " "
			if name:find(";") then --when find ; caracter, stops current info storage
				table.insert(info, name:match("[^;]+"))
				name = ""
			end
		end
		table.insert(info, name) --add name for info in info table
		if not self.newsInformation[info[1]] then
			table.insert(self.addedNews, info[1]) --add added news into addedNews table
		end
		self.newsInformation[info[1]] = {tonumber(info[2]), tonumber(info[3]:match("%d%.?%d+$"))} --add info to current table
		if not self.consensusManager:isFinished(info[1]) and self.newsInformation[info[1]][1] >= 30 then
			table.insert(self.canStart, info[1]) --if decided that can start consensus, then starts it
		end
	end
end

function NewsManager:asFileModified() --method that verifies if file as modified
	local attributes = self.lfs.attributes(self.filename) --get attributtes from file
	if attributes.modification > self.lastModification then --if file has been modified since last verification, then
		self.lastModification = attributes.modification --update last modification time
		self:readFile() --read file again
		return true
	end
	return false
end

function NewsManager:addNews(newsName) --function to add news into table
	local updated = not self.newsInformation[newsName] --verify if doesn't have that news
	self.newsInformation[newsName] = self.newsInformation[newsName] or {0, 0}
	if updated then --if is a new news, write it in the file
		local file = io.open(self.filename, "a")
		file:write(newsName .. "; " .. self.newsInformation[newsName][1] .. "; " .. self.newsInformation[newsName][2] .. "\n")
		file:close()
		self.lastModification = self.lfs.attributes(self.filename).modification
	end
end

function NewsManager:decisionAbout(newsName) --method to calculate decision about news
	return self.newsInformation[newsName] and (self.newsInformation[newsName][2] >= 3 and self.newsInformation[newsName][1] >= 30) or false
end

function NewsManager:__iterator(attribute) --metamethod to generic iterator without a specific attribute name
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
