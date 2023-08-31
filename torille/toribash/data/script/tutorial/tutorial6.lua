-- Global
local width, height = get_window_size()
local curtime = os.clock
local playername = get_master().master.nick

-- User settings
local default_background_click = 1
local default_autosave = 1
local default_hud = 1

local completion = 0
local completion_change = completion
local continue_condition = 0
local wait_for_continue = false
local step = 0
local t0, t1 = 0, 0
local modifier, width_modifier, height_modifier, trans_modifier, mp_modifier = 0, 0, 80, 1, 0
local change_init = false
local tut_end = false

local messages = {
	{
	"Hello and welcome to the Toribash tutorial!",
	"Toribash is a ragdoll fighting game",
	"Where you are able to control your character's joints",
	"In this tutorial we'll run through the gameplay basics",
	"And some other Toribash features",
	"But first let's finish watching this replay!",
	},
	{	
	"Camera controls!",
	"You can use the 'W/A/S/D' buttons to move the camera",
	"Hold Shift while pressing 'W/S'",
	"To adjust the camera height",
	"Alternatively, you can use your mouse to control the camera",
	"Right-click anywhere on the screen and move your mouse"
	},
	{
	"Now it's time to learn to move your Tori!",
	"Left-click on joints or use the mouse scroll",
	"to toggle their modes!",
	"There are four joint modes:",
	"Hold, relax, contract and extend",
	"You can also use 'Z' and 'X' keys",
	"While hovering over a joint to change its state",
	"Press 'C' to toggle all joints",
	"Between Hold and Relax",
	"While fighting, you can grab your opponents",
	"Left-click on hands to change the grip!",
	"Now press the spacebar to end your turn",
	"You can perform incredible moves",
	"by combining joint modes!",
	"See that ring on the ground?",
	"That is a Disqualification (DQ) Ring",
	"You will be disqualified if your body",
	"hits the ground first!",
	"Disqualify your opponents",
	"or score higher than them to win!",
	},
	{
	"There are lots of mods in Toribash",
	"You can see the mod browser on the left now",
	"Results shown in black are Toribash mod files",
	"And those in green are folders with other mods",
	"Toribash mods have .tbm extension,",
	"And they can be created with a built-in modmaker",
	"You can search for specific mod by entering its name",
	"In the search field (that says 'Type here' now)",
	"Let's load aikido.tbm now",
	"Mods usually change the game rules, including",
	"Gravitation, distance between players and more",
	"You can see the game rules window on the left now",
	"Some mods also add different environment objects",
	"Or modify players' body parts",
	"This is rk_f1.tbm",
	"It features some extreme modifications",
	"And allows you to race against your opponent",
	"Check the mod browser for more outstanding mods later!",
	"Toribash allows you to save your fight replays",
	"To save the replay of your current fight, press 'F'",
	"You can view your saved replays in the Replays menu in Setup",
	},
	{
	"Online Gameplay!",
	"After entering a room",
	"you will be put in the waiting list",
	"The players currently fighting",
	"are displayed here",
	"Players waiting for their fight",
	"Are displayed here",
	"Spectators are shown below the waiting list",
	"The winner of the match will fight with",
	"the next player on the list",
	"Once you have mastered some moves,",
	"pit your skills against other players!",
	"Have fun playing!",
	}
}

--[[
function display_step()
	set_color(0, 0, 0, 1)
	draw_text(step, 5, 5, FONTS.MEDIUM)
end
--]]

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
	
	if (wait_for_continue == true and continue_condition == 1) then
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
	
	if (wait_for_continue == true and continue_condition == 1) then
		if (x > (buttons.continue.x - buttons.continue.w/2) and x < (buttons.continue.x + buttons.continue.w/2) and (y > buttons.continue.y - buttons.continue.h/2) and y < (buttons.continue.y + buttons.continue.h/2)) then
		--	if (trans_modifier == 1) then
				buttons.continue.state = BTN_UP
				wait_for_continue = false
				change_init = true
				completion = completion + 1
		--	end
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
			dofile("tutorial/tutorial7.lua")
		end
	end
end

function mouse_move(x, y)	
	if (wait_for_continue == true and continue_condition == 1) then
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

local pressed_w, pressed_a, pressed_s, pressed_d, pressed_shift, pressed_space = false, false, false, false, false, false
local pressed_z, pressed_x, pressed_c = false, false, false
local wasd_render, space_render, shift_render, zxc_render = false, false, false, false
local wasd_press, space_press, shift_press, zxc_press = false, false, false, false		-- continue conditions

