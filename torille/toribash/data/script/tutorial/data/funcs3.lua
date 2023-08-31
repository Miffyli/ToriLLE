local INTRO = 1
local OUTRO = -1
local SPACEBAR = " "

local function showOverlay(viewElement, reqTable, out, speed)
	local speed = speed or 1
	local req = { type = "transition", ready = false }
	table.insert(reqTable, req)
	
	if (tbOutOverlay) then
		tbOutOverlay:kill()
	end
	local overlay = UIElement:new({
		parent = out and tbTutorialsOverlay or viewElement,
		pos = { 0, 0 },
		size = { viewElement.size.w, viewElement.size.h },
		bgColor = cloneTable(UICOLORWHITE)
	})
	if (out) then
		tbOutOverlay = overlay
	end
	overlay.bgColor[4] = out and 0 or 1
	overlay:addCustomDisplay(true, function()
			overlay.bgColor[4] = overlay.bgColor[4] + (out and 0.02 or -0.02) * speed
			if (not out and overlay.bgColor[4] <= 0) then
				req.ready = true
				reqTable.ready = Tutorials:checkRequirements(reqTable)
				overlay:kill()
			elseif (out and overlay.bgColor[4] >= 1) then
				req.ready = true
				reqTable.ready = Tutorials:checkRequirements(reqTable)
			end
			set_color(unpack(overlay.bgColor))
			draw_quad(overlay.pos.x, overlay.pos.y, overlay.size.w, overlay.size.h)
		end)
end

local function introOverlay(viewElement, reqTable)
	showOverlay(viewElement, reqTable)
end

local function outroOverlay(viewElement, reqTable)
	showOverlay(viewElement, reqTable, true)
end

local function requireKeyPress(viewElement, reqTable, key, show)
	local req = { type = "keypress", ready = false }
	table.insert(reqTable, req)
	
	local button = nil
	if (show) then
		local displayKey = key
		local width = 100
		if (key == SPACEBAR) then
			displayKey = "SPACEBAR"
			width = 300
		end
		local BUTTON_DEFAULT_COLOR = { unpack(TB_MENU_DEFAULT_BG_COLOR) }
		local BUTTON_HOVER_COLOR = { unpack(TB_MENU_DEFAULT_LIGHEST_COLOR) }
		
		button = UIElement:new({
			parent = viewElement,
			pos = { 250 - width / 2, -200 },
			size = { width, 70 },
			interactive = true,
			bgColor = BUTTON_DEFAULT_COLOR,
			hoverColor = BUTTON_HOVER_COLOR,
			shapeType = ROUNDED,
			rounded = 10
		})
		button:deactivate()
		button.isactive = true
		button:addAdaptedText(false, displayKey)
	end
	
	add_hook("key_up", "tbTutorialsCustom", function(s)
			if (string.char(s) == key) then
				if (show and button.hoverState) then
					button.hoverState = false
					req.ready = true
					reqTable.ready = Tutorials:checkRequirements(reqTable)
				elseif (not show) then
					req.ready = true
					reqTable.ready = Tutorials:checkRequirements(reqTable)
				end
			end
		end)
	add_hook("key_down", "tbTutorialsCustom", function(s)
			if (string.char(s) == key and show) then
				button.hoverState = BTN_HVR
			end
		end)
end

local function requireKeyPressC(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, "c")
end

local function showKeyPressSpace(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, SPACEBAR)
end

local function requireKeyPressB(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, "b")
end

local function requireKeyPressM(viewElement, reqTable)
	MOVEMEMORY_TUTORIAL_MODE = true
	requireKeyPress(viewElement, reqTable, "m")
end

