local INTRO = 1
local OUTRO = -1

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
	GAME_COUNT = 0
end

local function outroOverlay(viewElement, reqTable)
	showOverlay(viewElement, reqTable, true)
end

local function setStartPose()
	local startPose = {
		{ joint = JOINTS.R_HIP, state = JOINT_STATE.BACK },
		{ joint = JOINTS.L_HIP, state = JOINT_STATE.BACK },
		{ joint = JOINTS.R_GLUTE, state = JOINT_STATE.BACK },
		{ joint = JOINTS.L_GLUTE, state = JOINT_STATE.BACK },
		{ joint = JOINTS.R_PECS, state = JOINT_STATE.FORWARD },
		{ joint = JOINTS.L_PECS, state = JOINT_STATE.FORWARD },
		{ joint = JOINTS.R_SHOULDER, state = JOINT_STATE.BACK },
		{ joint = JOINTS.L_SHOULDER, state = JOINT_STATE.BACK },
		{ joint = JOINTS.R_ELBOW, state = JOINT_STATE.FORWARD },
		{ joint = JOINTS.L_ELBOW, state = JOINT_STATE.FORWARD },
		{ joint = JOINTS.ABS, state = JOINT_STATE.BACK },
	}
	for i,v in pairs(startPose) do
		set_joint_state(1, v.joint, v.state)
	end
end

local function checkScoreChange()
	local score = math.ceil(get_player_info(0).score)
	if (score ~= COMEBACK_LAST_SCORE) then
		COMEBACK_LAST_SCORE = score
		return true
	end
	return false
end

local function teleportUke(maxDisplace)
	local playerStomachPos = get_body_info(0, BODYPARTS.STOMACH).pos
	local stomachPos = get_body_info(1, BODYPARTS.STOMACH).pos
	
	-- Make sure Uke isn't spawned too close to player
	local randomDisplace = { x = math.random(-maxDisplace * 1000, maxDisplace * 1000) / 1000 + 1, y = math.random(-maxDisplace * 1000, maxDisplace * 1000) / 1000 - 0.1 }
	while (math.abs(randomDisplace.x - playerStomachPos.x) < maxDisplace * 0.8 or math.abs(randomDisplace.y - playerStomachPos.y) < maxDisplace * 0.8) do
		randomDisplace = { x = math.random(-maxDisplace * 1000, maxDisplace * 1000) / 1000 + 1, y = math.random(-maxDisplace * 1000, maxDisplace * 1000) / 1000 - 0.1 }
	end
	
	-- Move Uke
	local relPos = get_body_info(1, BODYPARTS.STOMACH).pos
	for i,v in pairs(BODYPARTS) do
		local pos = get_body_info(1, v).pos
		set_body_pos(1, v, randomDisplace.x + pos.x - relPos.x, randomDisplace.y + pos.y - relPos.y, pos.z)
	end
	set_joint_state(1, JOINTS.NECK, JOINT_STATE.HOLD)
end

local function checkCollision()
	if (checkScoreChange()) then
		local ws = get_world_state()
		if (ws.winner == -1 and ws.replay_mode == 0 and ws.match_frame ~= 0) then
			teleportUke(COMEBACK_DISPLACE)
		
			-- Increment teleport distance and comeback score after every teleporting
			COMEBACK_SCORE = COMEBACK_SCORE + 1
			COMEBACK_DISPLACE = COMEBACK_DISPLACE >= 6 and COMEBACK_DISPLACE or COMEBACK_DISPLACE + 0.5
		end
	end
end

local function toggleSettings(viewElement, button)
	local windowMover = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	button:deactivate()
	local hide = viewElement.pos.y < 0 and true or false
	local rad = math.pi / 10
	if (hide) then
		windowMover:addCustomDisplay(true, function()
				if (viewElement.pos.y < 30) then
					viewElement:moveTo(nil, math.sin(rad) * (viewElement.size.h * 0.07), true)
				else
					viewElement:moveTo(nil, 40)
					windowMover:kill()
					button:activate()
				end
				rad = rad + math.pi / 30
			end)
	else
		windowMover:addCustomDisplay(true, function()
				if (viewElement.pos.y > -viewElement.size.h + 50) then
					viewElement:moveTo(nil, -math.sin(rad) * (viewElement.size.h * 0.07), true)
				else
					viewElement:moveTo(nil, -viewElement.size.h - WIN_H + 50)
					windowMover:kill()
					button:activate()
				end
				rad = rad + math.pi / 30
			end)
	end
end

local function restartGame()
	TUTORIAL_LEAVEGAME = true
	UIElement:runCmd("loadmod system/tutorial/comebackpractice.tbm")
	UIElement:runCmd("set matchframes " .. COMEBACK_SETTINGS.matchframes)
	UIElement:runCmd("set turnframes " .. COMEBACK_SETTINGS.turnframes)
	UIElement:runCmd("set gravity 0.00 0.00 " .. COMEBACK_SETTINGS.gravity)
	start_new_game()
	TUTORIAL_LEAVEGAME = false