function key_down_func(key)
	if (key == string.byte('p')) then
		return 1
	end
	if (key == string.byte('q')) then
		return 1
	end
	if (key == string.byte('e')) then
		return 1
	end
	if (wasd_render == true) then
		if (key == string.byte('w')) then
			pressed_w = true
			wasd_press = true
		end
		if (key == string.byte('a')) then
			pressed_a = true
			wasd_press = true
		end
		if (key == string.byte('s')) then
			pressed_s = true
			wasd_press = true
		end
		if (key == string.byte('d')) then
			pressed_d = true
			wasd_press = true
		end
	else 
		if (key == string.byte('w') or key == string.byte('a') or key == string.byte('s') or key == string.byte('d')) then
			return 1
		end
	end
	if (zxc_render == true) then
		if (key == string.byte('z')) then
			pressed_z = true
			zxc_press = true
		end
		if (key == string.byte('x')) then
			pressed_x = true
			zxc_press = true
		end
		if (key == string.byte('c')) then
			pressed_c = true
			zxc_press = true
		end
	else
		if (key == string.byte('z') or key == string.byte('x') or key == string.byte('c')) then
			return 1
		end
	end
	if (space_render == true) then
		if (key == string.byte(' ')) then
			pressed_space = true
			space_press = true
		end
	else
		if (key == string.byte(' ')) then
			return 1
		end
	end
	if (shift_render == true) then
		if (get_shift_key_state() ~= 0) then
			pressed_shift = true
			shift_press = true
		end
	else
		if (get_shift_key_state() ~= 0) then
			return 1
		end
	end
end

function key_up_func(key)
	if (key == 13) then
		hide_chat_button()
		return 1
	end
	if (key == string.byte('p')) then
		return 1
	end
	if (wasd_render == true) then
		if (key == string.byte('w')) then
			pressed_w = false
		end
		if (key == string.byte('a')) then
			pressed_a = false
		end
		if (key == string.byte('s')) then
			pressed_s = false
		end
		if (key == string.byte('d')) then
			pressed_d = false
		end
	end
	if (zxc_render == true) then
		if (key == string.byte('z')) then
			pressed_z = false
		end
		if (key == string.byte('x')) then
			pressed_x = false
		end
		if (key == string.byte('c')) then
			pressed_c = false
		end
	end
	if (space_render == true) then
		if (key == string.byte(' ')) then
			pressed_space = false
		end
	end
	if (shift_render == true) then
		if (get_shift_key_state() == 0) then
			pressed_shift = false
		end
	end
end

function lock_key_down(key)
	return 1
end

function lock_key_up(key)
	if (key == 13) then
		hide_chat_button()
	end
	return 1
end

function lock_keyboard()
	remove_hooks("keyboard")
	--add_hook("key_down", "keyboard", function() return 1 end)
	--add_hook("key_up", "keyboard", function() return 1 end)
	add_hook("key_down", "keyboard", lock_key_down)
	add_hook("key_up", "keyboard", lock_key_up)
end

function unlock_keyboard()
	remove_hooks("keyboard")
	add_hook("key_down", "keyboard", key_down_func)
	add_hook("key_up", "keyboard", key_up_func)
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
		if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.025
	else
		step = _step
		modifier = 0
		change_init = false
		end
	end
end

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

function draw_rounded_quad(x, y, width, height, cornerRadius)
	draw_disk (x + cornerRadius, y + cornerRadius, 0, cornerRadius, 32, 1, -90, -90, 0)
	draw_quad ((x + cornerRadius), y, (width - cornerRadius * 2), height)
	draw_disk (x + (width - cornerRadius), y + cornerRadius, 0, cornerRadius, 32, 1, 180, -90, 0)
	draw_quad (x, (y + cornerRadius), cornerRadius, (height - cornerRadius * 2))
	draw_quad ((x + (width - cornerRadius)), (y + cornerRadius), cornerRadius, (height - cornerRadius * 2))
	draw_disk (x + cornerRadius, y + cornerRadius + (height - cornerRadius * 2), 0, cornerRadius, 32, 1, 0, -90, 0)
	draw_disk (x + (width - cornerRadius), y + cornerRadius + (height - cornerRadius * 2), 0, cornerRadius, 32, 1, 0, 90, 0)
end

function button_press_color(pressed_button, keys)
	local key_trans = 0
	if (keys == false) then key_trans = trans_modifier
	else key_trans = 1
	end
	if (pressed_button == true) then
		set_color(0.72, 0.29, 0.29, key_trans)
	else set_color(0, 0, 0, key_trans)
	end
end

