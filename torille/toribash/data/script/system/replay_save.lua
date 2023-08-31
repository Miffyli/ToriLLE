dofile("toriui/uielement.lua")
dofile("system/menu_manager.lua")

rploptions = { hint = get_option("hint"), feedback = get_option("feedback") }
local REPLAY_NEWGAME = false

for i,v in pairs(rploptions) do
	set_option(i, 0)
end

local function quitReplaySave()
	remove_hooks("replaySaveHandler")
	for i,v in pairs(rploptions) do
		set_option(i, v)
	end
	replaySave:kill()
end

replaySave = UIElement:new({
	globalid = TB_MENU_HUB_GLOBALID,
	pos = { WIN_W / 4, WIN_H / 2 - 90 },
	size = { WIN_W / 2, 180 },
	bgColor = TB_MENU_DEFAULT_BG_COLOR
})
UIElement:runCmd("savereplay " .. REPLAY_SAVETEMPNAME)

local replaySaveTitle = UIElement:new({
	parent = replaySave,
	pos = { 10, 0 },
	size = { replaySave.size.w - 20, 50 }
})
replaySaveTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSSAVING, nil, nil, FONTS.BIG, nil, 0.65)
local replaySaveInfo = UIElement:new({
	parent = replaySave,
	pos = { 10, replaySaveTitle.shift.y + replaySaveTitle.size.h },
	size = { replaySave.size.w - 20, 20 }
})
replaySaveInfo:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSDEFAULTPATH, nil, nil, 4, nil, 0.6)
local replaySaveButton = UIElement:new({
	parent = replaySave,
	pos = { replaySave.size.w / 2 + 5, -50 },
	size = { replaySave.size.w / 2 - 15, 40 },
	interactive = true,
	bgColor = { 0, 0, 0, 0.1 },
	hoverColor = { 0, 0, 0, 0.3 },
	pressedColor = { 1, 1, 1, 0.2 }
})
replaySaveButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSAVE)

local replayCancelButton = UIElement:new({
	parent = replaySave,
	pos = { 10, -50 },
	size = { replaySave.size.w / 2 - 15, 40 },
	interactive = true,
	bgColor = { 0, 0, 0, 0.1 },
	hoverColor = { 0, 0, 0, 0.3 },
	pressedColor = { 1, 1, 1, 0.2 }
})
replayCancelButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
replayCancelButton:addMouseHandlers(nil, function()
		quitReplaySave()
	end)
local replayNameBackground = UIElement:new({
	parent = replaySave,
	pos = { 10, replaySaveInfo.shift.y + replaySaveInfo.size.h + 10 },
	size = { replaySave.size.w - 20, 40 },
	bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
})
local replayNameOverlay = UIElement:new({
	parent = replayNameBackground,
	pos = { 1, 1 },
	size = { replayNameBackground.size.w - 2, replayNameBackground.size.h - 2 },
	bgColor = { 1, 1, 1, 0.6 }
})
local replayNameInput = UIElement:new({
	parent = replayNameOverlay,
	pos = { 10, 0 },
	size = { replayNameOverlay.size.w - 20, replayNameOverlay.size.h },
	interactive = true,
	textfield = true,
	textfieldsingleline = true
})
TBMenu:displayTextfield(replayNameInput, FONTS.SMALL, 1, UICOLORBLACK, TB_MENU_LOCALIZED.REPLAYSENTERNAME, CENTERMID)

local function saveReplay(newname)
	if (newname == "" or not newname) then
		TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERROREMPTYNAME, true)
		return
	end
	if (newname:find("[^%d%a-_ ]") or not newname:find("[%a%d]")) then
		TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORCHARACTERS, true)
		return
	end
	if (REPLAY_NEWGAME) then
		local error = rename_replay("my replays/" .. REPLAY_SAVETEMPNAME .. ".rpl", "my replays/" .. newname .. ".rpl")
		if (error) then
			TBMenu:showDataError(error, true)
			return
		end
		local rplFile = Files:new("../replay/my replays/" .. newname .. ".rpl")
		if (not rplFile.data) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORRENAMING, true)
			quitReplaySave(3)
			return
		end
		
		local fileData = rplFile:readAll()
		rplFile.mode = FILES_MODE_WRITE
		rplFile:reopen()
		for i,ln in pairs(fileData) do
			if (ln:find("^FIGHTNAME %d;")) then
				rplFile:writeLine("FIGHTNAME 0; " .. newname)
			else
				rplFile:writeLine(ln)
			end
		end
		rplFile:close()
	else
		UIElement:runCmd("savereplay " .. newname)
	end
	quitReplaySave()
end

replayNameInput:addEnterAction(function() saveReplay(replayNameInput.textfieldstr[1]:gsub("%.rpl$", "")) end)
replaySaveButton:addMouseHandlers(nil, function()
		saveReplay(replayNameInput.textfieldstr[1]:gsub("%.rpl$", ""))
	end)

add_hook("mouse_button_down", "replaySaveHandler", function(s, x, y)
	if (TB_MENU_MAIN_ISOPEN == 0) then
		UIElement:handleMouseDn(s, x, y)
		return 1
	end
end)
add_hook("mouse_button_up", "replaySaveHandler", function(s, x, y)
	if (TB_MENU_MAIN_ISOPEN == 0) then
		UIElement:handleMouseUp(s, x, y)
		return 1
	end
end)
add_hook("mouse_move", "replaySaveHandler", function(x, y)
	if (TB_MENU_MAIN_ISOPEN == 0) then
		UIElement:handleMouseHover(x, y)
	end
end)
add_hook("key_up", "replaySaveHandler", function(s) UIElement:handleKeyUp(s) return 1 end)
add_hook("key_down", "replaySaveHandler", function(s) UIElement:handleKeyDown(s) return 1 end)
add_hook("new_game_mp", "replaySaveHandler", function() REPLAY_NEWGAME = true end)
