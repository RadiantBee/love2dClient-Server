local function split(s, delimiter)
	local result = {}
	for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

local function getConfigData()
	print("Getting settings data")
	local output = {}
	local configFile = io.open("settings.txt", "r")
	if configFile == nil then
		return "localhost", 12345, testName
	end
	for line in configFile:lines("l") do
		output[#output + 1] = line
	end
	configFile:close()
	return output[1], output[2], output[3]
end

local game = {}

local socket
local udp
local address
local port

local player = {}
local secondPlayerCursor

local updatetime
local t
local data
local msg

function game:load()
	socket = require("socket")

	address, port, player.name = getConfigData()

	udp = socket.udp()
	udp:setpeername(address, port)
	udp:settimeout(0)
	print("Client ready!")
	print("Connecting to the server at " .. address .. ":" .. port)

	while true do
		udp:send("1")
		data = udp:receive()
		if data == "1" then
			print("Handshake recieved!")
			break
		end
	end
	print("Connected!")
	secondPlayerCursor = {}
	secondPlayerCursor.states = {
		love.graphics.newImage("img/secondPlayerCursor.png"),
		love.graphics.newImage("img/secondPlayerCursorClick.png"),
	}
	secondPlayerCursor.state = 1
	secondPlayerCursor.x = -100
	secondPlayerCursor.y = -100

	player = {}
	player.states =
		{ love.mouse.newCursor("img/myCursor.png", 2, 2), love.mouse.newCursor("img/myCursorClick.png", 2, 2) }
	player.state = 1
	player.x = -25
	player.y = -25

	love.mouse.setCursor(player.states[player.state])
	print("Initialisation complete!")

	updatetime = 0.01
	t = 0
end

function game:mousepressed()
	player.state = 2
	love.mouse.setCursor(player.states[player.state])
end

function game:mousereleased()
	player.state = 1
	love.mouse.setCursor(player.states[player.state])
end

function game:update(dt)
	t = t + dt

	if t > updatetime then
		player.x, player.y = love.mouse.getPosition()
		udp:send(tostring(player.x) .. "|" .. tostring(player.y) .. "|" .. tostring(player.state))
		t = t - updatetime
	end

	repeat
		data, msg = udp:receive()
		if data then
			local p = split(data, "|")
			if #p == 3 then
				secondPlayerCursor.x, secondPlayerCursor.y, secondPlayerCursor.state =
					tonumber(p[1]), tonumber(p[2]), tonumber(p[3])
			end
		end
		if msg and msg ~= "timeout" then
			error("Network error: " .. tostring(msg))
		end
	until not data
end

function game:draw()
	if secondPlayerCursor.x ~= nil and secondPlayerCursor.y ~= nil then
		love.graphics.draw(
			secondPlayerCursor.states[secondPlayerCursor.state],
			secondPlayerCursor.x,
			secondPlayerCursor.y
		)
	end
end