function message_transition()
	set_color(0, 0, 0, trans_modifier)
	if (change_init == false and trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
	else change_init = true
	end
end

local continue_colors = { r = 0.6, g = 0.6, b = 0.6 }

function tut_visuals()
	if (completion_change < completion) then completion_change = completion_change + 0.02 end
	set_color(0.95, 0.95, 0.95, 0.9)
	draw_quad(100, height - height_modifier, width - 200, 90)
	set_color(0, 0, 0, 1)
	draw_quad(100, height - height_modifier, width - 200, 1)
	draw_quad(100, height - height_modifier, 1, 90)
	draw_quad(width - 101, height - height_modifier, 1, 90)
	if (continue_condition == 0) then 
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
	draw_disk(buttons.continue.x, buttons.continue.y, 25, 30, 100, 1, 180, completion_change/31*(-360), 0)
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

local render_curfighting, render_waiting, render_spec = false, false, false

function mp_visuals()
	if (render_curfighting == true) then
		set_color(0, 0, 0, trans_modifier - 0.2)
		draw_quad(width-161, 139, 152, 42)
		set_color(1, 1, 1, trans_modifier - 0.05)
		draw_quad(width-160, 140, 150, 40)
	end
	if (render_waiting == true) then
		set_color(0, 0, 0, trans_modifier - 0.2)
		draw_quad(width-161, 178, 152, 55)
		set_color(1, 1, 1, trans_modifier - 0.05)
		draw_quad(width-160, 179, 150, 53)
	end
	if (render_spec == true) then
		set_color(0, 0, 0, trans_modifier - 0.2)
		draw_quad(width-161, 229, 152, 42)
		set_color(1, 1, 1, trans_modifier - 0.05)
		draw_quad(width-160, 230, 150, 40)
	end
	set_color(0.72, 0.3, 0.3, 1)
	draw_right_text("hampa", 10, 50, FONTS.MEDIUM)
	draw_right_text("Banana Belt, Rank 42", 10, 80)
	draw_right_text("~[MAD]hampa", 20, 143)
	set_color(0.16, 0.66, 0.86, 1)
	draw_text("deerslayer", 10, 50, FONTS.MEDIUM)
	draw_text("Black Belt, Rank 503", 10, 80)
	draw_right_text("[MAD]deerslayer", 20, 161)
	set_color(0.2, 0.2, 0.2, 1)
	draw_right_text("Dranix", 20, 179)
	draw_right_text("~(g)sir", 20, 197)
	set_color(0.0, 1.0, 0.0, 1.0)
	draw_right_text(playername, 20, 215)
	set_color(0.7, 0.7, 0.7, 1)
	draw_right_text("Tori", 20, 233)
	draw_right_text("Uke", 20, 251)
	if (curtime() - t1 < 18 and step > 1 and step < 10) then
		set_color(0.72, 0.3, 0.3, 0.5)
		draw_disk(width/2, 60, 20, 40, 100, 1, 180, 180-(curtime()-t1)*10, 0)
		set_color(0.16, 0.66, 0.86, 0.5)
		draw_disk(width/2, 60, 20, 40, 100, 1, 0, 180-(curtime()-t1)*10, 0)
	end
	if (get_world_state().game_frame - get_world_state().match_frame > 0) then
		set_color(1, 0.8, 0, 1)
		draw_centered_text(get_world_state().game_frame - get_world_state().match_frame, 0, FONTS.BIG)
	end
end
	
function tut_stage4()
	tut_visuals()
	mp_visuals()
	if (step == 0) then
		-- Preparation
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		run_cmd("loadreplay system/tut_1-3.rpl")
		freeze_game()
		add_hook("new_game", "terminate", terminate)
		step = 1
	elseif (step == 1) then
		-- Fade out
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.02 end 
		--display_step()
		step_change(0, 2)
	elseif (step == 2) then
		-- MP intro
		continue_condition = 1
		if (step > 1) then 
			mp_modifier = step
		end	
		unfreeze_game()
		if (get_world_state().match_frame == 10) then 
			freeze_game()
		else 
			t1 = t0
		end
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and (trans_modifier < 1 or height_modifier < 90)) then 
			if (trans_modifier < 1) then trans_modifier = trans_modifier + 0.025 end
			if (height_modifier < 90) then height_modifier = height_modifier + 1.5 end
		else 
			change_init = true
		end
		draw_centered_text(messages[5][1], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (change_init == true and wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 3) then
		message_transition()
		continue_condition = 1
		if (step > 1) then 
			mp_modifier = step
		end
		unfreeze_game()
		if (get_world_state().match_frame == 30) then 
			freeze_game()
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[5][2], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[5][3], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 4) then
		message_transition()
		continue_condition = 1
		if (step > 1) then 
			mp_modifier = step
		end
		render_curfighting = true
		unfreeze_game()
		if (get_world_state().match_frame == 50) then 
			freeze_game()
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[5][4], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[5][5], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 5) then
		message_transition()
		continue_condition = 1
		if (step > 1) then 
			mp_modifier = step
		end
		render_curfighting = false
		render_waiting = true
		unfreeze_game()
		if (get_world_state().match_frame == 80) then 
			freeze_game()
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[5][6], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[5][7], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 6) then
		message_transition()
		continue_condition = 1
		if (step > 1) then 
			mp_modifier = step
		end
		render_waiting = false
		render_spec = true
		unfreeze_game()
		if (get_world_state().match_frame == 110) then 
			freeze_game()
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[5][8], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 7) then
		message_transition()
		continue_condition = 1
		if (step > 1) then 
			mp_modifier = step
		end
		render_spec = false
		unfreeze_game()
		if (get_world_state().match_frame == 145) then 
			freeze_game()
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[5][9], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[5][10], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 8) then
		message_transition()
		continue_condition = 1
		if (step > 1) then 
			mp_modifier = step
		end
		unfreeze_game()
		if (get_world_state().match_frame == 180) then 
			freeze_game()
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[5][11], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[5][12], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 9) then
		message_transition()
		continue_condition = 1
		unfreeze_game()
		if (get_world_state().match_frame == 220) then 
			freeze_game()
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[5][13], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false) then
			step_change(0, 10)
		end
	elseif (step == 10) then
		--display_step()
		unfreeze_game()
		if (get_world_state().match_frame == 400) then 
			freeze_game()
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[5][13], height - height_modifier + 40, FONTS.MEDIUM)
		if ((trans_modifier > 0 or height_modifier > 0) and change_init == false) then 
			change_init = false
			if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.025 end
			if (height_modifier > 0) then height_modifier = height_modifier - 1.5 end
		else	
			change_init = true
		end
		if (change_init == true) then
			step = 11
		end
	elseif (step == 11) then
		-- Fade in
		unfreeze_game()
		if (get_world_state().match_frame == 400) then
			freeze_game()
			step = 12
		end
	elseif (step == 12) then
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		--display_step()
		if (trans_modifier < 1) then 
			trans_modifier = trans_modifier + 0.02
		else
			step = 13
		end
	elseif (step == 13) then
		set_color(1, 1, 1, 1)
		draw_quad(0, 0, width, height)
		tut_end = true
		trans_modifier = 0
		step = 14
		change_init = false
		--display_step()
	elseif (step == 14) then
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
		--display_step()
	elseif (step == -1) then
		wait_for_continue = true
		step = mp_modifier + 1
		continue_condition = 0
		t0 = curtime()
		t1 = t0
	end 
