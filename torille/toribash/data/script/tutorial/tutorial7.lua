local width, height = get_window_size()
local curtime = os.clock
local player_name = get_master().master.nick

local SPACE = 1

-- User settings
local default_opt = {backgroundclick = 0, autosave = 0, hud = 0}

local completion = 0
local completion_change = completion
local wait_for_continue = false
local step = 0
local t0, t1 = 0, 0
local modifier, width_modifier, height_modifier, trans_modifier, mp_modifier = 0, 0, 0, 1, 0
local change_init = false
local tut_end = false

local std_delay = 5

local continue_colors = { r = 0.6, g = 0.6, b = 0.6 }
local globaltimeouts = { }
	
local conditions_load = false

local messages = {
	{
		"Welcome back!",
		"In this tutorial you'll learn how to perform basic moves",
		"Before you get into your first fight, you have to understand",
		"How different joints affect your movements",
		"Let's finish watching this replay",
		"And then try to replicate it",
		"The first thing you need to do is jump",
		"To reach Uke's head with your leg kick",
		"To do that, let's contract the right hip",
		"And extend your left hip",
		"Now contract your left knee and extend the left ankle",
		"To increase the momentum and jump higher",
		"Great, time to finish the turn! As this is your first move,",
		"We'll help you a little bit to make the kick better",
		"To give your jump a needed angle, we'll extend both glutes",
		"And rotate your chest to the right",
		"Now press space to finish the turn",
		"Great!",
		"Now you'll need to rotate your body",
		"To add force to your leg kick",
		"First off, rotate your chest to the left",
		"Contract your right pec and extend left pec to finish this turn",
		"Hit space when you're ready",
		"Time to get your leg ready for the kick",
		"Contract your left hip and hit the spacebar to finish the turn",
		"And here goes the fun part!",
		"Extend your knee to decapitate Uke",	
		"and press the spacebar to end this turn!",
		"...",
		"Ok, wait, that was totally unplanned",
		"Let's get back to the moment when we executed the kick",
		"Press \"R\" to restart your current fight",
		"Situations like these are the reason",
		"Why your ghost is so important",
		"Press \"B\" to display both players' ghosts",
		"Now you can see that despite your kick's power",
		"It only slightly touches Uke's head",
		"To adjust the angle and get a perfect kick",
		"Contract your left glute",
		"Press the spacebar, let's see what we got",
		"Awesome!"
	},
	{
	},
	{
		"Time to try out a real fight!",
	}
}

function run_timeout(delta)
	delta = delta or 1	-- Prevent it from being nil

	local final = { }
	for i, t in ipairs(globaltimeouts) do
		t.timeleft = t.timeleft - delta
		if (t.timeleft < 0) then
			t.func()
		else
			table.insert(final, t)
		end
	end
	globaltimeouts = final
end

function update_loop()
	run_timeout(1)
end

function draw_3d()
	render_hand_alert()
	render_joint_alert()
end

function set_timeout(timeout, fn)
	local temp = 0
	if (get_option("framerate") == 30) then
		temp = get_world_state().frame_tick - 350
	else
		temp = get_world_state().frame_tick - 700
	end
	if (fn) then
		table.insert(globaltimeouts, { timeleft = timeout*(get_world_state().frame_tick - temp)/1000, func = fn } )
	end
end

-- Hand/Joint Tooltips
local hand_text = nil
local joint_text = nil
local hand_joint_render = false

function set_hand_tooltip(player, body)
	if ((body == BODYPARTS.L_HAND or body == BODYPARTS.R_HAND) and player == 0) then
		hand_text = { }
		local hand_info = get_body_info(player, body)
		hand_text['body_name'] = hand_info.name
		hand_text['player'] = player
		hand_text['hand'] = body
		hand_text['x'], hand_text['y'] = get_body_screen_pos(player, body)
	else
		hand_text = nil
	end
end

function draw_hand_tooltip()
	if (hand_text ~= nil and hand_joint_render == true) then
		-- get current grip from stored player and hand
		if (get_grip_info(hand_text.player, hand_text.hand) == 0) then
			hand_text['screen_state'] = "RELEASE"
		else
			hand_text['screen_state'] = "GRAB"
		end
		
		if (hand_text.body_name == "L_HAND") then hand_text.body_name = "Left hand"
		elseif (hand_text.body_name == "R_HAND") then hand_text.body_name = "Right hand" end
		
		-- Draw hand name
		set_color(0.7, 0.7, 0.7, 0.8)
		draw_quad(hand_text.x + 30, hand_text.y + 10, 200, 30)
		set_color(0.0, 0.0, 0.0, 1.0)
		draw_text(hand_text.body_name, hand_text.x + 40, hand_text.y + 12, FONTS.MEDIUM)

		-- Draw hand state
		set_color(0.8, 0.8, 0.8, 0.8)
		draw_quad(hand_text.x + 30, hand_text.y + 40, 200, 30)
		set_color(0.0, 0.3, 0.0, 1.0)
		draw_text(hand_text.screen_state, hand_text.x + 40, hand_text.y + 42, FONTS.MEDIUM)
	end
end

function set_joint_tooltip(player, joint)
	if (joint ~= -1 and player == 0) then
		joint_text = { }
		local joint_info = get_joint_info(player, joint)
		joint_text['player'] = player
		joint_text['joint'] = joint
		joint_text['joint_name'] = joint_info.name
		joint_text['x'], joint_text['y'] = get_joint_screen_pos(player, joint)
	else
		joint_text = nil
	end
end

