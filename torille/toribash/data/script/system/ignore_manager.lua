-- Chat ignore manager

MESSAGE_SYSTEM = 1
MESSAGE_ECHO = 4
MESSAGE_ROOM = 8
MESSAGE_PLAYER = 16

local chatcensor = get_option("chatcensor")
TB_MENU_CHAT_IGNORE_SETTINGS = { hideecho = chatcensor > 1, wordfilter = (chatcensor % 2 == 1) }

do
	ChatIgnore = {}
	ChatIgnore.__index = ChatIgnore
	local cln = {}
	setmetatable(cln, ChatIgnore)
	
	function ChatIgnore:bannedWords()
		return {
			"[Nn]+[1Ii]+[Gg]+[3EeAa]+[Rr]*[Ss]*",
			"[Ff]+[Uu]+[Cc]+[Kk]+[3Ee]*[Rr]*[Ss]*",
			"[Ff]+[Aa]+[Gg]+[0OoTt]*[Ss]*",
			"[Cc]+[Uu]+[Nn]+[Tt]+[Ss]*",
		}
	end
	
	function ChatIgnore:checkLine(line, msgType)
		local randomCut = math.random(1, string.len("!@#$^&*"))
		local grawlix = string.sub("!@#$^&*", randomCut) .. string.sub("!@#$^&*", 0, randomCut - 1)
		if (msgType == MESSAGE_ECHO and TB_MENU_CHAT_IGNORE_SETTINGS.hideecho) then
			return true
		end
		if (msgType >= MESSAGE_ROOM and TB_MENU_CHAT_IGNORE_SETTINGS.wordfilter) then
			local replaced = false
			local nameStart, nameEnd = line:find('%b<>')
			for i, word in pairs(ChatIgnore:bannedWords()) do
				local wStart, wEnd = line:find(word, nameEnd)
				if (wStart) then
					line = line:sub(nameStart, nameEnd) .. line:sub(nameEnd + 1):gsub(word, grawlix:sub(1, wEnd - wStart + 1))
					replaced = true
				end
			end
			if (replaced) then
				if (msgType == MESSAGE_PLAYER) then
					echo("^02" .. TB_MENU_LOCALIZED.CHATCENSOREDMESSAGE)
				end
				echo(line)
				return true
			end
		end
	end
	
	function ChatIgnore:activate()
		CHATIGNORE_ACTIVE = true
		add_hook("console", "tbMenuChatCensorIgnore", function(s, i)
				if (ChatIgnore:checkLine(s, i)) then
					return 1
				end
			end)
	end
	
	function ChatIgnore:deactivate()
		CHATIGNORE_ACTIVE = false
		remove_hooks("tbMenuChatCensorIgnore")
	end
end