end

function init_tut_stage4()
	step = 0
	set_option("score", 1)
	modifier, width_modifier, height_modifier, trans_modifier = 0, 0, 0, 1
	wait_for_continue = true
	add_hook("draw2d", "stage4", tut_stage4)
	remove_hooks("terminate")
end

function tut_stage3()
	tut_visuals()
	if (step == 0) then
		-- Preparation
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		run_cmd("set engagedistance 100")
		start_new_game()
		set_option("uke", 1)
		add_hook("new_game", "terminate", terminate)
		step = 0.5
	elseif (step == 0.5) then
		-- Open mod browser
		trans_modifier = 1
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		open_menu(7)
		step = 1
		ese = true
		continue_condition = 0
	elseif (step == 1) then
		-- Fade out
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.02 end 
		--display_step()
		step_change(0, 2)
	elseif (step == 2) then
		-- Mods intro
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and (trans_modifier < 1 or height_modifier < 90)) then 
			if (trans_modifier < 1) then trans_modifier = trans_modifier + 0.025 end
			if (height_modifier < 90) then height_modifier = height_modifier + 1.5 end
		else 
			change_init = true
			buttons.continue.state = BTN_UP
		end
		draw_centered_text(messages[4][1], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (change_init == true) then
			step_change(5, 3)
		end
	elseif (step == 3) then
		-- Intro to mod browser
		if (continue_condition == 0) then
			wait_for_continue = true
			continue_condition = 1
		end
		message_transition()
		if (trans_modifier > 1) then
			trans_modifier = 1
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][2], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 4) then
		-- Info on mods
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][3], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[4][4], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 5) then
		-- Info on mods 2
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][5], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[4][6], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 6) then
		-- Info on mods 3
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][7], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[4][8], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 7) then
		-- Info on mods 4
		message_transition()
		continue_condition = 0
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][9], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		remove_hooks("terminate")
		if (get_game_rules().mod == 'aikido.tbm' or get_game_rules().mod == '/aikido.tbm') then 
			step_change(0, 8)
		end
	elseif (step == 8) then
		-- Add terminate hook, open gamerules
		add_hook("new_game", "terminate", terminate)
	--	close_menu(7)
		open_menu(5)
		step = 9
		trans_modifier = 0
		wait_for_continue = true
	elseif (step == 9) then
		-- Game rules intro
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][10], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[4][11], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 10) then
		-- Game rules 2
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][12], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 11) then
		-- Game rules 3
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][13], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[4][14], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 12) then
		-- Load rk_f1.tbm
		remove_hooks("terminate")
		close_menu(5)
		run_cmd("loadreplay system/tut_1-2.rpl")
		freeze_game()
		add_hook("new_game", "terminate", terminate)
		step = 13
		trans_modifier = 0
	elseif (step == 13) then
		-- Rk_f1 
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][15], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 14) then
		-- Rk_f1 2
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][16], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[4][17], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 15) then
		-- Rk_f1 2
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][18], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 16) then
		-- rk_f1 ending, replays beginning
		--display_step()
		continue_condition = 0
		set_color(1, 1, 1, trans_modifier)
		if ((trans_modifier > 0 or height_modifier > 0) and change_init == false) then 
			change_init = false
			if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.025 end
			if (height_modifier > 0) then height_modifier = height_modifier - 1.5 end
		else	
			change_init = true
		end
		if (change_init == true) then 
			unfreeze_game()
			if (get_world_state().match_frame == 775) then
				freeze_game()
				change_init = false
				step = 17
				trans_modifier = 0
			end
		end
	elseif (step == 17) then
		-- Replays 1
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and (trans_modifier < 1 or height_modifier < 90)) then 
			if (trans_modifier < 1) then trans_modifier = trans_modifier + 0.025 end
			if (height_modifier < 90) then height_modifier = height_modifier + 1.5 end
		else 
			change_init = true
			continue_condition = 1
		end
		--display_step()
		draw_centered_text(messages[4][19], height - height_modifier + 40, FONTS.MEDIUM)
		if (step > 1) then
			mp_modifier = step
		end
		if (change_init == true and wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 18) then
		-- Replays 2
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][20], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 19) then
		message_transition()
		continue_condition = 1
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][21], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 20) then
		--display_step()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[4][21], height - height_modifier + 40, FONTS.MEDIUM)
		if ((trans_modifier > 0 or height_modifier > 0) and change_init == false) then 
			change_init = false
			if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.025 end
			if (height_modifier > 0) then height_modifier = height_modifier - 1.5 end
		else	
			change_init = true
		end
		if (change_init == true) then
			step = 21
		end
	elseif (step == 21) then
		-- Fade in
		--display_step()
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		--display_step()
		if (trans_modifier < 1) then 
			trans_modifier = trans_modifier + 0.02
		else
			remove_hooks("stage3")
			init_tut_stage4()
		end
	elseif (step == -1) then
		wait_for_continue = true
		continue_condition = 0
		step = mp_modifier + 1
	end
