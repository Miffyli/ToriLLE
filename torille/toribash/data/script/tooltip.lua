-- tooltip.lua

local tooltip = nil

local function set_tooltip(player, joint)
	if (joint ~= -1) then
		tooltip = { }
		tooltip['player'] = player
		tooltip['joint'] = joint
		tooltip['joint_info'] = get_joint_info(player, joint)
		tooltip['pos'] = { x=0, y=0 }
		tooltip['pos'].x, tooltip['pos'].y = get_joint_screen_pos(player, joint)
	else
		tooltip = nil
	end
end

local function draw_tooltip()
	if (tooltip ~= nil and get_world_state().replay_mode == 0) then
		set_color(0.5, 0.5, 0.5, 0.4)
		draw_quad(tooltip.pos.x + 30, tooltip.pos.y + 10, 160, 30)
		set_color(0, 0, 0, 1)
		draw_text(tooltip.joint_info.name, tooltip.pos.x + 40, tooltip.pos.y + 15)

		-- Draw the state name
		set_color(0.7, 0.7, 0.7, 0.3)
		draw_quad(tooltip.pos.x + 30, tooltip.pos.y + 40, 160, 30)
		set_color(0.0, 0.3, 0.0, 1.0)
		draw_text(get_joint_info(tooltip.player, tooltip.joint).screen_state, tooltip.pos.x + 40, tooltip.pos.y + 45)

	end
end

add_hook("joint_select", "tooltip", set_tooltip)
add_hook("draw2d", "tooltip", draw_tooltip)
