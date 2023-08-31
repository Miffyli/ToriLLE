-- DO NOT MODIFY THIS FILE
-- Old UI friends interface
TB_MENU_DEFAULT_BG_COLOR = { 0.67, 0.11, 0.11, 1 }
TB_MENU_DEFAULT_DARKER_COLOR = { 0.607, 0.109, 0.109, 1 }

dofile("toriui/uielement.lua")
dofile("system/menu_manager.lua")
dofile("system/friendlist_manager.lua")

if (tbMenuMain) then
	FRIENDSLIST_OPEN = false
	tbMenuMain:kill()
end

FRIENDSLIST_OPEN = true
TBMenu:create()
function TBMenu:addBottomBloodSmudge() end
TBMenu:getTranslation(get_language())

tbMenuMain = UIElement:new({
	globalid = 1100,
	pos = { WIN_W / 8, WIN_H / 5 },
	size = { WIN_W / 8 * 6, WIN_H / 5 * 3 },
})
local navBarBG = UIElement:new({
	parent = tbMenuMain,
	pos = { 0, 0 },
	size = { tbMenuMain.size.w, 50 },
	bgColor = { 0, 0, 0, 0.95 }
})
tbMenuNavigationBar = UIElement:new({
	parent = navBarBG,
	pos = { 0, 0 },
	size = { navBarBG.size.w, navBarBG.size.h }
})

tbMenuCurrentSection = UIElement:new({
	parent = tbMenuMain,
	pos = { 0, 50 },
	size = { tbMenuMain.size.w, tbMenuMain.size.h - 50 },
	bgColor = TB_MENU_DEFAULT_DARKER_COLOR
})

TBMenu:showFriendsList()

add_hook("key_up", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyUp(s) if (FRIENDSLIST_OPEN) then return 1 end end)
add_hook("key_down", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyDown(s) if (FRIENDSLIST_OPEN) then return 1 end end)
add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
add_hook("draw2d", "tbMainMenuVisual", function() UIElement:drawVisuals(1100) end)