end

function init_tut_stage3()
	step = 0
	width_modifier, height_modifier, trans_modifier = 0, 0, 1
	add_hook("draw2d", "stage3", tut_stage3)
	remove_hooks("terminate")
end

local dq_render, dq_size, dq_alpha = false, 0, 1

function tut_stage2_drawdq()
	if (dq_render == true) then
		dq_size = dq_size + 0.05
		if (dq_size >= 10) then
			dq_alpha = dq_alpha - 0.02
		end
		if (dq_alpha < 0) then
			dq_size = 0.0
			dq_alpha = 1
		end
		set_color(1.0, 0.0, 0.0, dq_alpha)
		x = get_body_info(0, 0).pos.x
		y = get_body_info(0, 0).pos.y
		local inner = dq_size - 0.4
		local outer = dq_size
		if (inner < 0) then
			inner = 0
		end
		draw_disk_3d(x, y, 0.1, inner, outer, 32, 2, 180, -360, 0)
	end
end

function draw_camera_controls()
	local key_trans = 0
	if (wasd_press == false) then
		key_trans = trans_modifier - 0.1
	else
		key_trans = 0.9
	end
	set_color(0.6, 0.6, 0.6, key_trans)
	draw_rounded_quad(129, height/4 - 13, 82, 82, 7)
	draw_rounded_quad(29, height/4 + 87, 82, 82, 7)
	draw_rounded_quad(129, height/4 + 87, 82, 82, 7)
	draw_rounded_quad(229, height/4 + 87, 82, 82, 7)
	
	set_color(0.9, 0.9, 0.9, key_trans)
	draw_rounded_quad(130, height/4 - 12, 80, 80, 5)
	draw_rounded_quad(30, height/4 + 88, 80, 80, 5)
	draw_rounded_quad(130, height/4 + 88, 80, 80, 5)
	draw_rounded_quad(230, height/4 + 88, 80, 80, 5)
	
	button_press_color(pressed_w, wasd_press)
	draw_text("W", 151, height/4, FONTS.BIG)
	draw_text("W", 151, height/4, FONTS.BIG)
	button_press_color(pressed_a, wasd_press)
	draw_text("A", 52, height/4 + 100, FONTS.BIG)
	draw_text("A", 52, height/4 + 100, FONTS.BIG)
	button_press_color(pressed_s, wasd_press)
	draw_text("S", 154, height/4 + 100, FONTS.BIG)
	draw_text("S", 154, height/4 + 100, FONTS.BIG)
	button_press_color(pressed_d, wasd_press)
	draw_text("D", 254, height/4 + 100, FONTS.BIG)
	draw_text("D", 254, height/4 + 100, FONTS.BIG)
	
	if (step == 5) then
		if (shift_press == false) then 
			key_trans = trans_modifier - 0.1
		else
			key_trans = 0.9
		end
		set_color(0.6, 0.6, 0.6, key_trans)
		draw_rounded_quad(29, height/4 + 197, 282, 82, 7)
		set_color(0.9, 0.9, 0.9, key_trans)
		draw_rounded_quad(30, height/4 + 198, 280, 80, 7)
		button_press_color(pressed_shift, shift_press)
		draw_text("SHIFT", 52, height/4 + 210, FONTS.BIG)
	end
end

local camera_info
local camera_pos = { 0, 0, 0 }
	
