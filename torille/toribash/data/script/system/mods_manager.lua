-- Mods manager

MODS_MENU_POS = MODS_MENU_POS or { x = 10, y = 10 }
MODS_LIST_SHIFT = MODS_LIST_SHIFT or { 0 }
MODS_MENU_LAST_CLICKED = nil
MODS_MENU_START_NEW_GAME = MODS_MENU_START_NEW_GAME == nil and true or MODS_MENU_START_NEW_GAME

do
	Mods = {}
	Mods.__index = Mods
	local cln = {}
	setmetatable(cln, Mods)

	function Mods:getModFiles(path)
		local path = path or "data/mod"
		local data = { name = path, mods = {}, folders = {}, contents = {} }
		for i,v in pairs(get_files(path, "")) do
			if (v:match(".tbm$")) then
				table.insert(data.mods, v)
			elseif (not v:find("^%.+[%s%S]*$") and v ~= "system" and v ~= "modmaker_draft" and not v:find("%.%a+$")) then
				local v = v:sub(0, 1):upper() .. v:sub(2)
				table.insert(data.folders, v)
				data.contents[#data.folders] = Mods:getModFiles(path .. "/" .. v, fullsearch)
				data.contents[#data.folders].parent = data
			end
		end
		return data
	end

	function Mods:spawnMainList(listingHolder, toReload, topBar, elementHeight, data, search)
		if (listingHolder.scrollBar) then
			listingHolder.scrollBar:kill()
		end
		listingHolder:kill(true)
		listingHolder:moveTo(nil, 0)
		topBar:kill(true)
		local modsFolderName = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w - 20, topBar.size.h }
		})
		modsFolderName:addAdaptedText(true, data.name:gsub("^data/mod", "Mods"):gsub("/", " :: "), nil, nil, FONTS.BIG, nil, 0.6)

		local searchString = search.textfieldstr[1]
		local listElements = {}
		CURRENT_MOD_FOLDER = data

		if (data.name ~= "data/mod" or searchString ~= "") then
			local default = UIElement:new({
				parent = listingHolder,
				pos = { 0, 0 },
				size = { listingHolder.size.w, elementHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			table.insert(listElements, default)
			local defaultIcon = UIElement:new({
				parent = default,
				pos = { 5, 0 },
				size = { elementHeight, elementHeight },
				bgImage = "../textures/menu/general/back.tga"
			})
			local defaultText = UIElement:new({
				parent = default,
				pos = { elementHeight, 0 },
				size = { default.size.w - elementHeight, elementHeight }
			})
			defaultText:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK, 10, nil, 4, LEFTMID, 0.8, 0.8)
			default:addMouseHandlers(nil, function()
					search:clearTextfield()
					Mods:spawnMainList(listingHolder, toReload, topBar, elementHeight, data.parent and data.parent or data, search)
				end)
		end

		local modmakerId = 0
		for i, folder in pairs(data.folders) do
			if (folder == "modmaker") then
				modmakerId = i
			else
				local element = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
				})
				element:addAdaptedText(false, folder, elementHeight + 15, nil, 4, LEFTMID, 0.8, 0.8)
				element:addMouseHandlers(nil, function()
						search:clearTextfield()
						Mods:spawnMainList(listingHolder, toReload, topBar, elementHeight, data.contents[i], search)
					end)
				local folderIcon = UIElement:new({
					parent = element,
					pos = { 10, 0 },
					size = { elementHeight, elementHeight },
					bgImage = "../textures/menu/general/folder.tga"
				})
				local inserted = false
				if (searchString ~= "") then
					for i, file in pairs(data.contents[i].mods) do
						if (file:lower():find(searchString)) then
							if (not inserted) then
								inserted = true
								table.insert(listElements, element)
							end
							local element = UIElement:new({
								parent = listingHolder,
								pos = { 0, #listElements * elementHeight },
								size = { listingHolder.size.w, elementHeight },
								interactive = true,
								bgColor = TB_MENU_DEFAULT_BG_COLOR,
								hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
								pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
							})
							local elementIcon = UIElement:new({
								parent = element,
								pos = { elementHeight, 0 },
								size = { elementHeight / 2, elementHeight },
								bgImage = "../textures/menu/general/buttons/arrowright.tga"
							})
							table.insert(listElements, element)
							element:addAdaptedText(false, file:gsub("%.tbm$", ""), elementHeight * 1.5 + 5, nil, 4, LEFTMID, 0.8, 0.8)
							element:addMouseHandlers(nil, function()
									if (not MODS_MENU_LAST_CLICKED) then
										MODS_MENU_LAST_CLICKED = { time = os.clock(), mod = file }
									elseif (MODS_MENU_LAST_CLICKED.time + 0.5 > os.clock() and MODS_MENU_LAST_CLICKED.mod == file) then
										UIElement:runCmd("loadmod " .. file)
										if (MODS_MENU_START_NEW_GAME and get_world_state().game_type == 1) then
											UIElement:runCmd("reset")
										end
									else
										MODS_MENU_LAST_CLICKED = { time = os.clock(), mod = file }
									end
								end)
						end
					end
					if (not inserted) then
						element:kill()
					end
				else
					table.insert(listElements, element)
				end
			end
		end
		for i, file in pairs(data.mods) do
			if (file:lower():find(searchString)) then
				local element = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
				})
				table.insert(listElements, element)
				element:addAdaptedText(false, file:gsub("%.tbm$", ""), 10, nil, 4, LEFTMID, 0.8, 0.8)
				element:addMouseHandlers(nil, function()
						if (not MODS_MENU_LAST_CLICKED) then
							MODS_MENU_LAST_CLICKED = { time = os.clock(), mod = file }
						elseif (MODS_MENU_LAST_CLICKED.time + 0.5 > os.clock() and MODS_MENU_LAST_CLICKED.mod == file) then
							UIElement:runCmd("loadmod " .. file)
							if (MODS_MENU_START_NEW_GAME and get_world_state().game_type == 1) then
								UIElement:runCmd("reset")
							end
						else
							MODS_MENU_LAST_CLICKED = { time = os.clock(), mod = file }
						end
					end)
			end
		end
		if (modmakerId > 0) then
			local element = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			element:addAdaptedText(false, data.folders[modmakerId], elementHeight + 15, nil, 4, LEFTMID, 0.8, 0.8)
			element:addMouseHandlers(nil, function()
					search:clearTextfield()
					Mods:spawnMainList(listingHolder, toReload, topBar, elementHeight, data.contents[modmakerId], search)
				end)
			local folderIcon = UIElement:new({
				parent = element,
				pos = { 10, 0 },
				size = { elementHeight, elementHeight },
				bgImage = "../textures/menu/general/folder.tga"
			})
			local inserted = false
			if (searchString ~= "") then
				for i, file in pairs(data.contents[modmakerId].mods) do
					if (file:lower():find(searchString)) then
						if (not inserted) then
							inserted = true
							table.insert(listElements, element)
						end
						local element = UIElement:new({
							parent = listingHolder,
							pos = { 0, #listElements * elementHeight },
							size = { listingHolder.size.w, elementHeight },
							interactive = true,
							bgColor = TB_MENU_DEFAULT_BG_COLOR,
							hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
							pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
						})
						local elementIcon = UIElement:new({
							parent = element,
							pos = { elementHeight, 0 },
							size = { elementHeight / 2, elementHeight },
							bgImage = "../textures/menu/general/buttons/arrowright.tga"
						})
						table.insert(listElements, element)
						element:addAdaptedText(false, file:gsub("%.tbm$", ""), elementHeight * 1.5 + 5, nil, 4, LEFTMID, 0.8, 0.8)
						element:addMouseHandlers(nil, function()
								if (not MODS_MENU_LAST_CLICKED) then
									MODS_MENU_LAST_CLICKED = { time = os.clock(), mod = file }
								elseif (MODS_MENU_LAST_CLICKED.time + 0.5 <= os.clock() and MODS_MENU_LAST_CLICKED.mod == file) then
									UIElement:runCmd("loadmod " .. file)
									if (MODS_MENU_START_NEW_GAME and get_world_state().game_type == 1) then
										UIElement:runCmd("reset")
									end
								else
									MODS_MENU_LAST_CLICKED = { time = os.clock(), mod = file }
								end
							end)
					end
				end
				if (not inserted) then
					element:kill()
				end
			else
				table.insert(listElements, element)
			end
		end
		if (#listElements == 0) then
			local element = UIElement:new({
				parent = listingHolder,
				pos = { 0, 0 },
				size = { listingHolder.size.w, listingHolder.size.h },
			})
			table.insert(listElements, element)
			element:addAdaptedText(false, TB_MENU_LOCALIZED.NOFILESFOUND .. " :(")
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		scrollBar:makeScrollBar(listingHolder, listElements, toReload, MODS_LIST_SHIFT)
	end

	function Mods:showMain()
		local mainView = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { MODS_MENU_POS.x, MODS_MENU_POS.y },
			size = { WIN_W / 4, WIN_H / 4 * 3 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		MODS_MENU_MAIN_ELEMENT = mainView
		MODS_MENU_POS = mainView.pos
		local mainMoverHolder = UIElement:new({
			parent = mainView,
			pos = { 0, 0 },
			size = { mainView.size.w, 30 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = mainView.shapeType,
			rounded = mainView.rounded
		})
		local mainMover = UIElement:new({
			parent = mainMoverHolder,
			pos = { 0, 0 },
			size = { mainMoverHolder.size.w, mainMoverHolder.size.h },
			interactive = true,
			bgColor = UICOLORWHITE,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		mainMover:addCustomDisplay(true, function()
				set_color(unpack(mainMover:getButtonColor()))
				local posX = mainMover.pos.x + mainMover.size.w / 2 - 15
				draw_quad(posX, mainMover.pos.y + 10, 30, 2)
				draw_quad(posX, mainMover.pos.y + 18, 30, 2)
			end)
		mainMover:addMouseHandlers(function(s, x, y)
					mainMover.pressedPos.x = x - mainMover.pos.x
					mainMover.pressedPos.y = y - mainMover.pos.y
				end, nil, function(x, y)
				if (mainMover.hoverState == BTN_DN) then
					local x = x - mainMover.pressedPos.x
					local y = y - mainMover.pressedPos.y
						x = x < 0 and 0 or (x + mainView.size.w > WIN_W and WIN_W - mainView.size.w or x)
					y = y < 0 and 0 or (y + mainView.size.h > WIN_H and WIN_H - mainView.size.h or y)
					mainView:moveTo(x, y)
				end
			end)

		local modNewGameToggleView = UIElement:new({
			parent = mainView,
			pos = { 0, -35 },
			size = { mainView.size.w, 30 }
		})
		local modNewGameToggleBG = UIElement:new({
			parent = modNewGameToggleView,
			pos = { 5, 2 },
			size = { modNewGameToggleView.size.h - 4, modNewGameToggleView.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local modNewGameToggle = UIElement:new({
			parent = modNewGameToggleBG,
			pos = { 1, 1 },
			size = { modNewGameToggleBG.size.w - 2, modNewGameToggleBG.size.h - 2 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		local modNewGameToggleIcon = UIElement:new({
			parent = modNewGameToggle,
			pos = { 0, 0 },
			size = { modNewGameToggle.size.w, modNewGameToggle.size.h },
			bgImage = "../textures/menu/general/buttons/checkmark.tga"
		})
		if (not MODS_MENU_START_NEW_GAME) then
			modNewGameToggleIcon:hide()
		end
		modNewGameToggle:addMouseHandlers(nil, function()
				MODS_MENU_START_NEW_GAME = not MODS_MENU_START_NEW_GAME
				if (not MODS_MENU_START_NEW_GAME) then
					modNewGameToggleIcon:hide()
				else
					modNewGameToggleIcon:show()
				end
			end)
		local modNewGameText = UIElement:new({
			parent = modNewGameToggleView,
			pos = { modNewGameToggleBG.shift.x * 2 + modNewGameToggleBG.size.w, 0 },
			size = { modNewGameToggleView.size.w - modNewGameToggleBG.shift.x * 3 - modNewGameToggleBG.size.w, modNewGameToggleView.size.h }
		})
		modNewGameText:addAdaptedText(true, TB_MENU_LOCALIZED.MODSRESTARTGAME, nil, nil, 4, LEFTMID)
		--[[local modDownloadHolder = UIElement:new({
			parent = mainView,
			pos = { 0, -55 },
			size = { mainView.size.w, 55 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local modDownloadButton = UIElement:new({
			parent = modDownloadHolder,
			pos = { 5, 10 },
			size = { modDownloadHolder.size.w - 10, modDownloadHolder.size.h - 15 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			shapeType = ROUNDED,
			rounded = 5
		})
		modDownloadButton:addAdaptedText(false, "Get more mods")
		modDownloadButton:addMouseHandlers(nil, function()
			end)]]

		local mainList = UIElement:new({
			parent = mainView,
			pos = { 0, mainMoverHolder.size.h },
			size = { mainView.size.w, mainView.size.h - mainMoverHolder.size.h - modNewGameToggleView.size.h - 5 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local elementHeight = 25
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(mainList, 50, 35, 15)

		add_hook("key_up", "tbModsKeyboard", function(s) return(UIElement:handleKeyUp(s)) end)
		add_hook("key_down", "tbModsKeyboard", function(s) return(UIElement:handleKeyDown(s)) end)
		local search = TBMenu:spawnTextField(botBar, 5, 5, botBar.size.w - 10, botBar.size.h - 10, nil, nil, 1, nil, nil, TB_MENU_LOCALIZED.SEARCHNOTE)
		search:addKeyboardHandlers(nil, function()
				MODS_LIST_SHIFT[1] = 0
				Mods:spawnMainList(listingHolder, toReload, topBar, elementHeight, CURRENT_MOD_FOLDER, search)
			end)
		CURRENT_MOD_FOLDER = Mods:getModFiles()
		Mods:spawnMainList(listingHolder, toReload, topBar, elementHeight, CURRENT_MOD_FOLDER, search)

		local quitButton = UIElement:new({
			parent = mainMoverHolder,
			pos = { -mainMoverHolder.size.h, 0 },
			size = { mainMoverHolder.size.h , mainMoverHolder.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			shapeType = ROUNDED,
			rounded = 4
		})
		local quitIcon = UIElement:new({
			parent = quitButton,
			pos = { 2, 2 },
			size = { quitButton.size.w - 4, quitButton.size.h - 4 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		quitButton:addMouseHandlers(nil, function()
				remove_hooks("tbModsKeyboard")
				mainView:kill()
				MODS_MENU_MAIN_ELEMENT = nil
			end)
	end
end
