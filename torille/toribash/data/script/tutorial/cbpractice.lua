-- Comeback practice tutorial
dofile('toriui/uielement3d.lua')

local TB_MENU_ISOPEN_LAST = 0
local options = { score = 1, name = 1, timer = 1 }

ComebackPractice = {}
ComebackPractice.__index = ComebackPractice

function ComebackPractice:checkScoreChange()
	local score = math.ceil(get_player_info(0).score)
	if (score ~= COMEBACK_LAST_SCORE) then
		COMEBACK_LAST_SCORE = score
		return true
	end
	return false
end

function ComebackPractice:teleportUke(maxDisplace)
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

function ComebackPractice:checkCollision()
	if (ComebackPractice:checkScoreChange()) then
		local ws = get_world_state()
		if (ws.winner == -1 and ws.replay_mode == 0) then
			ComebackPractice:teleportUke(COMEBACK_DISPLACE)
		
			-- Increment teleport distance and comeback score after every teleporting
			COMEBACK_SCORE = COMEBACK_SCORE + 1
			COMEBACK_DISPLACE = COMEBACK_DISPLACE >= 6 and COMEBACK_DISPLACE or COMEBACK_DISPLACE + 0.5
		end
	end
end

function ComebackPractice:preventUkeControls()
	local ws = get_world_state()
	if (ws.selected_player == 1) then
		select_player(0)
	end
end

function ComebackPractice:setMod()
	UIElement:runCmd("loadmod system/comebackpractice.tbm")
	UIElement:runCmd("set matchframes " .. COMEBACK_SETTINGS.matchframes)
	UIElement:runCmd("set turnframes " .. COMEBACK_SETTINGS.turnframes)
	UIElement:runCmd("set gravity 0.00 0.00 " .. COMEBACK_SETTINGS.gravity)
	start_new_game()
end

function ComebackPractice:setStartPose()
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

function ComebackPractice:toggleSettings(viewElement)
	viewElement.progress = 0
	if (not viewElement.isopen) then
		viewElement:addCustomDisplay(false, function()
				viewElement.progress = viewElement.progress + math.pi / 34
				if (viewElement.shift.y + viewElement.size.h / 16 * math.sin(viewElement.progress + math.pi / 34) < -25) then
					viewElement:moveTo(nil, viewElement.shift.y + viewElement.size.h / 16 * math.sin(viewElement.progress))
				else
					viewElement:moveTo(nil, -25)
					viewElement.isopen = true
					viewElement:addCustomDisplay(false, function() end)
				end
			end)
	else
		viewElement:addCustomDisplay(false, function()
				viewElement.progress = viewElement.progress + math.pi / 40
				if (viewElement.shift.y > -viewElement.size.h - viewElement.parent.size.h) then
					viewElement:moveTo(nil, viewElement.shift.y - viewElement.size.h / 16 * math.sin(viewElement.progress))
				else
					viewElement:moveTo(nil, -viewElement.size.h - viewElement.parent.size.h)
					viewElement.isopen = false
					viewElement:addCustomDisplay(false, function() end)
				end
			end)
	end
end

function ComebackPractice:spawnSettings(viewElement)
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
		hoverSound = 31,
		upSound = 50
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
		ComebackPractice:toggleSettings(viewElement)
			ComebackPractice:showConfirmation(function()
				for i,v in pairs(settingsState) do
					COMEBACK_SETTINGS[i] = v
				end
				canApply = false
				applySettings:deactivate()
				ComebackPractice:reset()
			end)
		end)
end