function draw_joint_tooltip()
	if (joint_text ~= nil and hand_joint_render == true) then
		-- get current state from stored player and joint
		joint_text['screen_state'] = get_joint_info(joint_text.player, joint_text.joint).screen_state
		
		if (joint_text.joint_name == "Abs") then joint_text.joint_name = "ABS" end
		
		-- Draw joint name
		set_color(0.7, 0.7, 0.7, 0.8)
		draw_quad(joint_text.x + 30, joint_text.y + 10, 200, 30)
		set_color(0.0, 0.0, 0.0, 1.0)
		draw_text(joint_text.joint_name, joint_text.x + 40, joint_text.y + 12, FONTS.MEDIUM)

		-- Draw joint state
		set_color(0.8, 0.8, 0.8, 0.8)
		draw_quad(joint_text.x + 30, joint_text.y + 40, 200, 30)
		set_color(0.0, 0.3, 0.0, 1.0)
		draw_text(joint_text.screen_state, joint_text.x + 40, joint_text.y + 42, FONTS.MEDIUM)
	end
end

-- Hand/Joint Alerts
local body_alert_size = 0.1
local body_alert_alpha = 1
local hand_alert_render = false
local joint_alert_render = false

function enlarge_body_alert()
	if (joint_alert_render == true or hand_alert_render == true) then
		body_alert_size = body_alert_size + 0.005
		body_alert_alpha = body_alert_alpha - 0.02
		if (body_alert_alpha < 0) then
			body_alert_size = 0.1
			body_alert_alpha = 1
		end
		set_timeout(5, enlarge_body_alert)
	end
end

local left_hand = nil
local right_hand = nil

function start_hand_alert()
	left_hand = get_body_info(0, BODYPARTS.L_HAND)
	right_hand = get_body_info(0, BODYPARTS.R_HAND)

	body_alert_size = 0
	body_alert_alpha = 1
	hand_alert_render = true
	set_timeout(5, enlarge_body_alert)
end

function end_hand_alert()
	hand_alert_render = false
end

function render_hand_alert()
	if (hand_alert_render == true) then
		set_color(0.5, 0.5, 0.5, body_alert_alpha)
		draw_box_m(left_hand.pos.x, left_hand.pos.y, left_hand.pos.z, body_alert_size, body_alert_size, body_alert_size, left_hand.rot)
		draw_box_m(right_hand.pos.x, right_hand.pos.y, right_hand.pos.z, body_alert_size, body_alert_size, body_alert_size, right_hand.rot)
	end
end

local joint = {{ j = nil, x = 0, y = 0, z = 0 }, { j = nil, x = 0, y = 0, z = 0 }}
local color = { relax = 0, force = 0 }

function start_joint_alert(joint_1, joint_2)	-- Pass in up to 2 joints
	joint[1].j = joint_1
	joint[2].j = joint_2

	if (joint[1].j ~= nil) then
		local tmp = get_joint_color(0, joint[1].j)
		color.relax = tmp.joint.relax
		color.force = tmp.joint.force
		joint[1].x, joint[1].y, joint[1].z = get_joint_pos(0, joint[1].j)
		set_selected_joint_force_color(0, joint[1].j, 4)
		set_selected_joint_relax_color(0, joint[1].j, 25)
	end
	if (joint[2].j ~= nil) then
		local tmp = get_joint_color(0, joint[2].j)
		color.relax = tmp.joint.relax
		color.force = tmp.joint.force
		joint[2].x, joint[2].y, joint[2].z = get_joint_pos(0, joint[2].j)
		set_selected_joint_force_color(0, joint[2].j, 4)
		set_selected_joint_relax_color(0, joint[2].j, 25)
	end

	if (joint[1].j ~= nil) then
		body_alert_size = 0.1
		body_alert_alpha = 1
		joint_alert_render = true
		set_timeout(5, enlarge_body_alert)
	end
end

function end_joint_alert()
	joint_alert_render = false

	if (joint[1].j ~= nil) then
		set_selected_joint_relax_color(0, joint[1].j, color.relax)
		set_selected_joint_force_color(0, joint[1].j, color.force)
	end
	if (joint[2].j ~= nil) then
		set_selected_joint_relax_color(0, joint[2].j, color.relax)
		set_selected_joint_force_color(0, joint[2].j, color.force)
	end

	joint[1].j = nil
	joint[2].j = nil
end

function render_joint_alert()
	if (joint_alert_render == true) then
		set_color(0.5, 0.5, 1, body_alert_alpha)
		if (joint[1].j ~= nil) then
			draw_sphere(joint[1].x, joint[1].y, joint[1].z, body_alert_size)
		end
		if (joint[2].j ~= nil) then
			draw_sphere(joint[2].x, joint[2].y, joint[2].z, body_alert_size)
		end
	end
end

function display_step()
	set_color(0, 0, 0, 1)
	draw_text(step, 5, 5, FONTS.MEDIUM)
	draw_text(completion, 5, 25, FONTS.MEDIUM)
end

local buttons = {}

function load_buttons()
	buttons.continue = { x = width - 50, y = height - 45, w = 62, h = 62, state = BTN_UP }
	buttons.next_tut = { x = width/2 - 50, y = height/2 + 30, w = 100, h = 20, state = BTN_UP }
	buttons.quit = { x = width/2 - 25, y = height/2 + 65, w = 50, h = 20, state = BTN_UP }
end


local BTN_UP = 1
local BTN_HOVER = 2
local BTN_DOWN = 3
local MOUSE_UP = 0
local MOUSE_DOWN = 1
local mouse_state = MOUSE_UP

function mouse_down(mouse_btn, x, y)
	mouse_state = MOUSE_DOWN
	
	if (wait_for_continue == true and change_init == true) then
		if (x > (buttons.continue.x - buttons.continue.w/2) and x < (buttons.continue.x + buttons.continue.w/2) and (y > buttons.continue.y - buttons.continue.h/2) and y < (buttons.continue.y + buttons.continue.h/2)) then
			buttons.continue.state = BTN_DOWN
		end
	end
	if (tut_end == true) then
		if (x > (buttons.quit.x) and x < (buttons.quit.x + buttons.quit.w) and (y > buttons.quit.y) and y < (buttons.quit.y + buttons.quit.h)) then
			buttons.quit.state = BTN_DOWN
		end
		if (x > (buttons.next_tut.x) and x < (buttons.next_tut.x + buttons.next_tut.w) and (y > buttons.next_tut.y) and y < (buttons.next_tut.y + buttons.next_tut.h)) then
			buttons.next_tut.state = BTN_DOWN
		end
	end