function tut_stage2()
	tut_visuals()
	if (step == 0) then
		--display_step()
		-- Screen preparation stage 2
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		run_cmd("set engagedistance 500")
		start_new_game()
		start_torishop_camera(4)
		set_option("uke", 0)
		add_hook("new_game", "terminate", terminate)
		step = 1
	elseif (step == 1) then
		-- Fade out
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.02 end 
		--display_step()
		step_change(0, 2)
	elseif (step == 2) then
		-- Camera controls intro
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and (trans_modifier < 1 or height_modifier < 90)) then 
			if (trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
			elseif (trans_modifier > 1) then trans_modifier = 1 end
			if (height_modifier < 90) then height_modifier = height_modifier + 1.5 end
		else 
			change_init = true
		end
		draw_centered_text(messages[2][1], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		step_change(5, 3)
		wait_for_continue = true
		unlock_keyboard()
		wasd_render = true
	elseif (step == 3) then
		-- WASD camera controls
		draw_camera_controls()
		message_transition()
		if (wasd_press == true) then continue_condition = 1 end
		draw_centered_text(messages[2][2], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false and continue_condition == 1) then 
			step_change(0, 4)
			shift_render = true
			buttons.continue.state = BTN_UP
		end
	elseif (step == 4) then
		-- Preparation for step 5
		draw_camera_controls()
		continue_condition = 0
		wait_for_continue = true
		--display_step()
		step = 5
	elseif (step == 5) then
		-- Shitf + WS controls
		draw_camera_controls()
		message_transition()
		if ((pressed_w == true or pressed_s == true) and pressed_shift == true) then continue_condition = 1
		end
		draw_centered_text(messages[2][3], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[2][4], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false and continue_condition == 1) then 
			step_change(0, 6)
			wasd_press = false
			shift_press = false
			buttons.continue.state = BTN_UP
		end
	elseif (step == 6) then
		-- Preparation for step 7, getting current camera pos
		wasd_render = false
		continue_condition = 0
		wait_for_continue = true
		camera_info = get_camera_info()
		local i = 1
		for key,value in pairs(camera_info.pos) do 
			camera_pos[i] = value
			i = i + 1
		end
		--display_step()
		step = 7
	elseif (step == 7) then
		-- Mouse camera controls
		message_transition()
		local _camera_pos = { }
		camera_info = get_camera_info()
		local i = 1
		for key,value in pairs(camera_info.pos) do 
			_camera_pos[i] = value
			i = i + 1
		end
		for i = 1, 3 do
		if (camera_pos[i] ~= _camera_pos[i]) then continue_condition = 1 end
		end
		draw_centered_text(messages[2][5], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[2][6], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false and continue_condition == 1) then 
			step_change(0, 8)
			buttons.continue.state = BTN_UP
		end
	elseif (step == 8) then
		-- Nulling conditions
		lock_keyboard()
		continue_condition = 0
		wait_for_continue = true
		--display_step()
		step = 9
	elseif (step == 9) then
		-- Fade in
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and (trans_modifier > 0 or height_modifier > 0)) then 
			if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.025 end
			if (height_modifier > 0) then height_modifier = height_modifier - 1.5 end
		else change_init = true
		end
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		--display_step()
		if (change_init == true) then 
			if (trans_modifier < 1) then 
				trans_modifier = trans_modifier + 0.02
			else
				reset_camera(1)
				unlock_keyboard()
				step = 10
			end
		end
	elseif (step == 10) then
		-- Fade out
		wasd_render = true
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		--display_step()
		if (trans_modifier > 0) then 
			trans_modifier = trans_modifier - 0.02
		else 
			change_init = true
			step_change(0, 11) 
			add_hook("joint_select", "bodyparts", set_joint_tooltip)
			add_hook("body_select", "bodyparts", set_hand_tooltip)
			hand_joint_render = true
		end
	elseif (step == 11) then
		-- Tori controls intro
		if (change_init == false and (trans_modifier < 1 or height_modifier < 90)) then 
			if (trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
			elseif (trans_modifier > 1) then trans_modifier = 1 end
			if (height_modifier < 90) then height_modifier = height_modifier + 1.5 end
		else 
			change_init = true
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][1], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (change_init == true) then
			step_change(3, 12)
		end
		wait_for_continue = true
	elseif (step == 12) then
		-- Mouse joint controls
		message_transition()
		draw_joint_tooltip()
		draw_hand_tooltip()
		--display_step()
		local check_conditions = function()
			if (joint_text ~= nil) then
				continue_condition = 1
				remove_hooks("conditions")
			end
		end
		add_hook("mouse_button_down", "conditions", check_conditions)
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][2], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[3][3], height - height_modifier + 54, FONTS.MEDIUM)
		if (wait_for_continue == false and continue_condition == 1) then 
			step_change(0, 13)
		end
	elseif (step == 13) then
		-- Introduction to joint states
		message_transition()
		draw_joint_tooltip()
		draw_hand_tooltip()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][4], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[3][5], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		wait_for_continue = true
		continue_condition = 0
		step_change(3, 14)
	elseif (step == 14) then
		-- ZXC joint controls
		zxc_render = true
		message_transition()
		draw_joint_tooltip()
		draw_hand_tooltip()
		local check_conditions = function(key)
			if (joint_text ~= nil and (key == string.byte('z') or key == string.byte('x'))) then
				continue_condition = 1
				remove_hooks("conditions")
			end
		end
		add_hook("key_up", "conditions", check_conditions)
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][6], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[3][7], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false and continue_condition == 1) then 
			step_change(0, 14.5)
		end
	elseif (step == 14.5) then
		-- Nulling
		wait_for_continue = true
		continue_condition = 0
		step = 15
	elseif (step == 15) then
		-- Hold all / relax all
		message_transition()
		draw_joint_tooltip()
		draw_hand_tooltip()
		local check_conditions = function(key)
			if (key == string.byte('c')) then
				continue_condition = 1
				remove_hooks("conditions")
			end
		end
		add_hook("key_up", "conditions", check_conditions)
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][8], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[3][9], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false and continue_condition == 1) then 
			step_change(0, 15.5)
		end
	elseif (step == 15.5) then
		-- Nulling
		wait_for_continue = true
		continue_condition = 0
		step = 16
	elseif (step == 16) then
		-- Grab a hand
		message_transition()
		draw_joint_tooltip()
		draw_hand_tooltip()
		local check_conditions = function(mouse_btn, x, y)
			if (hand_text ~= nil and mouse_btn == 1) then
				continue_condition = 1
				remove_hooks("conditions")
			end
		end
		add_hook("mouse_button_down", "conditions", check_conditions)
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][10], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[3][11], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false and continue_condition == 1) then 
			step_change(0, 16.5)
		end
	elseif (step == 16.5) then
		-- Nulling
		wait_for_continue = true
		continue_condition = 0
		step = 17
		render_space = true
	elseif (step == 17) then
		-- Press space
		message_transition()
		local check_conditions = function(key)
			if (key == string.byte(' ')) then
				wait_for_continue = false
				remove_hooks("conditions")
			end
		end
		add_hook("key_up", "conditions", check_conditions)
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][12], height - height_modifier + 40, FONTS.MEDIUM)
		--display_step()
		if (wait_for_continue == false) then 
			run_frames(100)
			if (space_render == true) then 
				completion = completion + 1
			end
			space_render = false
			hand_joint_render = false
			remove_hooks("bodyparts")
			step_change(1, 18)
		end
	elseif (step == 18) then
		-- Fade in
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and (trans_modifier > 0 or height_modifier > 0)) then 
			if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.025 end
			if (height_modifier > 0) then height_modifier = height_modifier - 1.5 end
		else change_init = true
		end
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		--display_step()
		if (change_init == true) then 
			if (trans_modifier < 1) then 
				trans_modifier = trans_modifier + 0.02
			else
				remove_hooks("terminate")
				step = 19
			end
		end
	elseif (step == 19) then
		-- Start replay
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		--display_step()
		run_cmd("loadreplay system/tut_1-1.rpl")
		run_cmd("option uke 1")
		add_hook("new_game", "terminate", terminate)
		run_frames(220)
		step = 20
	elseif (step == 20) then
		-- Fade out
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		--display_step()
		if (get_world_state().match_frame == 220) then 
			dq_render = true
		end
		if (trans_modifier > 0) then 
			trans_modifier = trans_modifier - 0.02
		else
			change_init = false
			step = 21
		end
	elseif (step == 21) then
		-- "You can make incredible moves"
		if (get_world_state().match_frame == 220) then 
			dq_render = true
		end
		if (change_init == false and (trans_modifier < 1 or height_modifier < 90)) then 
			if (trans_modifier < 1) then trans_modifier = trans_modifier + 0.025 end
			if (height_modifier < 90) then height_modifier = height_modifier + 1.5 end
		else 
			change_init = true
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][13], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[3][14], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (change_init == true) then
			step_change(4, 22)
			continue_condition = 0
		end
	elseif (step == 22) then
		-- DQ ring 1
		message_transition()
		if (continue_condition == 0) then
			continue_condition = 1
			wait_for_continue = true
		end
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][15], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[3][16], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end
	elseif (step == 23) then
		-- DQ ring 2
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][17], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[3][18], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, -1)
		end	
	elseif (step == 24) then
		-- DQ ring 3
		message_transition()
		set_color(0, 0, 0, trans_modifier)
		draw_centered_text(messages[3][19], height - height_modifier + 24, FONTS.MEDIUM)
		draw_centered_text(messages[3][20], height - height_modifier + 54, FONTS.MEDIUM)
		--display_step()
		if (step > 1) then
			mp_modifier = step
		end
		if (wait_for_continue == false) then
			step_change(0, 24.5)
		end	
	elseif (step == 24.5) then
		change_init = false
		step = 25
		trans_modifier = 1
	elseif (step == 25) then
		-- Stage 2 ending
		set_color(1, 1, 1, trans_modifier)
		--display_step()
		if ((trans_modifier > 0 or height_modifier > 0) and change_init == false) then
			if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.025 end
			if (height_modifier > 0) then height_modifier = height_modifier - 1.5 end
		else	
			change_init = true
			set_color(1, 1, 1, trans_modifier)
			draw_quad(0, 0, width, height)
		end
		if (change_init == true) then
			if (trans_modifier <= 1) then
				trans_modifier = trans_modifier + 0.02
			else
				dq_render = false
				remove_hooks("stage2")
				init_tut_stage3()
			end
		end
	elseif (step == -1) then
		wait_for_continue = true
		step = mp_modifier + 1
	end
