local function split(s, delimiter)
	local result = {}
	for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

local function getConfigData(filename)
	local output = {}
	print("\n[~] Openning " .. filename .. " file...")
	local configFile = io.open(filename, "r")
	if configFile == nil then
		print("[-] Error: Cannot acces " .. filename .. "!")
		print("[*] Using localhost:12345 instead")
		return "localhost", 12345
	end
	print("[+] " .. filename .. " file accessed successfully")
	print("\n[~] Reading " .. filename .. "...")
	for line in configFile:lines("l") do
		output[#output + 1] = line
		print("[*] Option loaded: " .. line)
	end
	print("[+] " .. filename .. " file closed")
	configFile:close()
	return output
end

local socket
local udp

local players = {}
local playerID

local updatetime = 0.01
local t = 0
local data
local msg
local cursorStates

function love.load()
	socket = require("socket")

	local configData = getConfigData("config.txt")

	local address = configData[1]
	local port = configData[2]
	local name = configData[3] or "noNameRead"
	local color = { configData[4] or 1, configData[5] or 1, configData[6] or 1 }

	print("[~] Setting up UDP connection to " .. address .. ":" .. port)

	udp = socket.udp()
	udp:setpeername(address, port)
	udp:settimeout(0)
	print("[+] Client ready!")
	print("[~] Connecting to the server...")

	while true do
		udp:send("h|" .. name .. "|" .. color[1] .. "|" .. color[2] .. "|" .. color[3])
		data = split(udp:receive() or "", "|")
		if data[1] == "h" then
			print("[+] Handshake recieved!")
			-- Parsing data about every player on the server
			for i = 2, #data, 4 do
				table.insert(players, {})
				players[#players].nickname = data[i]
				players[#players].colorR = data[i + 1]
				players[#players].colorG = data[i + 2]
				players[#players].colorB = data[i + 3]
				players[#players].state = 1
				players[#players].x = 0
				players[#players].y = 0
			end
			table.insert(players, {})
			players[#players].nickname = name
			players[#players].colorR = color[1]
			players[#players].colorG = color[2]
			players[#players].colorB = color[3]
			players[#players].state = 1
			players[#players].x = 0
			players[#players].y = 0

			playerID = #players
			break
		end
	end

	print("[+] Connected!")
	cursorStates = {
		love.graphics.newImage("img/cursor.png"),
		love.graphics.newImage("img/cursorClick.png"),
	}

	love.mouse.setVisible(false)

	print("[+] Initialisation complete!")
end

function love.mousepressed()
	players[playerID].state = 2
end

function love.mousereleased()
	players[playerID].state = 1
end

function love.quit()
	if playerID then
		udp:send("q|" .. playerID)
		print("Exit sent, goodbye!")
	end
end

function love.update(dt)
	t = t + dt

	players[playerID].x, players[playerID].y = love.mouse.getPosition()
	if t > updatetime then
		udp:send(
			"g|"
				.. tostring(playerID)
				.. "|"
				.. tostring(players[playerID].x)
				.. "|"
				.. tostring(players[playerID].y .. "|" .. players[playerID].state)
		)
		t = t - updatetime
	end

	repeat
		data, msg = udp:receive()
		if data then
			data = split(data, "|")
			if data[1] == "g" then
				if tonumber(data[2]) <= #players then
					players[tonumber(data[2])].x = tonumber(data[3])
					players[tonumber(data[2])].y = tonumber(data[4])
					players[tonumber(data[2])].state = tonumber(data[5])
				end
				--[[
				for id, player in ipairs(players) do
					player.x = data[1 + id]
					player.y = data[2 + id]
				end
				--]]
			elseif data[1] == "h" then
				table.insert(players, {})
				players[#players].nickname = data[2]
				players[#players].colorR = data[3]
				players[#players].colorG = data[4]
				players[#players].colorB = data[5]
				players[#players].state = 1
				players[#players].x = 0
				players[#players].y = 0
			elseif data[1] == "q" then
				print("[*] Player #" .. data[2] .. " " .. players[tonumber(data[2])].nickname .. " has left!")
				table.remove(players, tonumber(data[2]))
				if playerID > tonumber(data[2]) then
					playerID = playerID - 1
				end
			end
		end
		if msg and msg ~= "timeout" then
			error("[!] Network error: " .. tostring(msg))
		end
	until not data
end

function love.draw()
	for id, player in ipairs(players) do
		love.graphics.draw(cursorStates[player.state], player.x, player.y)
		love.graphics.setColor(player.colorR, player.colorG, player.colorB)
		love.graphics.circle("fill", player.x + 17, player.y + 16, 5)
		love.graphics.print(player.nickname, player.x, player.y + 20)
		love.graphics.setColor(1, 1, 1)
	end
end
