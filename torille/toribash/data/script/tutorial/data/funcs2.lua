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

local function showPecsAxis()
	local rPecPos = get_joint_pos2(TORI, JOINTS.R_PECS)
	local lPecPos = get_joint_pos2(TORI, JOINTS.L_PECS)
	local rPecAxis = UIElement3D:new({
		parent = tbTutorials3DHolder,
		pos = { rPecPos.x, rPecPos.y, rPecPos.z },
		size = { 1, 1, 1 },
		objModel = "torishop/models/beaten_halo"
	})
	rPecAxis:addCustomDisplay(false, function()
			rPecAxis:rotate(0, 0, 1)
		end)
	local lPecAxis = UIElement3D:new({
		parent = tbTutorials3DHolder,
		pos = { lPecPos.x, lPecPos.y, lPecPos.z },
		size = { 1, 1, 1 },
		objModel = "torishop/models/beaten_halo"
	})
	lPecAxis:addCustomDisplay(false, function()
			lPecAxis:rotate(0, 0, -1)
		end)
end

local function punchingBag()
	local groinPos = get_body_info(1, BODYPARTS.GROIN).pos
	add_hook("enter_frame", "tbTutorialsCustomStatic", function()
			set_body_pos(1, BODYPARTS.GROIN, groinPos.x, groinPos.y, groinPos.z)
			set_body_rotation(1, BODYPARTS.GROIN, 0, 0, 0)
		end)
end

local function showDamageBar()
	local textColor = cloneTable(UICOLORTORI)
	textColor[4] = 0
	t2DamageMeter = UIElement:new({
		parent = tbTutorialsOverlay,
		pos = { -450, 7 },
		size = { 440, 40 },
		bgColor = textColor
	})
	local transparencyAnimation = UIElement:new({
		parent = t2DamageMeter,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	transparencyAnimation:addCustomDisplay(true, function()
			textColor[4] = textColor[4] + 0.04
			if (textColor[4] >= 1) then
				textColor[4] = 1
				transparencyAnimation:kill()
			end
		end)
	t2DamageMeter:addCustomDisplay(true, function()
			local damage = math.ceil(get_player_info(1).injury)
			t2DamageMeter:uiText(damage, nil, nil, FONTS.BIG, RIGHTMID, 1, nil, nil, textColor, nil, 0)
			t2DamageMeter:uiText("damage", nil, 35, nil, RIGHTMID, 1, nil, nil, textColor, nil, 0)
		end)
end

local function showTimer()
	local start_frame = get_world_state().match_frame
	local textColor = cloneTable(UICOLORTORI)
	textColor[4] = 0
	
	t2Timer = UIElement:new({
		parent = tbTutorialsOverlay,
		pos = { 0, 0 },
		size = { tbTutorialsOverlay.size.w, 90 },
		bgColor = textColor
	})
	transparencyAnimation = UIElement:new({
		parent = t2DamageMeter,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	transparencyAnimation:addCustomDisplay(true, function()
			t2Timer.bgColor[4] = t2Timer.bgColor[4] + 0.04
			if (t2Timer.bgColor[4] >= 1) then
				t2Timer.bgColor = t2DamageMeter.bgColor
				transparencyAnimation:kill()
			end
		end)
	t2Timer:addCustomDisplay(true, function()
			local current_frame = get_world_state().match_frame
			local frame = 500 - (current_frame - start_frame)
			
			set_color(1, (500 - (current_frame - start_frame)) / 650, 0, t2Timer.bgColor[4] / 3)
			draw_disk(t2Timer.pos.x + t2Timer.size.w / 2, t2Timer.pos.y + t2Timer.size.h / 2 + 3, t2Timer.size.h / 10, t2Timer.size.h / 2 - 5, 500, 1, 180 + (current_frame - start_frame) / 50 * 36, (500 - (current_frame - start_frame)) / 50 * 36, 0)
			t2Timer:uiText(frame < 0 and 0 or frame, nil, nil, FONTS.BIG, nil, 1, nil, 1, { 1, 0.8, 0, 1 }, { 1, 1, 1, 0.4 }, 0)
		end)
end

local function hideDamageAndTimerBars(viewElement, reqTable)
	local req = { type = "animationOutro", ready = false }
	table.insert(reqTable, req)
	
	local transparencyAnimation = UIElement:new({
		parent = t2DamageMeter,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	transparencyAnimation:addCustomDisplay(true, function()
			t2DamageMeter.bgColor[4] = t2DamageMeter.bgColor[4] - 0.04
			if (t2DamageMeter.bgColor[4] <= 0) then
				t2DamageMeter:kill()
				t2Timer:kill()
				req.ready = true
				reqTable.ready = Tutorials:checkRequirements(reqTable)
			end
		end)
end

local function showDamageAndTimerBars()
	showTimer()
	showDamageBar()
end

local function unloadStaticHook(viewElement, reqTable)
	remove_hooks("tbTutorialsCustomStatic")
	hideDamageAndTimerBars(viewElement, reqTable)
end

local function unloadStaticHookWithAchievement(viewElement, reqTable)
	unloadStaticHook(viewElement, reqTable)
	award_achievement(788)
end

functions = {
	IntroOverlay = introOverlay,
	OutroOverlay = outroOverlay,
	RequireKeyPressC = requireKeyPressC,
	RequireKeyPressSpace = showKeyPressSpace,
	DisplayAxisPecs = showPecsAxis,
	LockPunchingBag = punchingBag,
	ClearStaticHooks = unloadStaticHook,
	ClearStaticHooksAch = unloadStaticHookWithAchievement,
	ShowDamageBar = showDamageBar,
	ShowTimer = showTimer,
	ShowDamageAndTimer = showDamageAndTimerBars,
	HideDamageTimer = hideDamageAndTimerBars
}
