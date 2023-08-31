-- random.lua
-- Joint state randomiser

local function joint_random()
	for k,v in pairs(JOINTS) do
		set_joint_state(1, v, math.random(1,4))
	end
	set_grip_info(1, BODYPARTS.L_HAND, math.random(0,2))
	set_grip_info(1, BODYPARTS.R_HAND, math.random(0,2))
end

local function start()
	run_cmd("echo random.lua")
	joint_random()
end
start()

add_hook("new_game", "random_lua", start)
add_hook("enter_freeze", "random_lua", joint_random)