end

function mouse_up(mouse_btn, x, y)
	mouse_state = MOUSE_UP
	
	if (wait_for_continue == true and change_init == true) then
		if (x > (buttons.continue.x - buttons.continue.w/2) and x < (buttons.continue.x + buttons.continue.w/2) and (y > buttons.continue.y - buttons.continue.h/2) and y < (buttons.continue.y + buttons.continue.h/2)) then
			buttons.continue.state = BTN_UP
			wait_for_continue = false
			completion = completion + 1
		end
	end
	if (tut_end == true) then
		if (x > (buttons.quit.x) and x < (buttons.quit.x + buttons.quit.w) and (y > buttons.quit.y) and y < (buttons.quit.y + buttons.quit.h)) then
			buttons.quit.state = BTN_UP
			start_new_game()
			terminate()
		end
		if (x > (buttons.next_tut.x) and x < (buttons.next_tut.x + buttons.next_tut.w) and (y > buttons.next_tut.y) and y < (buttons.next_tut.y + buttons.next_tut.h)) then
			buttons.next_tut.state = BTN_UP
			terminate()
			dofile("tutorial/fight_uke_v01.lua")
		end
	end
end

function mouse_move(x, y)	
	if (wait_for_continue == true and change_init == true) then
		if (x > (buttons.continue.x - buttons.continue.w/2) and x < (buttons.continue.x + buttons.continue.w/2) and (y > buttons.continue.y - buttons.continue.h/2) and y < (buttons.continue.y + buttons.continue.h/2)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.continue.state = BTN_DOWN
			else
				buttons.continue.state = BTN_HOVER
			end
		else
			buttons.continue.state = BTN_UP
		end
	end
	if (tut_end == true) then
		if (x > (buttons.quit.x) and x < (buttons.quit.x + buttons.quit.w) and (y > buttons.quit.y) and y < (buttons.quit.y + buttons.quit.h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.quit.state = BTN_DOWN
			else
				buttons.quit.state = BTN_HOVER
			end
		else
			buttons.quit.state = BTN_UP
		end
		if (x > (buttons.next_tut.x) and x < (buttons.next_tut.x + buttons.next_tut.w) and (y > buttons.next_tut.y) and y < (buttons.next_tut.y + buttons.next_tut.h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.next_tut.state = BTN_DOWN
			else
				buttons.next_tut.state = BTN_HOVER
			end
		else
			buttons.next_tut.state = BTN_UP
		end
	end
end

function full_lock(key)
	if (key == string.byte("z") 
	or key == string.byte("x") 
	or key == string.byte("c") 
	or key == string.byte(' ')
	or key == string.byte('l')
	or key == string.byte('e')
	or key == string.byte('r')
	or key == string.byte('p')
	or key == string.byte('k')) then
		return 1
	end
end

function space_lock(key)
	if (key == string.byte(' ')
		or key == string.byte('l')
		or key == string.byte('e')
		or key == string.byte('r')
		or key == string.byte('p')
		or key == string.byte('k')) then
		return 1
	end
end

function lock_keyboard(lock_type)
	remove_hooks("keyboard")
	if (lock_type == nil) then
		add_hook("key_down", "keyboard", full_lock)
		add_hook("key_up", "keyboard", full_lock)
	elseif (lock_type == SPACE) then
		add_hook("key_down", "keyboard", space_lock)
		add_hook("key_up", "keyboard", space_lock)
	end
end

function unlock_keyboard()
	remove_hooks("keyboard")
end

function mouse_lock()
	ws = get_world_state()
	if (ws.selected_joint > -1 or ws.selected_body > -1) then
		print("special lock active")
		return 1
	end
end

function lock_mouse()
	add_hook("mouse_button_down", "mouselock", mouse_lock)
end

function unlock_mouse()
	remove_hooks("mouselock")
end

function run_delay(delay)
	if (modifier == 0) then 
		t0 = curtime()
		modifier = 1
	end
	if ((curtime() - t0 > delay) or (curtime() - t0 < 0)) then
		return 1
	else
		return 0
	end
end

function step_change(delay, _step)
	if (run_delay(delay) == 1) then 
		if (trans_modifier > 0) then trans_modifier = math.ceil((trans_modifier - 0.025)*1000)/1000
	else
		step = _step
		modifier = 0
		change_init = false
		end
	end
end

function message_transition()
	set_color(0, 0, 0, trans_modifier)
	if (change_init == false and trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
	else change_init = true
	end
end

function tut_visuals()
	--display_step()
	if (completion_change < completion) then completion_change = completion_change + 0.02 end
	set_color(0.95, 0.95, 0.95, 0.9)
	draw_quad(100, height - height_modifier, width - 200, 90)
	set_color(0, 0, 0, 1)
	draw_quad(100, height - height_modifier, width - 200, 1)
	draw_quad(100, height - height_modifier, 1, 90)
	draw_quad(width - 101, height - height_modifier, 1, 90)
	if (wait_for_continue == false) then 
		if (continue_colors.r > 0.6) then
			continue_colors.r = continue_colors.r - 0.01
			continue_colors.g = continue_colors.g + 0.025
			continue_colors.b = continue_colors.b + 0.025
		end
	else
		if (continue_colors.r < 0.72) then
			continue_colors.r = continue_colors.r + 0.01
			continue_colors.g = continue_colors.g - 0.025
			continue_colors.b = continue_colors.b - 0.025
		end
	end
	set_color(continue_colors.r, continue_colors.g, continue_colors.b, 1)
	draw_disk(buttons.continue.x, buttons.continue.y, 0, 25, 100, 1, 180, -360, 0)
	set_color(0.16, 0.66, 0.86, 1)
	draw_disk(buttons.continue.x, buttons.continue.y, 25, 30, 100, 1, 180, completion_change/17*(-360), 0)
	set_color(0, 0, 0, 0.2)
	draw_disk(buttons.continue.x, buttons.continue.y, 30, 31, 100, 1, 180, -360, 0)
	set_color(0, 0, 0, 0.8)
	if (buttons.continue.state == BTN_DOWN) then
		draw_disk(buttons.continue.x, buttons.continue.y, 0, 13, 3, 1, -270, -360, 0)
	elseif (buttons.continue.state == BTN_HOVER) then
		draw_disk(buttons.continue.x, buttons.continue.y, 0, 16, 3, 1, -270, -360, 0)
	else
		draw_disk(buttons.continue.x, buttons.continue.y, 0, 14, 3, 1, -270, -360, 0)
	end
end	

--[[function tut_stage2()
-- Tutorial intro steps
	tut_visuals()
	draw_hand_tooltip()
	draw_joint_tooltip()
	
	if (step == 0) then
		-- Run replay
		run_cmd("lm aikido.tbm")
		run_cmd("reset")
		step = 1
	elseif (step == 1) then	
		add_hook("new_game", "terminate", terminate)
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.02 end
		if (get_world_state().match_frame > 44) then
			freeze_game()
			trans_modifier = 0
			step_change(0, 2)
		end
	elseif (step == 2) then
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and (trans_modifier < 1 or height_modifier < 90)) then 
			if (trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
			elseif (trans_modifier > 1) then trans_modifier = 1 end
			if (height_modifier < 90) then height_modifier = height_modifier + 1.5 end
		else 
			change_init = true
		end
		draw_centered_text(messages[1][1], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][2], height - height_modifier + 54, FONTS.MEDIUM)
		step_change(std_delay, 3)
		
	end
end--]]

function tut_stage1()
-- Tutorial intro steps
	tut_visuals()
	draw_hand_tooltip()
	draw_joint_tooltip()
	
	if (step == 0) then
		-- Run replay
		run_cmd("loadreplay system/tut_2-1.rpl")
		step = 1
	elseif (step == 1) then	
		add_hook("new_game", "terminate", terminate)
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.02 end
		if (get_world_state().match_frame > 44) then
			freeze_game()
			trans_modifier = 0
			step_change(0, 2)
		end
	elseif (step == 2) then
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and (trans_modifier < 1 or height_modifier < 90)) then 
			if (trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
			elseif (trans_modifier > 1) then trans_modifier = 1 end
			if (height_modifier < 90) then height_modifier = height_modifier + 1.5 end
		else 
			change_init = true
		end
		draw_centered_text(messages[1][1], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][2], height - height_modifier + 54, FONTS.MEDIUM)
		step_change(std_delay, 3)
	elseif (step == 3) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][3], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][4], height - height_modifier + 54, FONTS.MEDIUM)
		step_change(std_delay, 3.5)
	elseif (step == 3.5) then 
		wait_for_continue = true
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][5], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][6], height - height_modifier + 54, FONTS.MEDIUM)
		step = 4
	elseif (step == 4) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][5], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][6], height - height_modifier + 54, FONTS.MEDIUM)
		if (wait_for_continue == false) then
			step_change(0, 5)
		end
	elseif (step == 5) then
		unfreeze_game()
		if ((trans_modifier > 0 or height_modifier > 0) and change_init == false) then 
			change_init = false
			if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.025 end
			if (height_modifier > 0) then height_modifier = height_modifier - 1.5 end
		end
		if (get_world_state().match_frame > 194) then
			freeze_game()
			step = 6
		end
	elseif (step == 6) then
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		if (trans_modifier < 1) then 
			trans_modifier = trans_modifier + 0.02
		else
			step = 7
			remove_hooks("terminate")
			lock_mouse()
		end
	elseif (step == 7) then
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		run_cmd("lm classic.tbm")
		run_cmd("set ed 175")
		start_new_game()
		step = 8
		add_hook("new_game", "terminate", terminate)
		add_hook("joint_select", "bodyparts", set_joint_tooltip)
		add_hook("body_select", "bodyparts", set_hand_tooltip)
		hand_joint_render = true
	elseif (step == 8) then
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.02
		else 
			trans_modifier = 0 
			wait_for_continue = true
			step_change(0, 9)
		end
	elseif (step == 9) then
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and (trans_modifier < 1 or height_modifier < 90)) then 
			if (trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
			elseif (trans_modifier > 1) then trans_modifier = 1 end
			if (height_modifier < 90) then height_modifier = height_modifier + 1.5 end
		else 
			change_init = true
		end
		draw_centered_text(messages[1][7], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][8], height - height_modifier + 54, FONTS.MEDIUM)
		if (wait_for_continue == false) then
			conditions_load = true
			step_change(0, 10)
		end
	elseif (step == 10) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][9], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][10], height - height_modifier + 54, FONTS.MEDIUM)
		
		local check_key_conditions = function(key)
			if (key == string.byte('z') or key == string.byte('x')) then	-- z is locked on all joints but L_HIP and R_HIP
				local joint = get_world_state().selected_joint
				if (joint ~= JOINTS.L_HIP and joint ~= JOINTS.R_HIP) then
					return 1
				end
			elseif (key == string.byte('c')) then	-- c toggles L_HIP, R_HIP to hold
				if (get_joint_info(0, JOINTS.L_HIP).state == JOINT_STATE.HOLD and get_joint_info(0, JOINTS.R_HIP).state == JOINT_STATE.HOLD) then
					set_joint_state(0, JOINTS.L_HIP, JOINT_STATE.RELAX)
					set_joint_state(0, JOINTS.R_HIP, JOINT_STATE.RELAX)
				else
					set_joint_state(0, JOINTS.L_HIP, JOINT_STATE.HOLD)
					set_joint_state(0, JOINTS.R_HIP, JOINT_STATE.HOLD)
				end
				return 1
			end
		end

		local check_mousedown_conditions = function()
			local ws = get_world_state()
			local body = ws.selected_body
			local joint = ws.selected_joint

			if (body > -1 or (joint ~= JOINTS.L_HIP and joint ~= JOINTS.R_HIP)) then
				return 1
			end
		end

		local check_mouseup_conditions = function()
			local l_joint_info = get_joint_info(0, JOINTS.L_HIP).state
			local r_joint_info = get_joint_info(0, JOINTS.R_HIP).state

			if (l_joint_info == JOINT_STATE.BACK and r_joint_info == JOINT_STATE.FORWARD) then
				end_joint_alert()
				remove_hooks("conditions")
				completion = completion + 1
				step = 10.5
			end
		end
		
		if (conditions_load == true) then
			start_joint_alert(JOINTS.L_HIP, JOINTS.R_HIP)
			lock_keyboard(SPACE)
			unlock_mouse()
			add_hook("key_up", "conditions", check_key_conditions)
			add_hook("mouse_button_down", "conditions", check_mousedown_conditions)
			add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
			conditions_load = false
		end
		
		if (get_joint_info(0, JOINTS.L_HIP).state == JOINT_STATE.BACK and get_joint_info(0, JOINTS.R_HIP).state == JOINT_STATE.FORWARD) then 
			end_joint_alert()
			remove_hooks("conditions")
			completion = completion + 1
			step = 10.5
		end
		
	elseif (step == 10.5) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][9], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][10], height - height_modifier + 54, FONTS.MEDIUM)
		lock_keyboard()
		lock_mouse()
		conditions_load = true
		step_change(0, 11)
	elseif (step == 11) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][11], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][12], height - height_modifier + 54, FONTS.MEDIUM)
	
		local check_key_conditions = function(key)
			if (key == string.byte('z') or key == string.byte('x')) then	-- z and x are locked on all joints but L_KNEE
				if (get_world_state().selected_joint ~= JOINTS.L_KNEE and get_world_state().selected_joint ~= JOINTS.L_ANKLE) then
					return 1
				end
			elseif (key == string.byte('c')) then	-- c toggles L_KNEE to hold
				if (get_joint_info(0, JOINTS.L_KNEE).state == JOINT_STATE.HOLD and get_joint_info(0, JOINTS.L_ANKLE).state == JOINT_STATE.HOLD) then
					set_joint_state(0, JOINTS.L_KNEE, JOINT_STATE.RELAX)
					set_joint_state(0, JOINTS.L_ANKLE, JOINT_STATE.RELAX)
				else
					set_joint_state(0, JOINTS.L_KNEE, JOINT_STATE.HOLD)
					set_joint_state(0, JOINTS.L_ANKLE, JOINT_STATE.HOLD)
				end
				return 1
			end
		end
		add_hook("key_up", "conditions", check_key_conditions)

		local check_mousedown_conditions = function()
			ws = get_world_state()
			if ((ws.selected_joint ~= JOINTS.L_KNEE and ws.selected_joint ~= JOINTS.L_ANKLE) or ws.selected_body > -1) then
				return 1
			end
		end
		add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

		local check_mouseup_conditions = function()
			if (get_joint_info(0, JOINTS.L_KNEE).state == JOINT_STATE.BACK and get_joint_info(0, JOINTS.L_ANKLE).state == JOINT_STATE.BACK) then
				end_joint_alert()
				remove_hooks("conditions")
				completion = completion + 1
				step = 11.5
			end
		end
		add_hook("mouse_button_up", "conditions", check_mouseup_conditions)

		if (conditions_load == true) then
			start_joint_alert(JOINTS.L_KNEE, JOINTS.L_ANKLE)
			lock_keyboard(SPACE)
			unlock_mouse()
			add_hook("key_up", "conditions", check_key_conditions)
			add_hook("mouse_button_down", "conditions", check_mousedown_conditions)
			add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
			conditions_load = false
		end
		
		if (get_joint_info(0, JOINTS.L_KNEE).state == JOINT_STATE.BACK and get_joint_info(0, JOINTS.L_ANKLE).state == JOINT_STATE.BACK) then 
			end_joint_alert()
			remove_hooks("conditions")
			completion = completion + 1
			step = 11.5
		end
		
	elseif (step == 11.5) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][11], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][12], height - height_modifier + 54, FONTS.MEDIUM)
		lock_keyboard()
		lock_mouse()
		conditions_load = true
		wait_for_continue = true
		step_change(0, 12)
	elseif (step == 12) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][13], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][14], height - height_modifier + 54, FONTS.MEDIUM)
		
		if (wait_for_continue == false) then
			step_change(0, 12.5)
		end
	elseif (step == 12.5) then
		wait_for_continue = true
		step = 13
	elseif (step == 13) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][15], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][16], height - height_modifier + 54, FONTS.MEDIUM)
		
		if (conditions_load == true) then
			set_joint_state(0, JOINTS.L_PECS, JOINT_STATE.BACK)
			set_joint_state(0, JOINTS.CHEST, JOINT_STATE.FORWARD)
			set_joint_state(0, JOINTS.L_GLUTE, JOINT_STATE.BACK)
			set_joint_state(0, JOINTS.R_GLUTE, JOINT_STATE.BACK)
			conditions_load = false
		end
		
		if (wait_for_continue == false) then
			step_change(0, 13.5)
		end
	elseif (step == 13.5) then
		unlock_keyboard()
		step = 14
	elseif (step == 14) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][17], height - height_modifier + 39, FONTS.MEDIUM)
		
		local check_key_conditions = function(key)
			if (key == string.byte(' ')) then
				lock_keyboard()
				remove_hooks("conditions")
				run_frames(20)
				step = 15
				completion = completion + 1
				return 1
			else return 1
			end
		end
		add_hook("key_up", "conditions", check_key_conditions)
		
	elseif (step == 15) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][17], height - height_modifier + 39, FONTS.MEDIUM)
		step_change(0, 16)
	elseif (step == 16) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][18], height - height_modifier + 39, FONTS.MEDIUM)
		conditions_load = true
		step_change(std_delay, 17)
	elseif (step == 17) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][19], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][20], height - height_modifier + 54, FONTS.MEDIUM)
		step_change(std_delay, 18)
	elseif (step == 18) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][21], height - height_modifier + 39, FONTS.MEDIUM)
		
		local check_key_conditions = function(key)
			if (key == string.byte('z') or key == string.byte('x')) then	-- z and x are locked on all joints but CHEST
				local joint = get_world_state().selected_joint
				if (joint ~= JOINTS.CHEST) then
					return 1
				end
			elseif (key == string.byte('c')) then	-- c toggles CHEST between hold/relax 
				if (get_joint_info(0, JOINTS.CHEST).state == JOINT_STATE.HOLD) then
					set_joint_state(0, JOINTS.CHEST, JOINT_STATE.RELAX)
				else
					set_joint_state(0, JOINTS.CHEST, JOINT_STATE.HOLD)
				end
				return 1
			end
		end

		local check_mousedown_conditions = function()
			local ws = get_world_state()

			if (ws.selected_body > -1 or ws.selected_joint ~= JOINTS.CHEST) then
				return 1
			end
		end

		local check_mouseup_conditions = function()
			if (get_joint_info(0, JOINTS.CHEST).state == JOINT_STATE.BACK) then
				end_joint_alert()
				remove_hooks("conditions")
				completion = completion + 1
				step = 18.5
			end
		end
		
		if (conditions_load == true) then
			start_joint_alert(JOINTS.CHEST)
			lock_keyboard(SPACE)
			unlock_mouse()
			add_hook("key_up", "conditions", check_key_conditions)
			add_hook("mouse_button_down", "conditions", check_mousedown_conditions)
			add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
			conditions_load = false
		end
		
		if (get_joint_info(0, JOINTS.CHEST).state == JOINT_STATE.BACK) then 
			end_joint_alert()
			remove_hooks("conditions")
			completion = completion + 1
			step = 18.5
		end
	elseif (step == 18.5) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][21], height - height_modifier + 39, FONTS.MEDIUM)
		lock_keyboard()
		lock_mouse()
		conditions_load = true
		step_change(0, 19)
	elseif (step == 19) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][22], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][23], height - height_modifier + 54, FONTS.MEDIUM)
	
		local check_key_conditions = function(key)
			if (key == string.byte('z') or key == string.byte('x')) then	-- z and x are locked on all joints but L_PECS
				if (get_world_state().selected_joint ~= JOINTS.L_PECS and get_world_state().selected_joint ~= JOINTS.R_PECS) then
					return 1
				end
			elseif (key == string.byte('c')) then	-- c toggles L_PECS to hold
				if (get_joint_info(0, JOINTS.L_PECS).state == JOINT_STATE.HOLD and get_joint_info(0, JOINTS.R_PECS).state == JOINT_STATE.HOLD) then
					set_joint_state(0, JOINTS.L_PECS, JOINT_STATE.RELAX)
					set_joint_state(0, JOINTS.R_PECS, JOINT_STATE.RELAX)
				else
					set_joint_state(0, JOINTS.L_PECS, JOINT_STATE.HOLD)
					set_joint_state(0, JOINTS.R_PECS, JOINT_STATE.HOLD)
				end
				return 1
			end
		end
		add_hook("key_up", "conditions", check_key_conditions)

		local check_mousedown_conditions = function()
			ws = get_world_state()
			if ((ws.selected_joint ~= JOINTS.L_PECS and ws.selected_joint ~= JOINTS.R_PECS) or ws.selected_body > -1) then
				return 1
			end
		end
		add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

		local check_mouseup_conditions = function()
			if (get_joint_info(0, JOINTS.L_PECS).state == JOINT_STATE.FORWARD and get_joint_info(0, JOINTS.R_PECS).state == JOINT_STATE.BACK) then
				end_joint_alert()
				unlock_keyboard()
				lock_mouse()
				remove_hooks("conditions")
				completion = completion + 1
				step = 20
			end
		end
		add_hook("mouse_button_up", "conditions", check_mouseup_conditions)

		if (conditions_load == true) then
			start_joint_alert(JOINTS.L_PECS, JOINTS.R_PECS)
			lock_keyboard(SPACE)
			unlock_mouse()
			add_hook("key_up", "conditions", check_key_conditions)
			add_hook("mouse_button_down", "conditions", check_mousedown_conditions)
			add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
			conditions_load = false
		end
		
		if (get_joint_info(0, JOINTS.L_PECS).state == JOINT_STATE.FORWARD and get_joint_info(0, JOINTS.R_PECS).state == JOINT_STATE.BACK) then 
			end_joint_alert()
			unlock_keyboard()
			lock_mouse()
			remove_hooks("conditions")
			completion = completion + 1
			step = 20
		end
	elseif (step == 20) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][22], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][23], height - height_modifier + 54, FONTS.MEDIUM)
		
		local check_key_conditions = function(key)
			if (key == string.byte(' ')) then
				lock_keyboard()
				remove_hooks("conditions")
				run_frames(10)
				completion = completion + 1
				step = 21
				return 1
			else return 1
			end
		end
		add_hook("key_up", "conditions", check_key_conditions)
	elseif (step == 21) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][22], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][23], height - height_modifier + 54, FONTS.MEDIUM)
		conditions_load = true
		step_change(0, 22)
	elseif (step == 22) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][24], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][25], height - height_modifier + 54, FONTS.MEDIUM)
		
		local check_key_conditions = function(key)
			if (key == string.byte('z') or key == string.byte('x')) then	-- z and x are locked on all joints but L_HIP
				local joint = get_world_state().selected_joint
				if (joint ~= JOINTS.L_HIP) then
					return 1
				end
			elseif (key == string.byte('c')) then	-- c toggles L_HIP between hold/relax 
				if (get_joint_info(0, JOINTS.L_HIP).state == JOINT_STATE.HOLD) then
					set_joint_state(0, JOINTS.L_HIP, JOINT_STATE.RELAX)
				else
					set_joint_state(0, JOINTS.L_HIP, JOINT_STATE.HOLD)
				end
				return 1
			end
		end

		local check_mousedown_conditions = function()
			local ws = get_world_state()

			if (ws.selected_body > -1 or ws.selected_joint ~= JOINTS.L_HIP) then
				return 1
			end
		end

		local check_mouseup_conditions = function()
			if (get_joint_info(0, JOINTS.L_HIP).state == JOINT_STATE.FORWARD) then
				end_joint_alert()
				unlock_keyboard()
				lock_mouse()
				remove_hooks("conditions")
				step = 22.5
			end
		end
		
		if (conditions_load == true) then
			start_joint_alert(JOINTS.L_HIP)
			lock_keyboard(SPACE)
			unlock_mouse()
			add_hook("key_up", "conditions", check_key_conditions)
			add_hook("mouse_button_down", "conditions", check_mousedown_conditions)
			add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
			conditions_load = false
		end
		
		if (get_joint_info(0, JOINTS.L_HIP).state == JOINT_STATE.FORWARD) then 
			end_joint_alert()
			unlock_keyboard()
			lock_mouse()
			remove_hooks("conditions")
			step = 22.5
		end
	elseif (step == 22.5) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][24], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][25], height - height_modifier + 54, FONTS.MEDIUM)
		
		local check_key_conditions = function(key)
			if (key == string.byte(' ')) then
				lock_keyboard()
				remove_hooks("conditions")
				run_frames(10)
				completion = completion + 1
				step = 23
				return 1
			else return 1
			end
		end
		add_hook("key_up", "conditions", check_key_conditions)
	elseif (step == 23) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][24], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][25], height - height_modifier + 54, FONTS.MEDIUM)
		conditions_load = true
		step_change(0, 24)
	elseif (step == 24) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][26], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][27], height - height_modifier + 54, FONTS.MEDIUM)
		
		local check_key_conditions = function(key)
			if (key == string.byte('z') or key == string.byte('x')) then	-- z and x are locked on all joints but L_KNEE
				local joint = get_world_state().selected_joint
				if (joint ~= JOINTS.L_KNEE) then
					return 1
				end
			elseif (key == string.byte('c')) then	-- c toggles L_KNEE between hold/relax 
				if (get_joint_info(0, JOINTS.L_KNEE).state == JOINT_STATE.HOLD) then
					set_joint_state(0, JOINTS.L_KNEE, JOINT_STATE.RELAX)
				else
					set_joint_state(0, JOINTS.L_KNEE, JOINT_STATE.HOLD)
				end
				return 1
			end
		end

		local check_mousedown_conditions = function()
			local ws = get_world_state()

			if (ws.selected_body > -1 or ws.selected_joint ~= JOINTS.L_KNEE) then
				return 1
			end
		end

		local check_mouseup_conditions = function()
			if (get_joint_info(0, JOINTS.L_KNEE).state == JOINT_STATE.FORWARD) then
				end_joint_alert()
				lock_keyboard()
				lock_mouse()
				remove_hooks("conditions")
				step_change(0, 25)
			end
		end
		
		if (conditions_load == true) then
			start_joint_alert(JOINTS.L_KNEE)
			lock_keyboard(SPACE)
			unlock_mouse()
			add_hook("key_up", "conditions", check_key_conditions)
			add_hook("mouse_button_down", "conditions", check_mousedown_conditions)
			add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
			conditions_load = false
		end
		
		if (get_joint_info(0, JOINTS.L_KNEE).state == JOINT_STATE.FORWARD) then 
			end_joint_alert()
			lock_mouse()
			lock_keyboard()
			conditions_load = true
			remove_hooks("conditions")
			step_change(0, 25)
		end
	elseif (step == 25) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][28], height - height_modifier + 39, FONTS.MEDIUM)
		
		local check_key_conditions = function(key)
			if (key == string.byte(' ')) then
				lock_keyboard()
				remove_hooks("conditions")
				run_frames(150)
				completion = completion + 1
				step = 25.5
				return 1
			else return 1
			end
		end
		add_hook("key_up", "conditions", check_key_conditions)
		
		if (conditions_load == true) then
			unlock_keyboard()
			conditions_load = false
		end
	elseif (step == 25.5) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][28], height - height_modifier + 39, FONTS.MEDIUM)
		step_change(0, 26)
	elseif (step == 26) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][29], height - height_modifier + 39, FONTS.MEDIUM)
		step_change(std_delay, 27)
	elseif (step == 27) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][30], height - height_modifier + 39, FONTS.MEDIUM)
		step_change(std_delay, 27.5)
	elseif (step == 27.5) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][30], height - height_modifier + 39, FONTS.MEDIUM)
		unlock_keyboard()
		step = 28
	elseif (step == 28) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][31], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][32], height - height_modifier + 54, FONTS.MEDIUM)
		local check_key_conditions = function(key)
			if (key == string.byte('r')) then
				lock_keyboard()
				remove_hooks("conditions")
				remove_hooks("terminate")				
				completion = completion + 1
				run_cmd("loadreplay system/tut_2-1.rpl")
				run_cmd("loadreplay system/tut_2-1.rpl")
				run_cmd("lp 0"..player_name)
				add_hook("new_game", "terminate", terminate)
				step = 29
				return 1
			else return 1
			end
		end
		add_hook("key_up", "conditions", check_key_conditions)
	
	elseif (step == 29) then
		if (get_world_state().match_frame == 40) then
			edit_game()
			set_joint_state(0, JOINTS.L_GLUTE, JOINT_STATE.BACK)
			step = 30
			wait_for_continue = true
		end
	elseif (step == 30) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][33], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][34], height - height_modifier + 54, FONTS.MEDIUM)
		if (wait_for_continue == false) then
			step_change(0, 31)
		end
	elseif (step == 31) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][35], height - height_modifier + 39, FONTS.MEDIUM)
		local check_key_conditions = function(key)
			if (key == string.byte('b')) then
				step = 31.5
				completion = completion + 1
			end
		end
		add_hook("key_up", "conditions", check_key_conditions)
	elseif (step == 31.5) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][35], height - height_modifier + 39, FONTS.MEDIUM)
		step_change(0, 31.9)
	elseif (step == 31.9) then
		wait_for_continue = true
		step = 32
	elseif (step == 32) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][36], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][37], height - height_modifier + 54, FONTS.MEDIUM)
		if (wait_for_continue == false) then
			step_change(0, 33)
			conditions_load = true
		end
	elseif (step == 33) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][38], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[1][39], height - height_modifier + 54, FONTS.MEDIUM)
		
		local check_key_conditions = function(key)
			if (key == string.byte('z') or key == string.byte('x')) then	-- z and x are locked on all joints but L_GLUTE
				local joint = get_world_state().selected_joint
				if (joint ~= JOINTS.L_GLUTE) then
					return 1
				end
			elseif (key == string.byte('c')) then	-- c toggles L_GLUTE between hold/relax 
				if (get_joint_info(0, JOINTS.L_GLUTE).state == JOINT_STATE.HOLD) then
					set_joint_state(0, JOINTS.L_GLUTE, JOINT_STATE.RELAX)
				else
					set_joint_state(0, JOINTS.L_GLUTE, JOINT_STATE.HOLD)
				end
				return 1
			end
		end

		local check_mousedown_conditions = function()
			local ws = get_world_state()

			if (ws.selected_body > -1 or ws.selected_joint ~= JOINTS.L_GLUTE) then
				return 1
			end
		end

		local check_mouseup_conditions = function()
			if (get_joint_info(0, JOINTS.L_GLUTE).state == JOINT_STATE.FORWARD) then
				end_joint_alert()
				lock_keyboard()
				lock_mouse()
				remove_hooks("conditions")
				step_change(0, 34)
			end
		end
		
		if (conditions_load == true) then
			start_joint_alert(JOINTS.L_GLUTE)
			lock_keyboard(SPACE)
			unlock_mouse()
			add_hook("key_up", "conditions", check_key_conditions)
			add_hook("mouse_button_down", "conditions", check_mousedown_conditions)
			add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
			conditions_load = false
		end
		
		if (get_joint_info(0, JOINTS.L_GLUTE).state == JOINT_STATE.FORWARD) then 
			end_joint_alert()
			lock_mouse()
			lock_keyboard()
			conditions_load = true
			remove_hooks("conditions")
			step_change(0, 34)
		end
	elseif (step == 34) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][40], height - height_modifier + 39, FONTS.MEDIUM)
		
		local check_key_conditions = function(key)
			if (key == string.byte(' ')) then
				lock_keyboard()
				remove_hooks("conditions")
				hand_joint_render = false
				set_gameover_timelimit(-1)
				run_frames(500)
				completion = completion + 1
				step = 35
				return 1
			else return 1
			end
		end
		add_hook("key_up", "conditions", check_key_conditions)
		
		if (conditions_load == true) then
			unlock_keyboard()
			conditions_load = false
		end
	elseif (step == 35) then
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][40], height - height_modifier + 39, FONTS.MEDIUM)
		step_change(0, 36)
	elseif (step == 36) then
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[1][41], height - height_modifier + 39, FONTS.MEDIUM)
		step_change(std_delay * 2, 37)
	elseif (step == 37) then
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		if (trans_modifier < 1) then 
			trans_modifier = trans_modifier + 0.02
		else
			step = 38
		end
	elseif (step == 38) then
		set_color(1, 1, 1, 1)
		draw_quad(0, 0, width, height)
		tut_end = true
		trans_modifier = 0
		step = 39
		change_init = false
	elseif (step == 39) then
		set_color(1, 1, 1, 1)
		draw_quad(0, 0, width, height)
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text("Do you want to play the next tutorial?", height/2 - 20, FONTS.MEDIUM)
		if (buttons.next_tut.state == BTN_UP) then 
			set_color(0, 0, 0, trans_modifier)
		elseif (buttons.next_tut.state == BTN_DOWN) then 
			set_color(0.16, 0.66, 0.86, trans_modifier)
		else 
			set_color(0.82, 0.39, 0.39, trans_modifier)
		end
		draw_centered_text("Continue", buttons.next_tut.y, FONTS.MEDIUM)
		if (buttons.quit.state == BTN_UP) then 
			set_color(0, 0, 0, trans_modifier)
		elseif (buttons.quit.state == BTN_DOWN) then 
			set_color(0.16, 0.66, 0.86, trans_modifier)
		else 
			set_color(0.82, 0.39, 0.39, trans_modifier)
		end
		draw_centered_text("Quit", buttons.quit.y, FONTS.MEDIUM)
	end
end


function terminate()
	for i, v in pairs(default_opt) do
		set_option(i, default_opt[i])
	end
	
	run_cmd("clear")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	
	set_gameover_timelimit(4)
	unlock_keyboard()
	unlock_mouse()
	remove_hooks("tutorial")
	remove_hooks("terminate")
	remove_hooks("conditions")
	reset_camera(1)
end

function start_tutorial()
	for i, v in pairs(default_opt) do
		default_opt[i] = get_option(i)
		set_option(i, 0)
	end
	
	lock_keyboard()
	load_buttons()
	
	if string.find(player_name, "]") then
		player_name = string.sub(player_name, string.find(player_name, "]") + 1)
	end
	
	add_hook("draw2d", "tutorial", tut_stage1)
	add_hook("draw3d", "tutorial", function() draw_3d(); update_loop() end)
	add_hook("new_mp_game", "tutorial", terminate)
	add_hook("mouse_button_down", "tutorial", mouse_down)
	add_hook("mouse_button_up", "tutorial", mouse_up)
	add_hook("mouse_move", "tutorial", mouse_move)
end

start_tutorial()