end

local function loadSettings(viewElement, reqTable, viewElementGlobal)
	local settingsState = {}
	for i,v in pairs(COMEBACK_SETTINGS) do
		settingsState[i] = v
	end
	
	local cbsettings =
 	{
		matchframes = { 
			{ val = 2000 },
			{ val = 4000 },
			{ val = 8000 },
			{ val = 500000, name = "Endless" }
		},
		turnframes = {
			{ val = 30 },
			{ val = 50 },
			{ val = 70 }
		},
		gravity = {
			{ val = -9.87 },
			{ val = -20.00 },
			{ val = -30.00 }
		}
	}
	
	local canApply = false
	local applySettings = UIElement:new({
		parent = viewElement,
		pos = { 20, -70 },
		size = { viewElement.size.w - 40, 50 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		interactive = true,
		hoverColor = { 0, 0, 0, 0.6 },
		pressedColor = { 1, 0, 0, 0.2 },
		hoverSound = 31
	})
	applySettings:deactivate()
	
	local settingCount = 0
	for i,v in pairs(cbsettings) do
		local settingName = UIElement:new({
			parent = viewElement,
			pos = { 10, 30 + settingCount * 80 },
			size = { viewElement.size.w - 20, 30 }
		})
		settingName:addCustomDisplay(true, function()
				settingName:uiText(i, nil, nil, FONTS.BIG, nil, 0.55)
			end)
		for j,k in pairs(v) do
			local option = UIElement:new({
				parent = viewElement,
				pos = { 10 + (j - 1) / #v * (viewElement.size.w - 20), 65 + settingCount * 80 },
				size = { (viewElement.size.w - 20) / #v, 25 },
				interactive = true,
				bgColor = UICOLORWHITE,
				hoverColor = { 0.4, 0, 0, 1 },
				pressedColor = UICOLORBLACK,
				hoverSound = 31
			})
			option:addCustomDisplay(true, function()
					option:uiText(k.name or k.val, nil, nil, nil, nil, nil, nil, k.val == settingsState[i] and 1.4 or nil, k.val == settingsState[i] and UICOLORWHITE or option:getButtonColor())
				end)
			option:addMouseHandlers(nil, function()
					settingsState[i] = k.val
					for o,z in pairs(settingsState) do
						canApply = z ~= COMEBACK_SETTINGS[o] and true or false
						if (canApply) then
							applySettings:activate()
							break
						end
					end
					if (not canApply) then
						applySettings:deactivate()
					end
				end)
		end
		settingCount = settingCount + 1
	end
	applySettings:addCustomDisplay(false, function()
			if (canApply) then
				applySettings:uiText("Apply settings")
			else
				applySettings:uiText("No changes specified")
			end
		end)
	applySettings:addMouseHandlers(nil, function()
			TBMenu:showConfirmationWindow("Are you sure?", function()
					for i,v in pairs(settingsState) do
						COMEBACK_SETTINGS[i] = v
					end
					CURRENT_STEP.skip = 1
					Tutorials:reqDelay(viewElementGlobal, reqTable, 0)
				end)
		end)
end

local function initComebackPractice()
	COMEBACK_LAST_SCORE = 0
	COMEBACK_SCORE = 0
	COMEBACK_DISPLACE = 2
	COMEBACK_SETTINGS = COMEBACK_SETTINGS or {
		matchframes = 2000,
		turnframes = 30,
		gravity = -30,
	}
end

local function loadVisuals(viewElement, reqTable)
	DISPLAY_FRAMES = get_world_state().game_frame
	local settingsView = UIElement:new({
		parent = viewElement,
		pos = { viewElement.size.w / 4 + 10, -viewElement.size.h - 300 },
		size = { viewElement.size.w / 2 - 20, 350 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 10,
		shadowColor = TB_MENU_DEFAULT_DARKER_COLOR,
		innerShadow = { 15, 5 }
	})
	local settings = {}
	loadSettings(settingsView, reqTable, viewElement)
	local topBar = UIElement:new({
		parent = viewElement,
		pos = { viewElement.size.w / 4, -viewElement.size.h - 10 },
		size = { viewElement.size.w / 2, 60 },
		shapeType = ROUNDED,
		rounded = 10,
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local hitCounter = UIElement:new({
		parent = topBar,
		pos = { 15, 10 },
		size = { topBar.size.w / 3 - 30, 50 }
	})
	hitCounter:addCustomDisplay(true, function()
			hitCounter:uiText("Score: " .. COMEBACK_SCORE, nil, nil, nil, LEFTMID)
		end)
	local timer = UIElement:new({
		parent = topBar,
		pos = { topBar.size.w / 3 + 15, 8 },
		size = { topBar.size.w / 3 - 30, 50 },
		uiColor = { 1, 0.8, 0, 1 }
	})
	if (COMEBACK_SETTINGS.matchframes == 500000) then
		timer:addCustomDisplay(true, function()
				timer:uiText("Endless mode")
			end)
	else
		timer:addCustomDisplay(true, function()
				timer:uiText(DISPLAY_FRAMES, nil, nil, FONTS.BIG, nil, 0.9)
			end)
	end
	settings = UIElement:new({
		parent = topBar,
		pos = { -45, 15 },
		size = { 40, 40 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 10
	})
	local settingsIcon = UIElement:new({
		parent = settings,
		pos = { 5, 5 },
		size = { settings.size.w - 10, settings.size.h - 10 },
		bgImage = "../textures/menu/general/buttons/settingswhite.tga",		
	})
	settings:addMouseHandlers(nil, function()
			toggleSettings(settingsView, settings)
		end)
	local restart = UIElement:new({
		parent = topBar,
		pos = { -90, 15 },
		size = { 40, 40 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 10
	})
	local restartIcon = UIElement:new({
		parent = restart,
		pos = { 5, 5 },
		size = { restart.size.w - 10, restart.size.h - 10 },
		bgImage = "../textures/menu/general/buttons/restart.tga",
	})
	restart:addMouseHandlers(nil, function()
			TBMenu:showConfirmationWindow("Are you sure you want to reset the game?", function()
					CURRENT_STEP.fallback = 1
					Tutorials:reqDelay(viewElement, reqTable, 0)
				end)
		end)
	
	local leaveGame = false
	add_hook("end_game", "tbTutorialsCustom", function(gameEndType) COMEBACKPRACTICE_GAME_END = true end)
	add_hook("draw2d", "tbTutorialsCustom", function()
			checkCollision()
			local ws = get_world_state()
			local frame = ws.match_frame
			DISPLAY_FRAMES = ws.game_frame - ws.match_frame
			if (DISPLAY_FRAMES < 0) then
				DISPLAY_FRAMES = 0
			end
			if ((ws.winner > -1 or COMEBACKPRACTICE_GAME_END) and not leaveGame) then
				leaveGame = true
				GAME_COUNT = GAME_COUNT + 1
				local stopFrame = frame + 97
				local leaveGameHook = false
				add_hook("draw2d", "tbTutorialsCustomStatic", function()
						local wsMatchFrame = get_world_state().match_frame
						if (wsMatchFrame >= stopFrame and not TUTORIAL_LEAVEGAME) then
							leaveGameHook = true
							TUTORIAL_LEAVEGAME = true
						elseif (leaveGameHook and wsMatchFrame < stopFrame and wsMatchFrame >= 1) then
							leaveGameHook = false
							TUTORIAL_LEAVEGAME = false
						end
					end)
				Tutorials:reqDelay(viewElement, reqTable, 0)
			end
		end)
end

local function comebackPractice(viewElement, reqTable)
	COMEBACKPRACTICE_GAME_END = false
	CURRENT_STEP.skip = 0
	setStartPose()
	initComebackPractice()
	loadVisuals(viewElement, reqTable)
	
	add_hook("leave_game", "tbTutorialsCustomStatic", function()
			if (TUTORIAL_LEAVEGAME) then
				return 1
			end
		end)
	add_hook("key_up", "tbTutorialsCustom", function(key)
			if (get_shift_key_state() > 0 or get_keyboard_ctrl() > 0 or get_keyboard_alt() > 0) then
				return 1
			end
	end)
end

local function setMessage()
	if (COMEBACK_SCORE == 0) then
		Tutorials:setStepMessage("SENSEIMSGFAIL")
	elseif (COMEBACK_SCORE == 1) then
		Tutorials:setStepMessage("SENSEIMSGEND1")
	elseif (COMEBACK_SCORE < 3) then
		LOCALIZED_MESSAGES.SENSEIMSGEND2 = LOCALIZED_MESSAGES.SENSEIMSGEND2:gsub("%%d", COMEBACK_SCORE)
		Tutorials:setStepMessage("SENSEIMSGEND2")
	elseif (COMEBACK_SCORE < 6) then
		LOCALIZED_MESSAGES.SENSEIMSGEND3 = LOCALIZED_MESSAGES.SENSEIMSGEND3:gsub("%%d", COMEBACK_SCORE)
		Tutorials:setStepMessage("SENSEIMSGEND3")
	else
		LOCALIZED_MESSAGES.SENSEIMSGEND4 = LOCALIZED_MESSAGES.SENSEIMSGEND4:gsub("%%d", COMEBACK_SCORE)
		Tutorials:setStepMessage("SENSEIMSGEND4")
	end
end

functions = {
	IntroOverlay = introOverlay,
	OutroOverlay = outroOverlay,
	ComebackInit = initComebackPractice,
	PracticeCombacks = comebackPractice,
	SetMessage = setMessage,
	SetMod = restartGame
}
