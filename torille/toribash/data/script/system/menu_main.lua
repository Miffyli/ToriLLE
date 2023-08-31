-- modern main menu UI
-- DO NOT MODIFY THIS FILE

-- If tutorials are active, ESC press launches tutorial exit popup instead of main menu
if (TUTORIAL_ISACTIVE) then
	return
end

TB_MENU_DEBUG = false

TB_MENU_MAIN_ISOPEN = TB_MENU_MAIN_ISOPEN or 0
TB_MENU_SPECIAL_SCREEN_ISOPEN = TB_MENU_SPECIAL_SCREEN_ISOPEN or 0
TB_MENU_CLANS_OPENCLANID = TB_MENU_CLANS_OPENCLANID or 0
TB_MENU_NOTIFICATIONS_ISOPEN = 0
TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT or 0
TB_MENU_REPLAYS_ONLINE = TB_MENU_REPLAYS_ONLINE or 0
TB_MENU_DOWNLOAD_INACTION = TB_MENU_DOWNLOAD_INACTION or false
TB_MENU_KEYBOARD_ENABLED = false
TB_LAST_MENU_SCREEN_OPEN = TB_LAST_MENU_SCREEN_OPEN or (get_option("newshopitem") == 1 and 1 or 2)
TB_MENU_HOME_CURRENT_ANNOUNCEMENT = TB_MENU_HOME_CURRENT_ANNOUNCEMENT or 1

if (TORISHOP_ISOPEN == 1) then
	start_new_game()
	TORISHOP_ISOPEN = 0
end

if (TB_MENU_MAIN_ISOPEN == 1) then
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
	return
end

if (get_option("newmenu") == 0) then
	echo("You need to enable new UI to load this.")
	echo("   ^08/opt newmenu 1")
	return
end

dofile("toriui/uielement3d.lua")

-- Set old UI and return
if (WIN_W < 950 or WIN_H < 600) then
	set_option("newmenu", "0")
	return
end

dofile("system/menu_manager.lua")

TBMenu:create()
TBMenu:getTranslation(get_language())

dofile("system/store_manager.lua")
dofile("system/player_info.lua")
dofile("system/matchmake_manager.lua")
dofile("system/notifications_manager.lua")
dofile("system/quests_manager.lua")
dofile("system/rewards_manager.lua")
dofile("system/clans_manager.lua")
dofile("system/friendlist_manager.lua")
dofile("system/replays_manager.lua")
dofile("system/bounty_manager.lua")
dofile("system/settings_manager.lua")
dofile("system/scripts_manager.lua")
dofile("system/events_manager.lua")

TB_MENU_PLAYER_INFO = {}
TB_MENU_PLAYER_INFO.username = PlayerInfo:getUser()
TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData()
TB_MENU_PLAYER_INFO.ranking = PlayerInfo:getRanking()
TB_MENU_PLAYER_INFO.clan = PlayerInfo:getClan(TB_MENU_PLAYER_INFO.username)
TB_MENU_PLAYER_INFO.items = PlayerInfo:getItems(TB_MENU_PLAYER_INFO.username)

if (os.clock() < 10) then
	TB_STORE_DATA = { onsale = Torishop:getSaleItem(true) }
else
	if (not TB_STORE_DATA or not TB_STORE_DATA.ready) then
		TB_STORE_DATA = Torishop:getItems()
		if (not TB_STORE_DATA.failed) then
			TB_STORE_DATA.ready = true
			TB_STORE_DATA.onsale = Torishop:getSaleItem()
		end
	end
end

if (PlayerInfo:getLoginRewards().available and TB_STORE_DATA.ready and not TB_MENU_NOTIFICATION_LOGINREWARDS) then
	TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT + 1
	TB_MENU_NOTIFICATION_LOGINREWARDS = true
end

local launchOption = ARG1
if (launchOption == "15") then
	TBMenu:showMain(true)
	TBMenu:showTorishopMain()
elseif (launchOption == "friendslist") then
	TBMenu:showMain(true)
	TBMenu:showFriendsList()
elseif (launchOption == "matchmake" and TB_MENU_SPECIAL_SCREEN_ISOPEN == 2) then
	TBMenu:showMain(true)
	TBMenu:showMatchmaking()
elseif (launchOption:match("clans ")) then
	TBMenu:showMain(true)
	local clantag = launchOption:gsub("clans ", "")
	clantag = PlayerInfo:getClanTag(clantag)
	TBMenu:showClans(clantag)
elseif (launchOption == "register") then
	TBMenu:showMain()
	TBMenu:quit()
	dofile("tutorial/tutorial_manager.lua")
	Tutorials:runTutorial(1)
