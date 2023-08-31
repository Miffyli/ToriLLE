-- Tutorials manager
if (get_option("tooltip") == 0 or not TOOLTIP_ACTIVE) then
	dofile("system/tooltip_manager.lua")
	Tooltip:create()
	TUTORIAL_TOOLTIP_ACTIVE = true
end

TUTORIAL_STORED_OPTS = TUTORIAL_STORED_OPTS or {}
local tbTutorialsKeysIgnore = {}
local tbTutorialsJointsIgnore = {}
local tbTutorialTotalSteps = 0
local tbTutorialCurrentStep = 0

TUTORIALJOINTLOCK = false
TUTORIALKEYBOARDLOCK = false

do
	Tutorials = {}
	Tutorials.__index = Tutorials
	local cln = {}
	setmetatable(cln, Tutorials)

	function Tutorials:quit()
		for i,v in pairs(TUTORIAL_STORED_OPTS) do
			set_option(v.name, v.value)
		end
		TUTORIAL_STORED_OPTS = {}
		chat_input_activate()
		enable_mouse_camera_movement()
		tbTutorialsOverlay:kill()
		tbTutorials3DHolder:kill()
		TUTORIALJOINTLOCK = false
		TUTORIALKEYBOARDLOCK = false
		MOVEMEMORY_TUTORIAL_MODE = false
		TUTORIAL_ISACTIVE = false
		TUTORIAL_LEAVEGAME = false
		CURRENT_STEP = {}
		remove_hooks("tbTutorialsVisual")
		remove_hooks("tbTutorialKeyboardHandler")
		remove_hooks("tbTutorialsCustom")
		remove_hooks("tbTutorialsCustomStatic")
		remove_hooks("tbMoveMemoryPlayTurns0")
		remove_hooks("tbMoveMemoryPlayTurns1")
		start_new_game()
		if (TUTORIAL_TOOLTIP_ACTIVE) then
			Tooltip:quit()
			TUTORIAL_TOOLTIP_ACTIVE = false
		end
		if (tutorialQuitOverlay) then
			tutorialQuitOverlay:kill()
			tutorialQuitOverlay = nil
		end
		open_menu(19)
	end

	function Tutorials:quitPopup()
		if (tutorialQuitOverlay) then
			tutorialQuitOverlay:kill()
			tutorialQuitOverlay = nil
			return
		end
		tutorialQuitOverlay = TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.TUTORIALSLEAVINGPROMPT, function() close_menu() Tutorials:quit() end, function() close_menu() TUTORIAL_LEAVEGAME = false end)
	end

	function Tutorials:getLocalization(TUTORIAL_LOCALIZED, id, language)
		local language = language or get_language()

		local localization = Files:new("../data/tutorials/tutorial" .. id .. "_" .. language .. ".txt")
		if (not localization.data) then
			if (language == "english") then
				return false
			else
				return Tutorials:getLocalization(TUTORIAL_LOCALIZED, id, "english")
			end
		end

		for i, ln in pairs(localization:readAll()) do
			if (not ln:match("^#")) then
				local data_stream = { ln:match(("([^\t]*)\t?"):rep(2)) }
				TUTORIAL_LOCALIZED[data_stream[1]] = data_stream[2]
			end
		end
		localization:close()

		if (language ~= "english") then
			-- Make sure there's no missing values
			local localization = Files:new("../data/tutorials/tutorial" .. id .. "_english.txt")
			for i, ln in pairs(localization:readAll()) do
				if (not ln:match("^#")) then
					local data_stream = { ln:match(("([^\t]*)\t?"):rep(2)) }
					if (not TUTORIAL_LOCALIZED[data_stream[1]]) then
						TUTORIAL_LOCALIZED[data_stream[1]] = data_stream[2]
					end
				end
			end
			localization:close()
		end
		return true
	end

	function Tutorials:loadTutorial(id)
		local tutorial = Files:new("../data/tutorials/tutorial" .. id .. ".dat")
		local tutorialData = tutorial:readAll()
		tutorial:close()

		CURRENT_TUTORIAL = id

		local steps = {}
		for i, ln in pairs(tutorialData) do
			ln = ln:gsub(";\n$", "")
			if (ln:find("^STEP")) then
				if (ln:find("^STEPSKIP")) then
					steps[#steps].skip = ln:gsub("STEPSKIP ", "") + 0
				elseif (ln:find("^STEPFALLBACK")) then
					steps[#steps].fallback = ln:gsub("STEPFALLBACK ", "") + 0
				else
					steps[#steps + 1] = { skip = 0 }
				end
			elseif (ln:find("^NEWGAME")) then
				steps[#steps].newgame = true
				steps[#steps].mod = ln:gsub("^NEWGAME ", "")
			elseif (ln:find("^LOADREPLAY")) then
				steps[#steps].replay = ln:gsub("^LOADREPLAY ", ""):gsub(" %d", "")
				local _, cacheSpecified = ln:gsub("%d$", "")
				if (cacheSpecified > 0) then
					steps[#steps].cached = ln:sub(-1) + 0
				else
					steps[#steps].cached = 0
				end
			elseif (ln:find("^LOADPLAYER")) then
				steps[#steps].loadplayers = steps[#steps].loadplayers or {}
				ln = ln:gsub("^LOADPLAYER ", "")
				local playerid = tonumber(ln:gsub("%D", ""))
				local player = ln:gsub("^%d ", "")
				steps[#steps].loadplayers[playerid] = player
			elseif (ln:find("^ENABLECAMERA")) then
				steps[#steps].enablecamera = true
			elseif (ln:find("^DISABLECAMERA")) then
				steps[#steps].disablecamera = true
			elseif (ln:find("^DAMAGE %d")) then
				steps[#steps].damage = ln:gsub("%D", "") + 0
			elseif (ln:find("^DAMAGEOPT %d")) then
				steps[#steps].damageopt = ln:gsub("%D", "") + 0
			elseif (ln:find("^DISMEMBER")) then
				steps[#steps].dismember = ln:gsub("^DISMEMBER ", "")
			elseif (ln:find("^FRACTURE")) then
				steps[#steps].fracture = ln:gsub("^FRACTURE ", "")
			elseif (ln:find("^SHOWSAYMESSAGE")) then
				steps[#steps].showsaymessage = true
			elseif (ln:find("^HIDESAYMESSAGE")) then
				steps[#steps].hidesaymessage = true
			elseif (ln:find("^SHOWHINTMESSAGE")) then
				steps[#steps].showhintmessage = true
			elseif (ln:find("^HIDEHINTMESSAGE")) then
				steps[#steps].hidehintmessage = true
			elseif (ln:find("^SHOWTASKMESSAGE")) then
				steps[#steps].showtaskmessage = true
			elseif (ln:find("^HIDETASKMESSAGE")) then
				steps[#steps].hidetaskmessage = true
			elseif (ln:find("^SHOWTOOLTIP")) then
				steps[#steps].showtooltip = true
			elseif (ln:find("^HIDETOOLTIP")) then
				steps[#steps].hidetooltip = true
			elseif (ln:find("^SHOWWAITBUTTON")) then
				steps[#steps].showwaitbtn = true
			elseif (ln:find("^HIDEWAITBUTTON")) then
				steps[#steps].hidewaitbtn = true
			elseif (ln:find("^TASKCOMPLETE")) then
				steps[#steps].marktaskcomplete = true
			elseif (ln:find("^TASKOPTCOMPLETE")) then
				steps[#steps].taskoptcomplete = ln:gsub("^TASKOPTCOMPLETE ", "") + 0
			elseif (ln:find("^TASKOPT")) then
				local data = { ln:gsub("^TASKOPT ", ""):match(("([^\t]+)\t*"):rep(2)) }
				steps[#steps].taskoptional = steps[#steps].taskoptional or {}
				table.insert(steps[#steps].taskoptional, { id = data[1] + 0, text = data[2] })
			elseif (ln:find("^TASK")) then
				steps[#steps].task = ln:gsub("^TASK ", "")
			elseif (ln:find("^MESSAGE")) then
				steps[#steps].message = ln:gsub("^MESSAGE ", "")
			elseif (ln:find("^SAY")) then
				steps[#steps].messageby = ln:gsub("^SAY ", "")
			elseif (ln:find("^ADVANCE")) then
				steps[#steps].progressstep = true
				tbTutorialTotalSteps = tbTutorialTotalSteps + 1
			elseif (ln:find("^DELAY")) then
				steps[#steps].delay = ln:gsub("^%D+", "") + 0
			elseif (ln:find("^VICTORY")) then
				steps[#steps].victory = true
			elseif (ln:find("^EDITGAME")) then
				steps[#steps].editgame = true
			elseif (ln:find("^PLAYFRAMES")) then
				steps[#steps].playframes = ln:gsub("%D", "") + 0
			elseif (ln:find("^MOVEPLAYER")) then
				local player = ln:find("^MOVEPLAYER TORI") and TORI or UKE
				steps[#steps].moveplayer = steps[#steps].moveplayer or {}
				steps[#steps].moveplayer[player] = steps[#steps].moveplayer[player] or {}
				if (ln:find("HOLDALL$")) then
					for i,v in pairs(JOINTS) do
						table.insert(steps[#steps].moveplayer[player], { joint = i, state = "HOLD" })
					end
				elseif (ln:find("RELAXALL$")) then
					for i,v in pairs(JOINTS) do
						table.insert(steps[#steps].moveplayer[player], { joint = i, state = "RELAX" })
					end
				else
					local data = { ln:gsub("^MOVEPLAYER %a+ ", ""):match(("([^ ]+) *"):rep(2)) }
					table.insert(steps[#steps].moveplayer[player], { joint = data[1], state = data[2] })
				end
			elseif (ln:find("^MOVEJOINT")) then
				steps[#steps].movejoint = steps[#steps].movejoint or {}
				local optional = false
				local optTask = false
				if (ln:find("^MOVEJOINTOPTIONAL")) then
					optional = true
					if (ln:find("%d$")) then
						optTask = ln:gsub("^%D+", "") + 0
						ln = ln:gsub(" " .. optTask .. "$", "")
					end
				end
				local data = { ln:gsub("^MOVEJOINT" .. (optional and "OPTIONAL " or " "), ""):match(("([^ ]+) *"):rep(2)) }
				table.insert(steps[#steps].movejoint, { joint = data[1], state = data[2], opt = optional, optTask = optTask })
			elseif (ln:find("^WAITBUTTON")) then
				steps[#steps].waitbtn = true
			elseif (ln:find("^JOINTLOCK")) then
				steps[#steps].jointlock = true
			elseif (ln:find("^JOINTUNLOCK")) then
				steps[#steps].jointunlock = true
			elseif (ln:find("^KEYBOARDLOCK")) then
				steps[#steps].keyboardlock = true
			elseif (ln:find("^SHIFTUNLOCK")) then
				steps[#steps].shiftunlock = true
			elseif (ln:find("^PLAYSOUND")) then
				steps[#steps].playsound = ln:gsub("PLAYSOUND ", "") + 0
			elseif(ln:find("^FAILFRAME")) then
				steps[#steps].failframe = ln:gsub("FAILFRAME ", "") + 0
				steps[#steps].fallbackrequirement = true
			elseif(ln:find("^PROCEEDFRAME")) then
				steps[#steps].proceedframe = ln:gsub("PROCEEDFRAME ", "") + 0
			elseif (ln:find("^GHOSTMODE")) then
				local ghost = ln:gsub("^GHOSTMODE ", "")
				steps[#steps].ghostmode = ghost == "TORI" and 1 or (ghost == "NONE" and 0 or 2)
			elseif (ln:find("^KEYBOARDUNLOCK")) then
				steps[#steps].keyboardunlock = true
				if (ln:len() > 14) then
					steps[#steps].keystounlock = ln:gsub("KEYBOARDUNLOCK ", ""):lower()
				end
			elseif (ln:find("^CUSTOMFUNC")) then
				steps[#steps].customfuncdefined = true
				steps[#steps].customfuncfile = loadfile("tutorial/data/funcs" .. id .. ".lua")
				steps[#steps].customfunc = ln:gsub("CUSTOMFUNC ", "")
			elseif (ln:find("^OPT")) then
				steps[#steps].opt = true
				steps[#steps].opts = steps[#steps].opts or {}
				local opt = {
					name = ln:gsub("OPT ", ""):gsub(" %d+.*$", ""),
					value = ln:gsub("%D", "") + 0
				}
				table.insert(steps[#steps].opts, opt)
			end
		end
		return steps
	end

	local function checkRequirements(reqTable, waitBtn)
		for i,v in ipairs(reqTable) do
			if (type(v) == "table") then
				if (not v.ready) then
					if (not waitBtn) then
						return false
					end
					if (v.type ~= "button") then
						return false
					end
				end
			end
		end
		return true
	end

	local function checkOptRequirements(reqTable)
		local skip = 0
		for i,v in pairs(reqTable) do
			if (type(v) == "table") then
				if (v.optional) then
					skip = 1
					if (not v.optReady) then
						return 0
					end
				end
			end
		end
		return skip
	end

	function Tutorials:hideWaitButton(requirements)
		Tutorials:showWaitButton(requirements, true)
	end

	function Tutorials:showWaitButton(reqTable, hide)
		if (hide) then
			tbTutorialsContinueButton:hide()
		else
			tbTutorialsContinueButton:show()
			tbTutorialsContinueButton:activate()
			tbTutorialsContinueButton:deactivate()
		end
	end

	function Tutorials:reqButton(reqTable)
		local req = { type = "button", ready = false }
		table.insert(reqTable, req)

		local buttonWait = UIElement:new({
			parent = tbTutorialsContinueButton,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		buttonWait:addCustomDisplay(true, function()
				if (checkRequirements(reqTable, true)) then
					tbTutorialsContinueButton:activate()
					tbTutorialsContinueButton.req = req
					tbTutorialsContinueButton.reqTable = reqTable
					tbTutorialsContinueButton:addMouseHandlers(nil, function()
							req.ready = true
							reqTable.ready = checkRequirements(reqTable)
							tbTutorialsContinueButton:deactivate()
							tbTutorialsContinueButton.req = {}
							tbTutorialsContinueButton.reqTable = {}
						end)
					buttonWait:kill()
				end
			end)
	end

	function Tutorials:reqDamage(viewElement, reqTable, dmg, opt)
		local req = { type = "damage", ready = opt, optional = opt }
		table.insert(reqTable, req)
		local reqElement = UIElement:new({
			parent = viewElement,
			pos = { 0, 40 },
			size = { 200, 30 }
		})
		reqElement:addCustomDisplay(true, function()
				local damage = get_player_info(1).injury
				if (damage > dmg) then
					if (opt) then
						req.optReady = true
						reqTable.skip = checkOptRequirements(reqTable)
						if (reqTable.skip == 1) then
							Tutorials:taskOptComplete(0)
						end
					else
						req.ready = true
						reqTable.ready = checkRequirements(reqTable)
					end
					reqElement:kill()
				end
			end)
	end

	function Tutorials:reqDismember(viewElement, reqTable, jointName)
		if (not JOINTS[jointName]) then
			echo("No joint found with name " .. jointName)
			return false
		end

		local req = { type = "dismember", ready = false }
		table.insert(reqTable, req)
		local reqElement = UIElement:new({
			parent = viewElement,
			pos = { 0, 40 },
			size = { 200, 30 }
		})
		local jointPulse = UIElement3D:new({
			playerAttach = UKE,
			attachJoint = JOINTS[jointName],
			pos = { 0, 0, 0 },
			size = { 1, 1, 1 },
			shapeType = SPHERE,
			bgColor = { 0.3, 0.1, 0.7, 1 }
		})
		jointPulse:addCustomDisplay(false, function()
				jointPulse.size.x = jointPulse.size.x + 0.001
				jointPulse.bgColor[4] = jointPulse.bgColor[4] - 0.0075
				if (jointPulse.size.y + 0.1 < jointPulse.size.x) then
					jointPulse.size.x = jointPulse.size.y
					jointPulse.bgColor[4] = 1
				end
			end)
		reqElement:addCustomDisplay(true, function()
				local dismember = get_joint_dismember(1, JOINTS[jointName])
				reqElement:uiText("Dismember " .. jointName, nil, nil, nil, LEFTMID)
				if (dismember) then
					req.ready = true
					reqTable.ready = checkRequirements(reqTable)
					jointPulse:kill()
					reqElement:kill()
				end
			end)
	end

	function Tutorials:reqFracture(viewElement, reqTable, jointName)
		if (not JOINTS[jointName]) then
			echo("No joint found with name " .. jointName)
			return false
		end

		local req = { type = "fracture", ready = false }
		table.insert(reqTable, req)
		local reqElement = UIElement:new({
			parent = viewElement,
			pos = { 0, 40 },
			size = { 200, 30 }
		})

		reqElement:addCustomDisplay(true, function()
				local fracture = get_joint_fracture(1, JOINTS[jointName])
				reqElement:uiText("Fracture " .. jointName, nil, nil, nil, LEFTMID)
				if (fracture) then
					req.ready = true
					reqTable.ready = checkRequirements(reqTable)
					reqElement:kill()
				end
			end)
	end

	function Tutorials:showTask(viewElement, reqTable, message)
		local req = { type = "message", ready = false }
		table.insert(reqTable, req)

		local messageTransparency = UIElement:new({
			parent = tbTutorialsTaskView,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		local textColor = { 1, 1, 1, 0 }
		messageTransparency:addCustomDisplay(true, function()
				textColor[4] = textColor[4] + 0.05
				if (textColor[4] > 1) then
					textColor[4] = 1
					messageTransparency:kill()
					req.ready = true
					reqTable.ready = checkRequirements(reqTable)
				end
			end)

		tbTutorialsTaskView:addAdaptedText(true, message, nil, nil, 4, LEFTMID, 0.7, nil, nil, nil, textColor)
	end

	function Tutorials:showHint(viewElement, reqTable, message)
		local req = { type = "message", ready = false }
		table.insert(reqTable, req)
		tbTutorialsHintMessage:kill(true)

		local messageTransparency = UIElement:new({
			parent = tbTutorialsHint,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		local textColor = { 1, 1, 1, 0 }
		messageTransparency:addCustomDisplay(true, function()
				textColor[4] = textColor[4] + 0.05
				if (textColor[4] > 0.9) then
					textColor[4] = 1
					messageTransparency:kill()
					req.ready = true
					reqTable.ready = checkRequirements(reqTable)
				end
			end)

		tbTutorialsHintMessage:addAdaptedText(false, message, nil, nil, 4, nil, 0.8, nil, nil, nil, textColor)

		for i,v in pairs(tbTutorialsHintMessage.dispstr) do
			local _, count = v:gsub("%b~~", "")
			local endposLast = 0
			for j = 1, count do
				local startpos, endpos = v:find("%b~~", endposLast)
				endposLast = endpos + 1
				if (startpos) then
					local displayLength = get_string_length(v:sub(0, startpos - 1), 4) * tbTutorialsHintMessage.textScale - 1
					local displayLineLength = get_string_length(v, 4) * tbTutorialsHintMessage.textScale
					local displayKey = v:sub(startpos + 1, endpos - 1)
					local displayKeyLength = get_string_length(v:sub(startpos, endpos), 4) * tbTutorialsHintMessage.textScale + 2
					local keyPressBG = UIElement:new({
						parent = tbTutorialsHintMessage,
						pos = { (tbTutorialsHintMessage.size.w - displayLineLength) / 2 + displayLength, (tbTutorialsHintMessage.size.h - 24 * tbTutorialsHintMessage.textScale * #tbTutorialsHintMessage.dispstr) / 2 + 24 * tbTutorialsHintMessage.textScale * (i - 1) },
						size = { displayKeyLength, 28 * tbTutorialsHintMessage.textScale },
						bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						shapeType = ROUNDED,
						rounded = 4
					})
					local keyPress = UIElement:new({
						parent = keyPressBG,
						pos = { 1, 1 },
						size = { keyPressBG.size.w - 2, keyPressBG.size.h - 2 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						shapeType = ROUNDED,
						rounded = 4
					})
					keyPress:addAdaptedText(false, displayKey, nil, nil, 4)
				end
			end

			local startpos, endpos = v:find("^[A-Z][A-Z]+")
			if (startpos) then
				local displayLineLength = get_string_length(v, 4) * tbTutorialsHintMessage.textScale
				local displayKey = v:sub(startpos, endpos)
				local displayKeyLength = get_string_length(displayKey, 4) * tbTutorialsHintMessage.textScale
				local keyPressBG = UIElement:new({
					parent = tbTutorialsHintMessage,
					pos = { (tbTutorialsHintMessage.size.w - displayLineLength) / 2, (tbTutorialsHintMessage.size.h - 24 * tbTutorialsHintMessage.textScale * #tbTutorialsHintMessage.dispstr) / 2 + 24 * tbTutorialsHintMessage.textScale * (i - 1) },
					size = { displayKeyLength, 24 * tbTutorialsHintMessage.textScale }
				})
				keyPressBG:addCustomDisplay(true, function()
						keyPressBG:uiText(displayKey, nil, nil, 4, nil, tbTutorialsHintMessage.textScale, nil, 1, TB_MENU_DEFAULT_BG_COLOR, UICOLORWHITE, nil, nil, nil, true)
				end)
			end
			local _, count = v:gsub(" [A-Z][A-Z]+", "")
			local endposLast = 0
			for j = 1, count do
				local startpos, endpos = v:find(" [A-Z][A-Z]+", endposLast)
				endposLast = endpos
				if (startpos) then
					local displayLength = get_string_length(v:sub(0, startpos), 4) * tbTutorialsHintMessage.textScale
					local displayLineLength = get_string_length(v, 4) * tbTutorialsHintMessage.textScale
					local displayKey = v:sub(startpos + 1, endpos)
					local displayKeyLength = get_string_length(displayKey, 4) * tbTutorialsHintMessage.textScale
					local keyPressBG = UIElement:new({
						parent = tbTutorialsHintMessage,
						pos = { (tbTutorialsHintMessage.size.w - displayLineLength) / 2 + displayLength, (tbTutorialsHintMessage.size.h - 24 * tbTutorialsHintMessage.textScale * #tbTutorialsHintMessage.dispstr) / 2 + 24 * tbTutorialsHintMessage.textScale * (i - 1) },
						size = { displayKeyLength, 24 * tbTutorialsHintMessage.textScale }
					})
					keyPressBG:addCustomDisplay(true, function()
							keyPressBG:uiText(displayKey, nil, nil, 4, nil, tbTutorialsHintMessage.textScale, nil, 1, TB_MENU_DEFAULT_BG_COLOR, UICOLORWHITE, nil, nil, nil, true)
					end)
				end
			end
		end
	end

	function Tutorials:showMessage(viewElement, reqTable, message, messageby)
		local req = { type = "message", ready = false }
		table.insert(reqTable, req)

		local animationWait = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		animationWait:addCustomDisplay(true, function()
			if (tbTutorialsMessageView.pos.x > WIN_W - tbTutorialsMessageView.size.w) then
				return
			else
				animationWait:kill()
				tbTutorialsMessageAuthor.bgColor[4] = 1
				tbTutorialsMessageAuthorNeck.bgColor[4] = 1
				if (messageby == "PLAYER") then
					local headTexture = TB_MENU_PLAYER_INFO.items.textures.head.equipped and ("../../custom/" .. TB_MENU_PLAYER_INFO.username:lower() .. "/head.tga") or "../../custom/tori/head.tga"
					tbTutorialsMessageAuthor:updateImage(headTexture)
					local color = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force or 23)
					tbTutorialsMessageAuthorNeck.bgColor = { color.r, color.g, color.b, 1 }
					tbTutorialsMessageAuthorNameBackground.bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR)
					tbTutorialsMessageBackground.shadowColor[2] = cloneTable(TB_MENU_DEFAULT_BG_COLOR)
					tbTutorialsMessageAuthorName:addAdaptedText(false, TB_MENU_PLAYER_INFO.username or "Tori", -20, -15)
				else
					tbTutorialsMessageAuthorName:addAdaptedText(false, messageby, -20, -15)
					local neckColId = 23
					if (messageby == "SENSEI") then
						messageby = "senseitutorial"
						neckColId = 11
					end
					tbTutorialsMessageAuthor:updateImage("../../custom/" .. messageby:lower() .. "/head.tga", "../../custom/uke/head.tga")
					tbTutorialsMessageAuthorNameBackground.bgColor = { 0.2, 0.34, 0.87, 1 }
					tbTutorialsMessageBackground.shadowColor[2] = { 0.2, 0.34, 0.87, 1 }
					local color = get_color_info(neckColId)
					tbTutorialsMessageAuthorNeck.bgColor = { color.r, color.g, color.b, 1 }
				end

				local messageBuilder = UIElement:new({
					parent = tbTutorialsMessage,
					pos = { 0, 0 },
					size = { 0, 0 }
				})
				local sub = 1
				local wait = 0
				messageBuilder:addCustomDisplay(true, function()
						tbTutorialsMessageView:addAdaptedText(false, message:sub(0,sub), nil, nil, nil, LEFTMID)
						if (wait > 0) then
							wait = wait - 1
							return
						end
						if (message:sub(sub, sub):find("[.,?!:;]")) then
							wait = 10
						end
						if (sub < message:len()) then
							sub = sub + 1
						else
							req.ready = true
							reqTable.ready = checkRequirements(reqTable)
							messageBuilder:kill()
						end
					end)
			end
		end)
	end

	function Tutorials:reqDelay(viewElement, reqTable, delay)
		local req = { type = "delay", ready = false }
		table.insert(reqTable, req)

		local reqElement = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		local spawnTime = os.clock()
		reqElement:addCustomDisplay(true, function()
				if (os.clock() - spawnTime > delay) then
					req.ready = true
					reqTable.ready = checkRequirements(reqTable)
					reqElement:kill()
				end
			end)
	end

	function Tutorials:reqVictory(viewElement, reqTable)
		local req = { type = "victory", ready = false }
		table.insert(reqTable, req)

		local reqElement = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		reqElement:addCustomDisplay(true, function()
				if (get_world_state().winner == 0) then
					req.ready = true
					reqTable.ready = checkRequirements(reqTable)
					reqElement:kill()
				end
			end)
	end

	local spawnTime = {}

	function Tutorials:reqJointMove(viewElement, reqTable, info)
		local req = { type = "jointmove", ready = info.opt }
		if (info.opt) then
			req.optional = true
			req.optReady = false
		end
		table.insert(reqTable, req)
		table.insert(tbTutorialsJointsIgnore, JOINTS[info.joint])

		local reqElement = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		local jointPulse
		if (not info.opt) then
			jointPulse = UIElement3D:new({
				parent = tbTutorials3DHolder,
				playerAttach = TORI,
				attachJoint = JOINTS[info.joint],
				pos = { 0, 0, 0 },
				size = { 1, 1, 1 },
				shapeType = SPHERE,
				bgColor = { 0.3, 0.1, 0.7, 1 }
			})
			jointPulse:addCustomDisplay(false, function()
					jointPulse.size.x = jointPulse.size.x + 0.004
					jointPulse.bgColor[4] = jointPulse.bgColor[4] - 0.01
					if (jointPulse.size.y + 0.3 < jointPulse.size.x) then
						jointPulse.size.x = jointPulse.size.y
						jointPulse.bgColor[4] = 1
					end
				end)
		end
		reqElement:addCustomDisplay(true, function()
				if (get_joint_info(0, JOINTS[info.joint]).state == JOINT_STATE[info.state]) then
					for i,v in pairs(tbTutorialsJointsIgnore) do
						if (v == JOINTS[info.joint]) then
							table.remove(tbTutorialsJointsIgnore, i)
							break
						end
					end
					req.ready = true
					if (info.opt) then
						req.optReady = true
						reqTable.skip = checkOptRequirements(reqTable)
						if (reqTable.skip == 1) then
							Tutorials:taskOptComplete(info.optTask)
						end
					end
					reqTable.ready = checkRequirements(reqTable)
					reqElement:kill()
					if (not info.opt) then
						jointPulse:kill()
					end
				end
			end)
	end

	function Tutorials:playFrames(viewElement, reqTable, frames)
		local req = { type = "playframes", ready = false }
		table.insert(reqTable, req)

		local currentFrame = get_world_state().match_frame
		if (TB_TUTORIAL_REPLAY_CACHE > 0) then
			set_replay_speed(TB_TUTORIAL_REPLAY_SPEED or 1)
		else
			frames = frames - 1
			run_frames(frames - (get_world_state().replay_mode - 1))
		end

		local function checkFrame()
			if (get_world_state().match_frame == currentFrame + frames) then
				if (TB_TUTORIAL_REPLAY_CACHE > 0) then
					set_replay_speed(0)
				end
				req.ready = true
				reqTable.ready = checkRequirements(reqTable)
				remove_hook(TB_TUTORIAL_REPLAY_CACHE > 0 and "draw2d" or "enter_frame", "playFrame")
			end
		end

		add_hook(TB_TUTORIAL_REPLAY_CACHE > 0 and "draw2d" or "enter_frame", "playFrame", checkFrame)
	end

	function Tutorials:moveJoints(data)
		for i, player in pairs(data) do
			for j, joint in pairs(player) do
				set_joint_state(i, JOINTS[joint.joint], JOINT_STATE[joint.state])
			end
		end
	end

	function Tutorials:startNewGame(viewElement, reqTable, mod)
		local req = { type = "newgame", ready = false }
		table.insert(reqTable, req)

		TUTORIAL_LEAVEGAME = true
		if (mod) then
			UIElement:runCmd("lm " .. mod)
		else
			start_new_game()
		end

		local reqElement = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { 0, 0 }
		})

		reqElement:addCustomDisplay(true, function()
				req.ready = true
				reqTable.ready = checkRequirements(reqTable)
				reqElement:kill()
				TUTORIAL_LEAVEGAME = false
			end)
	end

	function Tutorials:loadPlayer(players)
		for i,v in pairs(players) do
			if (v == "PLAYER") then
				v = TB_MENU_PLAYER_INFO.username
			elseif (v == "SENSEI") then
				v = "senseitutorial"
			end
			UIElement:runCmd("loadplayer " .. i .. " " .. v)
		end
	end

	function Tutorials:loadReplay(viewElement, reqTable, replay, cache)
		local req = { type = "loadreplay", ready = false }
		table.insert(reqTable, req)

		TUTORIAL_LEAVEGAME = true
		TB_TUTORIAL_REPLAY_CACHE = cache
		open_replay("system/tutorial/" .. replay, cache)
		if (cache == 1) then
			set_replay_speed(0)
		end
		freeze_game()

		local reqElement = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		reqElement:addCustomDisplay(true, function()
				req.ready = true
				reqTable.ready = checkRequirements(reqTable)
				reqElement:kill()
				TUTORIAL_LEAVEGAME = false
			end)
	end

	function Tutorials:runTutorialCustomFunction(viewElement, reqTable, file, func)
		file()
		local customFunc = functions[func]
		customFunc(viewElement, reqTable)
	end

	function Tutorials:checkRequirements(reqTable)
		return checkRequirements(reqTable)
	end

	function Tutorials:ignoreKeyPress(key, jointlock, keyboardlock)
		if ((jointlock and TUTORIALJOINTLOCK) or (keyboardlock and TUTORIALKEYBOARDLOCK)) then
			for i,v in pairs(tbTutorialsKeysIgnore) do
				if (key == v) then
					if (v == string.byte("z") or v == string.byte("x")) then
						if (#tbTutorialsJointsIgnore > 0) then
							return Tutorials:ignoreMouseClick()
						else
							return 1
						end
					else
						return
					end
				end
			end
			return 1
		elseif (key == 112 or key == 114) then
			return 1
		end
	end

	function Tutorials:ignoreMouseClick()
		local ws = get_world_state()
		if (ws.selected_player == 1) then
			select_player(0)
			return 1
		end
		for i, v in pairs(tbTutorialsJointsIgnore) do
			if (ws.selected_joint == v) then
				return
			end
		end
		if (not TUTORIALJOINTLOCK) then
			if (ws.selected_body == 11 or ws.selected_body == 12) then
				return
			end
		end
		return 1
	end

	function Tutorials:editGame()
		edit_game()
		set_camera_mode(0)
	end

	function Tutorials:hideHintWindow(reqTable)
		Tutorials:showHintWindow(reqTable, true)
	end

	function Tutorials:showHintWindow(reqTable, hide)
		local req = { type = "hintmessagefade", ready = false }
		table.insert(reqTable, req)

		if (hide) then
			tbTutorialsHintMessage:kill(true)
			tbTutorialsHintMessage:addCustomDisplay(true, function() end)
		end
		local windowFade = UIElement:new({
			parent = tbTutorialsHint,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		windowFade:addCustomDisplay(true, function()
				tbTutorialsHint.bgColor[4] = tbTutorialsHint.bgColor[4] + (hide and -0.05 or 0.05)
				if (hide and tbTutorialsHint.bgColor[4] <= 0) then
					tbTutorialsHint.bgColor[4] = 0
					windowFade:kill()
					req.ready = true
					reqTable.ready = checkRequirements(reqTable)
				elseif (not hide and tbTutorialsHint.bgColor[4] >= 0.7) then
					tbTutorialsHint.bgColor[4] = 0.7
					windowFade:kill()
					req.ready = true
					reqTable.ready = checkRequirements(reqTable)
				end
			end)
	end

	function Tutorials:addOptionalTask(data, taskText)
		local optTaskColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR)
		optTaskColor[4] = 0.7

		local optTaskView = UIElement:new({
			parent = tbTutorialsTask,
			pos = { 0, tbTutorialsTask.size.h - 40 },
			size = { tbTutorialsTask.size.w, 40 },
			bgColor = optTaskColor
		})

		local optTaskMarkView = UIElement:new({
			parent = optTaskView,
			pos = { 10, 8 },
			size = { 24, 24 },
			bgColor = { 0, 0, 0, 0.2 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local optTaskMark = UIElement:new({
			parent = optTaskMarkView,
			pos = { 0, 0 },
			size = { optTaskMarkView.size.w, optTaskMarkView.size.h },
			bgImage = "../textures/menu/general/buttons/checkmark.tga"
		})
		optTaskMark:hide(true)
		local optTaskMarkFail = UIElement:new({
			parent = optTaskMarkView,
			pos = { 0, 0 },
			size = { optTaskMarkView.size.w, optTaskMarkView.size.h },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		optTaskMarkFail:hide(true)

		local optTaskTextView = UIElement:new({
			parent = optTaskView,
			pos = { 44, 3 },
			size = { optTaskView.size.w - 54, 34 }
		})
		optTaskTextView:addAdaptedText(true, taskText, nil, nil, 4, LEFTMID, 0.6)

		tbTutorialsTask:hide()
		optTaskView:show()
		tbTutorialsTask:show()

		local posVertical = #tbTutorialsTask.optional
		local task = { id = data.id, complete = false, element = optTaskView, mark = optTaskMark, markFail = optTaskMarkFail, textView = optTaskTextView }
		table.insert(tbTutorialsTask.optional, task)

		optTaskView:addCustomDisplay(false, function()
				if (optTaskView.shift.y < tbTutorialsTask.size.h + posVertical * 40) then
					optTaskView:moveTo(nil, optTaskView.shift.y + 2)
				else
					optTaskView:addCustomDisplay(false, function() end)
				end
			end)
	end

	function Tutorials:taskOptComplete(id)
		for i,v in pairs(tbTutorialsTask.optional) do
			if (v.id == id) then
				v.mark:show(true)
				v.complete = true
				local animationScale = v.mark.size.w / 3
				local rad = math.pi / 3
				local transparency = 0.7
				v.mark:addCustomDisplay(false, function()
						set_color(1, 1, 1, transparency)
						animationScale = animationScale + math.sin(rad) * 1
						transparency = transparency - 0.035
						rad = rad + math.pi / 40
						if (animationScale > v.mark.size.w) then
							v.mark:addCustomDisplay(false, function() end)
							return
						end
						draw_disk(v.mark.pos.x + v.mark.size.w / 2, v.mark.pos.y + v.mark.size.h / 2, 0, animationScale, 500, 1, 0, 360, 0)
					end)
			end
		end
	end

	function Tutorials:taskComplete()
		tbTutorialsTaskMark:show(true)
		local markAnimation = UIElement:new({
			parent = tbTutorialsTaskMark,
			pos = { 0, 0 },
			size = { tbTutorialsTaskMark.size.w, tbTutorialsTaskMark.size.h }
		})
		for i,v in pairs(tbTutorialsTask.optional) do
			if (not v.complete) then
				v.markFail:show(true)
				v.markFail.bgColor = { 1, 0, 0, 0.2 }
			end
		end

		local animationScale = markAnimation.size.w / 3
		local rad = math.pi / 3
		local transparency = 0.7
		markAnimation:addCustomDisplay(true, function()
				set_color(1, 1, 1, transparency)
				animationScale = animationScale + math.sin(rad) * 1
				transparency = transparency - 0.035
				rad = rad + math.pi / 40
				if (animationScale > markAnimation.size.w) then
					markAnimation:kill()
					return
				end
				draw_disk(markAnimation.pos.x + markAnimation.size.w / 2, markAnimation.pos.y + markAnimation.size.h / 2, 0, animationScale, 500, 1, 0, 360, 0)
			end)
	end

	function Tutorials:setGhostMode(mode)
		set_ghost(mode)
	end

	function Tutorials:playSound(id)
		play_sound(id)
	end

	function Tutorials:hideTaskWindow(reqTable)
		Tutorials:showTaskWindow(reqTable, true)
	end

	function Tutorials:showTaskWindow(reqTable, hide)
		local req = { type = "taskwindowmove", ready = false }
		table.insert(reqTable, req)

		local rad = math.pi / 10
		if (hide) then
			tbTutorialsTask:addCustomDisplay(false, function()
					if (tbTutorialsTask.shift.x > -tbTutorialsTask.parent.size.w - tbTutorialsTask.size.w) then
						tbTutorialsTask:moveTo(tbTutorialsTask.shift.x - math.sin(rad) * (tbTutorialsTask.size.w * 0.0375))
						rad = rad + math.pi / 60
					else
						tbTutorialsTask:moveTo(-tbTutorialsTask.parent.size.w - tbTutorialsTask.size.w)
						for i,v in pairs(tbTutorialsTask.optional) do
							v.element:kill()
						end
						tbTutorialsTask.optional = {}
						tbTutorialsTask:addCustomDisplay(false, function() end)
						req.ready = true
						reqTable.ready = checkRequirements(reqTable)
					end
				end)
		else
			tbTutorialsTaskMark:hide(true)
			tbTutorialsTask:addCustomDisplay(false, function()
					if (tbTutorialsTask.shift.x < -tbTutorialsTask.parent.size.w - 10) then
						tbTutorialsTask:moveTo(tbTutorialsTask.shift.x + math.sin(rad) * (tbTutorialsTask.size.w * 0.0375))
						rad = rad + math.pi / 60
					else
						tbTutorialsTask:addCustomDisplay(false, function() end)
						req.ready = true
						reqTable.ready = checkRequirements(reqTable)
					end
				end)
		end
	end

	function Tutorials:checkFailFrame(stepElement, val, steps, currentStep, LOCALIZED_MESSAGES)
		local fallback = steps[currentStep].fallback or 0
		local frameChecker = UIElement:new({
			parent = stepElement,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		frameChecker:addCustomDisplay(true, function()
				if (get_world_state().match_frame >= val) then
					stepElement:kill()
					tbTutorials3DHolder:kill(true)
					Tutorials:runSteps(steps, currentStep - fallback, LOCALIZED_MESSAGES)
				end
			end)
	end

	function Tutorials:checkProceedFrame(stepElement, reqTable, val, steps, currentStep, LOCALIZED_MESSAGES)
		local frameChecker = UIElement:new({
			parent = stepElement,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		frameChecker:addCustomDisplay(true, function()
				if (get_world_state().match_frame >= val) then
					stepElement:kill()
					tbTutorials3DHolder:kill(true)
					Tutorials:runSteps(steps, currentStep + 1 + reqTable.skip, LOCALIZED_MESSAGES)
				end
			end)
	end

	function Tutorials:hideMessageWindow(requirements)
		Tutorials:showMessageWindow(requirements, true)
	end

	function Tutorials:showMessageWindow(reqTable, hide)
		local req = { type = "messagewindowmove", ready = false }
		table.insert(reqTable, req)

		local windowMover = UIElement:new({
			parent = tbTutorialsMessage,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		local rad = math.pi / 10
		if (hide) then
			windowMover:addCustomDisplay(true, function()
					if (tbTutorialsMessage.shift.x < tbTutorialsMessage.parent.size.w) then
						tbTutorialsMessage:moveTo(tbTutorialsMessage.shift.x + math.sin(rad) * (tbTutorialsMessage.size.w * 0.035))
						tbTutorialsMessageAuthor.bgColor[4] = tbTutorialsMessageAuthor.bgColor[4] - tbTutorialsMessageAuthor.bgColor[4] * 0.15 * math.sin(rad)
						tbTutorialsMessageAuthorNeck.bgColor[4] = tbTutorialsMessageAuthorNeck.bgColor[4] - tbTutorialsMessageAuthorNeck.bgColor[4] * 0.15 * math.sin(rad)
						rad = rad + math.pi / 50
					else
						tbTutorialsMessageAuthorNameBackground.bgColor = cloneTable(tbTutorialsMessageBackground.accentColor)
						tbTutorialsMessageBackground.shadowColor[2] = cloneTable(tbTutorialsMessageBackground.accentColor)
						tbTutorialsMessageView:addCustomDisplay(false, function() end)
						tbTutorialsMessageAuthorName:addCustomDisplay(false, function() end)
						tbTutorialsMessage:moveTo(tbTutorialsMessage.parent.size.w)
						windowMover:kill()
						req.ready = true
						reqTable.ready = checkRequirements(reqTable)
					end
				end)
		else
			windowMover:addCustomDisplay(true, function()
					if (tbTutorialsMessage.shift.x > tbTutorialsMessage.parent.size.w - tbTutorialsMessage.size.w) then
						tbTutorialsMessage:moveTo(tbTutorialsMessage.shift.x - math.sin(rad) * (tbTutorialsMessage.size.w * 0.035))
						rad = rad + math.pi / 50
					else
						windowMover:kill()
						req.ready = true
						reqTable.ready = checkRequirements(reqTable)
					end
				end)
		end
	end

	function Tutorials:setStepMessage(message, author)
		if (message) then
			CURRENT_STEP.message = message
		end
		if (author) then
			CURRENT_STEP.messageby = author
		end
	end

	function Tutorials:runSteps(steps, currentStep, LOCALIZED_MESSAGES)
		local currentStep = currentStep or 1
		local requirements = { ready = false, skip = 0 }
		CURRENT_STEP = steps[currentStep]

		local stepElement = UIElement:new({
			parent = tbTutorialsOverlay,
			pos = { 0, 0 },
			size = { tbTutorialsOverlay.size.w, tbTutorialsOverlay.size.h }
		})
		local stepNext = UIElement:new({
			parent = stepElement,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		stepNext:addCustomDisplay(true, function()
				if (requirements.ready) then
					local skip = steps[currentStep].skip
					if (requirements.skip) then
						skip = skip + requirements.skip
					end
					remove_hooks("tbTutorialsCustom")
					stepElement:kill()
					tbTutorials3DHolder:kill(true)
					if (not steps[currentStep].fallbackrequirement and steps[currentStep].fallback) then
						Tutorials:runSteps(steps, currentStep - steps[currentStep].fallback, LOCALIZED_MESSAGES)
					elseif (currentStep + skip < #steps) then
						Tutorials:runSteps(steps, currentStep + 1 + skip, LOCALIZED_MESSAGES)
					else
						Tutorials:showTutorialEnd()
					end
				end
			end)

		if (steps[currentStep].customfuncdefined) then
			Tutorials:runTutorialCustomFunction(stepElement, requirements, steps[currentStep].customfuncfile, steps[currentStep].customfunc)
		end
		if (steps[currentStep].opts) then
			for i,v in pairs(steps[currentStep].opts) do
				local found = false
				for j,k in pairs(TUTORIAL_STORED_OPTS) do
					if (k.name == v.name) then
						found = true
					end
				end
				if (not found) then
					table.insert(TUTORIAL_STORED_OPTS, { name = v.name, value = get_option(v.name) })
				end
				set_option(v.name, v.value)
			end
		end
		if (steps[currentStep].progressstep) then
			tbTutorialCurrentStep = tbTutorialCurrentStep + 1
		end
		if (steps[currentStep].newgame) then
			Tutorials:startNewGame(stepElement, requirements, steps[currentStep].mod)
		end
		if (steps[currentStep].replay) then
			Tutorials:loadReplay(stepElement, requirements, steps[currentStep].replay, steps[currentStep].cached)
		end
		if (steps[currentStep].editgame) then
			Tutorials:editGame()
		end
		if (steps[currentStep].loadplayers) then
			Tutorials:loadPlayer(steps[currentStep].loadplayers)
		end
		if (steps[currentStep].jointlock) then
			TUTORIALJOINTLOCK = true
			tbTutorialsJointsIgnore = {}
		end
		if (steps[currentStep].jointunlock) then
			TUTORIALJOINTLOCK = false
			for i,v in pairs(JOINTS) do
				table.insert(tbTutorialsJointsIgnore, v)
			end
		end
		if (steps[currentStep].keyboardlock) then
			TUTORIALKEYBOARDLOCK = true
			tbTutorialsKeysIgnore = {}
		end
		if (steps[currentStep].showsaymessage) then
			Tutorials:showMessageWindow(requirements)
		elseif (steps[currentStep].hidesaymessage) then
			Tutorials:hideMessageWindow(requirements)
		end
		if (steps[currentStep].showwaitbtn) then
			Tutorials:showWaitButton(requirements)
		elseif (steps[currentStep].hidewaitbtn) then
			Tutorials:hideWaitButton(requirements)
		end
		if (steps[currentStep].showhintmessage) then
			Tutorials:showHintWindow(requirements)
		elseif (steps[currentStep].hidehintmessage) then
			Tutorials:hideHintWindow(requirements)
		end
		if (steps[currentStep].showtaskmessage) then
			Tutorials:showTaskWindow(requirements)
		elseif (steps[currentStep].hidetaskmessage) then
			Tutorials:hideTaskWindow(requirements)
		end
		if (TUTORIAL_TOOLTIP_ACTIVE) then
			if (steps[currentStep].showtooltip) then
				Tooltip:create()
			elseif (steps[currentStep].hidetooltip) then
				Tooltip:quit()
			end
		end
		if (steps[currentStep].taskoptcomplete) then
			Tutorials:taskOptComplete(steps[currentStep].taskoptcomplete)
		end
		if (steps[currentStep].shiftunlock) then
			table.insert(tbTutorialsKeysIgnore, 303)
			table.insert(tbTutorialsKeysIgnore, 304)
		end
		if (steps[currentStep].keyboardunlock) then
			if (steps[currentStep].keystounlock) then
				for i = 1, steps[currentStep].keystounlock:len() do
					table.insert(tbTutorialsKeysIgnore, string.byte(steps[currentStep].keystounlock:sub(i, i)))
				end
			else
				TUTORIALKEYBOARDLOCK = false
			end
		end
		if (steps[currentStep].enablecamera) then
			enable_mouse_camera_movement()
		elseif (steps[currentStep].disablecamera) then
			disable_mouse_camera_movement()
		end

		for reqType, val in pairs(steps[currentStep]) do
			if (reqType == "damage") then
				Tutorials:reqDamage(stepElement, requirements, val)
			elseif (reqType == "damageopt") then
				Tutorials:reqDamage(stepElement, requirements, val, true)
			elseif (reqType == "dismember") then
				Tutorials:reqDismember(stepElement, requirements, val)
			elseif (reqType == "fracture") then
				Tutorials:reqFracture(stepElement, requirements, val)
			elseif (reqType == "ghostmode") then
				Tutorials:setGhostMode(val)
			elseif (reqType == "message") then
				local randomStart, randomEnd = val:find("%%d%d+")
				if (randomStart) then
					local randomText = val:sub(randomStart, randomEnd)
					local randomNum = randomText:gsub("%D", "")
					val = val:gsub("%%d%d+", math.random(1, randomNum))
				end
				if (steps[currentStep].messageby) then
					Tutorials:showMessage(stepElement, requirements, LOCALIZED_MESSAGES[val], steps[currentStep].messageby)
				else
					Tutorials:showHint(stepElement, requirements, LOCALIZED_MESSAGES[val])
				end
			elseif (reqType == "task") then
				Tutorials:showTask(stepElement, requirements, LOCALIZED_MESSAGES[val])
			elseif (reqType == "taskoptional") then
				for i,task in pairs(val) do
					Tutorials:addOptionalTask(task, LOCALIZED_MESSAGES[task.text])
				end
			elseif (reqType == "marktaskcomplete") then
				Tutorials:taskComplete()
			elseif (reqType == "delay") then
				Tutorials:reqDelay(stepElement, requirements, val)
			elseif (reqType == "victory") then
				Tutorials:reqVictory(stepElement, requirements)
			elseif (reqType == "playframes") then
				Tutorials:playFrames(stepElement, requirements, val)
			elseif (reqType == "moveplayer") then
				Tutorials:moveJoints(val)
			elseif (reqType == "playsound") then
				Tutorials:playSound(val)
			elseif (reqType == "failframe") then
				Tutorials:checkFailFrame(stepElement, val, steps, currentStep, LOCALIZED_MESSAGES)
			elseif (reqType == "proceedframe") then
				Tutorials:checkProceedFrame(stepElement, requirements, val, steps, currentStep, LOCALIZED_MESSAGES)
			elseif (reqType == "movejoint") then
				for i, data in pairs(val) do
					Tutorials:reqJointMove(stepElement, requirements, data)
				end
			end
		end
		if (steps[currentStep].waitbtn) then
			Tutorials:reqButton(requirements)
		end
	end

	function Tutorials:updateConfig(next)
		-- Steam achievements integration
		local level = get_tutorial_level()
		if (level < CURRENT_TUTORIAL and CURRENT_TUTORIAL > 4) then
			set_tutorial_level(CURRENT_TUTORIAL)
		end
		
		local tutorialsConfig = Files:new("../data/tutorials/config.cfg")
		if (not tutorialsConfig.data) then
			return false
		end

		local nextTutId = 1
		for i, ln in pairs(tutorialsConfig:readAll()) do
			if (ln:find("^NEXT")) then
				nextTutId = ln:gsub("^NEXT ", "") + 0
				break
			end
		end
		if (CURRENT_TUTORIAL >= nextTutId) then
			if (next) then
				nextTutId = CURRENT_TUTORIAL + 1
			else
				nextTutId = CURRENT_TUTORIAL
			end
		end

		tutorialsConfig:reopen(FILES_MODE_WRITE)
		tutorialsConfig:writeLine("NEXT " .. nextTutId)
		tutorialsConfig:writeLine("LAST " .. CURRENT_TUTORIAL)
		tutorialsConfig:close()
		return true
	end

	function Tutorials:beginnerConnect()
		dofile("system/friendlist_manager.lua")
		local players = FriendsList:updateOnline()
		
		local rooms = { "beginner%d", "public%d" }
		local roomsOnline = {}
		for i, online in pairs(players) do
			if (online.room:find(rooms[1]) or online.room:find(rooms[2])) then
				roomsOnline[online.room] = roomsOnline[online.room] or { players = 0 }
				roomsOnline[online.room].players = roomsOnline[online.room].players + 1
			end
		end
		for i, room in pairs(roomsOnline) do
			room.name = i
		end
		roomsOnline = UIElement:qsort(roomsOnline, "players", true)
		Tutorials:quit()
		if (#roomsOnline > 0) then
			for i, room in pairs(roomsOnline) do
				if (room.players > 1 and room.players < 5) then
					UIElement:runCmd("jo " .. room.name)
					close_menu()
					return
				end
			end
			UIElement:runCmd("jo " .. roomsOnline[1].name)
			close_menu()
			return
		else
			UIElement:runCmd("jo beginner1")
			close_menu()
			return
		end
	end

	function Tutorials:showTutorialEnd(buttonsCustom)
		TUTORIAL_LEAVEGAME = true
		local buttons = {}
		local nextTutorial = Files:new("../data/tutorials/tutorial" .. CURRENT_TUTORIAL + 1 .. ".dat")
		Tutorials:updateConfig(nextTutorial.data and true or false)

		local scale = WIN_W > WIN_H * 2 and WIN_H or WIN_W / 7 * 6
		if (scale > 1024) then
			scale = 1024
		end
		local buttonHolder = UIElement:new({
			parent = tbTutorialsOverlay,
			pos = { (WIN_W - scale) / 2, (WIN_H - scale / 2.5) / 2 },
			size = { scale, scale / 2.5 }
		})
		if (not buttonsCustom) then
			if (nextTutorial.data) then
				table.insert(buttons, {
					title = TB_MENU_LOCALIZED.TUTORIALSCONTINUETONEXT,
					size = 0.66,
					shift = 0,
					image = "../textures/menu/tutorial" .. CURRENT_TUTORIAL + 1 .. ".tga",
					action = function() Tutorials:runTutorial(CURRENT_TUTORIAL + 1) end
				})
				nextTutorial:close()
			end
			table.insert(buttons, {
				title = TB_MENU_LOCALIZED.TUTORIALSBACKTOMAIN,
				size = #buttons == 0 and 0.66 or 0.33,
				shift = #buttons == 0 and buttonHolder.size.w * 0.17 + 20 or 0,
				image = #buttons == 0 and "../textures/menu/freeplay.tga" or "../textures/menu/multiplayer.tga",
				action = function() Tutorials:quit() end
			})
		else
			buttons = buttonsCustom
		end

		local maxWidthButton = { 0, 0 }
		for i, v in pairs (buttons) do
			if v.size > maxWidthButton[2] then
				maxWidthButton[2] = v.size
				maxWidthButton[1] = i
			end
		end
		local imageRes = buttonHolder.size.w * maxWidthButton[2] - 20
		local shift = 0
		for i,v in pairs(buttons) do
			local button = UIElement:new({
				parent = buttonHolder,
				pos = { shift + v.shift, 0 },
				size = { buttonHolder.size.w * v.size - 20, buttonHolder.size.h },
				bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR),
				interactive = true,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			shift = shift + button.size.w + 40
			button:deactivate()
			button.animateColor[4] = 0
			button:addCustomDisplay(false, function()
					if (button.animateColor[4] < 1) then
						button.animateColor[4] = button.animateColor[4] + 0.05
					else
						button:activate()
						button:addCustomDisplay(false, function() end)
						local imageSizeW, imageSizeH = button.size.w - 20, (imageRes - 20) / maxWidthButton[2] * v.size
						if (v.size >= 0.5) then
							imageSizeW, imageSizeH = (imageRes - 20) / maxWidthButton[2] * v.size, (imageRes - 20) / maxWidthButton[2] * v.size / 2
						end
						local buttonImage = UIElement:new({
							parent = button,
							pos = { 10, 10 },
							size = { imageSizeW, imageSizeH },
							bgColor = cloneTable(button.bgColor),
							bgImage = v.image
						})
						buttonImage:addCustomDisplay(false, function()
							if (buttonImage.bgColor[4] > 0) then
								buttonImage.bgColor[4] = buttonImage.bgColor[4] - 0.1
								set_color(unpack(buttonImage.bgColor))
								draw_quad(buttonImage.pos.x, buttonImage.pos.y, buttonImage.size.w, buttonImage.size.h)
							else
								buttonImage:addCustomDisplay(false, function() end)
							end
						end)
					end
			end)
			button:addMouseHandlers(nil, v.action)
			local buttonText = UIElement:new({
				parent = button,
				pos = { 10, -button.size.h / 5 - 10 },
				size = { button.size.w - 20, button.size.h / 5 }
			})
			buttonText:addAdaptedText(true, v.title)
		end
	end

	function Tutorials:runTutorial(id)
		TUTORIAL_ISACTIVE = true
		TUTORIAL_LEAVEGAME = true
		
		if (get_world_state().game_type == 1) then
			start_new_game()
		end

		Tutorials:loadHooks()
		Tutorials:loadOverlay()

		chat_input_deactivate()

		local id = tonumber(id)
		LOCALIZED_MESSAGES = {}
		local tutorialSteps = Tutorials:loadTutorial(id)
		if (Tutorials:getLocalization(LOCALIZED_MESSAGES, id)) then
			Tutorials:updateConfig()
			Tutorials:runSteps(tutorialSteps, nil, LOCALIZED_MESSAGES)
		end
	end

	function Tutorials:loadOverlay()
		if (tbTutorialsOverlay) then
			tbTutorialsOverlay:kill()
		end
		tbTutorialsOverlay = UIElement:new({
			globalid = TB_TUTORIAL_MODERN_GLOBALID,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H }
		})

		if (tbTutorials3DHolder) then
			tbTutorials3DHolder:kill()
		end
		tbTutorials3DHolder = UIElement3D:new({
			globalid = TB_TUTORIAL_MODERN_GLOBALID,
			pos = { 0, 0, 0 },
			size = { 0, 0, 0 }
		})
		tbTutorials3DHolder:addCustomDisplay(false, function() end)

		tbTutorialsHint = UIElement:new({
			parent = tbTutorialsOverlay,
			pos = { 0, -95 },
			size = { tbTutorialsOverlay.size.w, 90 },
			bgColor = { 0, 0, 0, 0 }
		})
		tbTutorialsHintMessage = UIElement:new({
			parent = tbTutorialsHint,
			pos = { 120, 5 },
			size = { tbTutorialsHint.size.w - 240, tbTutorialsHint.size.h - 10 }
		})

		tbTutorialsTask = UIElement:new({
			parent = tbTutorialsOverlay,
			pos = { -tbTutorialsOverlay.size.w - 400, 20 },
			size = { 400, 50 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		tbTutorialsTask.optional = {}
		local tbTutorialsTaskMarkOutline = UIElement:new({
			parent = tbTutorialsTask,
			pos = { 10, 10 },
			size = { 30, 30 },
			bgColor = { 1, 1, 1, 0.8 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local tbTutorialsTaskMarkBackground = UIElement:new({
			parent = tbTutorialsTaskMarkOutline,
			pos = { 2, 2 },
			size = { tbTutorialsTaskMarkOutline.size.w - 4, tbTutorialsTaskMarkOutline.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = tbTutorialsTaskMarkOutline.shapeType,
			rounded = tbTutorialsTaskMarkOutline.rounded
		})
		tbTutorialsTaskMark = UIElement:new({
			parent = tbTutorialsTaskMarkBackground,
			pos = { 0, 0 },
			size = { tbTutorialsTaskMarkBackground.size.w, tbTutorialsTaskMarkBackground.size.h },
			bgImage = "../textures/menu/general/buttons/checkmark.tga"
		})
		tbTutorialsTaskMark:hide(true)
		tbTutorialsTaskView = UIElement:new({
			parent = tbTutorialsTask,
			pos = { 50, 5 },
			size = { tbTutorialsTask.size.w - 55, tbTutorialsTask.size.h - 10 }
		})

		tbTutorialsMessage = UIElement:new({
			parent = tbTutorialsOverlay,
			pos = { tbTutorialsOverlay.size.w, -200 },
			size = { tbTutorialsOverlay.size.w / 2, 100 }
		})
		tbTutorialsMessageAuthorNameBackground = UIElement:new({
			parent = tbTutorialsMessage,
			pos = { tbTutorialsMessage.size.h / 2, -tbTutorialsMessage.size.h - 35 },
			size = { 196, 64 },
			shapeType = ROUNDED,
			rounded = 5,
			bgColor = { 0.852, 0.852, 0.852, 1 }
		})
		tbTutorialsMessageAuthorNameBackground:addCustomDisplay(false, function()
				set_color(unpack(tbTutorialsMessageAuthorNameBackground.bgColor))
				draw_quad(tbTutorialsMessageAuthorNameBackground.pos.x + tbTutorialsMessageAuthorNameBackground.size.w, tbTutorialsMessageAuthorNameBackground.pos.y + 5, 10, 59)
				draw_quad(tbTutorialsMessageAuthorNameBackground.pos.x + tbTutorialsMessageAuthorNameBackground.size.w + 10, tbTutorialsMessageAuthorNameBackground.pos.y + 8, 5, 56)
				draw_quad(tbTutorialsMessageAuthorNameBackground.pos.x + tbTutorialsMessageAuthorNameBackground.size.w + 15, tbTutorialsMessageAuthorNameBackground.pos.y + 10, 5, 54)
				draw_quad(tbTutorialsMessageAuthorNameBackground.pos.x + tbTutorialsMessageAuthorNameBackground.size.w + 20, tbTutorialsMessageAuthorNameBackground.pos.y + 15, 5, 49)
				draw_quad(tbTutorialsMessageAuthorNameBackground.pos.x + tbTutorialsMessageAuthorNameBackground.size.w + 25, tbTutorialsMessageAuthorNameBackground.pos.y + 22, 5, 42)
				draw_quad(tbTutorialsMessageAuthorNameBackground.pos.x + tbTutorialsMessageAuthorNameBackground.size.w + 30, tbTutorialsMessageAuthorNameBackground.pos.y + 35, 5, 34)
			end)
		tbTutorialsMessageAuthorName = UIElement:new({
			parent = tbTutorialsMessageAuthorNameBackground,
			pos = { 0, 0 },
			size = { 256, 64 },
			bgImage = "../textures/menu/general/tutorial_speech_box_dotted.tga"
		})
		tbTutorialsMessageBackground = UIElement:new({
			parent = tbTutorialsMessage,
			pos = { tbTutorialsMessage.size.h / 2, 0 },
			size = { tbTutorialsMessage.size.w - tbTutorialsMessage.size.h / 2, tbTutorialsMessage.size.h },
			bgColor = { 0.129, 0.129, 0.129, 1 },
			shapeType = ROUNDED,
			rounded = 10,
			innerShadow = { 0, 5 },
			shadowColor = { 0.852, 0.852, 0.852, 1 }
		})
		tbTutorialsMessageBackground.accentColor = { 0.852, 0.852, 0.852, 1 }
		tbTutorialsMessageView = UIElement:new({
			parent = tbTutorialsMessage,
			pos = { tbTutorialsMessage.size.h + 25, 10 },
			size = { tbTutorialsMessage.size.w - tbTutorialsMessage.size.h - 30, tbTutorialsMessage.size.h - 20 }
		})
		local playerHeadHolder = UIElement:new({
			parent = tbTutorialsMessage,
			pos = { 0, -tbTutorialsMessage.size.h - 5 },
			size = { tbTutorialsMessage.size.h + 10, tbTutorialsMessage.size.h + 10 },
			bgColor = { 0, 0, 0, 1 },
			shapeType = ROUNDED,
			rounded = tbTutorialsMessage.size.h
		})
		local headBackground = UIElement:new({
			parent = playerHeadHolder,
			pos = { 2, 2 },
			size = { playerHeadHolder.size.w - 4, playerHeadHolder.size.h - 4 },
			bgColor = { 0.129, 0.129, 0.129, 1 },
			shapeType = playerHeadHolder.shapeType,
			rounded = playerHeadHolder.size.h
		})
		local headViewport = UIElement:new({
			parent = headBackground,
			pos = { -headBackground.size.w - 10, -headBackground.size.h - 10 },
			size = { headBackground.size.w + 20, headBackground.size.h + 20 },
			viewport = true
		})
		local colors = get_color_info(23)
		tbTutorialsMessageAuthorNeck = UIElement:new({
			parent = headViewport,
			pos = { 0, 0.1, 9.65 },
			rot = { 0, 0, 0 },
			radius = 0.54,
			bgColor = { colors.r, colors.g, colors.b, 0 }
		})
		tbTutorialsMessageAuthor = UIElement:new({
			parent = headViewport,
			pos = { 0, 0, 10.3 },
			rot = { 0, 0, -10 },
			radius = 0.95,
			bgColor = { 1, 1, 1, 0 },
			bgImage = { "../../custom/tori/head.tga", "../../custom/tori/head.tga" }
		})

		tbTutorialsContinueButton = UIElement:new({
			parent = tbTutorialsOverlay,
			pos = { -100, -80 },
			size = { 60, 60 },
			shapeType = ROUNDED,
			rounded = 70,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_LIGHEST_COLOR,
			interactive = true,
			hoverSound = 31
		})
		tbTutorialsContinueButton:deactivate()
		local buttonPulse = UIElement:new({
			parent = tbTutorialsContinueButton,
			pos = { tbTutorialsContinueButton.size.w / 2, tbTutorialsContinueButton.size.h / 2 },
			size = { tbTutorialsContinueButton.size.w / 2, tbTutorialsContinueButton.size.h / 2 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local pulseMod = 0
		buttonPulse:addCustomDisplay(true, function()
				if (tbTutorialsContinueButton.isactive) then
					local r, g, b, a = unpack(buttonPulse.bgColor)
					set_color(r, g, b, a - pulseMod / 10)
					draw_disk(buttonPulse.pos.x, buttonPulse.pos.y, buttonPulse.size.w, buttonPulse.size.w + pulseMod, 500, 1, 0, 360, 0)
					pulseMod = pulseMod + 0.2
					if (pulseMod > 10) then
						pulseMod = 0
					end
				else
					pulseMod = 0
				end
			end)
		local buttonSign = UIElement:new({
			parent = tbTutorialsContinueButton,
			pos = { tbTutorialsContinueButton.size.w / 2, tbTutorialsContinueButton.size.w / 2 },
			size = { tbTutorialsContinueButton.size.w / 4, tbTutorialsContinueButton.size.h / 4 },
			bgColor = UICOLORWHITE
		})
		buttonSign:addCustomDisplay(true, function()
				set_color(unpack(buttonSign.bgColor))
				draw_disk(buttonSign.pos.x, buttonSign.pos.y, 0, buttonSign.size.h, 3, 1, 90, 360, 0)
			end)

		local tutorialProgress = UIElement:new({
			parent = tbTutorialsOverlay,
			pos = { 0, -5 },
			size = { tbTutorialsOverlay.size.w, 5 },
			bgColor = { 1, 1, 1, 0.5 }
		})
		local step = tbTutorialCurrentStep
		tutorialProgress:addCustomDisplay(false, function()
				if (step < tbTutorialCurrentStep) then
					step = step + 0.05
				end
				set_color(unpack(TB_MENU_DEFAULT_BG_COLOR))
				draw_quad(tutorialProgress.pos.x, tutorialProgress.pos.y, tutorialProgress.size.w / tbTutorialTotalSteps * step, tutorialProgress.size.h)
			end)
	end

	function Tutorials:getNavigationButtons(showBack)
		local buttonsData = {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
				action = function()
						tbMenuCurrentSection:kill(true)
						tbMenuNavigationBar:kill(true)
						TBMenu:showNavigationBar()
						TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
					end,
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, FONTS.BIG) * 0.65 + 30
			}
		}
		if (showBack) then
			table.insert(buttonsData, {
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function() end,
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONBACK, FONTS.BIG) * 0.65 + 30
			})
		end
		return buttonsData
	end

	function Tutorials:getAllTutorials()
		return {
			{
				id = 1,
				title = TB_MENU_LOCALIZED.TUTORIALSINTRONAME,
				subtitle = TB_MENU_LOCALIZED.TUTORIALSINTRODESC,
			},
			{
				id = 2,
				title = TB_MENU_LOCALIZED.TUTORIALSPUNCHNAME,
				subtitle = TB_MENU_LOCALIZED.TUTORIALSPUNCHDESC,
			},
			{
				id = 3,
				title = TB_MENU_LOCALIZED.TUTORIALSKICKNAME,
				subtitle = TB_MENU_LOCALIZED.TUTORIALSKICKDESC,
			},
			{
				id = 4,
				title = TB_MENU_LOCALIZED.TUTORIALSCHALLENGEUKENAME,
				subtitle = TB_MENU_LOCALIZED.TUTORIALSCHALLENGEUKEDESC,
			},
			{
				id = 5,
				title = TB_MENU_LOCALIZED.TUTORIALSCOMEBACKPRACTICENAME,
				subtitle = TB_MENU_LOCALIZED.TUTORIALSCOMEBACKPRACTICEDESC,
			}
		}
	end

	function Tutorials:showAllTutorials(featuredTutorial)
		local tutorials = Tutorials:getAllTutorials()
		local size = 1 / math.ceil(#tutorials / 2)

		if (#tutorials % 2 == 1) then
			tutorials[featuredTutorial].size = size
			tutorials[featuredTutorial].mode = ORIENTATION_LANDSCAPE
			if (not tutorials[featuredTutorial].image) then
				tutorials[featuredTutorial].image = "../textures/menu/tutorial" .. featuredTutorial .. ".tga"
			end
			if (featuredTutorial % 2 == 0) then
				local temp = cloneTable(tutorials[featuredTutorial])
				tutorials[featuredTutorial] = cloneTable(tutorials[featuredTutorial - 1])
				tutorials[featuredTutorial - 1] = temp
			end
		end
		for i,v in pairs(tutorials) do
			if (not tutorials[i].size) then
				tutorials[i].vsize = 0.5
				tutorials[i].image = nil
				tutorials[i].size = size
			end
			if (i > featuredTutorial and TB_MENU_PLAYER_INFO.data.qi < i * 250) then
				tutorials[i].locked = true
			end
			tutorials[i].action = function() Tutorials:runTutorial(tutorials[i].id) end
			tutorials[i].quit = true
		end
		TBMenu:showSection(tutorials, nil, TB_MENU_LOCALIZED.TUTORIALSLOCKED)
	end

	function Tutorials:getConfig()
		local tutorialsConfig = Files:new("../data/tutorials/config.cfg")
		local nextTutorial, lastTutorial = 1, 1
		if (tutorialsConfig.data) then
			for i, ln in pairs(tutorialsConfig:readAll()) do
				if (ln:find("^LAST")) then
					lastTutorial = ln:gsub("^LAST ", "") + 0
				elseif (ln:find("^NEXT")) then
					nextTutorial = ln:gsub("^NEXT ", "") + 0
				end
			end
			tutorialsConfig:close()
		end
		return nextTutorial, lastTutorial
	end

	function Tutorials:getMainMenuButtons()
		local tutorials = Tutorials:getAllTutorials()
		local nextTutorial, lastTutorial = Tutorials:getConfig()
		local allTutorialsNext = nextTutorial
		if (nextTutorial == 5 and lastTutorial >= 4) then
			nextTutorial = 4
			lastTutorial = 5
		elseif (lastTutorial == 1) then
			lastTutorial = nextTutorial
		end

		local mainTutorialButton = {
			title = tutorials[nextTutorial].title,
			subtitle = tutorials[nextTutorial].subtitle,
			image = tutorials[nextTutorial].image or "../textures/menu/tutorial" .. nextTutorial .. ".tga",
			mode = ORIENTATION_LANDSCAPE,
			size = 0.47,
			action = function() Tutorials:runTutorial(nextTutorial) end,
			quit = true
		}
		local lastTutorialButton = {
			title = tutorials[lastTutorial].title,
			subtitle = tutorials[lastTutorial].subtitle,
			image = tutorials[lastTutorial].smallimage or "../textures/menu/tutorial" .. lastTutorial .. "_small.tga",
			mode = ORIENTATION_PORTRAIT,
			size = 0.235,
			action = function() Tutorials:runTutorial(lastTutorial) end,
			quit = true
		}
		local allTutorialsButton = {
			title = TB_MENU_LOCALIZED.TUTORIALSVIEWALLNAME,
			subtitle = TB_MENU_LOCALIZED.TUTORIALSVIEWALLDESC,
			image = "../textures/menu/tutorials_all_small.tga",
			mode = ORIENTATION_LANDSCAPE_SHORTER,
			size = 0.295,
			action = function()
				TBMenu:clearNavSection()
				Tutorials:showAllTutorials(allTutorialsNext)
				TBMenu:showNavigationBar(Tutorials:getNavigationButtons(), true)
			end,
		}

		if (lastTutorial ~= nextTutorial) then
			return {
				mainTutorialButton,
				lastTutorialButton,
				allTutorialsButton
			}
		else
			mainTutorialButton.size = 0.5
			allTutorialsButton.image = "../textures/menu/tutorials_all.tga"
			allTutorialsButton.mode = ORIENTATION_LANDSCAPE
			allTutorialsButton.size = 0.5
			return {
				mainTutorialButton,
				allTutorialsButton
			}
		end
	end

	function Tutorials:loadHooks()
		add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y)
				UIElement:handleMouseDn(s, x, y)
				if (TUTORIALJOINTLOCK or (not TUTORIALJOINTLOCK and TUTORIALKEYBOARDLOCK)) then
					return Tutorials:ignoreMouseClick()
				end
			end)
		add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
		add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
		add_hook("key_down", "tbTutorialKeyboardHandler", function(key)
				return Tutorials:ignoreKeyPress(key, true, true)
			end)
		add_hook("key_up", "tbTutorialKeyboardHandler", function(key)
				if (key == 13) then
					if (tbTutorialsContinueButton.isactive) then
						if (tbTutorialsContinueButton.req.ready ~= nil) then
							tbTutorialsContinueButton.req.ready = true
							tbTutorialsContinueButton.reqTable.ready = checkRequirements(tbTutorialsContinueButton.reqTable)
							tbTutorialsContinueButton:deactivate()
						end
					end
				else
					return Tutorials:ignoreKeyPress(key, true)
				end
			end)

		add_hook("draw2d", "tbTutorialsVisual", function()
				if (TB_MENU_MAIN_ISOPEN == 0) then
					UIElement:drawVisuals(TB_TUTORIAL_MODERN_GLOBALID)
				end
			end)
		add_hook("draw3d", "tbTutorialsVisual", function()
				if (TB_MENU_MAIN_ISOPEN == 0) then
					UIElement3D:drawVisuals(TB_TUTORIAL_MODERN_GLOBALID)
				end
			end)
		add_hook("draw_viewport", "tbTutorialsVisual", function()
				if (TB_MENU_MAIN_ISOPEN == 0) then
					UIElement:drawViewport(TB_TUTORIAL_MODERN_GLOBALID)
				end
			end)

		add_hook("leave_game", "tbTutorialsVisual", function()
				if (not TUTORIAL_LEAVEGAME and TB_MENU_MAIN_ISOPEN == 0) then
					Tutorials:quitPopup()
				end
			end)
		add_hook("console", "tbTutorialsVisual", function(message, type)
				return 1
			end)
	end
end
