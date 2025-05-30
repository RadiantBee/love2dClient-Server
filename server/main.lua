local function isUnique(t, ip, port)
	for _, element in pairs(t) do
		if element.ip == ip and element.port == port then
			return false
		end
	end
	return true
end

local function split(s, delimiter)
	local result = {}
	for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

--[[
[~] - process started
[*] - something happened/info
[+] - process complete successfully
[-] - process completion failed
[!] - Error/something important
--]]

--[[
*type*|*related data*
Data bandle types:

handshake:
<- h|nickname|color
Response to client:
-> h|nickname1|color1 (and the same for every user)
Response to other clients:
-> h|nickname|color

(for current usecase) game update:
<- g|userID|gameData

For Immediate Broadcasting:
 Update all other players:
 -> g|userID|gameData
For bundled tick-based update:
 *Every player will recieve the same gamestate update*

Quitting the server:
<- q|userID
-> q|userID
--]]

local socket = require("socket")

local udp
local port = 12345

local thread = love.thread.newThread("consoleInput.lua")
local channel = love.thread.getChannel("command")

local players = {}
local data, senderIp, senderPort
local parcedData
local commandID

--local time = 0
--local updateRate = 0.01

function love.load()
	print("[~] Launching server")
	print("[~] Setting up UPD socket for *:" .. port)
	udp = socket.udp()
	udp:setsockname("*", port)
	udp:settimeout(0)
	print("[+] UDP socket is ready!")
	thread:start()
	print("[+] Thread active!")
	print("[+] Initialisation complete!")
end

function love.update(dt)
	-- Woking with the CLI thread
	commandID = channel:pop()

	if commandID then
		if commandID == 1 then
			if #players == 0 then
				print("[*] There are no player connected to the server!")
			else
				print("[*] Player list:")
				for id, player in pairs(players) do
					print("[" .. id .. "] " .. player.nickname .. ":")
					print("  - ip: " .. player.ip)
					print("  - port: " .. player.port)
				end
			end
		end
		if commandID == 2 then
			print("[~] Restarting...")
			love.event.quit("restart")
		end
		if commandID == 3 then
			print("[~] Quitting...")
			love.event.quit(0)
		end
	end

	-- Getting data
	data, senderIp, senderPort = udp:receivefrom()
	if data then -- if server recieves data
		parcedData = split(data, "|")
		-- Processing handshake
		if parcedData[1] == "h" and isUnique(players, senderIp, senderPort) then
			data = "h"
			for id, player in ipairs(players) do
				-- collecting data from every connected player to get new user up to date
				data = data
					.. "|"
					.. player.nickname
					.. "|"
					.. player.colorR
					.. "|"
					.. player.colorG
					.. "|"
					.. player.colorB
				-- sending every player data about our new user
				udp:sendto(
					"h|" .. parcedData[2] .. "|" .. parcedData[3] .. "|" .. parcedData[4] .. "|" .. parcedData[5],
					player.ip,
					player.port
				)
			end
			table.insert(players, {})
			players[#players].ip = senderIp
			players[#players].port = senderPort
			players[#players].nickname = parcedData[2]
			players[#players].colorR = parcedData[3]
			players[#players].colorG = parcedData[4]
			players[#players].colorB = parcedData[5]
			players[#players].state = 1
			players[#players].x = 0
			players[#players].y = 0
			print("[*] " .. players[#players].nickname .. "#" .. #players .. " joined:")
			print("  - ip: " .. players[#players].ip)
			print("  - port: " .. players[#players].port)
			udp:sendto(data, senderIp, senderPort)
		-- Processing client data
		elseif parcedData[1] == "g" then
			if tonumber(parcedData[2]) <= #players then
				players[tonumber(parcedData[2])].x = parcedData[3]
				players[tonumber(parcedData[2])].y = parcedData[4]
				players[tonumber(parcedData[2])].state = parcedData[5]
			end
			-- Updating every other player
			for id, player in ipairs(players) do
				if id ~= tonumber(parcedData[2]) then
					udp:sendto(data, player.ip, player.port)
				end
			end
		elseif parcedData[1] == "q" then
			print("[*] Player #" .. parcedData[2] .. " " .. players[tonumber(parcedData[2])].nickname .. " has left!")
			table.remove(players, tonumber(parcedData[2]))
			for _, player in ipairs(players) do
				udp:sendto(data, player.ip, player.port)
			end
		end
	end

	--[[
	-- Gamestate update for every user
	time = time + dt
	if time > updateRate then
		-- Collecting datapack
		data = "g"
		for _, player in ipairs(players) do
			data = data .. "|" .. player.x .. "|" .. player.y
		end
		for _, player in ipairs(players) do
			udp:sendto(data, player.ip, player.port)
		end
		time = time - updateRate
	end
	--]]
end
