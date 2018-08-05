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
local NewsManager = require "server.models.business.NewsManager" --import NewsManager object class
local ConsensusManager = require "server.models.business.ConsensusManager"
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

    local file = io.open("../config.conf", "r")
    local conf = file:read("*all")
    this.host = conf:match("[^:]+")
    this.port = tonumber(conf:match("%d+$"))

    -- bind socket to the local host, at any port
    this.server:bind(this.host, this.port)
    this.server:listen(1000)
    this.server:settimeout(0.001)
    this.newsManager:readFile()

    return setmetatable(this, Server)
end

function Server:loadAddresses(filename)
    for line in io.lines(filename) do
        local host = line:match("[^;]+")
        local port = tonumber(line:match("%d+$"))
        table.insert(self.serverAddresses, {host = host, port = port})
    end
    return self
end

function Server:verifyNews()
    if self.newsManager:asFileModified() then
        if #self.newsManager.addedNews > 0 then
            for newsAdded in self.newsManager:iterateAddedNews() do
                local message = "add:<>" .. newsAdded
                self:sendInformations(message)
            end
        end
    end
end

function Server:sendInformations(message)
    for key, value in pairs(self.serverAddresses) do
        local connection = socket.tcp() --create a tcp object for connection
        connection:bind(value.host, value.port) --establish the port and host to connect
        connection:settimeout(0.1) --set timeout connection for don't stop client UI
        for attempt = 1, 7 do
            if connection:connect(value.host, value.port) then --connection established
                connection:send(message .. "\n")
                attempt = 8
            --[[else
                print(message:match("[^add:<>]+[%S, %d]+"))
                print("Attempt " .. attempt .. ":Error to connect to " .. value.host .. ":" .. value.port)
            end
            coroutine.yield()--]]
            end
        end
        coroutine.yield()
    end
end

function Server:protocol(connection)
    local peername = connection:getpeername()
    local message = connection:receive()
    if message:find("add:<>") then
        self.newsManager:addNews(message:match("[^add:<>]+[%S, %d]+"))
    elseif message:find("consensus:<>") then
        self.consensusManager:stage(message)
    end
end

function Server:execute()
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
    table.insert(self.threads, coroutine.create(connection_loop))
    table.insert(self.threads, coroutine.create(function() while true do self:verifyNews(); coroutine.yield() end end))

    for count = 1, 50 do
        for index = 1, #self.threads do
            coroutine.resume(self.threads[index])
        end
    end
end

return Server