end

function init_tut_stage2()
	step = 0
	modifier, width_modifier, height_modifier, trans_modifier = 0, 0, 0, 1
	add_hook("draw2d", "stage2", tut_stage2)
	remove_hooks("terminate")
end

function tut_stage1()
	-- Message background
	if (step >= 2 and step <= 7) then
		if (width_modifier ~= 0) then
			set_color(1, 1, 1, 0.8)
			draw_quad(width/2 - 2 - width_modifier/2, height/2 - height_modifier/2, 4 + width_modifier, height_modifier)
			set_color(0.82, 0.39, 0.39, width_modifier/600)
			draw_quad(width/2 - 2 - width_modifier/2, height/2 - height_modifier/2, 2, height_modifier)
			draw_quad(width/2 + width_modifier/2, height/2 - height_modifier/2, 2, height_modifier)
			draw_quad(width/2 - 2 - width_modifier/2, height/2 - height_modifier/2, 4 + width_modifier, 2)
			draw_quad(width/2 - 2 - width_modifier/2, height/2 + height_modifier/2 - 2, 4 + width_modifier, 2)
		end
	end
	
	-- Stage 1 steps
	if (step == 0) then
		-- Run replay
		run_cmd("loadreplay system/tut_1-0.rpl")
		run_cmd("lp 0tori")
		run_cmd("lp 1uke")
		step = 1
	elseif (step == 1) then
		--display_step()
		add_hook("new_game", "terminate", terminate)
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		if (trans_modifier > 0) then trans_modifier = trans_modifier - 0.02 end
		if (get_world_state().match_frame > 190) then
			freeze_game()
			trans_modifier = 0
			step_change(0, 2)
		end
	elseif (step == 2) then
		--display_step()
		if (modifier == 0) then 
			t0 = curtime()
			modifier = 3
		end
		if ((curtime() - t0) > 1 or (curtime() - t0) < 0) then
			if (width_modifier < 600) then
				width_modifier = width_modifier + math.floor(modifier*modifier)
				if (modifier < 5) then modifier = modifier + 0.1
				else modifier = modifier - 0.1
				end
			elseif (width_modifier ~= 600) then
				width_modifier = width_modifier - 1
			else 
				step = 3
				modifier = 0
			end
		end
	elseif (step == 3) then
		--display_step()
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
		else change_init = true
		end
		draw_centered_text(messages[1][1], height/2 - 9, FONTS.MEDIUM)
		if (change_init == true) then 
			step_change(3, 4)
		end
	elseif (step == 4) then
		--display_step()
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
		else change_init = true
		end
		if (width_modifier < 680) then width_modifier = width_modifier + 4 end
		if (height_modifier < 100) then height_modifier = height_modifier + 1 end
		draw_centered_text(messages[1][2], height/2 - 25, FONTS.MEDIUM)
		draw_centered_text(messages[1][3], height/2 + 3, FONTS.MEDIUM)
		if (change_init == true) then 
			step_change(5, 5) 
		end
	elseif (step == 5) then
		--display_step()
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
		else change_init = true
		end
		draw_centered_text(messages[1][4], height/2 - 25, FONTS.MEDIUM)
		draw_centered_text(messages[1][5], height/2 + 3, FONTS.MEDIUM)
		if (change_init == true) then 
			step_change(5, 6)
		end
	elseif (step == 6) then
		--display_step()
		set_color(0, 0, 0, trans_modifier)
		if (change_init == false and trans_modifier < 1) then trans_modifier = trans_modifier + 0.025
		else change_init = true
		end
		if (width_modifier > 600) then width_modifier = width_modifier - 4 end
		if (height_modifier > 80) then height_modifier = height_modifier - 1 end
		draw_centered_text(messages[1][6], height/2 - 9, FONTS.MEDIUM)
		if (change_init == true) then 
			step_change(3, 7)
		end
	elseif (step == 7) then
		--display_step()
		if (change_init == false) then 
			modifier = 6 
			change_init = true
		end
		if (width_modifier > 0) then
			width_modifier = width_modifier - math.floor(modifier*modifier)
			modifier = modifier - 0.1
		else
			trans_modifier = 0
			step_change(0, 8)
		end
	elseif (step == 8) then
		--display_step()
		unfreeze_game()
		if (get_world_state().match_frame == get_world_state().game_frame) then 
			step = 9
		end
	elseif (step == 9) then
		--display_step()
		freeze_game()
		step_change(1, 10)
	elseif (step == 10) then
		--display_step()
		set_color(1, 1, 1, trans_modifier)
		draw_quad(0, 0, width, height)
		if (trans_modifier < 1) then
			trans_modifier = trans_modifier + 0.05
		else
			remove_hooks("stage1")
			init_tut_stage2()
		end
	end
