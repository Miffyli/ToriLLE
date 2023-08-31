-- Modern UI mods screen
-- DO NOT MODIFY THIS FILE

dofile("toriui/uielement3d.lua")
dofile("system/iofiles.lua")
dofile("system/menu_manager.lua")
dofile("system/mods_manager.lua")

if (MODS_MENU_MAIN_ELEMENT) then
	MODS_MENU_MAIN_ELEMENT:kill()
	MODS_MENU_MAIN_ELEMENT = nil
	return
end

Mods:showMain()