-- can be improved by splitting the string and getting args

local commandList = { "list", "restart", "exit" }
local channel = love.thread.getChannel("command")
while true do
	local input = io.read()

	if input == "help" then
		print("[*] List of commands:")
		print("  - help: show list of commands")
		print("  - list: show list of connected players")
		print("  - restart: restart server")
		print("  - exit: closes the server")
	end

	for id, command in pairs(commandList) do
		if input == command then
			channel:push(id)
			break
		end
	end
	if input == "restart" or input == "exit" then
		break
	end
end
