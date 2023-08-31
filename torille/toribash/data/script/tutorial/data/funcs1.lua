local INTRO = 1
local OUTRO = -1

local function drawSingleKey(viewElement, reqTable, key)
	local BUTTON_DEFAULT_COLOR = { unpack(TB_MENU_DEFAULT_BG_COLOR) }
	local BUTTON_HOVER_COLOR = { unpack(TB_MENU_DEFAULT_LIGHTEST_COLOR) }
	
	local button = UIElement:new({
		parent = viewElement,
		pos = { 200, -WIN_H / 3 - 35 },
		size = { 100, 70 },
		interactive = true,
		bgColor = BUTTON_DEFAULT_COLOR,
		hoverColor = BUTTON_HOVER_COLOR,
		shapeType = ROUNDED,
		rounded = 10
	})
	button:deactivate()
	button.isactive = true
	button:addAdaptedText(false, key)
	
	local req = { type = "keypresscontrol", ready = false }
	table.insert(reqTable, req)
	
	add_hook("key_up", "tbTutorialsCustom", function(s)
			if (string.char(s) == key and button.hoverState) then
				button.hoverState = false
				req.ready = true
				reqTable.ready = Tutorials:checkRequirements(reqTable)
			end
		end)
	add_hook("key_down", "tbTutorialsCustom", function(s)
			if (string.char(s) == key) then
				button.hoverState = BTN_HVR
			end
		end)
end

