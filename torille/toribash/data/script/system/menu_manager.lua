-- modern main menu manager class
-- DO NOT MODIFY THIS FILE

dofile("system/menu_defines.lua")

ORIENTATION_PORTRAIT = 1
ORIENTATION_LANDSCAPE = 2
ORIENTATION_LANDSCAPE_SHORTER = 3
BLURENABLED = false

TB_MENU_LANGUAGE = TB_MENU_LANGUAGE or nil
TB_MENU_LOCALIZED = TB_MENU_LOCALIZED or {}

TB_MENU_IGNORE_REWARDS = 0

--Global objects
tbMenuMain = nil -- base parent element
tbMenuCurrentSection = nil -- parent element for current section items
tbMenuNavigationBar = nil -- parent element for navbar
tbMenuBottomRightBar = nil -- parent element for bottom right bar
tbMenuBottomLeftBar = nil -- parent element for bottom left bar

do
	TBMenu = {}
	TBMenu.__index = TBMenu
	local cln = {}
	setmetatable(cln, TBMenu)

	function TBMenu:create()
		TB_MENU_MAIN_ISOPEN = 1
	end

	function TBMenu:setLanguageFontOptions(language)
		if (language == "hebrew") then
			FONTS.BIG = 4
			FONTS.MEDIUM = 4
			LEFT = 2
			LEFTBOT = 5
			LEFTMID = 8
		else
			-- Scaling for huge screens
			if (WIN_W * WIN_H > 2000000) then
				UI_HIGH_RESOLUTION_MODE = true
			else
				UI_HIGH_RESOLUTION_MODE = false
			end
			FONTS.BIG = 0
			FONTS.MEDIUM = 2
			LEFT = 0
			LEFTBOT = 3
			LEFTMID = 6
		end
	end

	function TBMenu:getTranslation(language)
		local language = language or "english"
		TBMenu:setLanguageFontOptions(language)
		if (TB_MENU_LOCALIZED.language ~= language or TB_MENU_DEBUG) then
			TB_MENU_LOCALIZED.language = language
		else
			return
		end

		local file = io.open("data/script/system/language/" .. language .. ".txt", "r", 1)
		if (not file) then
			file = io.open("data/script/system/language/english.txt", "r", 1)
			if (not file) then
				echo("^04Localization file not found, exiting main menu")
				TBMenu:quit()
				set_option("newmenu", 0)
				return
			end
		end

		for ln in file:lines() do
			if (not ln:match("^#")) then
				local data_stream = { ln:match(("([^\t]*)\t"):rep(2)) }
				TB_MENU_LOCALIZED[data_stream[1]] = data_stream[2]
			end
		end
		file:close()

		if (language ~= "english") then
			-- Make sure there's no missing values
			local file = io.open("data/script/system/language/english.txt", "r", 1)
			for ln in file:lines() do
				if (not ln:match("^#")) then
					local data_stream = { ln:match(("([^\t]*)\t"):rep(2)) }
					if (not TB_MENU_LOCALIZED[data_stream[1]]) then
						TB_MENU_LOCALIZED[data_stream[1]] = data_stream[2]
					end
				end
			end
			file:close()
		end
	end

	function TBMenu:quit()
		remove_hooks("tbMainMenuVisual")
		remove_hooks("tbMainMenuMouse")
		remove_hooks("tbMenuConsoleIgnore")
		remove_hooks("tbMenuKeyboardHandler")
		
		enable_camera_movement()
		disable_blur()
		disable_menu_keyboard()
		chat_input_activate()
		
		TB_MENU_MAIN_ISOPEN = 0
		tbMenuMain:kill()
	end

	function TBMenu:createCurrentSectionView()
		tbMenuCurrentSection = UIElement:new( {
			parent = tbMenuMain,
			pos = { 75, 140 + WIN_H / 16 },
			size = { WIN_W - 150, WIN_H - 250 - WIN_H / 16 }
		})
	end

	-- Get image based on screen and element size
	function TBMenu:getImageDimensions(width, height, ratio, shift1, shift2)
		local elementWidth = width - 20
		if (elementWidth * ratio > height - 20) then
			elementWidth = (height - 20) / ratio
		end
		local elementHeight = elementWidth * ratio
		if (elementHeight + shift1 + shift2 <= height - 20) then
			return { elementWidth, elementHeight, 0 }
		elseif (elementHeight + shift2 <= height - 20) then
			return { elementWidth, elementHeight, shift1 }
		else
			return { elementWidth, elementHeight, shift1 + shift2 }
		end
		return { elementWidth, elementHeight, heightShift }
	end

	function TBMenu:createImageButtons(parentElement, x, y, w, h, img, imgHvr, imgPress, col, colHvr, colPress, round)
		if (not parentElement or not x or not y or not w or not h or not img) then
			return false
		end
		local imgHvr = imgHvr or img
		local imgPress = imgPress or img
		local col = col or nil
		local colHvr = colHvr or col
		local colPress = colPress or colHvr
		local round = round or nil
		local buttonMain = UIElement:new( {
			parent = parentElement,
			pos = { x, y },
			size = { w, h },
			interactive = true,
			bgColor = col,
			hoverColor = colHvr,
			pressedColor = colPress,
			hoverSound = 31,
			shapeType = round and ROUNDED or SQUARE,
			rounded = round and round or 0
		})
		local buttonImage = UIElement:new( {
			parent = buttonMain,
			pos = { 0, 0 },
			size = { 0, 0 },
			bgImage = img
		})
		buttonImage:addCustomDisplay(true, function() end)
		local buttonImageHover = UIElement:new( {
			parent = buttonMain,
			pos = { 0, 0 },
			size = { 0, 0 },
			bgImage = imgHvr
		})
		buttonImageHover:addCustomDisplay(true, function() end)
		local buttonImagePress = UIElement:new( {
			parent = buttonMain,
			pos = { 0, 0 },
			size = { 0, 0 },
			bgImage = imgPress
		})
		buttonImagePress:addCustomDisplay(true, function()
				if (buttonMain.hoverState == false) then
					draw_quad(buttonMain.pos.x, buttonMain.pos.y, buttonMain.size.w, buttonMain.size.h, buttonImage.bgImage)
				elseif (buttonMain.hoverState == BTN_HVR) then
					draw_quad(buttonMain.pos.x, buttonMain.pos.y, buttonMain.size.w, buttonMain.size.h, buttonImageHover.bgImage)
				elseif (buttonMain.hoverState == BTN_DN) then
					draw_quad(buttonMain.pos.x, buttonMain.pos.y, buttonMain.size.w, buttonMain.size.h, buttonImagePress.bgImage)
				end
			end)
		return buttonMain
	end

	function TBMenu:changeCurrentEvent(viewElement, eventsData, eventItems, clock, reloadElement, direction)
		for i, v in pairs(eventItems) do
			if (i == TB_MENU_HOME_CURRENT_ANNOUNCEMENT) then
				v.image:hide()
				TB_MENU_HOME_CURRENT_ANNOUNCEMENT = TB_MENU_HOME_CURRENT_ANNOUNCEMENT + direction
				if (TB_MENU_HOME_CURRENT_ANNOUNCEMENT > #eventItems) then
					TB_MENU_HOME_CURRENT_ANNOUNCEMENT = TB_MENU_HOME_CURRENT_ANNOUNCEMENT - #eventItems
				elseif (TB_MENU_HOME_CURRENT_ANNOUNCEMENT < 1) then
					TB_MENU_HOME_CURRENT_ANNOUNCEMENT = #eventItems
				end
				eventItems[TB_MENU_HOME_CURRENT_ANNOUNCEMENT].image:show()
				local function behavior()
					eventsData[TB_MENU_HOME_CURRENT_ANNOUNCEMENT].action()
					if (eventsData[TB_MENU_HOME_CURRENT_ANNOUNCEMENT].stop) then
						clock.pause = true
					end
				end
				viewElement:addMouseHandlers(nil, behavior, nil)
				reloadElement:reload()
				local tickTime = os.clock() * 10
				clock.start = math.floor(tickTime)
				clock.last = math.floor(tickTime)
				clock.pause = false
				break
			end
		end
	end

	-- Stores and displays event announcements with timed rotation
	function TBMenu:showEvents(viewElement)
		-- Table to store event announcement data
		local eventsData = {
			{
				title = "Head Texture of the Month: Ocean",
				subtitle = "The Ocean has many interesting creatures dwelling within - show us your favorite!",
				image = "../textures/menu/promo/htotmocean.tga",
				stop = true,
				action = function()
						Events:showEventInfo(1)
					end,
			},
			{
				title = "Clan Outreach",
				subtitle = "We're trying to make Toribash clans better - and we need your opinions on it",
				image = "../textures/menu/promo/clanoutreach.tga",
				action = function()
						open_url("http://forum.toribash.com/showthread.php?t=624019")
					end,
			},
		}

		--[[if (TB_MENU_PLAYER_INFO.data.qi < 500 and TB_MENU_PLAYER_INFO.clan.id == 0 and TB_MENU_PLAYER_INFO.username ~= "") then
			local clanModifier = string.byte(TB_MENU_PLAYER_INFO.username) % 2
			local clan = {
				name = clanModifier == 0 and "Blue" or "Red",
				texture = clanModifier == 0 and "../textures/menu/promo/blueclan.tga" or "../textures/menu/promo/redclan.tga"
			}
			table.insert(eventsData, 1, {
				title = "Join Clan (" .. clan.name .. ")!",
				subtitle = "A beginner clan that will help you find new Toribash friends and understand the game is always open for joining!",
				image = clan.texture,
				action = function()
						TBMenu:showClans(clan.name)
					end
			})
		end]]

		-- Store all elements that would require reloading when switching event announcements in one table
		local toReload = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})

		-- Create bottom splat
		local eventButtonSplat = TBMenu:addBottomBloodSmudge(toReload, 1)

		local textHeight, descHeight = viewElement.size.h / 9, viewElement.size.h / 8
		local elementWidth, elementHeight, heightShift = unpack(TBMenu:getImageDimensions(viewElement.size.w, viewElement.size.h, 0.5, textHeight, descHeight))
		-- Spawn event announcement elements
		local eventItems = {}
		for i, v in pairs (eventsData) do
			local titleTextScale, subtitleTextScale = 1, 1
			eventItems[i] = {}
			eventItems[i].image = UIElement:new( {
				parent = viewElement,
				pos = { (viewElement.size.w - elementWidth) / 2, 10 },
				size = { elementWidth, elementHeight },
				bgImage = v.image
			})
			eventItems[i].button = UIElement:new( {
				parent = eventItems[i].image,
				pos = { 0, eventItems[i].image.size.h - heightShift },
				size = { eventItems[i].image.size.w, textHeight + descHeight }
			})
			local textColor, descColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR), cloneTable(TB_MENU_DEFAULT_BG_COLOR)
			textColor[4] = 0.8
			descColor[4] = 0.8
			if (heightShift == textHeight) then
				descColor = nil
			elseif (heightShift == 0) then
				descColor, textColor = nil, nil
			end
			eventItems[i].titleView = UIElement:new( {
				parent = eventItems[i].button,
				pos = { 0, 0 },
				size = { eventItems[i].button.size.w, textHeight },
				bgColor = textColor
			})
			eventItems[i].title = UIElement:new( {
				parent = eventItems[i].titleView,
				pos = { 10, 5 },
				size = { eventItems[i].titleView.size.w - 20, eventItems[i].titleView.size.h - 10 }
			})
			while (not eventItems[i].title:uiText(v.title, nil, nil, 0, 0, titleTextScale, nil, nil, nil, nil, nil, true)) do
				titleTextScale = titleTextScale - 0.05
			end
			eventItems[i].title:addCustomDisplay(false, function()
					eventItems[i].title:uiText(v.title, nil, nil, 0, 0, titleTextScale)
				end)
			eventItems[i].subtitleView = UIElement:new( {
				parent = eventItems[i].button,
				pos = { 0, textHeight },
				size = { eventItems[i].button.size.w, descHeight },
				bgColor = descColor
			})
			eventItems[i].subtitle = UIElement:new( {
				parent = eventItems[i].subtitleView,
				pos = { 10, 5 },
				size = { eventItems[i].subtitleView.size.w - 20, eventItems[i].subtitleView.size.h }
			})
			eventItems[i].subtitle:addAdaptedText(true, v.subtitle, nil, nil, 4, LEFT)
			if (i ~= TB_MENU_HOME_CURRENT_ANNOUNCEMENT) then
				eventItems[i].image:hide()
			end
		end

		if (#eventsData > 1) then
			-- Spawn progress bar before next/prev buttons
			local eventDisplayTime = UIElement:new( {
				parent = toReload,
				pos = {0, 0},
				size = {0, 0}
			})

			-- Auto-rotate event announcements
			local rotateTime = 100
			local tickTime = os.clock() * 10
			local rotateClock = { start = math.floor(tickTime), last = math.floor(tickTime) }
			eventDisplayTime:addCustomDisplay(true, function()
					if (not rotateClock.pause) then
						set_color(1,1,1,1)
						draw_quad(eventItems[1].button.pos.x, eventItems[1].button.pos.y - 5, (os.clock() * 10 - rotateClock.start) % rotateTime / rotateTime * eventItems[1].button.size.w, 5)
					end
				end)
			viewElement:addCustomDisplay(false, function()
					if ((math.floor(os.clock() * 10) - rotateClock.start) % rotateTime == 0 and math.floor(os.clock() * 10) ~= rotateClock.last and not rotateClock.pause) then
						TBMenu:changeCurrentEvent(viewElement, eventsData, eventItems, rotateClock, toReload, 1)
					end
				end)
				
			-- Manual announcement change
			local eventPrevButton = TBMenu:createImageButtons(toReload, 10, toReload.size.h / 2 - 32, 32, 64, "../textures/menu/general/buttons/arrowleft.tga", nil, nil, { 0, 0, 0, 0 }, { 0, 0, 0, 0.7 })
			eventPrevButton:addMouseHandlers(nil, function()
					TBMenu:changeCurrentEvent(viewElement, eventsData, eventItems, rotateClock, toReload, -1)
				end, nil)
			local eventNextButton = TBMenu:createImageButtons(toReload, toReload.size.w - 42, toReload.size.h / 2 - 32, 32, 64, "../textures/menu/general/buttons/arrowright.tga", nil, nil, { 0, 0, 0, 0 }, { 0, 0, 0, 0.7 })
			eventNextButton:addMouseHandlers(nil, function()
					TBMenu:changeCurrentEvent(viewElement, eventsData, eventItems, rotateClock, toReload, 1)
				end, nil)
			
			-- Set event button behavior
			local function behavior()
				eventsData[TB_MENU_HOME_CURRENT_ANNOUNCEMENT].action()
				if (eventsData[TB_MENU_HOME_CURRENT_ANNOUNCEMENT].stop and rotateClock) then
					rotateClock.pause = true
				end
			end
			viewElement:addMouseHandlers(nil, behavior, nil)
		else
			local function behavior()
				eventsData[TB_MENU_HOME_CURRENT_ANNOUNCEMENT].action()
			end
		end
	end

	function TBMenu:showHomeButton(viewElement, buttonData, isTorishop)
		local titleHeight, descHeight = viewElement.size.h / 4.5, viewElement.size.h / 5
		local elementWidth, elementHeight, heightShift
		local itemIcon
		if (viewElement.size.h < viewElement.size.w and buttonData.image2) then
			elementWidth, elementHeight, heightShift = unpack(TBMenu:getImageDimensions(viewElement.size.w, viewElement.size.h, buttonData.ratio2, titleHeight, descHeight))
			itemIcon = UIElement:new( {
				parent = viewElement,
				pos = { (viewElement.size.w - elementWidth) / 2, 10 },
				size = { elementWidth, elementHeight },
				bgImage = buttonData.image2
			})
		else
			elementWidth, elementHeight, heightShift = unpack(TBMenu:getImageDimensions(viewElement.size.w, viewElement.size.h, buttonData.ratio, titleHeight, descHeight))
			itemIcon = UIElement:new( {
				parent = viewElement,
				pos = { (viewElement.size.w - elementWidth) / 2, 10 },
				size = { elementWidth, elementHeight },
				bgImage = buttonData.image
			})
		end
		if (isTorishop and itemIcon.size.h > 160 and TB_STORE_DATA.onsale) then
			local shopView = UIElement:new({
				parent = itemIcon,
				pos = { itemIcon.size.w * 0.4, 10 },
				size = { itemIcon.size.w * 0.6 - 10, itemIcon.size.h * 0.45 },
				bgColor = { 0, 0, 0, 0.2 },
			})
			local iconScale = shopView.size.h > 64 and 64 or shopView.size.h
			local tbMenuSaleIcon = UIElement:new({
				parent = shopView,
				pos = { 5, (shopView.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = "../textures/store/items/" .. TB_STORE_DATA.onsale.id .. ".tga"
			})
			local tbMenuSaleName = UIElement:new({
				parent = shopView,
				pos = { iconScale + 10, 0 },
				size = { shopView.size.w - iconScale - 10, shopView.size.h / 2 }
			})
			local tbMenuSaleDiscount = UIElement:new({
				parent = shopView,
				pos = { iconScale + 5, tbMenuSaleName.size.h },
				size = { shopView.size.w - iconScale - 5, shopView.size.h - tbMenuSaleName.size.h }
			})
			local saleDiscount = TB_STORE_DATA.onsale.tcOld ~= 0 and (TB_STORE_DATA.onsale.tcOld - TB_STORE_DATA.onsale.tc) / TB_STORE_DATA.onsale.tcOld * 100 or (TB_STORE_DATA.onsale.usdOld - TB_STORE_DATA.onsale.usd) / TB_STORE_DATA.onsale.usdOld * 100
			saleDiscount = math.floor(saleDiscount)
			tbMenuSaleName:addAdaptedText(true, TB_STORE_DATA.onsale.name, nil, nil, nil, CENTERBOT, nil, nil, nil, 1)
			tbMenuSaleDiscount:addAdaptedText(true, saleDiscount .. "% OFF!", nil, nil, FONTS.BIG, CENTER, 0.6, nil, nil, 1)
		end
		local buttonOverlay = UIElement:new( {
			parent = viewElement,
			pos = { 0, -titleHeight - descHeight - 10 },
			size = { viewElement.size.w, titleHeight + descHeight }
		})
		if (viewElement.size.h + buttonOverlay.shift.y < itemIcon.shift.y + itemIcon.size.h) then
			local overlayColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR)
			overlayColor[4] = 0.9
			local overlay = UIElement:new({
				parent = itemIcon,
				pos = { 0, viewElement.size.h + buttonOverlay.shift.y - itemIcon.shift.y - itemIcon.size.h },
				size = { itemIcon.size.w, -buttonOverlay.shift.y - itemIcon.shift.y - (viewElement.size.h - 20 - itemIcon.size.h) },
				bgColor = overlayColor
			})
		end
		local shopTitleView = UIElement:new( {
			parent = buttonOverlay,
			pos = { 10, 0 },
			size = { buttonOverlay.size.w - 20, titleHeight }
		})
		local shopTitle = UIElement:new( {
			parent = shopTitleView,
			pos = { 5, 5 },
			size = { shopTitleView.size.w - 10, shopTitleView.size.h - 5 }
		})
		shopTitle:addAdaptedText(true, buttonData.title, nil, nil, FONTS.BIG, LEFTBOT, nil, nil, 0.2)
		local shopSubtitleView = UIElement:new( {
			parent = buttonOverlay,
			pos = { 10, titleHeight },
			size = { buttonOverlay.size.w - 20, descHeight }
		})
		local shopSubtitle = UIElement:new( {
			parent = shopSubtitleView,
			pos = { 5, 0 },
			size = { shopSubtitleView.size.w - 10, shopSubtitleView.size.h - 5 }
		})
		shopSubtitle:addAdaptedText(true, buttonData.subtitle, nil, nil, 4, LEFT)
		viewElement:addMouseHandlers(nil, buttonData.action, nil)
	end

	-- Loads home section
	-- Uses custom methods, can't be loaded with showSection() unlike other sections
	function TBMenu:showHome()
		-- Buttons data; doesn't include events section
		local tbMenuHomeButtonsData = {
			shop = {
				title = TB_MENU_LOCALIZED.MAINMENUTORISHOPNAME,
				subtitle = TB_MENU_LOCALIZED.MAINMENUTORISHOPDESC,
				image = "../textures/menu/torishop.tga",
				ratio = 0.435,
				action = function() TBMenu:showTorishopMain() end
			},
			clan = {
				title = TB_MENU_LOCALIZED.MAINMENUCLANSNAME,
				subtitle = TB_MENU_LOCALIZED.MAINMENUCLANSDESC,
				image = "../textures/menu/clansbig.tga",
				image2 = "../textures/menu/clanssmall.tga",
				ratio = 1,
				ratio2 = 0.5,
				action = function() TBMenu:showClans() end
			},
			replays = {
				title = TB_MENU_LOCALIZED.MAINMENUREPLAYSNAME,
				subtitle = TB_MENU_LOCALIZED.MAINMENUREPLAYSDESC,
				image = "../textures/menu/replaysbig.tga",
				image2 = "../textures/menu/replayssmall.tga",
				ratio = 1,
				ratio2 = 0.5,
				action = function() TBMenu:showReplays() end
			}
		}

		-- Base UI element
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		end

		-- Create and load events view
		local tbMenuHomeEventsView = UIElement:new( {
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w * 0.6 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			interactive = true,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverSound = 31
		})
		TBMenu:showEvents(tbMenuHomeEventsView)

		-- Create and load home section buttons
		local tbMenuShopButton = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { tbMenuCurrentSection.size.w * 0.6 + 5, 0 },
			size = { tbMenuCurrentSection.size.w * 0.4 - 10, tbMenuCurrentSection.size.h / 2 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverSound = 31
		})
		TBMenu:showHomeButton(tbMenuShopButton, tbMenuHomeButtonsData.shop, true)
		local tbMenuClansButton = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { tbMenuCurrentSection.size.w * 0.6 + 5, tbMenuCurrentSection.size.h / 2 + 5 },
			size = { tbMenuCurrentSection.size.w * 0.2 - 10, tbMenuCurrentSection.size.h / 2 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverSound = 31
		})
		local tbMenuClansBottomSplat = TBMenu:addBottomBloodSmudge(tbMenuClansButton, 1)
		TBMenu:showHomeButton(tbMenuClansButton, tbMenuHomeButtonsData.clan)
		local tbMenuReplaysButton = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { tbMenuCurrentSection.size.w * 0.8 + 5, tbMenuCurrentSection.size.h / 2 + 5 },
			size = { tbMenuCurrentSection.size.w * 0.2 - 10, tbMenuCurrentSection.size.h / 2 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverSound = 31
		})
		local tbMenuReplaysBottomSplat = TBMenu:addBottomBloodSmudge(tbMenuReplaysButton, 2)
		TBMenu:showHomeButton(tbMenuReplaysButton, tbMenuHomeButtonsData.replays)
	end

	-- Clears navigation bar and current section element for side modules
	function TBMenu:clearNavSection()
		tbMenuNavigationBar:kill(true)
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		else
			tbMenuCurrentSection:kill(true)
		end
	end

	function TBMenu:showClans(clantag)
		tbMenuBottomLeftBar:hide()
		TBMenu:clearNavSection()
		
		CLANLISTLASTPOS = CLANLISTLASTPOS or { scroll = {}, list = {} }
		
		if (not Clans:getLevelData() or not Clans:getAchievementData() or not Clans:getClanData()) then
			download_clan()
			TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
			TB_MENU_CLANS_OPENCLANID = 0
			TBMenu:showNavigationBar()
			TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
			TBMenu:showDataError(TB_MENU_LOCALIZED.CLANDATALOADERROR)
		else
			Clans:showMain(tbMenuCurrentSection, clantag)
		end
	end

	function TBMenu:showReplays()
		tbMenuBottomLeftBar:hide()
		TBMenu:clearNavSection()

		if (TB_MENU_REPLAYS_ONLINE == 1) then
			local menubg = UIElement:new({
				parent = tbMenuCurrentSection,
				pos = { 5, 0 },
				size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			TBMenu:addBottomBloodSmudge(menubg, 1)
			Replays:getServerReplays()
		else
			Replays:showMain(tbMenuCurrentSection)
		end
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 5
	end

	function TBMenu:showNotifications()
		if (not TB_STORE_DATA.ready) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.STOREDATALOADERROR)
			return
		end
		TBMenu:clearNavSection()
		Notifications:showMain()
	end

	function TBMenu:showScripts()
		TBMenu:clearNavSection()
		Scripts:showMain()
		TBMenu:showNavigationBar(Scripts:getNavigationButtons(), true)
	end

	function TBMenu:showSettings()
		tbMenuBottomLeftBar:hide()
		TBMenu:clearNavSection()
		Settings:showMain()
		TBMenu:showNavigationBar(Settings:getNavigationButtons(), true, true, TB_MENU_SETTINGS_SCREEN_ACTIVE or 1)
	end

	function TBMenu:showFriendsList()
		TBMenu:clearNavSection()
		FriendsList:showMain(tbMenuCurrentSection)
		TBMenu:showNavigationBar(FriendsList:getNavigationButtons(), true)
	end

	function TBMenu:showBounties()
		if (TB_BOUNTIES_DEFINED) then
			TBMenu:clearNavSection()
			Bounty:prepare()
			TBMenu:showNavigationBar(Bounty:getNavigationButtons(), true)
		else
			open_url("http://forum.toribash.com/tori_bounty.php")
		end
	end

	function TBMenu:prepareScrollableList(viewElement, topBarH, botBarH, scrollWidth, accentColor)
		local topBarH = topBarH or 50
		local toReload = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})
		local topBar = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { viewElement.size.w, topBarH },
			interactive = true,
			bgColor = accentColor or TB_MENU_DEFAULT_DARKER_COLOR
		})
		local botBar = UIElement:new({
			parent = toReload,
			pos = { 0, -botBarH },
			size = { viewElement.size.w, botBarH },
			interactive = true,
			bgColor = accentColor or TB_MENU_DEFAULT_DARKER_COLOR
		})
		local listingView = UIElement:new({
			parent = viewElement,
			pos = { 0, topBar.size.h },
			size = { viewElement.size.w, viewElement.size.h - topBar.size.h - botBar.size.h },
			interactive = true
		})
		local listingHolder = UIElement:new({
			parent = listingView,
			pos = { 0, 0 },
			size = { listingView.size.w - scrollWidth, listingView.size.h }
		})
		local listingScrollBG = UIElement:new({
			parent = listingView,
			pos = { -scrollWidth, 0 },
			size = { scrollWidth, listingView.size.h },
			bgColor = accentColor or TB_MENU_DEFAULT_DARKER_COLOR
		})
		return toReload, topBar, botBar, listingView, listingHolder, listingScrollBG
	end

	function TBMenu:getTime(seconds, cut)
		local returnval = ""
		local timeleft = 0
		local timetype = ""
		if (math.floor(seconds / 3600 / 24 / 7) > 1) then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEWEEKS
			timeleft = math.floor(seconds / 3600 / 24 / 7)
			seconds = seconds - timeleft * 3600 * 24 * 7
			returnval = timeleft .. " " .. timetype
		end
		if (math.floor(seconds / 3600 / 24 / 7) == 1) then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEWEEK
			timeleft = math.floor(seconds / 3600 / 24 / 7)
			seconds = seconds - timeleft * 3600 * 24 * 7
			returnval = timeleft .. " " .. timetype
		end
		if (math.floor(seconds / 3600 / 24) > 1) then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEDAYS
			timeleft = math.floor(seconds / 3600 / 24)
			seconds = seconds - timeleft * 3600 * 24
			returnval = returnval .. " " .. timeleft .. " " .. timetype
		end
		if (math.floor(seconds / 3600 / 24) == 1) then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEDAY
			timeleft = math.floor(seconds / 3600 / 24)
			seconds = seconds - timeleft * 3600 * 24
			returnval = returnval .. " " .. timeleft .. " " .. timetype
		end
		if (math.floor(seconds / 3600) > 1) then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEHOURS
			timeleft = math.floor(seconds / 3600)
			seconds = seconds - timeleft * 3600
			returnval = returnval .. " " .. timeleft .. " " .. timetype
		end
		if (math.floor(seconds / 3600) == 1) then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEHOUR
			timeleft = math.floor(seconds / 3600)
			seconds = seconds - timeleft * 3600
			returnval = returnval .. " " .. timeleft .. " " .. timetype
		end
		if (math.floor(seconds / 60) > 1) then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEMINUTES
			timeleft = math.floor(seconds / 60)
			seconds = seconds - timeleft * 60
			returnval = returnval .. " " .. timeleft .. " " .. timetype
		end
		if (math.floor(seconds / 60) == 1) then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEMINUTE
			timeleft = math.floor(seconds / 60)
			seconds = seconds - timeleft * 60
			returnval = returnval .. " " .. timeleft .. " " .. timetype
		end
		if (seconds > 0 and timetype == "") then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMESECONDS
			returnval = returnval .. " " .. seconds .. " " .. timetype
		end
		returnval = returnval:gsub("^ ", "")
		if (cut) then
			local sPos, ePos = returnval:find(("%d+%s%S+%s"):rep(cut))
			if (ePos) then
				returnval = returnval:sub(0, ePos - 1)
			end
		end
		return returnval 
	end

	function TBMenu:spawnWindowOverlay(color)
		UIScrollbarIgnore = true
		local overlay = UIElement:new({
			globalid = TB_MENU_MAIN_ISOPEN == 0 and TB_MENU_HUB_GLOBALID,
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H },
			interactive = true,
			bgColor = color or { 0, 0, 0, 0.4 }
		})
		overlay.killAction = function() UIScrollbarIgnore = false end
		return overlay
	end

	function TBMenu:showConfirmationWindowInput(title, inputInfo, confirmAction, cancelAction)
		local confirmOverlay = TBMenu:spawnWindowOverlay()
		local confirmBoxView = UIElement:new({
			parent = confirmOverlay,
			pos = { confirmOverlay.size.w / 7 * 2, confirmOverlay.size.h / 2 - 75 },
			size = { confirmOverlay.size.w / 7 * 3, 150 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local confirmBoxTitle = UIElement:new({
			parent = confirmBoxView,
			pos = { 10, 5 },
			size = { confirmBoxView.size.w - 20, 35 }
		})
		confirmBoxTitle:addAdaptedText(true, title)
		local textField = TBMenu:spawnTextField(confirmBoxView, 10, 50, confirmBoxView.size.w - 20, 30, nil, nil, 1, nil, nil, inputInfo)
		local cancelButton = UIElement:new({
			parent = confirmBoxView,
			pos = { 10, -50 },
			size = { confirmBoxView.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
		cancelButton:addMouseHandlers(nil, function()
				confirmOverlay:kill()
				if (cancelAction) then
					cancelAction(textField.textfieldstr[1])
				end
			end)
		local acceptButton = UIElement:new({
			parent = confirmBoxView,
			pos = { confirmBoxView.size.w / 2 + 5, -50 },
			size = { confirmBoxView.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		acceptButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCONTINUE)
		acceptButton:addMouseHandlers(nil, function()
				confirmOverlay:kill()
				confirmAction(textField.textfieldstr[1])
			end)
		return confirmOverlay
	end

	function TBMenu:showConfirmationWindow(message, confirmAction, cancelAction)
		local confirmOverlay = TBMenu:spawnWindowOverlay()
		local confirmBoxView = UIElement:new({
			parent = confirmOverlay,
			pos = { confirmOverlay.size.w / 7 * 2, confirmOverlay.size.h / 2 - 75 },
			size = { confirmOverlay.size.w / 7 * 3, 150 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local confirmBoxMessage = UIElement:new({
			parent = confirmBoxView,
			pos = { 10, 10 },
			size = { confirmBoxView.size.w - 20, 80 }
		})
		confirmBoxMessage:addAdaptedText(true, message)
		local cancelButton = UIElement:new({
			parent = confirmBoxView,
			pos = { 10, -50 },
			size = { confirmBoxView.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
		cancelButton:addMouseHandlers(nil, function()
				confirmOverlay:kill()
				if (cancelAction) then
					cancelAction()
				end
			end)
		local acceptButton = UIElement:new({
			parent = confirmBoxView,
			pos = { confirmBoxView.size.w / 2 + 5, -50 },
			size = { confirmBoxView.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		acceptButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCONTINUE)
		acceptButton:addMouseHandlers(nil, function()
				confirmOverlay:kill()
				confirmAction()
			end)
		return confirmOverlay
	end

	function TBMenu:showDataError(message, noParent)
		local transparency = 1
		if (tbMenuDataErrorMessage) then
			tbMenuDataErrorMessage:kill()
		end
		tbMenuDataErrorMessage = UIElement:new({
			globalid = noParent and TB_MENU_HUB_GLOBALID,
			parent = tbMenuMain,
			pos = { WIN_W / 4, noParent and WIN_H - 40 or -40 },
			size = { WIN_W / 2, 40 },
			bgColor = { 0, 0, 0, 0.8 * transparency }
		})
		local startTime = os.clock()
		tbMenuDataErrorMessage:addCustomDisplay(false, function()
				if (os.clock() - startTime > 2) then
					transparency = transparency - 0.05
					tbMenuDataErrorMessage.bgColor[4] = 0.8 * transparency
				end
				if (transparency <= 0) then
					tbMenuDataErrorMessage:kill()
				end
			end)
		local errorMessageView = UIElement:new({
			parent = tbMenuDataErrorMessage,
			pos = { 10, 0 },
			size = { tbMenuDataErrorMessage.size.w - 20, tbMenuDataErrorMessage.size.h }
		})
		errorMessageView:addAdaptedText(true, message, nil, nil, 4, nil, 0.7, nil, nil, nil, { 1, 1, 1, transparency })
	end

	function TBMenu:showTorishopMain()
		if (not TB_STORE_DATA.ready) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.STOREDATALOADERROR)
			return
		end
		TBMenu:clearNavSection()
		tbMenuBottomLeftBar:hide()
		Torishop:showTorishopMain(tbMenuCurrentSection)
		TBMenu:showNavigationBar(Torishop:getNavigationButtons(), true)
	end

	function TBMenu:showMatchmaking()
		-- Connect user to matchmake server
		Matchmake:connect()
		Matchmake:showMain(tbMenuCurrentSection)
	end

	function TBMenu:showPlaySection()
		local tbMenuPlayButtonsData = {
			{ title = TB_MENU_LOCALIZED.MAINMENUFREEPLAYNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUFREEPLAYDESC, size = 0.5, image = "../textures/menu/freeplay.tga", mode = ORIENTATION_LANDSCAPE, action = function() open_menu(1) end },
			{ title = TB_MENU_LOCALIZED.MAINMENURANKEDNAME, subtitle = TB_MENU_LOCALIZED.MAINMENURANKEDDESC, size = 0.25, image = "../textures/menu/matchmaking.tga", mode = ORIENTATION_PORTRAIT, action = function() if (TB_MENU_PLAYER_INFO.username == '') then TBMenu:showLoginError(tbMenuCurrentSection, TB_MENU_LOCALIZED.MAINMENUMATCHMAKINGNAME) return end TBMenu:showMatchmaking() end },
			{ title = TB_MENU_LOCALIZED.MAINMENUROOMLISTNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUROOMLISTDESC, size = 0.25, image = "../textures/menu/multiplayer.tga", mode = ORIENTATION_PORTRAIT, action = function() if (TB_MENU_PLAYER_INFO.username == '') then TBMenu:showLoginError(tbMenuCurrentSection, TB_MENU_LOCALIZED.MAINMENUROOMLISTNAME) return end open_menu(2) end }
		}
		TBMenu:showSection(tbMenuPlayButtonsData)
	end

	function TBMenu:showPracticeSection()
		dofile("tutorial/tutorial_manager.lua")
		local tbMenuPracticeButtonsData = Tutorials:getMainMenuButtons()
		TBMenu:showSection(tbMenuPracticeButtonsData)
	end
	
	function TBMenu:showHotkeys()
		local overlay = TBMenu:spawnWindowOverlay()
		overlay:addMouseHandlers(nil, function()
				overlay:kill()
			end)
		local hotkeysView = UIElement:new({
			parent = overlay,
			pos = { WIN_W / 10, 100 },
			size = { WIN_W * 0.8, WIN_H - 200 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		
		local elementHeight = 50
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(hotkeysView, elementHeight, elementHeight - 16, 20, TB_MENU_DEFAULT_BG_COLOR)
		local hotkeysTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w - 20, topBar.size.h }
		})
		hotkeysTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUHOTKEYSNAME, nil, nil, FONTS.BIG)
		local backButton = UIElement:new({
			parent = topBar,
			pos = { -(get_string_length(TB_MENU_LOCALIZED.NAVBUTTONBACK, FONTS.MEDIUM) + 100), 10 },
			size = { get_string_length(TB_MENU_LOCALIZED.NAVBUTTONBACK, FONTS.MEDIUM) + 90, topBar.size.h - 20 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		backButton:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK)
		backButton:addMouseHandlers(nil, function()
				overlay:kill()
			end)
		TBMenu:addBottomBloodSmudge(botBar, 1)
		
		local hotkeys = {
			{
				name = TB_MENU_LOCALIZED.HOTKEYSBASICCONTROLS,
				items = {
					{
						keys = { { "w", "a", "s", "d" }, "shift" },
						desc = TB_MENU_LOCALIZED.HOTKEYSCAMERACONTROLS
					},
					{
						keys = { "c" },
						desc = TB_MENU_LOCALIZED.HOTKEYSHOLDALL
					},
					{
						keys = { "x" },
						desc = TB_MENU_LOCALIZED.HOTKEYSHOLDRELAX
					},
					{
						keys = { "z" },
						desc = TB_MENU_LOCALIZED.HOTKEYSCONTRACTEXTEND
					},
					{
						keys = { "l" },
						desc = TB_MENU_LOCALIZED.HOTKEYSGRABUNGRAB
					},
					{
						keys = { "v" },
						desc = TB_MENU_LOCALIZED.HOTKEYSGRABALL
					},
					{
						keys = { "f" },
						desc = TB_MENU_LOCALIZED.HOTKEYSSAVEREPLAY
					},
					{
						keys = { "g" },
						desc = TB_MENU_LOCALIZED.HOTKEYSTORIGHOST
					},
					{
						keys = { "b" },
						desc = TB_MENU_LOCALIZED.HOTKEYSPLAYERSGHOST
					},
					{
						keys = { "space", "shift" },
						desc = TB_MENU_LOCALIZED.HOTKEYSTURN
					},
				}
			},
			{
				name = TB_MENU_LOCALIZED.HOTKEYSCHAT,
				items = {
					{
						keys = { { "enter", "t" } },
						desc = TB_MENU_LOCALIZED.HOTKEYSOPENCHAT
					},
					{
						keys = { Settings:getKeyName(get_option("chattoggle")) },
						desc = TB_MENU_LOCALIZED.HOTKEYSTOGGLECHAT
					},
					{
						keys = { { "pgup", "pgdn" } },
						desc = TB_MENU_LOCALIZED.HOTKEYSSCROLLCHAT
					},
					{
						keys = { { "home", "end" } },
						desc = TB_MENU_LOCALIZED.HOTKEYSSCROLLCHATMAX
					}
				}
			},
			{
				name = TB_MENU_LOCALIZED.HOTKEYSREPLAYS,
				items = {
					{
						keys = { "r" },
						desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYRESTART
					},
					{
						keys = { "p" },
						desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYPAUSE
					},
					{
						keys = { "e" },
						desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYEDIT
					},
					{
						keys = { "k" },
						desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYKEYFRAME
					},
					{
						keys = { "i" },
						desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYKEYFRAMESCLEAR
					},
					{
						keys = { "ctrl", "]" },
						desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYNEXT
					},
					{
						keys = { "ctrl", "[" },
						desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYPREV
					}
				}
			},
			{
				name = TB_MENU_LOCALIZED.HOTKEYSOTHER,
				items = {
					{
						keys = { "ctrl", "m" },
						desc = TB_MENU_LOCALIZED.HOTKEYSMODLIST
					},
					{
						keys = { "ctrl", "h" },
						desc = TB_MENU_LOCALIZED.HOTKEYSSHADERS
					},
					{
						keys = { "ctrl", "g" },
						desc = TB_MENU_LOCALIZED.HOTKEYSGAMERULES
					},
					{
						keys = { "ctrl", "enter" },
						desc = TB_MENU_LOCALIZED.HOTKEYSFULLSCREEN
					},
					{
						keys = { "1", "7" },
						dash = true,
						desc = TB_MENU_LOCALIZED.HOTKEYSCAMERAMODES
					}
				}
			}
		}
		
		local listElements = {}
		for i, section in pairs(hotkeys) do
			local sectionTitle = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			sectionTitle:addAdaptedText(false, section.name, 10, nil, FONTS.BIG, LEFTMID, 0.6, nil, 0.2)
			table.insert(listElements, sectionTitle)
			for i, hotkey in pairs(section.items) do
				local hotkeyView = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight + 5 },
					size = { listingHolder.size.w - 20, elementHeight - 10 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				table.insert(listElements, hotkeyView)
				local description = UIElement:new({
					parent = hotkeyView,
					pos = { 10, 0 },
					size = { hotkeyView.size.w / 2 - 10, hotkeyView.size.h }
				})
				description:addAdaptedText(true, hotkey.desc, nil, nil, nil, LEFTMID)
				local kPos = description.size.w + 20
				for i, key in pairs(hotkey.keys) do
					if (type(key) == "table") then
						for i, v in pairs(key) do
							if (i > 1) then
								local commaSign = UIElement:new({
									parent = hotkeyView,
									pos = { kPos, 0 },
									size = { get_string_length(",", FONTS.MEDIUM) + 10, hotkeyView.size.h - 5 }
								})
								commaSign:addAdaptedText(true, ",", nil, nil, FONTS.MEDIUM, LEFTBOT)
								kPos = kPos + commaSign.size.w
							end
							local keyViewBG = UIElement:new({
								parent = hotkeyView,
								pos = { kPos, 5 },
								size = { hotkeyView.size.h - 10 + get_string_length(v, FONTS.MEDIUM), hotkeyView.size.h - 10 },
								bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
								shapeType = ROUNDED,
								rounded = 4
							})
							local keyView = UIElement:new({
								parent = keyViewBG,
								pos = { 1, 1 },
								size = { keyViewBG.size.w - 2, keyViewBG.size.h - 2 },
								bgColor = TB_MENU_DEFAULT_BG_COLOR,
								shapeType = ROUNDED,
								rounded = 4,
								innerShadow = { 2, 2 },
								shadowColor = { TB_MENU_DEFAULT_LIGHTER_COLOR, TB_MENU_DEFAULT_DARKEST_COLOR }
							})
							keyView:addAdaptedText(false, v)
							kPos = kPos + keyView.size.w + 5
						end
					else
						if (#hotkeyView.child > 1) then
							local plusSign = UIElement:new({
								parent = hotkeyView,
								pos = { kPos, 0 },
								size = { get_string_length(hotkey.dash and "-" or "+", FONTS.MEDIUM) + 10, hotkeyView.size.h }
							})
							plusSign:addAdaptedText(true, hotkey.dash and "-" or "+", nil, nil, FONTS.MEDIUM)
							kPos = kPos + plusSign.size.w + 5
						end
						local keyViewBG = UIElement:new({
							parent = hotkeyView,
							pos = { kPos, 5 },
							size = { hotkeyView.size.h - 10 + get_string_length(key, FONTS.MEDIUM), hotkeyView.size.h - 10 },
							bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							shapeType = ROUNDED,
							rounded = 4
						})
						local keyView = UIElement:new({
							parent = keyViewBG,
							pos = { 1, 1 },
							size = { keyViewBG.size.w - 2, keyViewBG.size.h - 2 },
							bgColor = TB_MENU_DEFAULT_BG_COLOR,
							shapeType = ROUNDED,
							rounded = 4,
							innerShadow = { 2, 2 },
							shadowColor = { TB_MENU_DEFAULT_LIGHTER_COLOR, TB_MENU_DEFAULT_DARKEST_COLOR }
						})
						keyView:addAdaptedText(false, key)
						kPos = kPos + keyView.size.w + 5
					end
				end
			end
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		UIScrollbarIgnore = false
	end

	function TBMenu:showModsSection()
		local tbMenuModsButtonsData = {
			{ title = TB_MENU_LOCALIZED.MAINMENUMODMAKERNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUMODMAKERDESC, size = 0.25, image = "../textures/menu/modmaker.tga", mode = ORIENTATION_PORTRAIT, action = function() open_menu(17) end },
			{ title = TB_MENU_LOCALIZED.MAINMENUGAMERULESNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUGAMERULESDESC, size = 0.25, image = "../textures/menu/gamerules.tga", mode = ORIENTATION_PORTRAIT, action = function() open_menu(5) end, quit = true },
			{ title = TB_MENU_LOCALIZED.MAINMENUMODLISTNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUMODLISTDESC, size = 0.5, image = "../textures/menu/modlist.tga", mode = ORIENTATION_LANDSCAPE, action = function()
					dofile("system/mods_manager.lua")
					if (MODS_MENU_MAIN_ELEMENT) then
						MODS_MENU_MAIN_ELEMENT:kill()
						MODS_MENU_MAIN_ELEMENT = nil
					end
					Mods:showMain()
				end, quit = true }
		}
		TBMenu:showSection(tbMenuModsButtonsData)
	end

	function TBMenu:showToolsSection()
		local tbMenuToolsButtonsData = {
			{ title = TB_MENU_LOCALIZED.MAINMENUSCRIPTSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUSCRIPTSDESC, size = 0.25, image = "../textures/menu/scripts.tga", mode = ORIENTATION_PORTRAIT, action = function() TBMenu:showScripts() end },
			{ title = TB_MENU_LOCALIZED.MAINMENUSHADERSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUSHADERSDESC, size = 0.5, image = "../textures/menu/shaders.tga", mode = ORIENTATION_LANDSCAPE, action = function() dofile("system/atmo.lua") end, quit = true },
			{ title = TB_MENU_LOCALIZED.MAINMENUHOTKEYSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUHOTKEYSDESC, size = 0.25, image = "../textures/menu/hotkeys.tga", mode = ORIENTATION_PORTRAIT, action = function() TBMenu:showHotkeys() end }
		}
		TBMenu:showSection(tbMenuToolsButtonsData)
	end

	function TBMenu:addBottomBloodSmudge(parentElement, num, scale)
		local scale = scale or 64
		local bottomSmudge = TB_MENU_BOTTOM_SMUDGE_BIG
		if (parentElement.size.w < 400) then
			if (num % 2 == 1) then
				bottomSmudge = TB_MENU_BOTTOM_SMUDGE_MEDIUM1
			else
				bottomSmudge = TB_MENU_BOTTOM_SMUDGE_MEDIUM2
			end
		end
		local smudgeElement = UIElement:new({
			parent = parentElement,
			pos = { 0, -(scale / 2) },
			size = { parentElement.size.w, scale },
			bgImage = bottomSmudge
		})
		return smudgeElement
	end

	function TBMenu:showSection(buttonsData, shift, lockedMessage)
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		end
		local tbMenuSectionButtons = {}
		local sectionX = shift and shift + 15 or 5
		local sectionY = 0
		local maxWidthButton = { 0, 0 }
		for i, v in pairs (buttonsData) do
			if (v.size > maxWidthButton[2] and not v.vsize) then
				maxWidthButton[2] = v.size
				maxWidthButton[1] = i
			end
		end
		local imageRes = tbMenuCurrentSection.size.w * maxWidthButton[2] - 10
		local titleScaleModifier, titleFont, subtitleScaleModifier = 1, UI_HIGH_RESOLUTION_MODE and FONTS.BIGGER or FONTS.BIG, 1
		for i, v in pairs (buttonsData) do
			if (v.vsize) then
				titleScaleModifier, subtitleScaleModifier = 0.7, 0.8
				break
			end
		end
		for i, v in pairs (buttonsData) do
			tbMenuSectionButtons[i] = {}
			if (buttonsData[i].vsize) then
				if (sectionY + tbMenuCurrentSection.size.h * buttonsData[i].vsize - 5 > tbMenuCurrentSection.size.h) then
					tbMenuSectionButtons[i - 1].bottomSmudge = TBMenu:addBottomBloodSmudge(tbMenuSectionButtons[i - 1].mainView, i - 1)
					sectionY = 0
					sectionX = sectionX + tbMenuCurrentSection.size.w * buttonsData[i].size
				end
				tbMenuSectionButtons[i].mainView = UIElement:new( {
					parent = tbMenuCurrentSection,
					pos = { sectionX, sectionY },
					size = { tbMenuCurrentSection.size.w * buttonsData[i].size - 10, tbMenuCurrentSection.size.h * buttonsData[i].vsize - 5 },
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					interactive = true,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					hoverSound = 31
				})
				if (i == #buttonsData) then
					tbMenuSectionButtons[i].bottomSmudge = TBMenu:addBottomBloodSmudge(tbMenuSectionButtons[i].mainView, i - 1)
				end
				sectionY = sectionY + tbMenuCurrentSection.size.h * buttonsData[i].vsize + 5
			else
				if (i > 1 and tbMenuSectionButtons[i - 1].mainView.shift.x == sectionX) then
					sectionX = sectionX + tbMenuCurrentSection.size.w * buttonsData[i - 1].size
					tbMenuSectionButtons[i - 1].bottomSmudge = TBMenu:addBottomBloodSmudge(tbMenuSectionButtons[i - 1].mainView, i - 1)
				end
				sectionY = 0
				tbMenuSectionButtons[i].mainView = UIElement:new( {
					parent = tbMenuCurrentSection,
					pos = { sectionX, 0 },
					size = { tbMenuCurrentSection.size.w * buttonsData[i].size - 10, tbMenuCurrentSection.size.h },
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					interactive = true,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					hoverSound = 31
				})
				tbMenuSectionButtons[i].bottomSmudge = TBMenu:addBottomBloodSmudge(tbMenuSectionButtons[i].mainView, i)
				sectionX = sectionX + tbMenuCurrentSection.size.w * buttonsData[i].size
			end
			if (imageRes > 0 and buttonsData[i].image and ((imageRes / 2 < tbMenuSectionButtons[i].mainView.size.h / 5 * 4 and buttonsData[maxWidthButton[1]].mode == ORIENTATION_LANDSCAPE) or (imageRes / 3 * 2 < tbMenuSectionButtons[i].mainView.size.h / 5 * 4 and buttonsData[maxWidthButton[1]].mode == ORIENTATION_LANDSCAPE_SHORTER) or (imageRes < tbMenuSectionButtons[i].mainView.size.h / 5 * 4 and buttonsData[maxWidthButton[1]].mode == ORIENTATION_PORTRAIT)) and not buttonsData[i].vsize) then
				local imageBottom
				if (buttonsData[i].mode == ORIENTATION_PORTRAIT) then
					tbMenuSectionButtons[i].imageView = UIElement:new( {
						parent = tbMenuSectionButtons[i].mainView,
						pos = { 10, 10 },
						size = { tbMenuSectionButtons[i].mainView.size.w - 20, (imageRes - 20) / maxWidthButton[2] * buttonsData[i].size },
						bgImage = buttonsData[i].image
					})
					imageBottom = (imageRes - 20) / maxWidthButton[2] * buttonsData[i].size + 20
				elseif (buttonsData[i].mode == ORIENTATION_LANDSCAPE) then
					tbMenuSectionButtons[i].imageView = UIElement:new( {
						parent = tbMenuSectionButtons[i].mainView,
						pos = { 10, 10 },
						size = { (imageRes - 20) / maxWidthButton[2] * buttonsData[i].size, (imageRes - 20) / maxWidthButton[2] * buttonsData[i].size / 2 },
						bgImage = buttonsData[i].image
					})
					imageBottom = (imageRes - 20) / maxWidthButton[2] * buttonsData[i].size / 2 + 20
				else
					tbMenuSectionButtons[i].imageView = UIElement:new( {
						parent = tbMenuSectionButtons[i].mainView,
						pos = { 10, 10 },
						size = { tbMenuSectionButtons[i].mainView.size.w - 20, (imageRes - 20) / maxWidthButton[2] * buttonsData[i].size * 0.795 },
						bgImage = buttonsData[i].image
					})
					imageBottom = (imageRes - 20) / maxWidthButton[2] * buttonsData[i].size * 0.795 + 20
				end
				tbMenuSectionButtons[i].titleView = UIElement:new( {
					parent = tbMenuSectionButtons[i].mainView,
					pos = { tbMenuSectionButtons[i].mainView.size.w / 20, imageBottom},
					size = { tbMenuSectionButtons[i].mainView.size.w * 0.9, (tbMenuSectionButtons[i].mainView.size.h - imageBottom) / 2 - 10 }
				})
				tbMenuSectionButtons[i].subtitleView = UIElement:new( {
					parent = tbMenuSectionButtons[i].mainView,
					pos = { tbMenuSectionButtons[i].mainView.size.w / 20, imageBottom + (tbMenuSectionButtons[i].mainView.size.h - imageBottom) / 2 },
					size = { tbMenuSectionButtons[i].mainView.size.w * 0.9, (tbMenuSectionButtons[i].mainView.size.h - imageBottom) / 3 }
				})
			elseif (buttonsData[i].vsize) then
				tbMenuSectionButtons[i].titleView = UIElement:new( {
					parent = tbMenuSectionButtons[i].mainView,
					pos = { tbMenuSectionButtons[i].mainView.size.w / 20, tbMenuSectionButtons[i].mainView.size.h * 1 / 10 },
					size = { tbMenuSectionButtons[i].mainView.size.w * 0.9, tbMenuSectionButtons[i].mainView.size.h * 4 / 10 - 5 }
				})
				tbMenuSectionButtons[i].subtitleView = UIElement:new( {
					parent = tbMenuSectionButtons[i].mainView,
					pos = { tbMenuSectionButtons[i].mainView.size.w / 20, tbMenuSectionButtons[i].mainView.size.h / 2 + 5 },
					size = { tbMenuSectionButtons[i].mainView.size.w * 0.9, tbMenuSectionButtons[i].mainView.size.h * 4 / 10 }
				})
			else
				tbMenuSectionButtons[i].titleView = UIElement:new( {
					parent = tbMenuSectionButtons[i].mainView,
					pos = { tbMenuSectionButtons[i].mainView.size.w / 20, tbMenuSectionButtons[i].mainView.size.h / 6 },
					size = { tbMenuSectionButtons[i].mainView.size.w * 0.9, tbMenuSectionButtons[i].mainView.size.h / 3 - 5 }
				})
				tbMenuSectionButtons[i].subtitleView = UIElement:new( {
					parent = tbMenuSectionButtons[i].mainView,
					pos = { tbMenuSectionButtons[i].mainView.size.w / 20, tbMenuSectionButtons[i].mainView.size.h / 2 + 5 },
					size = { tbMenuSectionButtons[i].mainView.size.w * 0.9, tbMenuSectionButtons[i].mainView.size.h / 3 }
				})
			end
			tbMenuSectionButtons[i].titleView:addAdaptedText(true, buttonsData[i].title, nil, nil, titleFont, LEFT)
			if (titleFont > tbMenuSectionButtons[i].titleView.textFont) then
				titleFont = tbMenuSectionButtons[i].titleView.textFont
				titleScaleModifier = tbMenuSectionButtons[i].titleView.textScale
			elseif (titleScaleModifier > tbMenuSectionButtons[i].titleView.textScale) then
				titleScaleModifier = tbMenuSectionButtons[i].titleView.textScale
			end
			
			while (not tbMenuSectionButtons[i].subtitleView:uiText(buttonsData[i].subtitle, nil, nil, 4, LEFT, subtitleScaleModifier, nil, nil, nil, nil, nil, true) and subtitleScaleModifier > 0.4) do
				subtitleScaleModifier = subtitleScaleModifier - 0.05
			end
		end
		for i, v in pairs (buttonsData) do
			tbMenuSectionButtons[i].mainView:addMouseHandlers(nil, function()
					if (v.quit) then
						close_menu()
					end
					buttonsData[i].action()
				end, nil)
			tbMenuSectionButtons[i].titleView:addCustomDisplay(false, function()
					tbMenuSectionButtons[i].titleView:uiText(buttonsData[i].title, nil, nil, titleFont, LEFTBOT, titleScaleModifier, nil, nil, nil, nil, 0.2)
				end)
			tbMenuSectionButtons[i].subtitleView:addCustomDisplay(false, function()
					tbMenuSectionButtons[i].subtitleView:uiText(buttonsData[i].subtitle, nil, nil, 4, LEFT, subtitleScaleModifier)
				end)
			if (lockedMessage) then
				if (v.locked) then
					tbMenuSectionButtons[i].locked = UIElement:new({
						parent = tbMenuSectionButtons[i].mainView,
						pos = { 0, 0 },
						size = { tbMenuSectionButtons[i].mainView.size.w, tbMenuSectionButtons[i].mainView.size.h },
						interactive = true,
						bgColor = cloneTable(TB_MENU_DEFAULT_DARKEST_COLOR)
					})
					tbMenuSectionButtons[i].locked.bgColor[4] = 0.8
					tbMenuSectionButtons[i].locked:addAdaptedText(false, lockedMessage)
					if (tbMenuSectionButtons[i].bottomSmudge) then
						tbMenuSectionButtons[i].bottomSmudge:kill()
						tbMenuSectionButtons[i].bottomSmudge = TBMenu:addBottomBloodSmudge(tbMenuSectionButtons[i].mainView, i)
					end
				end
			end
		end
	end

	function TBMenu:openMenu(screenId)
		tbMenuBottomLeftBar:show()
		if (TB_MENU_SPECIAL_SCREEN_ISOPEN == 1) then
			TBMenu:showTorishopMain()
			Torishop:prepareInventory(tbMenuCurrentSection)
		elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 2) then
			TBMenu:showMatchmaking()
		elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 3) then
			TBMenu:showClans()
			if (TB_MENU_CLANS_OPENCLANID ~= 0) then
				Clans:showClan(tbMenuCurrentSection, TB_MENU_CLANS_OPENCLANID)
			end
		elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 4) then
			TBMenu:showNotifications()
		elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 5) then
			TBMenu:showReplays()
		elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 6) then
			TBMenu:showSettings()
		elseif (screenId == 1) then
			TBMenu:showHome()
		elseif (screenId == 2) then
			TBMenu:showPlaySection()
		elseif (screenId == 3) then
			TBMenu:showPracticeSection()
		elseif (screenId == 4) then
			TBMenu:showModsSection()
		elseif (screenId == 5) then
			TBMenu:showToolsSection()
		elseif (screenId == 101) then
			TBMenu:showNotifications()
		elseif (screenId == 102) then
			TBMenu:showFriendsList()
		end
	end

	function TBMenu:showGameLogo()
		local logo = TB_MENU_GAME_LOGO
		local gametitle = TB_MENU_GAME_TITLE
		local logoSize = 80
		local customLogo = io.open("custom/" .. TB_MENU_PLAYER_INFO.username .. "/logo.tga", "r", 1)
		if (customLogo) then
			logo = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/logo.tga"
			logoSize = 120
			customLogo:close()
		end
		local customGametitle = io.open("custom/" .. TB_MENU_PLAYER_INFO.username .. "/header.tga", "r", 1)
		if (customGametitle) then
			gametitle = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/header.tga"
			customGametitle:close()
		end
		local tbMenuLogo = UIElement:new( {
			parent = tbMenuMain,
			pos = {50, 15},
			size = {logoSize, logoSize},
			bgImage = logo
		})
		local tbMenuGameTitle = UIElement:new( {
			parent = tbMenuMain,
			pos = {135, 25},
			size = {200, 200},
			bgImage = gametitle
		})
	end

	function TBMenu:buttonGrowHover(viewElement, iconElement)
		local scale = 1.1
		local growth = 0.4
		if (viewElement.hoverState == BTN_HVR) then
			if (iconElement.size.h < viewElement.size.h * scale) then
				iconElement.size.h = iconElement.size.h + growth
				iconElement.size.w = iconElement.size.h
				if (iconElement.shift.x >= 0) then
					iconElement:moveTo(-viewElement.size.w - growth / 2, -viewElement.size.h - growth / 2)
				else
					iconElement:moveTo(iconElement.shift.x - growth / 2, iconElement.shift.y - growth / 2)
				end
			end
		elseif (viewElement.hoverState == BTN_DN) then
			iconElement.size.h = viewElement.size.h * scale
			iconElement.size.w = iconElement.size.h
			iconElement:moveTo(-viewElement.size.w - viewElement.size.h * (scale - 1) / 2, -viewElement.size.h - viewElement.size.h * (scale - 1) / 2)
		else
			iconElement.size.h = viewElement.size.h
			iconElement.size.w = iconElement.size.h
			iconElement:moveTo(0, 0)
		end
	end

	function TBMenu:showUserBar()
		local tbMenuTopBarWidth = 512

		local tbMenuUserBar = UIElement:new( {
			parent = tbMenuMain,
			pos = {-tbMenuTopBarWidth, 0},
			size = {tbMenuTopBarWidth, 100}
		})
		local tbMenuUserBarBottomSplat2 = UIElement:new( {
			parent = tbMenuUserBar,
			pos = {-tbMenuTopBarWidth, 0},
			size = {512, 128},
			bgImage = TB_MENU_USERBAR_MAIN
		})
		local tbMenuUserBarSplat = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { -tbMenuTopBarWidth - 128, 0 },
			size = { 128, 128 },
			bgImage = TB_MENU_USERBAR_LEFT
		})
		local tbMenuUserHeadAvatarViewport = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { -tbMenuUserBar.size.w - 10, 10 },
			size = { 80, 80 },
			viewport = true
		})
		local color = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
		local tbMenuUserHeadAvatarNeck = UIElement:new({
			parent = tbMenuUserHeadAvatarViewport,
			pos = { 0, 0, 9.35 },
			rot = { 0, 0, 0 },
			radius = 0.6,
			bgColor = { color.r, color.g, color.b, 1 }
		})
		local headTexture = { "../../custom/tori/head.tga", "../../custom/tori/head.tga" }
		if (TB_MENU_PLAYER_INFO.items.textures.head.equipped) then
			headTexture[1] = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/head.tga"
		end
		local tbMenuUserHeadAvatar = UIElement:new({
			parent = tbMenuUserHeadAvatarViewport,
			pos = { 0, 0, 10 },
			rot = { 0, 0, 0 },
			radius = 1,
			bgColor = { 1, 1, 1, 1 },
			bgImage = headTexture
		})
		local headRotation = 0
		tbMenuUserHeadAvatar:addCustomDisplay(false, function()
				tbMenuUserHeadAvatar.rot.z = 180 - 180 * math.cos(headRotation)
				headRotation = headRotation + math.pi / 500
				if (math.floor(headRotation * 250) % math.floor(math.pi * 250) == 0) then
					headRotation = 0
				end
			end)
		local tbMenuUserName = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { 80, 10 },
			size = { 350, 25 }
		})
		local displayName = TB_MENU_PLAYER_INFO.username == "" and "Tori" or TB_MENU_PLAYER_INFO.username
		tbMenuUserName:addCustomDisplay(false, function()
				tbMenuUserName:uiText(displayName, tbMenuUserName.pos.x + 2, tbMenuUserName.pos.y + 2, 0, 0, 0.55, nil, nil, {0,0,0,0.2}, nil, 0)
				tbMenuUserName:uiText(displayName, nil, nil, 0, 0, 0.55, nil, nil, nil, nil, 0.5)
			end)
		local tbMenuLogoutButton = TBMenu:createImageButtons(tbMenuUserBar, 85 + get_string_length(displayName, 0) * 0.55, 15, 25, 25, TB_MENU_LOGOUT_BUTTON, TB_MENU_LOGOUT_BUTTON_HOVER, TB_MENU_LOGOUT_BUTTON_PRESS)
		tbMenuLogoutButton:addMouseHandlers(nil, function()
				open_menu(18)
			end, nil)

		if (TB_MENU_PLAYER_INFO.clan.id ~= 0) then
			local tbMenuClan = UIElement:new( {
				parent = tbMenuUserBar,
				pos = { 80, 45 },
				size = { 350, 20 }
			})
			tbMenuClan:addCustomDisplay(false, function()
					tbMenuClan:uiText(TB_MENU_LOCALIZED.MAINMENUUSERCLAN .. ": " .. TB_MENU_PLAYER_INFO.clan.tag .. "  |  " .. TB_MENU_PLAYER_INFO.clan.name, nil, nil, 4, 0, 0.6)
				end)
		end
		local tbMenuUserTcView = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { 80, 65 },
			size = { 170, 25 },
			interactive = true,
			bgColor = TB_MENU_UI_TEXT_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHER_COLOR,
			hoverSound = 31
		})
		tbMenuUserTcView:addCustomDisplay(true, function() end)
		tbMenuUserTcView:addMouseHandlers(nil, function()
				TBMenu:showTorishopMain()
			end, nil)
		local tbMenuUserTcIcon = UIElement:new( {
			parent = tbMenuUserTcView,
			pos = { 0, 0 },
			size = { tbMenuUserTcView.size.h, tbMenuUserTcView.size.h },
			bgImage = "../textures/store/toricredit_tiny.tga"
		})
		tbMenuUserTcIcon:addCustomDisplay(false, function()
				TBMenu:buttonGrowHover(tbMenuUserTcView, tbMenuUserTcIcon)
			end)
		local tbMenuUserTcBalance = UIElement:new( {
			parent = tbMenuUserTcView,
			pos = { 30, 0 },
			size = { tbMenuUserTcView.size.w - tbMenuUserTcIcon.size.w - 5, tbMenuUserTcView.size.h }
		})
		tbMenuUserTcBalance:addCustomDisplay(false, function()
				tbMenuUserTcBalance:uiText(PlayerInfo:tcFormat(TB_MENU_PLAYER_INFO.data.tc), nil, 2, 2, 0, 0.9, nil, nil, tbMenuUserTcView:getButtonColor(), nil, 0)
			end)
		local tbMenuUserStView = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { 255, 65 },
			size = { 100, 25 },
			interactive = true,
			bgColor = TB_MENU_UI_TEXT_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHER_COLOR,
			hoverSound = 31
		})
		tbMenuUserStView:addCustomDisplay(true, function() end)
		tbMenuUserStView:addMouseHandlers(nil, function()
				open_url("http://forum.toribash.com/tori_token_exchange.php")
			end, nil)
		local tbMenuUserStIcon = UIElement:new( {
			parent = tbMenuUserStView,
			pos = { 0, 0 },
			size = { tbMenuUserStView.size.h, tbMenuUserStView.size.h },
			bgImage = "../textures/store/shiaitoken_tiny.tga"
		})
		tbMenuUserStIcon:addCustomDisplay(false, function()
				TBMenu:buttonGrowHover(tbMenuUserStView, tbMenuUserStIcon)
			end)
		local tbMenuUserStBalance = UIElement:new( {
			parent = tbMenuUserStView,
			pos = { 30, 0 },
			size = { tbMenuUserStView.size.w - 30, tbMenuUserStView.size.h }
		})
		tbMenuUserStBalance:addCustomDisplay(false, function()
				-- Proper ST balance is deprecated until a fix is rolled out
				tbMenuUserStBalance:uiText("ST", nil, 2, 2, 0, 0.9, nil, nil, tbMenuUserStView:getButtonColor(), nil, 0)
				--tbMenuUserStBalance:uiText(TB_MENU_PLAYER_INFO.data.st, nil, tbMenuUserStBalance.pos.y + 2, nil, LEFT, 0.9, nil, nil, tbMenuUserStView:getButtonColor())
			end)
		local tbMenuUserBeltIcon = UIElement:new({
			parent = tbMenuUserBar,
			pos = { -130, 0 },
			size = { 110, 110 },
			bgImage = TB_MENU_PLAYER_INFO.data.belt.icon
		})
		local tbMenuUserQi = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { -130, 50 },
			size = { 110, 40 }
		})
		tbMenuUserQi:addCustomDisplay(false, function()
				tbMenuUserQi:uiText(TB_MENU_PLAYER_INFO.data.belt.name .. " belt", nil, nil, 2, nil, 0.7, nil, 1)
			end)
	end

	function TBMenu:showNavigationBar(buttonsData, customNav, customNavHighlight, selectedId)
		local tbMenuNavigationButtonsData = buttonsData or TBMenu:getMainNavigationButtons()
		local tbMenuNavigationButtons = {}
		local selectedId = selectedId or 0

		local navX = { l = { 30 } , r = { -30 } }
		tbMenuNavigationBar = tbMenuNavigationBar or UIElement:new({
			parent = tbMenuMain,
			pos = { 50, 130 },
			size = { WIN_W - 100, WIN_H / 16 },
			bgColor = { 0, 0, 0, 0.9 },
			shapeType = ROUNDED,
			rounded = 10
		})
		for i, v in pairs(tbMenuNavigationButtonsData) do
			-- Assign width dynamically and kill check element afterwards
			local temp = UIElement:new({
				parent = tbMenuNavigationBar,
				pos = { 0, 0 },
				size = { WIN_W, tbMenuNavigationBar.size.h / 6 * 4 }
			})
			temp:addAdaptedText(true, v.text, nil, nil, FONTS.BIG)
			v.width = get_string_length(temp.dispstr[1] .. "____", temp.textFont) * temp.textScale
			temp:kill()
			
			local navX = v.right and navX.r or navX.l
			tbMenuNavigationButtons[i] = UIElement:new( {
				parent = tbMenuNavigationBar,
				pos = { v.right and navX[1] - v.width or navX[1], 0 },
				size = { v.width, tbMenuNavigationBar.size.h },
				bgColor = { 0.2, 0.2, 0.2, 0 },
				interactive = true,
				hoverColor = TB_NAVBAR_DEFAULT_BG_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverSound = 31
			})
			navX[1] = v.right and navX[1] - v.width or navX[1] + v.width
			if ((not customNav and TB_LAST_MENU_SCREEN_OPEN == v.sectionId) or (customNav and customNavHighlight and selectedId == v.sectionId)) then
				tbMenuNavigationButtons[i].bgColor = TB_NAVBAR_DEFAULT_BG_COLOR
			end
			tbMenuNavigationButtons[i]:addCustomDisplay(false, function()
					set_color(tbMenuNavigationButtons[i].animateColor[1] - 0.1, tbMenuNavigationButtons[i].animateColor[2], tbMenuNavigationButtons[i].animateColor[3], tbMenuNavigationButtons[i].animateColor[4])
					for j = tbMenuNavigationBar.size.h - 10, 10, -10 do
						draw_line(tbMenuNavigationButtons[i].pos.x, tbMenuNavigationButtons[i].pos.y - 1 + j, tbMenuNavigationButtons[i].pos.x + j, tbMenuNavigationButtons[i].pos.y + 1, 0.5)
					end
					for j = 0, tbMenuNavigationButtons[i].size.w - tbMenuNavigationBar.size.h, 10 do
						draw_line(tbMenuNavigationButtons[i].pos.x + tbMenuNavigationBar.size.h + j, tbMenuNavigationButtons[i].pos.y + 1, tbMenuNavigationButtons[i].pos.x + j, tbMenuNavigationButtons[i].pos.y + tbMenuNavigationBar.size.h - 1, 0.5)
					end
					for j = tbMenuNavigationBar.size.h - 10, 10, -10 do
						draw_line(tbMenuNavigationButtons[i].pos.x + tbMenuNavigationButtons[i].size.w - j, tbMenuNavigationButtons[i].pos.y + tbMenuNavigationBar.size.h - 1, tbMenuNavigationButtons[i].pos.x + tbMenuNavigationButtons[i].size.w, tbMenuNavigationButtons[i].pos.y + tbMenuNavigationBar.size.h - 1 - j, 0.5)
					end
				end)
			local buttonText = UIElement:new({
				parent = tbMenuNavigationButtons[i],
				pos = { 15, tbMenuNavigationBar.size.h / 6 },
				size = { tbMenuNavigationButtons[i].size.w - 30, tbMenuNavigationBar.size.h / 6 * 4 }
			})
			buttonText:addAdaptedText(true, v.text, nil, nil, FONTS.BIG)
			tbMenuNavigationButtons[i]:addMouseHandlers(nil, function()
					if (not customNav) then
						if (v.sectionId ~= TB_LAST_MENU_SCREEN_OPEN) then
							tbMenuCurrentSection:kill(true)
							TB_LAST_MENU_SCREEN_OPEN = v.sectionId
							for i, v in pairs(tbMenuNavigationButtons) do
								v.bgColor = { 0.2, 0.2, 0.2, 0 }
							end
							tbMenuNavigationButtons[i].bgColor = TB_NAVBAR_DEFAULT_BG_COLOR
							TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
						end
					else
						if (customNavHighlight) then
							if (v.sectionId ~= selectedId) then
								selectedId = v.sectionId
								for i, v in pairs(tbMenuNavigationButtons) do
									v.bgColor = { 0.2, 0.2, 0.2, 0 }
								end
								tbMenuNavigationButtons[i].bgColor = TB_NAVBAR_DEFAULT_BG_COLOR
							end
						end
						v.action()
					end
				end, nil)
		end
	end

	function TBMenu:getMainNavigationButtons()
		local buttonData = {
			{ text = TB_MENU_LOCALIZED.NAVBUTTONHOME, sectionId = 1 },
			{ text = TB_MENU_LOCALIZED.NAVBUTTONPLAY, sectionId = 2 },
			{ text = TB_MENU_LOCALIZED.NAVBUTTONPRACTICE, sectionId = 3 },
			{ text = TB_MENU_LOCALIZED.NAVBUTTONMODS, sectionId = 4 },
			{ text = TB_MENU_LOCALIZED.NAVBUTTONTOOLS, sectionId = 5 }
		}
		return buttonData
	end

	function TBMenu:showBottomBar(leftOnly)
		tbMenuBottomLeftBar = tbMenuBottomLeftBar or UIElement:new( {
			parent = tbMenuMain,
			pos = { 45, -70 },
			size = { 110, 50 }
		})
		local tbMenuBottomLeftButtonsData = {
			{ action = function() TBMenu:openMenu(102) end, image = TB_MENU_FRIENDS_BUTTON, imageHover = TB_MENU_FRIENDS_BUTTON_HOVER, imagePress = TB_MENU_FRIENDS_BUTTON_PRESS },
			{ action = function() if (TB_MENU_SPECIAL_SCREEN_ISOPEN == 0) then TBMenu:openMenu(101) else Notifications:quit() end end, image = TB_MENU_NOTIFICATIONS_BUTTON, imageHover = TB_MENU_NOTIFICATIONS_BUTTON_HOVER, imagePress = TB_MENU_NOTIFICATIONS_BUTTON_PRESS },
			{ action = function() open_url("http://discord.gg/toribash") end, image = TB_MENU_DISCORD_BUTTON, imageHover = TB_MENU_DISCORD_BUTTON_HOVER, imagePress = TB_MENU_DISCORD_BUTTON_PRESS },
		}
		local tbMenuBottomLeftButtons = {}
		for i, v in pairs(tbMenuBottomLeftButtonsData) do
			tbMenuBottomLeftButtons[i] = TBMenu:createImageButtons(tbMenuBottomLeftBar, (i - 1) * (tbMenuBottomLeftBar.size.h + 10), 0, tbMenuBottomLeftBar.size.h, tbMenuBottomLeftBar.size.h, v.image, v.imageHover, v.imagePress)
			tbMenuBottomLeftButtons[i]:addMouseHandlers(nil, v.action, nil)
		end
		--[[if (TB_BOUNTIES_DEFINED) then
			local tbMenuPulseNotification = UIElement:new({
				parent = tbMenuBottomLeftBar,
				pos = { #tbMenuBottomLeftButtonsData * (tbMenuBottomLeftBar.size.h + 10) + 5, 5 },
				size = { tbMenuBottomLeftBar.size.h * 5 - 10, tbMenuBottomLeftBar.size.h - 10 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = tbMenuBottomLeftBar.size.h
			})
			tbMenuPulseNotification:addMouseHandlers(nil, function()
					TBMenu:showBounties()
				end)
			local pulseMod = 0
			tbMenuPulseNotification:addCustomDisplay(false, function()
					local r, g, b, a = unpack(tbMenuPulseNotification.animateColor)
					set_color(r, g, b, a - pulseMod / 15)
					draw_disk(tbMenuPulseNotification.pos.x + tbMenuPulseNotification.size.h / 2, tbMenuPulseNotification.pos.y + tbMenuPulseNotification.size.h / 2, tbMenuPulseNotification.size.h / 2, tbMenuPulseNotification.size.h / 2 + pulseMod, 500, 1, 180, 180, 0)
					draw_disk(tbMenuPulseNotification.pos.x + tbMenuPulseNotification.size.w - tbMenuPulseNotification.size.h / 2, tbMenuPulseNotification.pos.y + tbMenuPulseNotification.size.h / 2, tbMenuPulseNotification.size.h / 2, tbMenuPulseNotification.size.h / 2 + pulseMod, 500, 1, 0, 180, 0)
					draw_quad(tbMenuPulseNotification.pos.x + tbMenuPulseNotification.size.h / 2, tbMenuPulseNotification.pos.y - pulseMod, tbMenuPulseNotification.size.w - tbMenuPulseNotification.size.h, tbMenuPulseNotification.size.h + pulseMod * 2)
					pulseMod = pulseMod + 0.2
					if (pulseMod > 15) then
						pulseMod = 0
					end
				end)
			local tbMenuPulseNotificationCaption = UIElement:new({
				parent = tbMenuPulseNotification,
				pos = { 10, 0 },
				size = { tbMenuPulseNotification.size.w - 20, tbMenuPulseNotification.size.h }
			})
			tbMenuPulseNotificationCaption:addAdaptedText(false, "Toribash's Most Wanted")
		end]]
		--[[local tbMenuFriendsBetaCaption = UIElement:new({
			parent = tbMenuBottomLeftButtons[1],
			pos = { 0, -tbMenuBottomLeftBar.size.h / 3 },
			size = { tbMenuBottomLeftBar.size.h, tbMenuBottomLeftBar.size.h / 3 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = tbMenuBottomLeftBar.size.h
		})
		tbMenuFriendsBetaCaption:addCustomDisplay(false, function()
				tbMenuFriendsBetaCaption:uiText("Beta", nil, nil, nil, nil, 0.6)
			end)]]
		if (TB_MENU_NOTIFICATIONS_COUNT > 0) then
			local tbMenuNotificationsCount = UIElement:new({
				parent = tbMenuBottomLeftButtons[2],
				pos = { -tbMenuBottomLeftBar.size.h / 2, 0 },
				size = { tbMenuBottomLeftBar.size.h / 2, tbMenuBottomLeftBar.size.h / 2 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = ROUNDED,
				rounded = tbMenuBottomLeftBar.size.h
			})
			tbMenuNotificationsCount:addCustomDisplay(false, function()
					if (TB_MENU_NOTIFICATIONS_COUNT == 0) then
						tbMenuNotificationsCount:kill()
					else
						tbMenuNotificationsCount:uiText(TB_MENU_NOTIFICATIONS_COUNT, nil, nil, 4, nil, 0.7)
					end
				end)
		end
		if (leftOnly) then
			return
		end

		tbMenuBottomRightBar = tbMenuBottomRightBar or UIElement:new({
			parent = tbMenuMain,
			pos = { -145, -70 },
			size = { 110, 50 }
		})
		local tbMenuBottomRightButtonsData = {
			{ action = function() open_menu(4) end, image = TB_MENU_QUIT_BUTTON, imageHover = TB_MENU_QUIT_BUTTON_HOVER, imagePress = TB_MENU_QUIT_BUTTON_PRESS },
			{ action = function() TBMenu:showSettings() end, image = TB_MENU_SETTINGS_BUTTON, imageHover = TB_MENU_SETTINGS_BUTTON_HOVER, imagePress = TB_MENU_SETTINGS_BUTTON_PRESS }
		}
		local tbMenuBottomRightButtons = {}
		for i,v in pairs(tbMenuBottomRightButtonsData) do
			tbMenuBottomRightButtons[i] = TBMenu:createImageButtons(tbMenuBottomRightBar, -i * (tbMenuBottomRightBar.size.h + 10), 0, tbMenuBottomRightBar.size.h, tbMenuBottomRightBar.size.h, v.image, v.imageHover, v.imagePress)
			tbMenuBottomRightButtons[i]:addMouseHandlers(nil, v.action, nil)
		end
		local tbMenuDownloads = UIElement:new({
			parent = tbMenuMain,
			pos = { -300, -25 },
			size = { 300, 25 }
		})
		tbMenuDownloads:addCustomDisplay(true, function()
				local downloads = #get_downloads() or 0
				if (downloads > 0) then
					tbMenuDownloads:uiText(TB_MENU_LOCALIZED.DOWNLOADINGFILESWAIT, -10, nil, 4, RIGHTMID, 0.5, nil, nil, UICOLORBLACK)
				end
			end)
	end

	function TBMenu:showMain(noload)
		local mainBgColor = nil
		tbMenuMain = UIElement:new( {
			globalid = TB_MENU_MAIN_GLOBALID,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H },
			uiColor = TB_MENU_UI_TEXT_COLOR,
			uiShadowColor = TB_MENU_UI_TEXT_SHADOW_COLOR
		})
		local tbMenuBackground = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, - WIN_H * 2 },
			size = { WIN_W, WIN_H * 3 },
			bgColor = { 0, 0, 0, 0 }
		})
		if (enable_blur() == 0) then
			tbMenuBackground.bgColor = {0, 0, 0, 0.1}
		else
			BLURENABLED = true
		end
		local tbMenuHide = TBMenu:createImageButtons(tbMenuMain, WIN_W / 2 - 32, -74, 64, 64, "../textures/menu/general/buttons/arrowbot.tga", nil, nil, {0, 0, 0, 0}, { 0, 0, 0, 0.2 }, { 0, 0, 0, 0.4}, 32)
		tbMenuHide.state = 0
		tbMenuHide:addMouseHandlers(nil, function()
				if (tbMenuHide.state == 0) then
					tbMenuHide.state = -1
					tbMenuHide.progress = -math.pi/6
					disable_blur()
				elseif (tbMenuHide.state == 2) then
					tbMenuHide.state = 1
					tbMenuHide.progress = math.pi / 2
				end
			end, nil)
		tbMenuHide:addCustomDisplay(false, function()
				if (tbMenuHide.state == -1) then
					tbMenuHide.progress = tbMenuHide.progress + math.pi / 40
					tbMenuMain:moveTo(nil, tbMenuMain.pos.y + (WIN_H / 15) * math.sin(tbMenuHide.progress))
					tbMenuHide:moveTo(nil, -tbMenuMain.pos.y - 74)
					if (not BLURENABLED) then
						tbMenuBackground.bgColor[4] = tbMenuBackground.bgColor[4] - (0.1 / 15) * math.sin(tbMenuHide.progress)
					end
					if (tbMenuMain.pos.y >= WIN_H) then
						for i = 1, 3 do
							tbMenuHide.child[i]:updateImage("../textures/menu/general/buttons/arrowtop.tga")
						end
						tbMenuMain:moveTo(nil, WIN_H)
						tbMenuHide:moveTo(nil, -tbMenuMain.pos.y - 74)
						tbMenuHide.state = 2
						tbMenuBackground.bgColor[4] = 0
					end
				elseif (tbMenuHide.state == 1) then
					tbMenuHide.progress = tbMenuHide.progress + math.pi / 50
					tbMenuMain:moveTo(nil, tbMenuMain.pos.y - (WIN_H / 15) * math.sin(tbMenuHide.progress))
					tbMenuHide:moveTo(nil, -tbMenuMain.pos.y - 74)
					if (not BLURENABLED) then
						tbMenuBackground.bgColor[4] = tbMenuBackground.bgColor[4] + (0.1 / 15) * math.sin(tbMenuHide.progress)
					end
					if (tbMenuMain.pos.y <= 0) then
						for i = 1, 3 do
							tbMenuHide.child[i]:updateImage("../textures/menu/general/buttons/arrowbot.tga")
						end
						tbMenuMain:moveTo(nil, 0)
						tbMenuHide:moveTo(nil, -tbMenuMain.pos.y - 74)
						tbMenuHide.state = 0
						if (enable_blur() == 0) then
							tbMenuBackground.bgColor[4] = 0.1
						end
					end
				end
			end, false)
		local splatLeftImg = TB_MENU_BLOODSPLATTER_LEFT
		local splatCustom = false
		local customLogo = io.open("custom/" .. TB_MENU_PLAYER_INFO.username .. "/splatt1.tga", "r", 1)
		if (customLogo) then
			splatLeftImg = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/splatt1.tga"
			splatCustom = true
			customLogo:close()
		end
		local splatLeft = UIElement:new( {
			parent = tbMenuMain,
			pos = { 10, 200 },
			size = { WIN_H - 320, WIN_H - 320 },
			bgImage = splatLeftImg
		})
		local splatRight = UIElement:new( {
			parent = tbMenuMain,
			pos = { -(WIN_H - 320) - 10, 200 },
			size = { WIN_H - 320, WIN_H - 320 },
			bgImage = splatCustom and splatLeftImg or TB_MENU_BLOODSPLATTER_RIGHT
		})
		TBMenu:showGameLogo()
		TBMenu:showUserBar()
		TBMenu:showNavigationBar()
		TBMenu:showBottomBar()
		if (not noload) then
			TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
		end
	end

	-- Displays login error
	function TBMenu:showLoginError(viewElement, actionStr)
		viewElement:kill(true)
		local background = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(background, 1)
		local errorMessage = UIElement:new({
			parent = background,
			pos = { background.size.w / 4, 0 },
			size = { background.size.w / 2, background.size.h / 2 - 10 }
		})
		errorMessage:addCustomDisplay(true, function()
				errorMessage:uiText(TB_MENU_LOCALIZED.MAINMENUSIGNINERROR .. " " .. actionStr, nil, nil, nil, CENTERBOT)
			end)
		local loginButton = UIElement:new({
			parent = background,
			pos = { background.size.w / 4, background.size.h / 2 + 10 },
			size = { background.size.w / 2, background.size.h / 5 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		loginButton:addCustomDisplay(false, function()
				loginButton:uiText("Log in / Create account")
			end)
		loginButton:addMouseHandlers(nil, function()
				open_menu(18)
			end)
	end

	function TBMenu:spawnDropdown(holderElement, listElements, elementHeight, maxHeight, selectedItem, textScale, fontid, textScale2, fontid2)
		local maxHeight = maxHeight or #listElements * elementHeight + 4
		if (maxHeight > #listElements * elementHeight + 4) then
			maxHeight = #listElements * elementHeight + 4
		end
		local selectedItem = selectedItem or listElements[1]
		local fontid = fontid or 4
		local fontid2 = fontid2 or 4
		local overlay = UIElement:new({
			parent = holderElement,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H },
			interactive = true,
			scrollEnabled = true
		})
		local dropdownView = UIElement:new({
			parent = overlay,
			pos = { 0, 0 },
			size = { holderElement.size.w, maxHeight },
			bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 5
		})
		overlay:addMouseHandlers(function(s)
				if (s >= 4) then
					overlay:hide(true)
				end
			end, function()
				overlay:hide(true)
			end)
		local function updatePos(t)
			t:updateChildPos()
			for i,v in pairs(t.child) do
				updatePos(v)
			end
		end
		dropdownView:addCustomDisplay(false, function()
				overlay.pos.x = 0
				overlay.pos.y = 0
				for i,v in pairs(overlay.child) do
					v:updateChildPos()
				end
				local dropdownPosY = holderElement.pos.y + maxHeight > WIN_H - 10 and WIN_H - 10 - maxHeight or holderElement.pos.y
				dropdownView:moveTo(holderElement.pos.x, dropdownPosY)
				dropdownView.pos.x = overlay.pos.x + dropdownView.shift.x
				dropdownView.pos.y = overlay.pos.y + dropdownView.shift.y
				for i,v in pairs(dropdownView.child) do
					updatePos(v)
				end
			end, true)
		local selectedElement = UIElement:new({
			parent = holderElement,
			pos = { 0, 0 },
			size = { holderElement.size.w, holderElement.size.h },
			interactive = true,
			bgColor = holderElement.bgColor or TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = holderElement.hoverColor or TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = holderElement.pressedColor or TB_MENU_DEFAULT_BG_COLOR,
			shapeType = holderElement.shapeType,
			rounded = holderElement.rounded
		})
		local selectedElementText = UIElement:new({
			parent = selectedElement,
			pos = { 10, 0 },
			size = { selectedElement.size.w - selectedElement.size.h - 10, selectedElement.size.h }
		})
		selectedElementText:addAdaptedText(false, selectedItem.text:upper(), nil, nil, fontid, LEFTMID, textScale)
		local selectedElementArrow = UIElement:new({
			parent = selectedElement,
			pos = { -selectedElement.size.h, 0 },
			size = { selectedElement.size.h, selectedElement.size.h },
			bgImage = "../textures/menu/general/buttons/arrowbotwhite.tga"
		})
		if (#listElements * elementHeight <= maxHeight) then
			for i,v in pairs(listElements) do
				local element = UIElement:new({
					parent = dropdownView,
					pos = { 2, 2 + (i - 1) * elementHeight },
					size = { dropdownView.size.w - 4, elementHeight },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
					shapeType = holderElement.shapeType,
					rounded = holderElement.rounded
				})
				element:addAdaptedText(false, v.text:upper(), nil, nil, fontid2, nil, textScale2)
				element:addMouseHandlers(nil, function()
						overlay:hide(true)
						selectedElementText:addAdaptedText(false, v.text:upper(), nil, nil, fontid, LEFTMID, textScale)
						selectedElement:show()
						if (selectedItem == v) then
							return
						end
						selectedItem = v
						v.action()
					end)
			end
		end
		selectedElement:addMouseHandlers(nil, function()
				overlay:show(true)
			end)
		overlay:hide(true)
	end

	-- Spawns default menu scroll bar
	function TBMenu:spawnScrollBar(holderElement, listElements, elementHeight)
		local scrollActive = true
		local scrollScale = listElements > 0 and (holderElement.size.h) / (listElements * elementHeight) or holderElement.size.h
		if (scrollScale >= 1) then
			scrollScale = 1
			scrollActive = false
		elseif (scrollScale < 0.1) then
			scrollScale = 0.1
		end

		local scrollView = UIElement:new({
			parent = holderElement.parent,
			pos = { -(holderElement.parent.size.w - holderElement.size.w) / 4 * 3, 5 },
			size = { (holderElement.parent.size.w - holderElement.size.w) / 2, holderElement.size.h - 10 }
		})
		local scrollBar = UIElement:new({
			parent = scrollView,
			pos = { 0, 0 },
			size = { scrollView.size.w, scrollView.size.h * scrollScale },
			interactive = scrollActive,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.6 },
			scrollEnabled = true,
			shapeType = ROUNDED,
			rounded = 10
		})
		return scrollBar
	end

	function TBMenu:enableMenuKeyboard(element)
		enable_menu_keyboard()
		local id = 1
		for i,v in pairs(UIKeyboardHandler) do
			if (v.menuKeyboardId == id) then
				id = id + 1
			else
				element.menuKeyboardId = id
				break
			end
		end
	end

	function TBMenu:disableMenuKeyboard(element)
		element.menuKeyboardId = nil
		for i,v in pairs(UIKeyboardHandler) do
			if (v.menuKeyboardId) then
				return
			end
		end
		disable_menu_keyboard()
	end

	function TBMenu:displayLoadingMark(element, message)
		local loadMark = UIElement:new({
			parent = element,
			pos = { 0, 0 },
			size = { element.size.w, element.size.h }
		})
		local grow, rotate = 0, 0
		loadMark:addCustomDisplay(true, function()
				set_color(1, 1, 1, 1)
				draw_disk(loadMark.pos.x + loadMark.size.w / 2, loadMark.pos.y + loadMark.size.h / 2 - 40, 12, 20, 500, 1, rotate, grow, 0)
				grow = grow + 4
				rotate = rotate + 2
				if (grow >= 360) then
					grow = -360
				end
			end)
		if (message) then
			local textView = UIElement:new({
				parent = loadMark,
				pos = { 10, loadMark.size.h / 2 },
				size = { loadMark.size.w - 20, loadMark.size.h }
			})
			textView:addAdaptedText(true, message, nil, nil, nil, CENTER)
		end
	end
	
	function TBMenu:showTextExternal(viewElement, text)
		local textView = UIElement:new({
			parent = viewElement,
			pos = { 20, 0 },
			size = { viewElement.size.w - 30, viewElement.size.h }
		})
		textView:addAdaptedText(false, text, -17)
		local posX = get_string_length(textView.dispstr[1], FONTS.MEDIUM) * textView.textScale
		local bgColorDelta = viewElement.bgColor[1] + viewElement.bgColor[2] + viewElement.bgColor[3]
		local texture = "../textures/menu/general/buttons/external.tga"
		if (bgColorDelta > 1.5) then
			texture = "../textures/menu/general/buttons/externalblack.tga"
		end
		local onlineSign = UIElement:new({
			parent = textView,
			pos = { textView.size.w / 2 + posX / 2 - 13, textView.size.h / 2 - 13 },
			size = { 26, 26 },
			bgImage = texture
		})
	end

	function TBMenu:displayHelpPopup(element, message, forceManualPosCheck)
		local messageElement = UIElement:new({
			parent = element,
			pos = { 0, 0 },
			size = { WIN_W / 3, WIN_H / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.8 },
		})

		if (messageElement.pos.x < 0) then
			messageElement:moveTo(messageElement:getLocalPos(10, 0).x)
		end
		if (messageElement.pos.y < 0) then
			messageElement:moveTo(nil, messageElement:getLocalPos(0, 10).y)
		end
		if (messageElement.pos.x + messageElement.size.w > WIN_W) then
			messageElement:moveTo(messageElement:getLocalPos(WIN_W - 10 - messageElement.size.w, 0).x)
		end
		if (messageElement.pos.y + messageElement.size.h > WIN_H) then
			messageElement:moveTo(nil, messageElement:getLocalPos(0, WIN_H - 10 - messageElement.size.h).y)
		end

		messageElement:addAdaptedText(false, message, nil, nil, 4, nil, 0.7)
		messageElement:hide(true)

		local popupShown = false
		local pressTime = 0

		if (forceManualPosCheck) then
			element:addCustomDisplay(false, function()
					if (MOUSE_X > element.pos.x and MOUSE_Y > element.pos.y and MOUSE_X < element.pos.x + element.size.w and MOUSE_Y < element.pos.y + element.size.h) then
						element.hoverState = BTN_HVR
						if (not popupShown) then
							pressTime = pressTime + 0.07
							if (pressTime > 1) then
								messageElement:show(true)
								popupShown = true
							end
						end
					elseif (popupShown) then
						if (MOUSE_X < messageElement.pos.x or MOUSE_X > messageElement.pos.x + messageElement.size.w or MOUSE_Y < messageElement.pos.y or MOUSE_Y > messageElement.pos.y + messageElement.size.h) then
							messageElement:hide(true)
							pressTime = 0
							popupShown = false
						end
					end
				end)
		else
			element:addCustomDisplay(false, function()
					if (element.hoverState == BTN_HVR) then
						if (not popupShown) then
							pressTime = pressTime + 0.07
							if (pressTime > 1) then
								messageElement:show(true)
								popupShown = true
							end
						end
					elseif (popupShown) then
						if (not messageElement.hoverState) then
							messageElement:hide(true)
							pressTime = 0
							popupShown = false
						end
					end
				end)
		end

		local questionmark = UIElement:new({
			parent = element,
			pos = { 0, 0 },
			size = { element.size.w, element.size.h }
		})
		questionmark:addAdaptedText(true, "?", nil, nil, nil, nil, 0.7)
	end

	function TBMenu:spawnTextField(parent, x, y, w, h, textFieldString, numeric, fontid, scale, color, defaultStr, orientation, noCursor)
		if (not parent) then
			return false
		end
		local x = x or 0
		local y = y or 0
		local w = w or parent.size.w
		local h = h or parent.size.h
		local fontid = fontid or 4
		local color = color or cloneTable(UICOLORBLACK)

		local textBg = UIElement:new({
			parent = parent,
			pos = { x, y },
			size = { w, h },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = parent.shapeType,
			rounded = parent.rounded
		})
		local input = UIElement:new({
			parent = textBg,
			pos = { 1, 1 },
			size = { textBg.size.w - 2, textBg.size.h - 2 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = textBg.shapeType,
			rounded = textBg.rounded
		})
		local inputField = UIElement:new({
			parent = textBg,
			pos = { 5, 0 },
			size = { input.size.w - 10, input.size.h },
			interactive = true,
			textfield = true,
			isNumeric = numeric,
			textfieldstr = textFieldString,
			textfieldsingleline = true,
			shapeType = textBg.shapeType,
			rounded = textBg.rounded
		})
		inputField:addMouseHandlers(function()
				TBMenu:enableMenuKeyboard(inputField)
				chat_input_deactivate()
			end)
		TBMenu:displayTextfield(inputField, fontid, scale, color, defaultStr, orientation, noCursor)
		return inputField
	end

	function TBMenu:displayTextfield(element, fontid, scale, color, defaultStr, orientation, noCursor)
		local defaultStr = defaultStr or ""
		local orientation = orientation or LEFTMID
		local scale = scale or 1
		
		element:addAdaptedText(true, defaultStr, nil, nil, fontid, orientation, scale, nil, nil, nil, nil, nil, true)
		local defaultStringScale = element.textScale

		element:addCustomDisplay(true, function()
				if (element.keyboard == true) then
					set_color(1, 1, 1, 0.2)
					draw_quad(element.parent.pos.x, element.parent.pos.y, element.parent.size.w, element.parent.size.h)
					local part1 = element.textfieldstr[1]:sub(0, element.textfieldindex)
					local part2 = element.textfieldstr[1]:sub(element.textfieldindex + 1)
					local displayString = part1 .. (noCursor and "" or "|") .. part2
					element:uiText(displayString, nil, nil, fontid, orientation, scale, nil, nil, color, nil, nil, nil, nil, nil, true)
				else
					if (element.menuKeyboardId) then
						TBMenu:disableMenuKeyboard(element)
						chat_input_activate()
					end
					if (element.textfieldstr[1] == "") then
						element:uiText(defaultStr, nil, nil, fontid, orientation, defaultStringScale, nil, nil, { color[1], color[2], color[3], color[4] * 0.5 }, nil, nil, nil, nil, nil, true)
					else
						element:uiText(element.textfieldstr[1], nil, nil, fontid, orientation, scale, nil, nil, color, nil, nil, nil, nil, nil, true)
					end
				end
			end)
	end

end
