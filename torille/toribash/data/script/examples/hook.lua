local globaltimeouts = { }
function set_timeout(timeout, fn)
	if fn then table.insert(globaltimeouts, { timeleft=timeout, func=fn } ) end
end

function run_timeout(delta)
	delta = delta or 1 -- Prevent it from being nil

	local final = { }
	for i,t in ipairs(globaltimeouts) do
		t.timeleft = t.timeleft - delta
		if (t.timeleft < 0) then
			t.func()
		else
			table.insert(final, t)
		end
	end
	globaltimeouts = final
end

local templen1, templen2, templen3 = 0, 0, 0
local msg1, msg2, msg3 = '', '', ''

font_type = FONTS.SMALL

font_info_height = 32
font_info_width = 15

run_cmd ("chl " .. "100")

function set_message(str1, str2, str3, mid)
	templen1, templen2, templen3 = 0, 0, 0
	msg1 = str1 or ''
	msg2 = str2 or ''
	msg3 = str3 or ''
	mid_print = mid
	alpha = nil
	draw = on_draw2d_scroller
end

function change_message(timeout, str1, str2, str3, mid)
	alpha = 1
	draw = on_draw2d
	set_timeout(timeout, function() set_message(str1, str2, str3, mid) end)
end
	 
function draw() 
	 set_message ("TESTING HOOKS", "", "")
end

function enter_frame_test()
	 change_message(50,"Enter Frame", " ", " ")
end

function joint_select_test()
	 change_message(50,"Joint Select", " ", " ")
end

function on_draw2d()
	local width, height = get_window_size()

	local y_mid = height - font_info_height * 2
	if (mid_print == true) then y_mid = height/2 - font_info_height end

	set_color(0, 0, 0, alpha or 1)
	draw_centered_text(msg1, y_mid - font_info_height, font_type)
	draw_centered_text(msg2, y_mid, font_type)
	draw_centered_text(msg3, y_mid + font_info_height, font_type)

	if (alpha) then
		alpha = alpha - 0.01
		if (alpha < 0) then alpha = 0 end
	end
end

function on_draw2d_scroller()
	local width, height = get_window_size()

	local y_mid = height - font_info_height * 2
	if (mid_print == true) then y_mid = height/2 - font_info_height end

	set_color(0,0,0,1)
	draw_centered_text(string.sub(msg1, 1, templen1), y_mid - font_info_height, font_type)
	templen1 = templen1 + 1

	if templen1 >= string.len(msg1) then
		draw_centered_text(string.sub(msg2, 1, templen2), y_mid, font_type)
		templen2 = templen2 + 1

		if templen2 >= string.len(msg2) then
			draw_centered_text(string.sub(msg3, 1, templen3), y_mid + font_info_height, font_type)
			templen3 = templen3 + 1
		end
	end
end


add_hook ("draw2d", "test", function() run_timeout(1); draw() end)
add_hook ("new_game", "test" , function() echo("New Game Hook") end)
add_hook ("enter_frame", "test" , enter_frame_test)
add_hook ("new_mp_game", "test" , function() echo("New Multi Game Hook") end)
add_hook ("leave_game", "test" , function() echo("Leave Game Hook") end)
add_hook ("end_game", "test" , function() echo("End Game Hook") end)
add_hook ("enter_freeze", "test" , function() echo("Freeze Game Hook") end)
add_hook ("exit_freeze", "test" , function() echo("Exit freeze Hook") end)	 
add_hook ("key_up", "test" , function() echo("key up Hook") end)
add_hook ("key_down", "test" , function() echo("key down Hook") end)
add_hook ("mouse_button_down", "test" , function() echo("mouse button down Hook") end)
add_hook ("mouse_button_up", "test" , function() echo("mouse button up Hook") end)
add_hook ("player_select", "test" , function() echo("Player Select Hook") end)
add_hook ("joint_select", "test" , joint_select_test)