local function moveMemoryShow(viewElement, reqTable, static)
	dofile("system/movememory_manager.lua")
	local moveMemoryMain = UIElement:new({
		parent = viewElement,
		pos = { 50, WIN_H / 6 },
		size = { 250, WIN_H / 3 * 2 },
		bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR_TRANS),
		shapeType = ROUNDED,
		rounded = 4,
		uiColor = { 0, 0, 0, 1 }
	})
	local moveMemoryMoverHolder = UIElement:new({
		parent = moveMemoryMain,
		pos = { 0, 0 },
		size = { moveMemoryMain.size.w, 20 },
		bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR),
		shapeType = moveMemoryMain.shapeType,
		rounded = moveMemoryMain.rounded
	})
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
	local moveMemoryHolder = UIElement:new({
		parent = moveMemoryMain,
		pos = { 0, moveMemoryMoverHolder.size.h },
		size = { moveMemoryMain.size.w, moveMemoryMain.size.h - moveMemoryMoverHolder.size.h - moveMemoryMain.rounded}
	})
	moveMemoryHolder:addCustomDisplay(true, function() end)
	local moveMemoryTitleBg = UIElement:new({
		parent = moveMemoryHolder,
		pos = { 0, 0 },
		size = { moveMemoryHolder.size.w, 40 },
		bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR),
		uiColor = UICOLORWHITE
	})
	if (not static) then
		moveMemoryMain.bgColor[4] = 0
		moveMemoryMain:addCustomDisplay(false, function()
				if (moveMemoryMain.bgColor[4] < 0.5) then
					moveMemoryMain.bgColor[4] = moveMemoryMain.bgColor[4] + 0.1
				end
			end)
		moveMemoryMoverHolder.bgColor[4] = 0
		moveMemoryTitleBg.bgColor[4] = 0
		moveMemoryTitleBg:addCustomDisplay(false, function()
				if (moveMemoryTitleBg.bgColor[4] < 1) then
					moveMemoryTitleBg.bgColor[4] = moveMemoryTitleBg.bgColor[4] + 0.1
				end
				if (moveMemoryMoverHolder.bgColor[4] < 1) then
					moveMemoryMoverHolder.bgColor[4] = moveMemoryMoverHolder.bgColor[4] + 0.1
				end
			end)
	end
	moveMemoryMoverHolder:addCustomDisplay(true, function()
			set_color(unpack(moveMemoryMoverHolder.bgColor))
			draw_disk(moveMemoryMoverHolder.pos.x + moveMemoryMoverHolder.rounded, moveMemoryMoverHolder.pos.y + moveMemoryMoverHolder.rounded, 0, moveMemoryMoverHolder.rounded, 100, 1, -180, 90, 0)
			draw_disk(moveMemoryMoverHolder.pos.x + moveMemoryMoverHolder.size.w - moveMemoryMoverHolder.rounded, moveMemoryMoverHolder.pos.y + moveMemoryMoverHolder.rounded, 0, moveMemoryMoverHolder.rounded, 100, 1, 90, 90, 0)
			draw_quad(moveMemoryMoverHolder.pos.x + moveMemoryMoverHolder.rounded, moveMemoryMoverHolder.pos.y, moveMemoryMoverHolder.size.w - moveMemoryMoverHolder.rounded * 2, moveMemoryMoverHolder.rounded)
			draw_quad(moveMemoryMoverHolder.pos.x, moveMemoryMoverHolder.pos.y + moveMemoryMoverHolder.rounded, moveMemoryMoverHolder.size.w, moveMemoryMoverHolder.size.h - moveMemoryMoverHolder.rounded)
		end)
	local moveMemoryTitle = UIElement:new({
		parent = moveMemoryTitleBg,
		pos = { 0, 0 },
		size = { moveMemoryTitleBg.size.w, moveMemoryTitleBg.size.h }
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
	
	local openersHolder = UIElement:new({
		parent = moveMemoryHolder,
		pos = { 0, featuredHolder and featuredHolder.shift.y + featuredHolder.size.h or moveMemoryTitle.size.h },
		size = { moveMemoryHolder.size.w, featuredHolder and moveMemoryHolder.size.h - featuredHolder.size.h - featuredHolder.shift.y or moveMemoryHolder.size.h - moveMemoryTitle.size.h }
	})
	
	-- prevent interactions
	local clickOverlay = UIElement:new({
		parent = moveMemoryMain,
		pos = { 0, 0 },
		size = { moveMemoryMain.size.w, moveMemoryMain.size.h },
		interactive = true
	})
	return openersHolder, { moveMemoryMain, moveMemoryMoverHolder, moveMemoryTitleBg }
end

local function moveMemoryAddMoves(moves)
	local storedMoves = {}
	local file = Files:new("system/data.mm")
	if (file.data) then
		for i, ln in pairs(file:readAll()) do
			if (ln:find("^NAME")) then
				storedMoves[#storedMoves + 1] = { name = ln:gsub("^NAME ", "") }
			end
		end
	end
	file:reopen(FILES_MODE_APPEND)
	if (not file.data) then
		return
	end
	for i,v in pairs(moves) do
		local write = true
		if (#storedMoves > 0) then
			for j, k in pairs(storedMoves) do
				if (k.name:find(v.name)) then
					write = false
					break
				end
			end
		end
		if (write) then
			file:writeLine("")
			file:writeLine("NAME " .. v.name)
			if (v.desc) then
				file:writeLine("DESC " .. v.desc)
			end
			if (v.mod) then
				file:writeLine("MOD " .. v.mod)
			end
			for j, k in pairs(v.turnsdata) do
				file:writeLine(k)
			end
		end
	end
	file:close()
end

local function moveMemoryMovesShow(viewElement, reqTable, rpt)
	local openersHolder, toAnimate = moveMemoryShow(viewElement, nil, true)
	local moves = {
		{
			name = "Noobclap",
			desc = "Simple hand clap move",
			turnsdata = {
				"TURN 1; 0 3 1 3 2 3 3 3 4 2 5 3 6 3 7 2 8 3 9 3 10 3 11 3 12 3 13 3 14 3 15 3 16 3 17 3 18 3 19 3 20 1 21 1"
			}
		},
		{
			name = "Right Uppercut",
			desc = "Two-turn punch",
			turnsdata = {
				"TURN 1; 0 3 8 4 1 3 15 3 3 3 16 3 5 4 17 3 6 2 13 3 7 3 19 3 4 3 18 3 11 3 2 3 10 3 9 2 14 3 12 3 20 0 21 0",
				"TURN 2; 0 3 8 4 1 2 15 3 3 3 16 3 5 2 17 3 6 1 13 3 7 3 19 3 4 2 18 3 11 3 2 3 10 1 9 2 14 3 12 3 20 0 21 0"
			}
			
		},
		{
			name = "High Kick",
			desc = "High left leg kick",
			turnsdata = {
				"TURN 1; 0 3 8 3 1 2 15 1 3 3 16 3 5 3 17 2 6 3 13 2 7 3 19 3 4 2 18 3 11 3 2 2 10 3 9 3 14 2 12 2 20 0 21 0",
				"TURN 2; 0 3 8 3 1 2 15 1 3 3 16 3 5 3 17 1 6 3 13 2 7 3 19 3 4 2 18 3 11 3 2 2 10 3 9 3 14 2 12 2 20 0 21 0"
			}
		}
	}
	MoveMemory:spawnOpeners(openersHolder, moves)
	if (not rpt) then
		for i = 2, #openersHolder.child do
			local trans = 0.5
			local v = openersHolder.child[i]
			v:addCustomDisplay(false, function()
					set_color(1, 1, 1, trans)
					draw_quad(v.pos.x - (0.5 - trans) * 10, v.pos.y - (0.5 - trans) * 10, v.size.w + (0.5 - trans) * 20, v.size.h + (0.5 - trans) * 20)
					if (trans <= 0) then
						v:addCustomDisplay(false, function() end)
					end 
					trans = trans - 0.02
				end)
		end
		moveMemoryAddMoves(moves)
	else
		return toAnimate
	end
end

local function moveMemoryShowExit(viewElement)
	local toAnimate = moveMemoryMovesShow(viewElement, nil, true)
	for i,v in pairs(toAnimate) do
		v:addCustomDisplay(false, function()
				if (v.bgColor[4] > 0) then
					v.bgColor[4] = v.bgColor[4] - 0.1
				end
			end)
	end
	toAnimate[1]:addCustomDisplay(false, function()
			if (toAnimate[1].uiColor[4] > 0) then
				toAnimate[1].uiColor[4] = toAnimate[1].uiColor[4] - 0.1
			else
				toAnimate[1]:kill()
			end
		end)
end

local function checkJointStates(viewElement, reqTable)
	local req = { type = "jointstatecheck", ready = false }
	table.insert(reqTable, req)
	
	local states = {}
	for i,v in pairs(JOINTS) do
		states[v] = get_joint_info(0, v).state
	end
	
	local checker = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	checker:addCustomDisplay(true, function()
			for i,v in pairs(JOINTS) do
				if (get_joint_info(0, v).state ~= states[v]) then
					req.ready = true
					reqTable.ready = Tutorials:checkRequirements(reqTable)
					checker:kill()
				end
			end
		end)
end

functions = {
	IntroOverlay = introOverlay,
	OutroOverlay = outroOverlay,
	RequireKeyPressC = requireKeyPressC,
	RequireKeyPressB = requireKeyPressB,
	RequireKeyPressM = requireKeyPressM,
	RequireKeyPressSpace = showKeyPressSpace,
	ShowMovememory = moveMemoryShow,
	ShowMovememoryMoves = moveMemoryMovesShow,
	HideMovememoryMoves = moveMemoryShowExit,
	CheckJointStateChange = checkJointStates
}