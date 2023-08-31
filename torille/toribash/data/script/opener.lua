-- opener.lua
-- an automated opener for uke

local openers = {
	{ --EASY
		L_SHOULDER=2,
		L_GLUTE=3,
		R_HIP=3,
		NECK=3,
		L_HIP=3,
		LUMBAR=3,
		R_ANKLE=3,
		R_GLUTE=3,
		R_ELBOW=3,
		L_WRIST=3,
		L_KNEE=3,
		L_ANKLE=3,
		CHEST=3,
		L_PECS=2,
		R_SHOULDER=2,
		R_PECS=2,
		R_KNEE=3,
		ABS=3,
		L_ELBOW=3,
		R_WRIST=3
	},
	{ --STANDARD
		L_SHOULDER=3,
		L_GLUTE=1,
		R_HIP=1,
		NECK=3,
		L_HIP=2,
		LUMBAR=1,
		R_ANKLE=3,
		R_GLUTE=1,
		R_ELBOW=3,
		L_WRIST=3,
		L_KNEE=3,
		L_ANKLE=3,
		CHEST=2,
		L_PECS=2,
		R_SHOULDER=3,
		R_PECS=2,
		R_KNEE=3,
		ABS=2,
		L_ELBOW=3,
		R_WRIST=3
	},
	{ --LIMP
		L_SHOULDER=4,
		L_GLUTE=4,
		R_HIP=3,
		NECK=4,
		L_HIP=4,
		LUMBAR=3,
		R_ANKLE=4,
		R_GLUTE=3,
		R_ELBOW=4,
		L_WRIST=4,
		L_KNEE=4,
		L_ANKLE=4,
		CHEST=2,
		L_PECS=1,
		R_SHOULDER=4,
		R_PECS=2,
		R_KNEE=4,
		ABS=3,
		L_ELBOW=4,
		R_WRIST=4
	},
	{ --LIMP 2
		L_SHOULDER=4,
		L_GLUTE=4,
		R_HIP=4,
		NECK=4,
		L_HIP=3,
		LUMBAR=1,
		R_ANKLE=4,
		R_GLUTE=4,
		R_ELBOW=4,
		L_WRIST=4,
		L_KNEE=4,
		L_ANKLE=4,
		CHEST=2,
		L_PECS=1,
		R_SHOULDER=4,
		R_PECS=2,
		R_KNEE=4,
		ABS=4,
		L_ELBOW=4,
		R_WRIST=4
	}
}

local function set_joints(player, joints)
	for k,v in pairs(joints) do
		if (JOINTS[k] ~= nil) then
			set_joint_state(player, JOINTS[k], v)
		end
	end
end

local function do_opening(index)
	set_joints(1, openers[index])
end

local function joint_random()
	for i = 0, 19 do
		if (math.random() > 0.5) then
			-- Only change the joint state half the time
			set_joint_state(1, i, math.random(1,4))
		end
	end
end

local function firststep()
	do_opening(math.random(1, table.getn(openers)))
	add_hook("exit_freeze", "opener", joint_random)
end

local function start()
	run_cmd("echo opener.lua")
	add_hook("exit_freeze", "opener", firststep)
	--do_opening(math.random(1, table.getn(openers)))
end

add_hook("new_game", "opener", start)
add_hook("exit_freeze", "opener", firststep)

