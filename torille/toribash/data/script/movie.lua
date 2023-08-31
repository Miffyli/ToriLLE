-- script that creates and mpeg movie out of a replay

i = 0
frame = 0
fullspeed = true
capture = false
prefix = 0 

local function take_screenshot()
	
	if (not capture) then
		return
	end
	
	i=i+1
	if(fullspeed) then
		if((i % 3) == 0) then
			frame = frame+1
			screenshot(string.format("%s_screenshot_%04i.ppm", prefix, frame), 1)
			-- run_cmd("echo fullspeed screenshot " .. frame)
		end
	else
		frame = frame+1
		screenshot(string.format("%s_screenshot_%04i.ppm", prefix, frame), 1)
		-- run_cmd("echo half speed screenshot " .. frame)
	end	
end

local function key_up(key)
	-- Disable some keys
      	if key == string.byte(' ') then
		if (not capture) then
			rewind_replay()
			run_cmd("cb")
			run_cmd("option hud 1")
			capture = true 
		else
			fullspeed = not fullspeed
			if (fullspeed) then
				run_cmd("echo x1.5")
			else
				run_cmd("echo x0.5")
			end
		end
		-- dont let main program catch it
		return 1
	end
end

local function end_capture()
	capture = false
	remove_hooks("take_screenshot")
	run_cmd("echo Creating MPEG movie. program will freeze during create. Please wait")
	run_cmd(string.format("echo running ffmpeg and saving to %s_movie.mpeg", prefix))
	-- mbd rd -flags +4mv+trell+aic -cmp 2 -subcmp 2 -g 300 -pass 1/2
	-- some targets dont work on all -target vcd
	run_cmd(string.format("ffmpeg screenshots/%s_screenshot_%%04d.ppm %s_movie.mpeg", prefix, prefix))

	-- reset variables incase they run again
	frame = 0
	i = 0
	fullspeed = true
	capture = false
	prefix = math.random(100,10000)
	run_cmd("option hud 1")
end

local function on_leave_game()
	if (capture and frame > 1) then
		end_capture()
	end
end

math.randomseed(get_world_state().frame_tick)
prefix = math.random(100,10000)

run_cmd("echo --== Movie Capture Script " .. prefix .. " ==--")
run_cmd("echo 1. Select and pause a replay")
run_cmd("echo 2. Press SPACE to start the capture") 
run_cmd("echo 3. After that use SPACE to toggle slowmotion")
run_cmd("echo when replay ends. movie is created in your toribash directory") 
add_hook("draw2d", "moviemaker", take_screenshot)
add_hook("key_up", "moviemaker", key_up)
add_hook("leave_game", "moviemaker", on_leave_game)