end

function terminate()
	set_option("backgroundclick", default_background_click)
	set_option("autosave", default_autosave)
	set_option("hud", default_hud)
	
	run_cmd("option uke 1")
	run_cmd("set engagedistance 100")
	run_cmd("clear")

	remove_hooks("tutorial")
	remove_hooks("keyboard")
	remove_hooks("stage1")
	remove_hooks("stage2")
	remove_hooks("stage3")
	remove_hooks("stage4")
	remove_hooks("terminate")
	reset_camera(1)
	
	echo(" ")
	echo(" ")
	echo(" ")
	echo("Access the Toribash Beginner Sanctuary from the link below!")
	echo("http://forum.toribash.com/forumdisplay.php?f=362")
end

function start_tutorial()
	default_background_click = get_option("backgroundclick")
	default_autosave = get_option("autosave")
	default_hud = get_option("hud")
	
	set_option("uke", 1)
	set_option("backgroundclick", 0)
	set_option("autosave", 0)
	set_option("hud", 0)
	
	run_cmd("lm classic.tbm")
	
	lock_keyboard()
	load_buttons()
	
	add_hook("draw2d", "stage1", tut_stage1)
	add_hook("draw3d", "stage2", tut_stage2_drawdq)
	add_hook("new_mp_game", "tutorial", terminate)
	add_hook("mouse_button_down", "tutorial", mouse_down)
	add_hook("mouse_button_up", "tutorial", mouse_up)
	add_hook("mouse_move", "tutorial", mouse_move)
	add_hook("key_down", "tutorial", key_down)
	add_hook("key_up", "tutorial", key_up)
end

start_tutorial()