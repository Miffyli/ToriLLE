dofile("toriui/uielement.lua")

DiscordRPCInstancesOpen = DiscordRPCInstancesOpen or 0

DISCORD_GLOBALID = 2000

local DiscordColorBlack = { 0.137, 0.153, 0.165, 1 }
local DiscordColorDark = { 0.173, 0.184, 0.2, 1 }
local DiscordColorBlurple = { 0.447, 0.514, 0.855, 1 }
local DiscordColorBlurpleHover = { 0.55, 0.6, 1, 1 }
local DiscordColorBlurplePress = { 0.34, 0.44, 0.7, 1 }
local DiscordColorRed = { 0.941, 0.278, 0.278, 1 }
local DiscordColorRedHover = { 1, 0.32, 0.32, 1 }
local DiscordColorRedPress = { 0.8, 0.2, 0.2, 1 }
local DiscordColorDecline = { 0.212, 0.22, 0.227, 1 }


local DiscordRPC = {}
DiscordRPC.__index = DiscordRPC
local cln = {}
setmetatable(cln, DiscordRPC)

local DiscordUsername, DiscordUserid, DiscordAvatar = ARG1:match(("([^ ]*) *"):rep(3))

if (DiscordUsername == "" or DiscordUserid == "" or DiscordAvatar == "") then
	return
end

function DiscordRPC:quit(viewElement, buttons)
	for i,v in pairs(buttons) do
		v:deactivate()
	end
	
	local progress = math.pi / 60
	viewElement:addCustomDisplay(false, function()
			if (viewElement.pos.x > -viewElement.size.w) then
				viewElement:moveTo(-viewElement.size.w * math.sin(progress))
				progress = progress + math.pi / 60
			else
				DiscordRPCInstancesOpen = DiscordRPCInstancesOpen - 1
				viewElement:kill()
				if (DiscordRPCInstancesOpen == 0) then
					remove_hooks("tbDiscordRPCVisuals")
				end
			end
		end)
end