else
	TBMenu:showMain()
end

-- Wait for customs update on client start
if (os.clock() < 10) then
	add_hook("draw2d", "playerinfoUpdate", function()
			if (#get_downloads() == 0) then
				TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData()
				TB_MENU_PLAYER_INFO.ranking = PlayerInfo:getRanking()
				TB_MENU_PLAYER_INFO.clan = PlayerInfo:getClan(TB_MENU_PLAYER_INFO.username)
				TB_MENU_PLAYER_INFO.items = PlayerInfo:getItems(TB_MENU_PLAYER_INFO.username)
				TB_STORE_DATA = Torishop:getItems()
				if (not TB_STORE_DATA.failed) then
					TB_STORE_DATA.ready = true
					TB_STORE_DATA.onsale = Torishop:getSaleItem()
				end
				if (PlayerInfo:getLoginRewards().available and TB_MENU_MAIN_ISOPEN == 1) then
					if (TB_MENU_SPECIAL_SCREEN_ISOPEN == 0 and TB_MENU_IGNORE_REWARDS == 0) then
						TBMenu:showNotifications()
					end
				end
				remove_hooks("playerinfoUpdate")
				download_clan()
			end
		end)
	-- Set default atmosphere from a draw2d hook so that shader settings are applied properly
	if (not DEFAULT_ATMOSPHERE_ISSET) then
		add_hook("draw2d", "atmodefault", function()
				dofile("system/atmospheres_defines.lua")
				dofile("system/atmospheres_manager.lua")
				Atmospheres:loadDefaultAtmo()
				remove_hooks("atmodefault")
			end)
	end
end

add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y)
		UIElement:handleMouseDn(s, x, y)
		if (TB_MENU_MAIN_ISOPEN == 1) then
			return 1
		end
	end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y)
		UIElement:handleMouseHover(x, y)
		if (TB_MENU_MAIN_ISOPEN == 1) then
			return 1
		end
	end)
add_hook("mouse_move", "tbMainMenuMouse", function(x, y)
		if (INVENTORY_UPDATE) then
			if (x ~= INVENTORY_MOUSE_POS.x or y ~= INVENTORY_MOUSE_POS.y) then
				if (x > WIN_W / 2) then
					Torishop:refreshInventory()
					if (INVENTORY_SELECTION_RESET) then
						INVENTORY_SELECTED_ITEMS = {}
						INVENTORY_SELECTION_RESET = false
					end
				else
					INVENTORY_UPDATE = false
					INVENTORY_SELECTION_RESET = false
				end
			end
		end
	end)
add_hook("key_up", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyUp(s) return 1 end)
add_hook("key_down", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyDown(s) return 1 end)
add_hook("draw2d", "tbMainMenuVisual", function() UIElement:drawVisuals(TB_MENU_MAIN_GLOBALID) end)
add_hook("draw_viewport", "tbMainMenuVisual", function() UIElement:drawViewport(TB_MENU_MAIN_GLOBALID) end)

add_hook("console", "tbMainMenuStatic", function(s, i)
		if (s == "Download complete" and TB_MENU_DOWNLOAD_INACTION) then
			TB_MENU_DOWNLOAD_INACTION = false
			return 1
		end
	end)
add_hook("new_mp_game", "tbMainMenuStatic", function()
		if (TB_MENU_MAIN_ISOPEN == 1) then
			TB_MATCHMAKER_SEARCHSTATUS = nil
			close_menu()
		end
	end)

-- Keep hub elements always displayed above tooltip and movememory
add_hook("draw2d", "tbMainHubVisual", function()
		if (TB_MENU_MAIN_ISOPEN == 0) then
			if (TOOLTIP_ACTIVE) then
				UIElement:drawVisuals(TB_TOOLTIP_GLOBALID)
			end
			if (TB_MOVEMEMORY_ISOPEN == 1) then
				UIElement:drawVisuals(TB_MOVEMEMORY_GLOBALID)
			end
			UIElement:drawVisuals(TB_MENU_HUB_GLOBALID)
		end
	end)

-- Load miscellaneous scripts
if (get_option("chatcensor") > 0 and not CHATIGNORE_ACTIVE) then
	dofile("system/ignore_manager.lua")
	ChatIgnore:activate()
end
if (get_option("movememory") == 1 and not MOVEMEMORY_ACTIVE) then
	dofile("system/movememory_manager.lua")
	MoveMemory:spawnHotkeyListener()
end
if (get_option("tooltip") == 1 and not TOOLTIP_ACTIVE) then
	dofile("system/tooltip_manager.lua")
	Tooltip:create()
end
