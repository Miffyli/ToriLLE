-- Movememory 2.0 manager
-- DO NOT MODIFY THIS FILE

MOVEMEMORY_PLAYBACK_ACTIVE = MOVEMEMORY_PLAYBACK_ACTIVE or {}
MOVEMEMORYPOS = MOVEMEMORYPOS or { x = 60, y = 100 }

do
	MoveMemory = {}
	MoveMemory.__index = MoveMemory
	local cln = {}
	setmetatable(cln, MoveMemory)
	
	function MoveMemory:quit()
		TB_MOVEMEMORY_ISOPEN = 0
		moveMemoryMain:kill()
	end
	
	function MoveMemory:getOpeners()
		local file = Files:new("system/data.mm")
		if (not file.data) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.MOVEMEMORYLOADERROR, true)
			return false
		end
		MOVEMEMORY_DATA = {}
		for i, line in pairs(file:readAll()) do
			local line = line:gsub("[\n]?$", "")
			if (line:find("^NAME")) then
				MOVEMEMORY_DATA[#MOVEMEMORY_DATA + 1] = { id = #MOVEMEMORY_DATA + 1 }
				MOVEMEMORY_DATA[#MOVEMEMORY_DATA].name = line:gsub("^NAME ", "")
			elseif (#MOVEMEMORY_DATA > 0) then
				if (line:find("^DESC")) then
					MOVEMEMORY_DATA[#MOVEMEMORY_DATA].desc = line:gsub("^DESC ", "")
				elseif (line:find("^MOD")) then
					MOVEMEMORY_DATA[#MOVEMEMORY_DATA].mod = line:gsub("^MOD ", ""):gsub("%.tbm$", "")
				elseif (line:find("^TURN")) then
					if (not MOVEMEMORY_DATA[#MOVEMEMORY_DATA].movements) then
						MOVEMEMORY_DATA[#MOVEMEMORY_DATA].movements = {}
					end
					line = line:gsub("^TURN ", "")
					local min, max = line:find("^%d+;")
					local turn = line:sub(min, max - 1) + 0
					MOVEMEMORY_DATA[#MOVEMEMORY_DATA].movements[turn] = {}
					if (not MOVEMEMORY_DATA[#MOVEMEMORY_DATA].turns) then
						MOVEMEMORY_DATA[#MOVEMEMORY_DATA].turns = turn
					elseif (MOVEMEMORY_DATA[#MOVEMEMORY_DATA].turns < turn) then
						MOVEMEMORY_DATA[#MOVEMEMORY_DATA].turns = turn
					end
					
					line = line:gsub("^%d+; ", "")
					local _, count = line:gsub("%d+", "")
					local data_stream = { line:match(("(%d+ %d+) *"):rep(count / 2)) }
					for i,v in pairs(data_stream) do
						local info = { v:match(("(%d+) *"):rep(2)) }
						MOVEMEMORY_DATA[#MOVEMEMORY_DATA].movements[turn][info[1] + 0] = info[2] + 0
					end
				end
			end
		end
		file:close()
		return true
	end
	
	function MoveMemory:isMoveStored(memorymove)
		local file = Files:new("system/data.mm")
		if (not file.data) then
			return false
		end
		for i, ln in pairs(file:readAll()) do
			if (ln:find("^NAME " .. memorymove.name)) then
				return true
			end
		end
		return false
	end
	
	function MoveMemory:saveMove(memorymove)
		if (memorymove.name:len() == 0) then
			return
		end
		local file = Files:new("system/data.mm", FILES_MODE_APPEND)
		if (not file.data) then
			return
		end
		file:writeLine("")
		file:writeLine("NAME " .. memorymove.name)
		if (memorymove.desc) then
			file:writeLine("DESC " .. memorymove.desc)
		end
		if (memorymove.mod) then
			file:writeLine("MOD " .. memorymove.mod)
		end
		for i, turn in pairs(memorymove.movements) do
			local line = "TURN " .. i .. "; "
			for joint, state in pairs(turn) do
				line = line .. joint .. " " .. state .. " "
			end
			file:writeLine(line)
		end
		file:close()
	end
	
	function MoveMemory:showSaveRecordingComplete(successAction, discard)
		local overlay = TBMenu:spawnWindowOverlay()
		local options = { hint = get_option("hint"), feedback = get_option("feedback") }
		local function quitMoveSave()
			remove_hooks("moveSaveKeyboardHandler")
			remove_hooks("moveSaveMouseHandler")
			for i,v in pairs(options) do
				set_option(i, v)
			end
			overlay:kill()
		end
		for i,v in pairs(options) do
			set_option(i, 0)
		end		
		
		local moveSave = UIElement:new({
			parent = overlay,
			pos = { WIN_W / 4, WIN_H / 2 - 140 },
			size = { WIN_W / 2, 280 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		
		local moveSaveTitle = UIElement:new({
			parent = moveSave,
			pos = { 10, 0 },
			size = { moveSave.size.w - 20, 50 }
		})
		moveSaveTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYSAVING, nil, nil, FONTS.BIG, nil, 0.65)
		local moveSaveButton = UIElement:new({
			parent = moveSave,
			pos = { moveSave.size.w / 2 + 5, -50 },
			size = { moveSave.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		moveSaveButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSAVE)
		
		local moveCancelButton = UIElement:new({
			parent = moveSave,
			pos = { 10, -50 },
			size = { moveSave.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		moveCancelButton:addAdaptedText(false, discard and TB_MENU_LOCALIZED.BUTTONDISCARD or TB_MENU_LOCALIZED.BUTTONCANCEL)
		moveCancelButton:addMouseHandlers(nil, function()
				quitMoveSave()
				if (discard) then
					successAction()
				end
			end)
		local moveNameBackground = UIElement:new({
			parent = moveSave,
			pos = { 10, moveSaveTitle.shift.y + moveSaveTitle.size.h + 10 },
			size = { moveSave.size.w - 20, 40 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local moveNameOverlay = UIElement:new({
			parent = moveNameBackground,
			pos = { 1, 1 },
			size = { moveNameBackground.size.w - 2, moveNameBackground.size.h - 2 },
			bgColor = { 1, 1, 1, 0.6 }
		})
		local moveNameInput = UIElement:new({
			parent = moveNameOverlay,
			pos = { 10, 0 },
			size = { moveNameOverlay.size.w - 20, moveNameOverlay.size.h },
			interactive = true,
			textfield = true,
			textfieldsingleline = true
		})
		TBMenu:displayTextfield(moveNameInput, FONTS.SMALL, 1, UICOLORBLACK, TB_MENU_LOCALIZED.MOVEMEMORYENTERMOVENAME, CENTERMID)
		moveNameInput:addMouseHandlers(nil, function() TBMenu:enableMenuKeyboard(moveNameInput) end)
			
		local moveDescBackground = UIElement:new({
			parent = moveSave,
			pos = { 10, moveNameBackground.shift.y + moveNameBackground.size.h + 10 },
			size = { moveSave.size.w - 20, 40 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local moveDescOverlay = UIElement:new({
			parent = moveDescBackground,
			pos = { 1, 1 },
			size = { moveDescBackground.size.w - 2, moveDescBackground.size.h - 2 },
			bgColor = { 1, 1, 1, 0.6 }
		})
		local moveDescInput = UIElement:new({
			parent = moveDescOverlay,
			pos = { 10, 0 },
			size = { moveDescOverlay.size.w - 20, moveDescOverlay.size.h },
			interactive = true,
			textfield = true,
			textfieldsingleline = true
		})
		TBMenu:displayTextfield(moveDescInput, FONTS.SMALL, 1, UICOLORBLACK, TB_MENU_LOCALIZED.MOVEMEMORYENTERMOVEDESCOPT, CENTERMID)
		moveDescInput:addMouseHandlers(nil, function() TBMenu:enableMenuKeyboard(moveDescInput) end)
			
		local moveModBackground = UIElement:new({
			parent = moveSave,
			pos = { 10, moveDescBackground.shift.y + moveDescBackground.size.h + 10 },
			size = { moveSave.size.w - 20, 40 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local moveModOverlay = UIElement:new({
			parent = moveModBackground,
			pos = { 1, 1 },
			size = { moveModBackground.size.w - 2, moveModBackground.size.h - 2 },
			bgColor = { 1, 1, 1, 0.6 }
		})
		local moveModInput = UIElement:new({
			parent = moveModOverlay,
			pos = { 10, 0 },
			size = { moveModOverlay.size.w - 20, moveModOverlay.size.h },
			interactive = true,
			textfield = true,
			textfieldsingleline = true,
			textfieldstr = { get_game_rules().mod:gsub("%.tbm$", "") }
		})
		TBMenu:displayTextfield(moveModInput, FONTS.SMALL, 1, UICOLORBLACK, TB_MENU_LOCALIZED.MOVEMEMORYENTERMODNAMEOPT, CENTERMID)
		moveModInput:addMouseHandlers(nil, function() TBMenu:enableMenuKeyboard(moveModInput) end)
		
		local function saveMove(name, description, mod)
			if (name:len() == 0) then
				TBMenu:showDataError(TB_MENU_LOCALIZED.MOVEMEMORYMODNAMEEMPTYERROR, true)
				return
			end
			local file = Files:new("system/data.mm", FILES_MODE_APPEND)
			if (not file.data) then
				TBMenu:showDataError(LOCALIZED.MOVEMEMORYMOVESAVEERRORPERMS, true)
				return
			end
			file:writeLine("")
			file:writeLine("NAME " .. name)
			if (description:len() > 0) then
				file:writeLine("DESC " .. description)
			end
			if (mod:len() > 0) then
				file:writeLine("MOD " .. mod)
			end
			for i,v in pairs(MOVEMEMORY_MOVE_RECORD) do
				local line = "TURN " .. i .. "; "
				for j, k in pairs(v) do
					line = line .. k.joint .. " " .. k.state .. " "
				end
				file:writeLine(line)
			end
			file:close()
			quitMoveSave()
			successAction()
			MoveMemory:reload()
		end
		
		moveSaveButton:addMouseHandlers(nil, function() saveMove(moveNameInput.textfieldstr[1], moveDescInput.textfieldstr[1], moveModInput.textfieldstr[1]) end)
			
		add_hook("mouse_button_down", "moveSaveMouseHandler", function(s, x, y)
			if (TB_MENU_MAIN_ISOPEN == 0) then
				UIElement:handleMouseDn(s, x, y)
				return 1
			end
		end)
		add_hook("mouse_button_up", "moveSaveMouseHandler", function(s, x, y)
			if (TB_MENU_MAIN_ISOPEN == 0) then
				UIElement:handleMouseUp(s, x, y)
				return 1
			end
		end)
		add_hook("mouse_move", "moveSaveMouseHandler", function(x, y)
			if (TB_MENU_MAIN_ISOPEN == 0) then
				UIElement:handleMouseHover(x, y)
				return 1
			end
		end)
		add_hook("key_up", "moveSaveKeyboardHandler", function(s) UIElement:handleKeyUp(s) return 1 end)
		add_hook("key_down", "moveSaveKeyboardHandler", function(s) UIElement:handleKeyDown(s) return 1 end)
	end
	
	function MoveMemory:recordMove()
		local ws = get_world_state()
		local player = ws.selected_player
		if (player < 0) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.MOVEMEMORYERRORNOTINGAME, true)
			return false
		end
		if (MOVEMEMORY_PLAYBACK_ACTIVE[player]) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.MOVEMEMORYERRORSTOPMOVE, true)
			return false
		end
		local turn = ws.match_turn + 1
		MOVEMEMORY_MOVE_RECORD = {}
		
		local function cancelRecording()
			remove_hooks("tbMoveMemoryRecordMove")
			moveMemoryToolbar[0]:kill()
			moveMemoryToolbar[0] = nil
		end
		local function saveRecording(exitAction, discard)
			MoveMemory:showSaveRecordingComplete(exitAction, discard)
		end
		MoveMemory:showToolbar(player, TB_MENU_LOCALIZED.MOVEMEMORYRECORDINGMOVE .. " #" .. turn .. " (" .. #MOVEMEMORY_MOVE_RECORD .. " " .. TB_MENU_LOCALIZED.WORDTOTAL .. ")", cancelRecording, saveRecording)
		add_hook("exit_freeze", "tbMoveMemoryRecordMove", function()
				MOVEMEMORY_MOVE_RECORD[#MOVEMEMORY_MOVE_RECORD + 1] = {}
				for i,v in pairs(JOINTS) do
					table.insert(MOVEMEMORY_MOVE_RECORD[#MOVEMEMORY_MOVE_RECORD], { joint = v, state = get_joint_info(player, v).state })
				end
				table.insert(MOVEMEMORY_MOVE_RECORD[#MOVEMEMORY_MOVE_RECORD], { joint = 20, state = get_grip_info(player, 11) })
				table.insert(MOVEMEMORY_MOVE_RECORD[#MOVEMEMORY_MOVE_RECORD], { joint = 21, state = get_grip_info(player, 12) })
				MoveMemory:showToolbar(player, TB_MENU_LOCALIZED.MOVEMEMORYRECORDINGMOVE .. " #" .. get_world_state().match_turn + 2 .. " (" .. #MOVEMEMORY_MOVE_RECORD .. " " .. TB_MENU_LOCALIZED.WORDTOTAL .. ")", cancelRecording, saveRecording)
			end)
		add_hook("leave_game", "tbMoveMemoryRecordMove", function() if (not ESC_KEY_PRESSED) then if (#MOVEMEMORY_MOVE_RECORD > 0) then saveRecording(cancelRecording, true) else cancelRecording() end end end)
	end
	
	function MoveMemory:deleteMove(memorymove)
		local file = Files:new("system/data.mm")
		if (not file.data) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.MOVEMEMORYLOADERROR, true)
			return false
		end
		local moveid = 0
		local deleted = -1
		local towrite = {}
		for i, ln in pairs(file:readAll()) do
			if (ln:find("^NAME")) then
				moveid = moveid + 1
				local name = ln:gsub("^NAME ", ""):gsub("[\r\n]?$", "")
				if (moveid == memorymove.id and name == memorymove.name) then
					deleted = 0
				else
					deleted = 1
					table.insert(towrite, ln)
				end
			elseif (deleted ~= 0) then
				table.insert(towrite, ln)
			end
		end
		
		file:reopen(FILES_MODE_WRITE)
		if (not file.data) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.MOVEMEMORYERRORUPDATINGDATA, true)
			return false
		end
		for i,v in pairs(towrite) do
			file:writeLine(v)
		end
		file:close()
	end
	
	function MoveMemory:reload()
		if (TB_MOVEMEMORY_ISOPEN == 1) then
			MoveMemory:quit()
		end
		MoveMemory:showMain()
	end
	
	function MoveMemory:showMain()
		if (not MoveMemory:getOpeners()) then
			return
		end
		TB_MOVEMEMORY_ISOPEN = 1
		
		moveMemoryMain = UIElement:new({
			globalid = TB_MOVEMEMORY_GLOBALID,
			pos = { 0, 0 },
			size = { 250, WIN_H / 3 * 2 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
			shapeType = ROUNDED,
			rounded = 4,
			uiColor = { 0, 0, 0, 1 }
		})
		moveMemoryMain.pos = MOVEMEMORYPOS
		local moveMemoryMoverHolder = UIElement:new({
			parent = moveMemoryMain,
			pos = { 0, 0 },
			size = { moveMemoryMain.size.w, 20 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = moveMemoryMain.shapeType,
			rounded = moveMemoryMain.rounded
		})
		moveMemoryMoverHolder:addCustomDisplay(true, function()
				set_color(unpack(moveMemoryMoverHolder.bgColor))
				draw_disk(moveMemoryMoverHolder.pos.x + moveMemoryMoverHolder.rounded, moveMemoryMoverHolder.pos.y + moveMemoryMoverHolder.rounded, 0, moveMemoryMoverHolder.rounded, 100, 1, -180, 90, 0)
				draw_disk(moveMemoryMoverHolder.pos.x + moveMemoryMoverHolder.size.w - moveMemoryMoverHolder.rounded, moveMemoryMoverHolder.pos.y + moveMemoryMoverHolder.rounded, 0, moveMemoryMoverHolder.rounded, 100, 1, 90, 90, 0)
				draw_quad(moveMemoryMoverHolder.pos.x + moveMemoryMoverHolder.rounded, moveMemoryMoverHolder.pos.y, moveMemoryMoverHolder.size.w - moveMemoryMoverHolder.rounded * 2, moveMemoryMoverHolder.rounded)
				draw_quad(moveMemoryMoverHolder.pos.x, moveMemoryMoverHolder.pos.y + moveMemoryMoverHolder.rounded, moveMemoryMoverHolder.size.w, moveMemoryMoverHolder.size.h - moveMemoryMoverHolder.rounded)
			end)
		local moveMemoryMover = UIElement:new({
			parent = moveMemoryMoverHolder,
			pos = { 0, 0 },
			size = { moveMemoryMoverHolder.size.w, moveMemoryMoverHolder.size.h },
			interactive = true,
			bgColor = UICOLORWHITE,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		moveMemoryMover:addCustomDisplay(true, function()
				set_color(unpack(moveMemoryMover:getButtonColor()))
				local posX = moveMemoryMover.pos.x + moveMemoryMover.size.w / 2 - 15
				draw_quad(posX, moveMemoryMover.pos.y + 5, 30, 2)
				draw_quad(posX, moveMemoryMover.pos.y + 13, 30, 2)
			end)
		if (not MOVEMEMORY_TUTORIAL_MODE) then
			moveMemoryMover:addMouseHandlers(function(s, x, y)
						moveMemoryMover.pressedPos.x = x - moveMemoryMover.pos.x
						moveMemoryMover.pressedPos.y = y - moveMemoryMover.pos.y
					end, nil, function(x, y)
					if (moveMemoryMover.hoverState == BTN_DN) then
						local x = x - moveMemoryMover.pressedPos.x
						local y = y - moveMemoryMover.pressedPos.y
						x = x < 0 and 0 or (x + moveMemoryMain.size.w > WIN_W and WIN_W - moveMemoryMain.size.w or x)
						y = y < 0 and 0 or (y + moveMemoryMain.size.h > WIN_H and WIN_H - moveMemoryMain.size.h or y)
						moveMemoryMain:moveTo(x, y)
					end
				end)
		end
		local moveMemoryHolder = UIElement:new({
			parent = moveMemoryMain,
			pos = { 0, moveMemoryMoverHolder.size.h },
			size = { moveMemoryMain.size.w, moveMemoryMain.size.h - moveMemoryMoverHolder.size.h - moveMemoryMain.rounded}
		})
		moveMemoryHolder:addCustomDisplay(true, function() end)
			
		local moveMemoryTitle = UIElement:new({
			parent = moveMemoryHolder,
			pos = { 0, 0 },
			size = { moveMemoryHolder.size.w, 40 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			uiColor = UICOLORWHITE
		})
		moveMemoryTitle:addAdaptedText(false, "MOVEMEMORY", -10, nil, nil, nil, nil, nil, 0)
		local moveMemoryAddMove = UIElement:new({
			parent = moveMemoryTitle,
			pos = { -30, 10 },
			size = { 20, 20 },
			interactive = true,
			bgColor = { 1, 1, 1, 0.1 },
			hoverColor = { 1, 1, 1, 0.3 },
			pressedColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		if (not MOVEMEMORY_TUTORIAL_MODE) then
			moveMemoryAddMove:addMouseHandlers(nil, function()
					MoveMemory:recordMove()
				end)
		end
		moveMemoryAddMove:addCustomDisplay(false, function()
				set_color(1, 1, 1, 0.8)
				draw_quad(	moveMemoryAddMove.pos.x + moveMemoryAddMove.size.w / 2 - 1,
							moveMemoryAddMove.pos.y + 4,
							2,
							moveMemoryAddMove.size.h - 8	)
				draw_quad(	moveMemoryAddMove.pos.x + 4,
							moveMemoryAddMove.pos.y + moveMemoryAddMove.size.h / 2 - 1,
							moveMemoryAddMove.size.w - 8,
							2	)
			end)
		
			
		if (#MOVEMEMORY_DATA == 0) then
			moveMemoryHolder:addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYNOMOVESFOUND, nil, nil, nil, nil, nil, nil, 0)
			return
		end
		local featuredHolder = UIElement:new({
			parent = moveMemoryHolder,
			pos = { 0, moveMemoryTitle.size.h },
			size = { moveMemoryHolder.size.w, 110 }
		})
		local memoryOpeners = {}
		local suggested = MoveMemory:spawnSuggested(featuredHolder)
		if (not suggested) then
			featuredHolder:kill()
			featuredHolder = nil
			for i,v in pairs(MOVEMEMORY_DATA) do
				table.insert(memoryOpeners, v)
			end
		else
			for i,v in pairs(MOVEMEMORY_DATA) do
				local skip = false
				for j,k in pairs(suggested) do
					if (v.id == k.id) then
						skip = true
					end
				end
				if (not skip) then
					table.insert(memoryOpeners, v)
				end
			end
		end
		local openersHolder = UIElement:new({
			parent = moveMemoryHolder,
			pos = { 0, featuredHolder and featuredHolder.shift.y + featuredHolder.size.h or moveMemoryTitle.size.h },
			size = { moveMemoryHolder.size.w, featuredHolder and moveMemoryHolder.size.h - featuredHolder.size.h - featuredHolder.shift.y or moveMemoryHolder.size.h - moveMemoryTitle.size.h }
		})
		MoveMemory:spawnOpeners(openersHolder, memoryOpeners, TB_MOVEMEMORY_LASTPAGE)
	end
	
	function MoveMemory:showToolbar(id, text, killAction, saveAction)
		if (MOVEMEMORY_TUTORIAL_MODE) then
			return
		end
		moveMemoryToolbar = moveMemoryToolbar or {}
		local posY = nil
		if (moveMemoryToolbar[id]) then
			posY = moveMemoryToolbar[id].pos.y
			moveMemoryToolbar[id]:kill()
			moveMemoryToolbar[id] = nil
		end
		
		local count = 0
		for i,v in pairs(moveMemoryToolbar) do
			count = count + 1
		end
		if (count == 1) then
			posY = nil
		end
		
		local toolbarH = WIN_W / 25 > 60 and 60 or WIN_W / 25
		local widthMod = saveAction and toolbarH - 10 or 0
		moveMemoryToolbar[id] = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { WIN_W / 6 * 4 - widthMod, posY or WIN_H - 50 - toolbarH * (count + 1) - count },
			size = { WIN_W / 6 * 2 - (100 - widthMod), toolbarH },
			bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
			shapeType = ROUNDED,
			rounded = 10
		})
		local moveMemoryTurnInfo = UIElement:new({
			parent = moveMemoryToolbar[id],
			pos = { 10, 10 },
			size = { moveMemoryToolbar[id].size.w - 60 - widthMod, moveMemoryToolbar[id].size.h - 20 }
		})
		moveMemoryTurnInfo:addAdaptedText(true, text, nil, nil, nil, LEFTMID)
		
		local killButtonSize = moveMemoryToolbar[id].size.h / 3 * 2
		local moveMemoryToolbarKill = UIElement:new({
			parent = moveMemoryToolbar[id],
			pos = { -killButtonSize - killButtonSize / 4, killButtonSize / 4 },
			size = { killButtonSize, killButtonSize },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
			pressedColor = { 1, 1, 1, 0.3 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local moveMemoryToolbarKillIcon = UIElement:new({
			parent = moveMemoryToolbarKill,
			pos = { 5, 5 },
			size = { moveMemoryToolbarKill.size.w - 10, moveMemoryToolbarKill.size.h - 10 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga",
		})
		moveMemoryToolbarKill:addMouseHandlers(nil, function()
				killAction()
			end)
		if (saveAction) then
			local moveMemoryToolbarSave = UIElement:new({
				parent = moveMemoryToolbar[id],
				pos = { -killButtonSize * 2 - killButtonSize / 4 - 5, killButtonSize / 4 },
				size = { killButtonSize, killButtonSize },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
				pressedColor = { 1, 1, 1, 0.3 },
				shapeType = ROUNDED,
				rounded = 4
			})
			local moveMemoryToolbarSaveIcon = UIElement:new({
				parent = moveMemoryToolbarSave,
				pos = { 5, 5 },
				size = { moveMemoryToolbarSave.size.w - 10, moveMemoryToolbarSave.size.h - 10 },
				bgImage = "../textures/menu/general/buttons/savewhite.tga",
			})
			moveMemoryToolbarSave:addMouseHandlers(nil, function()
					saveAction(function()
						killAction()
					end)
				end)
		end
	end
	
	function MoveMemory:playMove(memorymove, spawnHook, player, noToolbar)
		-- Plays a move for current turn
		local worldstate = get_world_state()
		local player = player or worldstate.selected_player
		if (player < 0) then
			return false
		end
		
		MOVEMEMORY_PLAYBACK_ACTIVE[player] = true
		
		local function playMoveQuit()
			MOVEMEMORY_PLAYBACK_ACTIVE[player] = false
			remove_hooks("tbMoveMemoryPlayTurns" .. player)
			if (moveMemoryToolbar[player]) then
				moveMemoryToolbar[player]:kill()
				moveMemoryToolbar[player] = nil
			end
		end
		
		local turn = worldstate.match_turn + 1
		if (memorymove.turns < turn) then
			playMoveQuit()
			return
		end
		if (memorymove.movements[turn]) then
			for joint, state in pairs(memorymove.movements[turn]) do
				if (joint < 20) then
					set_joint_state(player, joint, state)
				else
					-- Hand ids are 11 and 12, in data files we use 20 and 21
					set_grip_info(player, joint - 9, state)
				end
			end
		end
		
		-- Force-refresh ghost
		set_ghost(2)
		
		if (not noToolbar) then
			MoveMemory:showToolbar(player, memorymove.name .. ": " .. TB_MENU_LOCALIZED.WORDTURN .. " " .. turn .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF .. " " .. memorymove.turns, playMoveQuit)
		end
		if (spawnHook) then
			add_hook("enter_freeze", "tbMoveMemoryPlayTurns" .. player, function() MoveMemory:playMove(memorymove, false, player, noToolbar) end)
			add_hook("end_game", "tbMoveMemoryPlayTurns" .. player, playMoveQuit)
			add_hook("match_begin", "tbMoveMemoryPlayTurns" .. player, playMoveQuit)
		end
	end
	
	function MoveMemory:spawnMovementButton(viewElement, memorymove, pos)
		local openerElement = UIElement:new({
			parent = viewElement,
			pos = { 0, 20 + pos * 40 },
			size = { viewElement.size.w, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0 },
			hoverColor = { 0, 0, 0, 0.1 },
			pressedColor = { 1, 0, 0, 0.1 }
		})
		local openerDelete = TBMenu:createImageButtons(openerElement, -30, 10, 20, 20, "../textures/menu/general/buttons/trash.tga", nil, "../textures/menu/general/buttons/trashblack.tga", { 0, 0, 0, 0 })
		openerElement:addMouseHandlers(nil, function()
				MoveMemory:playMove(memorymove, true)
			end, function()
				if (not openerDelete.isactive) then
					openerDelete:show()
					openerDelete:activate()
				end
			end)
		openerDelete:addCustomDisplay(false, function()
				if (not openerElement.hoverState) then
					if (openerDelete.hoverState) then
						return
					end
					openerDelete:deactivate()
					openerDelete:hide()
				end
			end)
		if (not MOVEMEMORY_TUTORIAL_MODE) then
			openerDelete:addMouseHandlers(nil, function() TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.MOVEMEMORYDELETEMOVECONFIRM, function() MoveMemory:deleteMove(memorymove) MoveMemory:quit() MoveMemory:showMain() end) end)
		end
		local nameHolder = UIElement:new({
			parent = openerElement,
			pos = { 5, 2 },
			size = { openerElement.size.w - 10, openerElement.size.h / 3 * 2 - 2 }
		})
		nameHolder:addAdaptedText(true, memorymove.name, nil, nil, nil, LEFTMID, nil, nil, 0)
		if (memorymove.desc) then
			local descHolder = UIElement:new({
				parent = openerElement,
				pos = { 5, nameHolder.shift.y + nameHolder.size.h },
				size = { openerElement.size.w - 40, openerElement.size.h - 4 - nameHolder.size.h }
			})
			descHolder:addAdaptedText(true, memorymove.desc:upper(), nil, nil, FONTS.SMALL, LEFTMID, nil, 0.7, 0)
		end
	end
	
	function MoveMemory:spawnOpeners(viewElement, memoryOpeners, page)
		local page = page or 1
		TB_MOVEMEMORY_LASTPAGE = page
		viewElement:kill(true)
		
		if (#memoryOpeners > 0) then
			local openersTitle = UIElement:new({
				parent = viewElement,
				pos = { 0, 0 },
				size = { viewElement.size.w, 20 }
			})
			openersTitle:addAdaptedText(false, TB_MENU_LOCALIZED.MOVEMEMORYALLMOVES .. ":", 5, nil, 4, LEFTMID, 0.7)
		end
		local perPage = math.floor((viewElement.size.h - 40) / 40)
		local pages = math.ceil(#memoryOpeners / perPage)
		if (pages > 1) then
			local pagesHolder = UIElement:new({
				parent = viewElement,
				pos = { 0, -20 + moveMemoryMain.rounded },
				size = { viewElement.size.w, 20 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				uiColor = UICOLORWHITE
			})
			pagesHolder:addCustomDisplay(true, function()
					set_color(unpack(pagesHolder.bgColor))
					draw_disk(pagesHolder.pos.x + moveMemoryMain.rounded, pagesHolder.pos.y + pagesHolder.size.h - moveMemoryMain.rounded, 0, moveMemoryMain.rounded, 100, 1, -90, 90, 0)
					draw_disk(pagesHolder.pos.x + pagesHolder.size.w - moveMemoryMain.rounded, pagesHolder.pos.y + pagesHolder.size.h - moveMemoryMain.rounded, 0, moveMemoryMain.rounded, 100, 1, 0, 90, 0)
					draw_quad(pagesHolder.pos.x, pagesHolder.pos.y, pagesHolder.size.w, pagesHolder.size.h - moveMemoryMain.rounded)
					draw_quad(pagesHolder.pos.x + moveMemoryMain.rounded, pagesHolder.pos.y + pagesHolder.size.h - moveMemoryMain.rounded, pagesHolder.size.w - (moveMemoryMain.rounded * 2), moveMemoryMain.rounded)
				end)
			local pagePrevious = UIElement:new({
				parent = pagesHolder,
				pos = { 5, 0 },
				size = { pagesHolder.size.h, pagesHolder.size.h },
				interactive = true,
				bgColor = UICOLORWHITE,
				hoverColor = TB_MENU_DEFAULT_BG_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
			})
			pagePrevious:addCustomDisplay(true, function()
					set_color(unpack(pagePrevious:getButtonColor()))
					draw_disk(pagePrevious.pos.x + pagePrevious.size.w / 2, pagePrevious.pos.y + pagePrevious.size.h / 2, 0, pagePrevious.size.h / 5 * 2, 3, 1, -90, 360, 0)
				end)
			pagePrevious:addMouseHandlers(nil, function()
					MoveMemory:spawnOpeners(viewElement, memoryOpeners, page - 1 < 1 and pages or page - 1)
				end)
			local pageNext = UIElement:new({
				parent = pagesHolder,
				pos = { -pagesHolder.size.h - 5, 0 },
				size = { pagesHolder.size.h, pagesHolder.size.h },
				interactive = true,
				bgColor = UICOLORWHITE,
				hoverColor = TB_MENU_DEFAULT_BG_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
			})
			pageNext:addCustomDisplay(true, function()
					set_color(unpack(pageNext:getButtonColor()))
					draw_disk(pageNext.pos.x + pageNext.size.w / 2, pageNext.pos.y + pageNext.size.h / 2, 0, pageNext.size.h / 5 * 2, 3, 1, 90, 360, 0)
				end)
			pageNext:addMouseHandlers(nil, function()
					MoveMemory:spawnOpeners(viewElement, memoryOpeners, page + 1 > pages and 1 or page + 1)
				end)
			local pagesText = UIElement:new({
				parent = pagesHolder,
				pos = { pagesHolder.size.h + pagePrevious.shift.x, 0 },
				size = { pagesHolder.size.w - ((pagesHolder.size.h + pagePrevious.shift.x) * 2), pagesHolder.size.h }
			})
			pagesText:addAdaptedText(true, TB_MENU_LOCALIZED.PAGINATIONPAGE .. " " .. page .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF .. " " .. pages .. " " .. TB_MENU_LOCALIZED.WORDTOTAL, nil, nil, 4, nil, 0.6)
		end
		
		local count = 0
		for i = 1 + perPage * (page - 1), (#memoryOpeners < perPage * page and #memoryOpeners or perPage * page) do
			MoveMemory:spawnMovementButton(viewElement, memoryOpeners[i], count)
			count = count + 1
		end
	end
	
	function MoveMemory:spawnSuggested(viewElement)
		local loadedMod = get_game_rules().mod:gsub("%.tbm$", "")
		local suggestedOpeners = {}
		local displayedSuggested = {}
		for i,v in pairs(MOVEMEMORY_DATA) do
			if (v.mod) then
				if (loadedMod:find(v.mod) and v.mod:len() > 0) then
					table.insert(suggestedOpeners, v)
				end
			end
		end
		if (#suggestedOpeners == 0) then
			return false
		end
		if (#suggestedOpeners == 1) then
			viewElement.size.h = 70
		end
		local suggestedTitle = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, 20 }
		})
		suggestedTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYSUGGESTEDMOVES .. ":", nil, nil, 4, LEFTMID, 0.7)
		for i,v in pairs(suggestedOpeners) do
			if (i * 40 + 20 > viewElement.size.h) then
				return displayedSuggested
			end
			table.insert(displayedSuggested, v)
			MoveMemory:spawnMovementButton(viewElement, v, i - 1)
		end
		return displayedSuggested
	end
	
	function MoveMemory:spawnHotkeyListener()
		MOVEMEMORY_ACTIVE = true
		add_hook("key_down", "tbMoveMemoryHotkeyListener", function(key)
				-- Open movememory on "M" key press
				if (key == 109 and get_keyboard_ctrl() == 0 and get_keyboard_alt() == 0) then
					if (TB_MENU_MAIN_ISOPEN == 0) then
						if (TB_MOVEMEMORY_ISOPEN == 1) then
							MoveMemory:quit()
						else
							if (get_option("movememory") == 1) then
								MoveMemory:showMain()
							else
								MoveMemory:unloadHotkeyListener()
							end
						end
					end
				end
				--[[if (string.char(key) == "q") then
					if (TB_MOVEMEMORY_ISOPEN == 1) then
						MoveMemory:quit()
					end
					MoveMemory:unloadHotkeyListener()
				end]]
			end)
	end
	
	function MoveMemory:unloadHotkeyListener()
		MOVEMEMORY_ACTIVE = false
		remove_hooks("tbMoveMemoryHotkeyListener")
	end
	
end
