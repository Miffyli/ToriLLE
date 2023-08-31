-- clans view script
-- made by sir
CLANLISTLASTPOS = { scroll = {}, list = {} }
TB_MENU_DEFAULT_BG_COLOR = { 0.67, 0.11, 0.11, 1 }
TB_MENU_DEFAULT_DARKER_COLOR = { 0.607, 0.109, 0.109, 1 }

dofile("system/menu_manager.lua")
dofile("system/clans_manager.lua")
dofile("system/player_info.lua")
dofile("toriui/uielement.lua")

if (tbMenuMain) then
	tbMenuMain:kill()
end

TB_MENU_PLAYER_INFO = {}
TB_MENU_PLAYER_INFO.username = PlayerInfo:getUser()
TB_MENU_PLAYER_INFO.clan = PlayerInfo:getClan(TB_MENU_PLAYER_INFO.username)

TBMenu:create()
function TBMenu:addBottomBloodSmudge() end
TBMenu:getTranslation(get_language())

if (not Clans:getLevelData() or not Clans:getAchievementData() or not Clans:getClanData()) then
	return
end

tbMenuMain = UIElement:new({
	globalid = 1101,
	pos = { WIN_W / 10, WIN_H / 7 },
	size = { WIN_W / 10 * 8, WIN_H / 7 * 5 },
})
local navBarBG = UIElement:new({
	parent = tbMenuMain,
	pos = { 0, 0 },
	size = { tbMenuMain.size.w, 30 },
	bgColor = { 0, 0, 0, 0.95 }
})
tbMenuNavigationBar = UIElement:new({
	parent = navBarBG,
	pos = { 0, 0 },
	size = { navBarBG.size.w, navBarBG.size.h }
})

tbMenuCurrentSection = UIElement:new({
	parent = tbMenuMain,
	pos = { 0, navBarBG.size.h },
	size = { tbMenuMain.size.w, tbMenuMain.size.h - navBarBG.size.h },
	bgColor = TB_MENU_DEFAULT_DARKER_COLOR
})

local clanId = nil
if (ARG1 ~= "") then
	local clanTag = PlayerInfo:getClanTag(ARG1)
	for i,v in pairs(ClanData) do
		if (v.tag == clanTag) then
			clanId = v.id
			break
		end
	end
end

if (clanId) then
	Clans:showClan(tbMenuCurrentSection, clanId)
else
	Clans:showMain(tbMenuCurrentSection)
end


add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
add_hook("draw2d", "tbMainMenuVisual", function() UIElement:drawVisuals(1101) end)
add_hook("draw_viewport", "tbMainMenuVisual", function() UIElement:drawViewport(1101) end)
