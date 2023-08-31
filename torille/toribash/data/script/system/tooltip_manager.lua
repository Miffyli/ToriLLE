FRACTURECOLOR = { 0.44, 0.41, 1, 1 }
DISMEMBERCOLOR = cloneTable(UICOLORRED)
BACKGROUNDCOLOR = cloneTable(TB_MENU_DEFAULT_DARKEST_COLOR)
BACKGROUNDCOLOR[4] = 0.6

PLAYERINFO = {}
do
	Tooltip = {}
    Tooltip.__index = Tooltip
	local cln = {}
	setmetatable(cln, Tooltip)
	
	function Tooltip:quit()
		TOOLTIP_ACTIVE = false
		remove_hooks("tbSystemTooltip")
		if (tbTooltip) then
			tbTooltip:kill()
		end
	end
	
	function Tooltip:create()
		PLAYERINFO = PlayerInfo:getItems(PlayerInfo:getUser())
		local forceInfo = get_color_info(PLAYERINFO.colors.force)
		local relaxInfo = get_color_info(PLAYERINFO.colors.relax)
		PLAYERINFO = { rgbForce = { forceInfo.r, forceInfo.g, forceInfo.b, 1 }, rgbRelax = { relaxInfo.r, relaxInfo.g, relaxInfo.b, 1 }, default = PLAYERINFO.colors.default }
		if (not TOOLTIP_ACTIVE) then
			add_hook("joint_select", "tbSystemTooltip", function(player, joint)
					Tooltip:showTooltipJoint(player, joint)
				end)
			add_hook("body_select", "tbSystemTooltip", function(player, body)
					Tooltip:showTooltipBody(player, body)
				end)
		end
		TOOLTIP_ACTIVE = true
	end
	
	function Tooltip:reload()
		Tooltip:quit()
		Tooltip:create()
	end
	
	function Tooltip:showTooltipBody(player, body)
		if (tbTooltip) then
			tbTooltip:kill()
			BODYTOOLTIPACTIVE = false
		end
		if (get_option("tooltip") == 0) then
			Tooltip:quit()
			return
		end
		if (get_world_state().replay_mode == 1) then
			return
		end
		if (body > -1) then
			BODYTOOLTIPACTIVE = true
			local bodyInfo = get_body_info(player, body)
			bodyInfo.name = bodyInfo.name:gsub("^R_", "RIGHT "):gsub("^L_", "LEFT ")
			
			local height = (body == 11 or body == 12) and 70 or 40
			local width = get_string_length(bodyInfo.name, FONTS.MEDIUM) + 20 
			width = width < 200 and 200 or width
			local heightMod = (body == 11 or body == 12) and 3 or 2
			
			tbTooltip = UIElement:new({
				globalid = TB_TOOLTIP_GLOBALID,
				pos = { MOUSE_X + 15, MOUSE_Y - 15 },
				size = { width, height }
			})
			local frame = get_world_state().match_frame
			tbTooltip:addCustomDisplay(true, function()
					local ws = get_world_state()
					if (ws.replay_mode == 1 or ws.match_frame ~= frame or TB_MENU_MAIN_ISOPEN == 1 or ws.selected_player < 0) then
						tbTooltip:kill()
						BODYTOOLTIPACTIVE = false
						return
					end
					tbTooltip:moveTo(MOUSE_X + 15, MOUSE_Y - 15)
					if (tbTooltip.pos.x + tbTooltip.size.w > WIN_W - 10) then
						tbTooltip:moveTo(WIN_W - 10 - tbTooltip.size.w)
					end
					if (tbTooltip.pos.y + tbTooltip.size.h > WIN_H - 10) then
						tbTooltip:moveTo(nil, WIN_H - 10 - tbTooltip.size.h)
					end
				end)
			if (tbTooltip.pos.x + tbTooltip.size.w > WIN_W - 10) then
				tbTooltip:moveTo(WIN_W - 10 - tbTooltip.size.w)
			end
			if (tbTooltip.pos.y + tbTooltip.size.h > WIN_H - 10) then
				tbTooltip:moveTo(nil, WIN_H - 10 - tbTooltip.size.h)
			end
			
			local tbTooltipOutline = UIElement:new({
				parent = tbTooltip,
				pos = { 0, 0 },
				size = { tbTooltip.size.w, tbTooltip.size.h },
				bgColor = { 1, 1, 1, 0.4 },
				shapeType = ROUNDED,
				rounded = 4
			})
			local tbTooltipView = UIElement:new({
				parent = tbTooltipOutline,
				pos = { 1, 1 },
				size = { tbTooltipOutline.size.w - 2, tbTooltipOutline.size.h - 2 },
				bgColor = BACKGROUNDCOLOR,
				shapeType = tbTooltipOutline.shapeType,
				rounded = tbTooltipOutline.rounded
			})
			local jointTooltipName = UIElement:new({
				parent = tbTooltipView,
				pos = { 10, 5 },
				size = { tbTooltipView.size.w - 20, tbTooltipView.size.h / heightMod * 2 - 10 }
			})
			jointTooltipName:addAdaptedText(true, bodyInfo.name, nil, nil, nil, LEFTMID)
			
			if (body == 11 or body == 12) then
				local jointTooltipState = UIElement:new({
					parent = tbTooltipView,
					pos = { tbTooltipView.size.h / 3 + 10, jointTooltipName.shift.y + jointTooltipName.size.h },
					size = { tbTooltipView.size.w - tbTooltipView.size.h / 3 - 25, tbTooltipView.size.h / 3 - 5 }
				})
				local function drawGrabState(state)
					set_color(0.9, 0.9, 0.9, 1)
					if (state == 0) then
						draw_quad(tbTooltipView.pos.x + 10, jointTooltipState.pos.y, tbTooltipView.size.h / 3 - 5, tbTooltipView.size.h / 3 - 5)
					else
						draw_quad(tbTooltipView.pos.x + 10, jointTooltipState.pos.y + tbTooltip.size.h / 12, tbTooltipView.size.h / 3 - 5, tbTooltipView.size.h / 9)
						set_color(0, 1, 0, 1)
						draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 6 * 5, jointTooltipState.pos.y + jointTooltipState.size.h / 3 * 2, 0, jointTooltipState.size.h / 3, 500, 1, 0, 360, 1)
					end
				end
				
				jointTooltipState:addCustomDisplay(true, function()
						local grab = get_grip_info(player, body)
						drawGrabState(grab)
						jointTooltipState:uiText(grab == 0 and "UNGRABBING" or "GRABBING", nil, nil, 4, LEFTMID, 0.7)
					end)
			end
		end
	end
	
	function Tooltip:showTooltipJoint(player, joint)
		if (PLAYERINFO.default) then
			PLAYERINFO = PlayerInfo:getItems(PlayerInfo:getUser())
			local forceInfo = get_color_info(PLAYERINFO.colors.force)
			local relaxInfo = get_color_info(PLAYERINFO.colors.relax)
			PLAYERINFO = { rgbForce = { forceInfo.r, forceInfo.g, forceInfo.b, 1 }, rgbRelax = { relaxInfo.r, relaxInfo.g, relaxInfo.b, 1 }, default = PLAYERINFO.colors.default }
		end
		if (tbTooltip and not BODYTOOLTIPACTIVE) then
			tbTooltip:kill()
		end
		if (get_option("tooltip") == 0) then
			Tooltip:quit()
			return
		end
		if (get_world_state().replay_mode == 1) then
			return
		end
		if (joint > -1) then
			local jointInfo = get_joint_info(player, joint)
			jointInfo.pos = {}
			jointInfo.pos.x, jointInfo.pos.y, jointInfo.pos.z = get_joint_pos(player, joint)
			
			local width = get_string_length(jointInfo.name, FONTS.MEDIUM) + 20 
			width = width < 200 and 200 or width
			
			tbTooltip = UIElement:new({
				globalid = TB_TOOLTIP_GLOBALID,
				pos = { MOUSE_X + 15, MOUSE_Y - 15 },
				size = { width, 70 }
			})
			local frame = get_world_state().match_frame
			tbTooltip:addCustomDisplay(true, function()
					local ws = get_world_state()
					if (ws.replay_mode == 1 or ws.match_frame ~= frame or TB_MENU_MAIN_ISOPEN == 1 or ws.selected_player < 0) then
						tbTooltip:kill()
						return
					end
					tbTooltip:moveTo(MOUSE_X + 15, MOUSE_Y - 15)
					if (tbTooltip.pos.x + tbTooltip.size.w > WIN_W - 10) then
						tbTooltip:moveTo(WIN_W - 10 - tbTooltip.size.w)
					end
					if (tbTooltip.pos.y + tbTooltip.size.h > WIN_H - 10) then
						tbTooltip:moveTo(nil, WIN_H - 10 - tbTooltip.size.h)
					end
				end)
			if (tbTooltip.pos.x + tbTooltip.size.w > WIN_W - 10) then
				tbTooltip:moveTo(WIN_W - 10 - tbTooltip.size.w)
			end
			if (tbTooltip.pos.y + tbTooltip.size.h > WIN_H - 10) then
				tbTooltip:moveTo(nil, WIN_H - 10 - tbTooltip.size.h)
			end
			local tbTooltipOutline = UIElement:new({
				parent = tbTooltip,
				pos = { 0, 0 },
				size = { tbTooltip.size.w, tbTooltip.size.h },
				bgColor = { 1, 1, 1, 0.4 },
				shapeType = ROUNDED,
				rounded = 4
			})
			local tbTooltipView = UIElement:new({
				parent = tbTooltipOutline,
				pos = { 1, 1 },
				size = { tbTooltipOutline.size.w - 2, tbTooltipOutline.size.h - 2 },
				bgColor = BACKGROUNDCOLOR,
				shapeType = tbTooltipOutline.shapeType,
				rounded = tbTooltipOutline.rounded
			})
			local jointTooltipName = UIElement:new({
				parent = tbTooltipView,
				pos = { 10, 5 },
				size = { tbTooltipView.size.w - 20, tbTooltipView.size.h / 3 * 2 - 10 }
			})
			jointTooltipName:addAdaptedText(true, jointInfo.name, nil, nil, nil, LEFTMID)
			
			local jointTooltipState = UIElement:new({
				parent = tbTooltipView,
				pos = { tbTooltipView.size.h / 3 + 10, jointTooltipName.shift.y + jointTooltipName.size.h },
				size = { tbTooltipView.size.w - tbTooltipView.size.h / 3 - 25, tbTooltipView.size.h / 3 - 5 }
			})
			local function drawDismembered()
				set_color(unpack(DISMEMBERCOLOR))
				draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 2, 500, 1, 0, 360, 0)
			end
			local function drawFractured()
				set_color(unpack(FRACTURECOLOR))
				draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 2, 500, 1, 0, 360, 0)
			end
			local function drawJointState(state)				
				if (state ~= 3) then
					set_color(unpack(PLAYERINFO.rgbRelax))
					draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 3, 500, 1, 0, 360, 0)
					if (state == 4) then
						return
					end
				end
				local rotation = 0
				local scale = 360
				if (state == 1) then
					rotation = 40
					scale = 180
				elseif (state == 2) then
					rotation = 220
					scale = 180
				end
				set_color(unpack(PLAYERINFO.rgbForce))
				draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 2 - 0.5, 500, 1, rotation, scale, 0)
			end
			jointTooltipState:addCustomDisplay(true, function()
					-- Getting full joint state
					local dismembered = get_joint_dismember(player, joint)
					if (dismembered) then
						drawDismembered()
						jointTooltipState:uiText("DISMEMBERED", nil, nil, 4, LEFTMID, 0.7, nil, 0.2, nil, UICOLORRED)
						return
					end
					local fractured = get_joint_fracture(player, joint)
					if (fractured) then
						drawFractured()
						jointTooltipState:uiText("FRACTURED", nil, nil, 4, LEFTMID, 0.7, nil, 0.2, nil, UICOLORBLUE)
						return
					end
					local jInfo = get_joint_info(player, joint)
					drawJointState(jInfo.state)
					jointTooltipState:uiText(jInfo.screen_state, nil, nil, 4, LEFTMID, 0.7)
				end)
		end
	end
end