function DiscordRPC:show()
	DiscordRPCInstancesOpen = DiscordRPCInstancesOpen + 1
	local discordOverlay = UIElement:new({
		globalid = DISCORD_GLOBALID,
		pos = { -405, WIN_H - 200 },
		size = { 405, 110 },
		bgColor = DiscordColorBlack,
		shapeType = ROUNDED,
		rounded = 5
	})
	local progress = math.pi / 60
	discordOverlay:addCustomDisplay(false, function()
			if (discordOverlay.pos.x < -5) then
				discordOverlay:moveTo(-discordOverlay.size.w + discordOverlay.size.w * math.sin(progress))
				progress = progress + math.pi / 60
			else
				discordOverlay:moveTo(-5)
				discordOverlay:addCustomDisplay(false, function() end)
			end
		end)
	local discordBackgroundAnimation = UIElement:new({
		parent = discordOverlay,
		pos = { 5, 0 },
		size = { discordOverlay.size.w - 5, discordOverlay.size.h }
	})
	local circles = {}
	while (#circles < 30) do
		local whites = math.random(40, 90) / 100
		local blues = 1
		local circle = { 
			color = { whites, whites, blues, 1 }, 
			size = math.random(20, 60) / 10, 
			x = math.random(math.random(15, discordOverlay.size.w - 15), discordOverlay.size.w - 15),
		 	y = math.random(math.random(15, discordOverlay.size.h - 15), discordOverlay.size.h - 15)
		}
		table.insert(circles, circle)
	end
	discordBackgroundAnimation:addCustomDisplay(true, function()
			while (#circles < 30) do
				local whites = math.random(40, 90) / 100
				local blues = 1
				local circle = { 
					color = { whites, whites, blues, 1 }, 
					size = math.random(20, 60) / 10, 
					x = math.random(math.random(15, discordOverlay.size.w - 15), discordOverlay.size.w - 15),
				 	y = discordOverlay.size.h - 40
				}
				table.insert(circles, circle)
			end
			for i = #circles, 1, -1 do
				set_color(circles[i].color[1], circles[i].color[2], circles[i].color[3], (circles[i].y - 5.5) / discordOverlay.size.h * 2)
				draw_disk(discordOverlay.pos.x + circles[i].x + circles[i].size / 2, discordOverlay.pos.y + circles[i].y + circles[i].size / 2, 0, circles[i].size, 500, 1, 0, 360, 0)
				circles[i].y = circles[i].y - 0.2
				circles[i].x = circles[i].x - 0.08
				if (circles[i].y < 6) then
					table.remove(circles, i)
				end
			end
		end)
	local discordUsernameView = UIElement:new({
		parent = discordOverlay,
		pos = { 10, 10 },
		size = { discordOverlay.size.w - 20, 40 }
	})
	local discordLogo = UIElement:new({
		parent = discordUsernameView,
		pos = { 0, 0 },
		size = { discordUsernameView.size.h, discordUsernameView.size.h },
		bgImage = "../textures/menu/logos/discord.tga"
	})
	local discordUsername = UIElement:new({
		parent = discordUsernameView,
		pos = { discordUsernameView.size.h + discordUsernameView.shift.x, 0 },
		size = { discordUsernameView.size.w - discordUsernameView.size.h - discordUsernameView.shift.x, discordUsernameView.size.h / 2 }
	})
	discordUsername:addCustomDisplay(true, function()
			discordUsername:uiText(DiscordUsername, nil, nil, 4, LEFTBOT, 0.9, nil, 1)
		end)
	local discordStatusMessage = UIElement:new({
		parent = discordUsernameView,
		pos = { discordUsername.shift.x, discordUsername.size.h },
		size = { discordUsername.size.w, discordUsernameView.size.h / 2 }
	})
	discordStatusMessage:addCustomDisplay(true, function()
			discordStatusMessage:uiText("wants to join your game!", nil, nil, 4, LEFT, 0.7, nil, 0.5)
		end)
	local buttons = {}
	local discordAccept = UIElement:new({
		parent = discordOverlay,
		pos = { discordUsernameView.shift.x, discordUsernameView.shift.y * 2 + discordUsernameView.size.h },
		size = { (discordOverlay.size.w - discordUsernameView.shift.x * 3) / 2, discordOverlay.size.h - discordUsernameView.size.h - discordUsernameView.shift.y * 3 },
		shapeType = ROUNDED,
		rounded = 4,
		interactive = true,
		bgColor = DiscordColorBlurple,
		hoverColor = DiscordColorBlurpleHover,
		pressedColor = DiscordColorBlurplePress
	})
	table.insert(buttons, discordAccept)
	local discordDecline = UIElement:new({
		parent = discordOverlay,
		pos = { -discordUsernameView.shift.x - discordAccept.size.w, discordUsernameView.shift.y * 2 + discordUsernameView.size.h },
		size = { (discordOverlay.size.w - discordUsernameView.shift.x * 3) / 2, discordOverlay.size.h - discordUsernameView.size.h - discordUsernameView.shift.y * 3 },
		shapeType = ROUNDED,
		rounded = 4,
		interactive = true,
		bgColor = DiscordColorDecline,
		hoverColor = DiscordColorRed,
		pressedColor = DiscordColorRedPress
	})
	table.insert(buttons, discordDecline)
	
	discordAccept:addAdaptedText(false, "Accept")
	discordAccept:addMouseHandlers(nil, function()
			DiscordRPC:quit(discordOverlay, buttons)
			discord_accept_join(DiscordUserid)
		end)
	discordDecline:addAdaptedText(false, "Decline")
	discordDecline:addMouseHandlers(nil, function()
			DiscordRPC:quit(discordOverlay, buttons)
			discord_reject_join(DiscordUserid)
		end)
end

add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
add_hook("draw2d", "tbDiscordRPCVisuals", function() UIElement:drawVisuals(DISCORD_GLOBALID) end)

DiscordRPC:show()