local function drawWASD(viewElement, reqTable, shift, fade)
	set_camera_mode(0)
	local BUTTON_DEFAULT_COLOR = { unpack(TB_MENU_DEFAULT_BG_COLOR) }
	local BUTTON_HOVER_COLOR = { unpack(TB_MENU_DEFAULT_LIGHTEST_COLOR) }
	local wasdButtonsView = UIElement:new({
		parent = viewElement,
		pos = { 100, -320 },
		size = { 300, 200 }
	})
	
	local keysToPress = { 
		w = { pressed = false, pos = 2 },
		a = { pressed = false, pos = 4 },
		s = { pressed = false, pos = 5 },
		d = { pressed = false, pos = 6 },
	}
	if (shift) then
		keysToPress.shift = { pressed = false, pos = 7, size = 3 }
	end
	for i,v in pairs(keysToPress) do
		v.keyButton = UIElement:new({
			parent = wasdButtonsView,
			pos = { (v.pos - 1) % 3 * wasdButtonsView.size.w / 3 + 5, math.floor((v.pos - 1) / 3) * wasdButtonsView.size.h / 3 },
			size = { wasdButtonsView.size.w / 3 * (v.size and v.size or 1) - 10, wasdButtonsView.size.h / 3 - 5 },
			interactive = true,
			bgColor = BUTTON_DEFAULT_COLOR,
			hoverColor = BUTTON_HOVER_COLOR,
			shapeType = ROUNDED,
			rounded = 10
		})
		v.keyButton:deactivate()
		v.keyButton.isactive = true
		v.keyButton:addAdaptedText(false, i)
	end
	if (fade) then
		BUTTON_DEFAULT_COLOR[4] = (fade == INTRO and 0 or 1)
		local transparencyController = UIElement:new({
			parent = wasdButtonsView,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		transparencyController:addCustomDisplay(true, function()
				BUTTON_DEFAULT_COLOR[4] = BUTTON_DEFAULT_COLOR[4] + 0.04 * fade
				if (fade == 1) then
					if (BUTTON_DEFAULT_COLOR[4] >= 1) then
						BUTTON_DEFAULT_COLOR[4] = 1
						transparencyController:kill()
					end
				else
					if (BUTTON_DEFAULT_COLOR[4] <= 0) then
						wasdButtonsView:kill()
						BUTTON_DEFAULT_COLOR[4] = 0
					end
				end
			end)
	end
	
	if (reqTable) then
		local req = { type = "cameracontrols", ready = false }
		table.insert(reqTable, req)
		
		add_hook("key_up", "tbTutorialsCustom", function(key)
				if (shift and get_shift_key_state() == 0) then
					keysToPress.shift.keyButton.hoverState = false
				end
				for i,v in pairs(keysToPress) do
					if (i ~= "shift") then
						if (string.char(key) == i) then
							v.keyButton.hoverState = false
						end
						if (shift) then
							if ((string.char(key) == "w" or string.char(key) == "s") and get_shift_key_state() > 0) then
								req.ready = true
								reqTable.ready = Tutorials:checkRequirements(reqTable)
							end
						else
							local ready = true
							for i,v in pairs(keysToPress) do
								if (not v.pressed) then
									ready = false
								end
							end
							if (ready) then
								req.ready = true
								reqTable.ready = Tutorials:checkRequirements(reqTable)
							end
						end
					end
				end
			end)
		add_hook("key_down", "tbTutorialsCustom", function(key)
				if (shift and get_shift_key_state() > 0) then
					keysToPress.shift.keyButton.hoverState = BTN_HVR
				end
				for i,v in pairs(keysToPress) do
					if (i ~= "shift") then
						if (string.char(key) == i) then
							if (shift) then
								if (get_shift_key_state() > 0 and i ~= "shift") then
									keysToPress[i].pressed = true
								end
							else
								keysToPress[i].pressed = true
							end
							keysToPress[i].keyButton.hoverState = BTN_HVR
							break
						end
					end
				end
			end)
	end
end

local function prepareClassicCamera()
	local camera_info = get_camera_info()
	set_camera_mode(0)
	set_camera_lookat(camera_info.lookat.x, camera_info.lookat.y, camera_info.lookat.z)
	set_camera_pos(camera_info.pos.x, camera_info.pos.y, camera_info.pos.z)
end

local function drawWASDStatic(viewElement, reqTable, shift, fade)
	drawWASD(viewElement, nil, shift, fade or INTRO)
end

local function drawWASDShift(viewElement, reqTable)
	drawWASD(viewElement, reqTable, true)
end

local function drawWASDShiftStatic(viewElement, reqTable)
	drawWASDStatic(viewElement, nil, true, OUTRO)
end

local function setIntroPlayers()
	set_joint_color(0, 50, 27)
	set_joint_color(1, 50, 30)
	set_torso_color(0, 27)
	set_torso_color(1, 30)
end

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

local function outroOverlaySlow(viewElement, reqTable)
	showOverlay(viewElement, reqTable, true, 0.5)
end

local function drawSingleKeyC(viewElement, reqTable)
	drawSingleKey(viewElement, reqTable, "c")
end

local function drawSingleKeyZ(viewElement, reqTable)
	drawSingleKey(viewElement, reqTable, "z")
end

local function drawSingleKeyX(viewElement, reqTable)
	drawSingleKey(viewElement, reqTable, "x")
end

local function fractureToriKnee()
	fracture_joint(0, JOINTS.L_KNEE)
end

local function checkMouseCameraControls(viewElement, reqTable)
	local req = { type = "cameramouse", ready = false }
	table.insert(reqTable, req)
	
	local mousePressed = false
	
	add_hook("mouse_button_down", "tbTutorialsCustom", function()
			mousePressed = true
		end)
	add_hook("mouse_move", "tbTutorialsCustom", function()
			if (mousePressed) then
				req.ready = true
				reqTable.ready = Tutorials:checkRequirements(reqTable)
			end
		end)
end

local function hideWASDcheckMouse(viewElement, reqTable)
	drawWASDShiftStatic(viewElement, reqTable)
	checkMouseCameraControls(viewElement, reqTable)
end

functions = {
	DrawWASDCameraControls = drawWASD,
	DrawWASDCameraControlsStatic = drawWASDStatic,
	DrawWASDShiftCameraControls = drawWASDShift,
	HideWASDShiftControls = drawWASDShiftStatic,
	HideCameraKeyboardCheckMouseControls = hideWASDcheckMouse,
	SetIntroPlayers = setIntroPlayers,
	IntroOverlay = introOverlay,
	OutroOverlay = outroOverlay,
	OutroOverlaySlow = outroOverlaySlow,
	DrawXKey = drawSingleKeyX,
	DrawZKey = drawSingleKeyZ,
	DrawCKey = drawSingleKeyC,
	BreakLeg = fractureToriKnee,
	PrepareCamera = prepareClassicCamera,
}