function ComebackPractice:showConfirmation(action)
	if (get_world_state().match_frame == 0) then
		action()
		return
	end
	confirmBox = confirmBox or UIElement:new({
		parent = comebackPracticeBar,
		pos = { -comebackPracticeBar.size.w / 2 - 200, WIN_H / 2 - 70 },
		size = { 400, 140 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	confirmBox:show(true)
	local confirmText = UIElement:new({
		parent = confirmBox,
		pos = { 10, 0 },
		size = { confirmBox.size.w - 20, 70 }
	})
	confirmText:addCustomDisplay(true, function()
			confirmText:uiText("Are you sure you want to reset the game?", nil, nil, FONTS.BIG, nil, 0.5)
		end)
	local confirmAgree = UIElement:new({
		parent = confirmBox,
		pos = { 10, confirmBox.size.h / 2 + 10 },
		size = { (confirmBox.size.w - 40) / 2, 50 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 0, 0, 0.2 },
		hoverSound = 31
	})
	confirmAgree:addCustomDisplay(false, function()
			confirmAgree:uiText("Yes")
		end)
	confirmAgree:addMouseHandlers(nil, function()
			action()
			confirmBox:kill()
			confirmBox:hide(true)
		end)
	local confirmCancel = UIElement:new({
		parent = confirmBox,
		pos = { confirmBox.size.w / 2 + 10, confirmBox.size.h / 2 + 10 },
		size = { (confirmBox.size.w - 40) / 2, 50 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 0, 0, 0.2 },
		hoverSound = 31
	})
	confirmCancel:addCustomDisplay(false, function()
			confirmCancel:uiText("No")
		end)
	confirmCancel:addMouseHandlers(nil, function()
			confirmBox:kill()
			confirmBox:hide(true)
		end)
end

function ComebackPractice:drawUI()
	comebackPracticeBar = UIElement:new({
		pos = { WIN_W / 4, 0 },
		size = { WIN_W / 2, 70 }
	})
	local settingsView = UIElement:new({
		parent = comebackPracticeBar,
		pos = { comebackPracticeBar.size.h, -comebackPracticeBar.size.h - 350 },
		size = { comebackPracticeBar.size.w - comebackPracticeBar.size.h * 2, 350 },
		shapeType = ROUNDED,
		rounded = 25,
		innerShadow = { 0, 10 },
		shadowColor = { UICOLORBLACK, TB_MENU_DEFAULT_DARKER_COLOR },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	ComebackPractice:spawnSettings(settingsView)
	local topBar = UIElement:new({
		parent = comebackPracticeBar,
		pos = { 0, -comebackPracticeBar.size.h * 2 },
		size = { comebackPracticeBar.size.w, comebackPracticeBar.size.h * 2 },
		shapeType = ROUNDED,
		rounded = comebackPracticeBar.size.h,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		innerShadow = { 0, 10 },
		shadowColor = { UICOLORBLACK, TB_MENU_DEFAULT_DARKER_COLOR }
	})
	local playerScore = UIElement:new({
		parent = comebackPracticeBar,
		pos = { 50, 5 },
		size = { (comebackPracticeBar.size.w - 150) / 2, comebackPracticeBar.size.h - 20 }
	})
	playerScore:addCustomDisplay(false, function()
			playerScore:uiText("Score: " .. COMEBACK_SCORE, nil, nil, FONTS.BIG, LEFTMID, 0.6)
		end)
	local frames = UIElement:new({
		parent = comebackPracticeBar,
		pos = { comebackPracticeBar.size.w / 2 - 25, 5 },
		size = { 50, 50 },
		bgColor = { 0, 0, 0, 0.65 }
	})
	frames:addCustomDisplay(true, function()
			local ws = get_world_state()
			if (ws.game_frame <= 8192) then
				set_color(unpack(frames.bgColor))
				draw_disk(frames.pos.x + frames.size.w / 2, frames.pos.y + frames.size.h / 2, frames.size.w / 4, frames.size.w / 2, 500, 1, 180, 360 * (ws.game_frame - ws.match_frame) / ws.game_frame, 0)
				frames:uiText(ws.game_frame - ws.match_frame < 0 and 0 or ws.game_frame - ws.match_frame)
			end
		end)
	local restart = UIElement:new({
		parent = comebackPracticeBar,
		pos = { -180, 5 },
		size = { 50, 50 },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 25,
		hoverColor = { 0, 0, 0, 0.1 },
		pressedColor = { 1, 0, 0, 0.3 }
	})
	local restartIcon = UIElement:new({
		parent = restart,
		pos = { 7.5, 7.5 },
		size = { 35, 35 },
		bgImage = "../textures/menu/general/buttons/restart.tga"
	})
	restart:addMouseHandlers(nil, function()
			ComebackPractice:showConfirmation(function() 
					ComebackPractice:reset()
				end)
		end)
	local settings = UIElement:new({
		parent = comebackPracticeBar,
		pos = { -130, 5 },
		size = { 50, 50 },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 25,
		hoverColor = { 0, 0, 0, 0.1 },
		pressedColor = { 1, 0, 0, 0.3 }
	})
	local settingsIcon = UIElement:new({
		parent = settings,
		pos = { 7.5, 7.5 },
		size = { 35, 35 },
		bgImage = "../textures/menu/general/buttons/settingswhite.tga"
	})
	settings:addMouseHandlers(nil, function()
			ComebackPractice:toggleSettings(settingsView)
		end)
	local quit = UIElement:new({
		parent = comebackPracticeBar,
		pos = { -80, 5 },
		size = { 50, 50 },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 25,
		hoverColor = { 0, 0, 0, 0.1 },
		pressedColor = { 1, 0, 0, 0.3}
	})
	quit:addCustomDisplay(false, function()
			local indent = 14
			local weight = 6
			-- Quit button
			if (quit.hoverState == BTN_DN) then
				set_color(0,0,0,1)
			else
				set_color(1,1,1,1)
			end
			draw_line(quit.pos.x + indent, quit.pos.y + indent, quit.pos.x + quit.size.w - indent, quit.pos.y + quit.size.h - indent, weight)
			draw_line(quit.pos.x + quit.size.w - indent, quit.pos.y + indent, quit.pos.x + indent, quit.pos.y + quit.size.h - indent, weight)
		end)
	quit:addMouseHandlers(nil, function()
			ComebackPractice:quit()
		end)
end

function ComebackPractice:reset()
	remove_hook("new_game", "comebackTutorial")
	remove_hook("new_mp_game", "comebackTutorial")
	COMEBACK_LAST_SCORE = 0
	COMEBACK_SCORE = 0
	COMEBACK_DISPLACE = 2
	COMEBACK_SETTINGS = COMEBACK_SETTINGS or {
		matchframes = 2000,
		turnframes = 30,
		gravity = -30,
	}
	
	ComebackPractice:setMod()
	ComebackPractice:setStartPose()
	set_ghost(2)
	add_hook("new_game", "comebackTutorial", function() ComebackPractice:quit() end)
	add_hook("new_mp_game", "comebackTutorial", function() ComebackPractice:quit() end)
end

function ComebackPractice:init()
	for i,v in pairs(options) do
		v = get_option(i)
		set_option(i, 0)
	end
	
	ComebackPractice:reset()
	ComebackPractice:drawUI()
end

function ComebackPractice:quit()
	for i,v in pairs(options) do
		set_option(i, v)
	end
	comebackPracticeBar:kill()
	remove_hooks("comebackTutorial")
	set_default_rules()
	open_menu(1)
end

function ComebackPractice:draw3DVisuals()
	for i, v in pairs(UIElement3DManager) do
		v:updatePos()
	end
	for i, v in pairs(UIVisual3DManager) do
		v:display()
	end
end

function ComebackPractice:drawVisuals()
	for i, v in pairs(UIElementManager) do
		v:updatePos()
	end
	for i, v in pairs(UIVisualManager) do
		v:display()
	end
end

ComebackPractice:init()

local function hook3D()
	if (TB_MENU_ISOPEN_LAST < TB_MENU_MAIN_ISOPEN) then
		comebackPracticeBar:hide()
		remove_hook("draw2d", "comebackTutorial")
		TB_MENU_ISOPEN_LAST = TB_MENU_MAIN_ISOPEN
	elseif (TB_MENU_ISOPEN_LAST > TB_MENU_MAIN_ISOPEN) then
		comebackPracticeBar:show()
		add_hook("draw2d", "comebackTutorial", function() ComebackPractice:drawVisuals() end)
		TB_MENU_ISOPEN_LAST = TB_MENU_MAIN_ISOPEN
	end
	ComebackPractice:checkCollision()
	ComebackPractice:draw3DVisuals()
	ComebackPractice:preventUkeControls()
end

add_hook("draw3d", "comebackTutorial", hook3D)
add_hook("draw2d", "comebackTutorial", function() ComebackPractice:drawVisuals() end)
add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)