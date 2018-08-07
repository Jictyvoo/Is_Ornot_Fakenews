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

local socket = require "socket" --import socket api
local NewsManager = require "models.business.NewsManager" --import NewsManager object class
local ConsensusManager = require "models.business.ConsensusManager"
local Server = {} --create table to have new function

Server.__index = Server -- set index metadata to Server table

function Server:new(newsFilename) --metafunction to instantiate the object
    local this = {--local table to storage private attributes
        host = "192.168.43.250", --server host attribute
        port = 3040, --server port attribute
        -- create a TCP socket
        server = socket.tcp(), --server connection object
        threads = {}, --thread that will run tcp connections
        newsManager = NewsManager:new(newsFilename), --NewsManager object
        serverAddresses = {},
        consensusManager = ConsensusManager:new()
    }
    this.consensusManager:setNewsManager(this.newsManager)
    this.consensusManager:setParentServer(this)

    local file = io.open("../config.conf", "r") --open config file with host and port for current server
    local conf = file:read("*all")
    this.host = conf:match("[^:]+")
    this.port = conf:match(":%d+"):gsub(":", "")

    -- bind socket to the local host, at specified port
    this.server:bind(this.host, this.port)
    this.server:listen(1000) --say that can listen 1000 clients connections
    this.server:settimeout(0.001)
    this.newsManager:setConsensusManager(this.consensusManager) --add object to newsManager

    return setmetatable(this, Server)
end

function Server:loadAddresses(filename) --function that loads server addresses
    for line in io.lines(filename) do --open file and read every line in it
        local host = line:match("[^;]+")
        local port = tonumber(line:match("%d+$"))
        table.insert(self.serverAddresses, {host = host, port = port}) --add address readed into address list
    end
    self.consensusManager:setServerLimit(#self.serverAddresses + 1) --add the number of existent servers
    return self
end

function Server:verifyNews() --function for thread that execute verifications in file and start protocol
    if self.newsManager:asFileModified() then --verify if file was modified
        if #self.newsManager.addedNews > 0 then --if have added new news to file, send it to others servers
            for newsAdded in self.newsManager:iterateAddedNews() do --iterate all added news from file
                local message = "add:<>" .. newsAdded
                self:sendInformations(message) --send message to all servers
            end
        end
        coroutine.yield() --interrupt thread
        if #self.newsManager.canStart > 0 then --verify if can start the consesus protocol
            for newsToConsensus in self.newsManager:iterateCanStartConsensus() do --iterate news to start consensus
                self:sendInformations("consensus<start>:" .. newsToConsensus)
            end
        end
    end
end

function Server:sendInformations(message) --method to send messages to all others servers
    for key, value in pairs(self.serverAddresses) do
        local connection = socket.tcp() --create a tcp object for connection
        connection:bind(value.host, value.port) --establish the port and host to connect
        connection:settimeout(0.1) --set timeout connection for don't stop client UI
        for attempt = 1, 7 do
            if connection:connect(value.host, value.port) then --connection established
                print(attempt .. ": " .. message .. " - " .. value.host .. ":" .. value.port)
                connection:send(message .. "\n")
                attempt = 8 --force exit from attempts to connection
            end
        end
        coroutine.yield() --pause current thread
    end
end

function Server:protocol(connection) --method to start connection protocol
    local peername = connection:getpeername()
    local message = connection:receive() --receive message from connection
    if message:find("add:<>") then --verify if is to add a new news
        self.newsManager:addNews(message:match("[^add:<>]+[%S, %d]+")) --added news
    elseif message:find("consensus") then --verify if is a consensus attempt
        self.consensusManager:stage(message) --start consensus protocol
    end
end

function Server:execute() --method to execute main thread and coroutines management
    --[[table.insert(self.threads, coroutine.create(function() self.consensusManager:stage("consensus<start>: É possível encolher") end))--Only for test]]
    local connection_loop = function() --function that execute listen thread
        local connection = nil --variable that stores accepted connection
        while true do --main loop for current thread
            connection = self.server:accept() --try to connect to a connection
            if connection then --if successfuly connect to a connection
                table.insert(self.threads, coroutine.create(function() self:protocol(connection) end))
            end
            coroutine.yield() --pause current coroutine
        end
    end
    table.insert(self.threads, coroutine.create(connection_loop)) --add connection thread to threads table
    table.insert(self.threads, coroutine.create(function() while true do self:verifyNews(); coroutine.yield() end end))

    while true do --main loop
        local index = 1 --index to run out all threads
        while index <= #self.threads do
            if not coroutine.resume(self.threads[index]) then
                table.remove(self.threads, index) --remove thread from table if it is a dead thread
            end
            index = index + 1
        end
    end
end

return Server
