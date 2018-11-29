--[[
A stripped-down version of remotecontrol.lua: Connects to a remote controller
(via TCP), and starts sending observations and receiving commands for the local player 
(not uke). Turns are ended manually by human player pressing SPACE.
This allows more fine-tuned control of the character as well as helps
with issues with step_game()

This script is mainly designed to make it possible to play
multiplayer games from Python

Usage:
    - Launch the remote controller that listens to connections 
      to port specified below
    - Launch this lua script in Toribash
    - The remote end now receives states and sends back actions
    - Press SPACE to continue to next turn
    - Both scripts end once round finishes
]]

-- Toribash attempts to find remote controller at this address+port.
-- Change if needed.
-- You remote control script has to listen connections to this port
local CONNECT_IP = "127.0.0.1"
local CONNECT_PORT = 7788
local TIMEOUT = 30

-- This will be the TCP connection object
local s = nil

local NUM_JOINTS = 20
local NUM_LIMBS = 21
local NUM_SETTINGS = 19

-- Sleep function based on socket.select function
-- From Stackoverflow #17987618
function sleep(sec)
    socket.select(nil, nil, sec)
end

-- Wait for content to be read from socket, else throws error
function wait_for_data()
	local result = s:receive("*l")
	if result ~= nil then
		return result
	else 
        echo("Server error: Timeout. ")
	end
end

-- Split string by comma and turn numeric
function split_comma_and_numerize(str)
	local ret = {}
	for v in string.gmatch(str, "([^,]+)") do
		table.insert(ret, tonumber(v))
	end
	return ret
end

-- Split string by comma 
function split_comma(str)
	local ret = {}
	for v in string.gmatch(str, "([^,]+)") do
		table.insert(ret, v)
	end
	return ret
end
           
-- Build state current state representation
local function build_state()
    local state = {}
    local info = nil
    local x = nil
    local y = nil
    local z = nil
    for plridx = 0,1 do
        -- Bodypart positions
        for bodyidx = 0,NUM_LIMBS-1 do
            info = get_body_info(plridx, bodyidx)
            table.insert(state, info.pos.x)
            table.insert(state, info.pos.y)
            table.insert(state, info.pos.z)
        end
        -- Bodypart velocities
        for bodyidx = 0,NUM_LIMBS-1 do
            x, y, z = get_body_linear_vel(plridx, bodyidx)
            table.insert(state, x)
            table.insert(state, y)
            table.insert(state, z)
        end
        -- Rotation of groin (4x4 matrix)
        info = get_body_info(plridx, 4)
        table.insert(state, info.rot.r0)
        table.insert(state, info.rot.r1)
        table.insert(state, info.rot.r2)
        table.insert(state, info.rot.r3)
        table.insert(state, info.rot.r4)
        table.insert(state, info.rot.r5)
        table.insert(state, info.rot.r6)
        table.insert(state, info.rot.r7)
        table.insert(state, info.rot.r8)
        table.insert(state, info.rot.r9)
        table.insert(state, info.rot.r10)
        table.insert(state, info.rot.r11)
        table.insert(state, info.rot.r12)
        table.insert(state, info.rot.r13)
        table.insert(state, info.rot.r14)
        table.insert(state, info.rot.r15)
        -- Joint states
        for jointidx = 0,NUM_JOINTS-1 do
            info = get_joint_info(plridx, jointidx)
            table.insert(state, info.state)
        end
        -- Handgrips
        table.insert(state, get_grip_info(plridx, 12))
        table.insert(state, get_grip_info(plridx, 11))
        -- Injury
        table.insert(state, get_player_info(plridx).injury)
    end
    -- Add current selected player
    table.insert(state, get_world_state().selected_player)
    state = table.concat(state, ",")
    return state
end

-- Send state to the connection, and receive actions
-- Actions will be a list of plr0 joint states that should be set
local function send_state_recv_actions(state)
    -- Send state
	local send_amount = s:send(state.."\n")
    
	-- Wait for actions
	local actions = wait_for_data(s)
	actions = split_comma_and_numerize(actions)
    return actions
end


-- Send message indicating end of episode, remove all hooks
-- and quit the lua script
local function send_end_and_quit()
    -- Send info that episode was terminated.
    -- Send the final state along with it as well
    local state = build_state()
    local world_state = get_world_state()
    -- Add indicator of end state
    -- and add the winner of the game
    -- 0 = tie, 1 = red wins, 2 = blue wins
    -- (blue is uke, red is player)
    winner = world_state["winner"]+1
    state = "end:"..winner..","..state
	s:send(state.."\n")
    
    -- Quit by removing all hooks
    remove_hook("end_game", "remotecontrol")
    remove_hook("enter_freeze", "remotecontrol")
    -- Close the socket
    s:close()
end

-- Set joins according to given action
-- Actions is a list of joint states for plr0
local function make_move(actions)
    local offset = 1 -- +1 to make [0,...n] -> [1, ...n+1] for table indexing
    -- plr0 joint states
    for jointIdx = 0,NUM_JOINTS-1 do
        set_joint_state(0, jointIdx, actions[jointIdx+offset])
    end
    -- Hand grips
    set_grip_info(0, BODYPARTS.L_HAND, actions[NUM_JOINTS+offset])
    set_grip_info(0, BODYPARTS.R_HAND, actions[NUM_JOINTS+1+offset])
    
    -- Note: No control of player 1 here, only player 2
end

-- Send state, get actions and set characters accordingly
local function simulation_next_turn()
    local state = build_state()
    
    local actions = send_state_recv_actions(state)
    make_move(actions)
end

--Starup
local function run_controlled()
    -- Attempt to connect to the controller
	echo("Connecting to "..CONNECT_IP..":"..CONNECT_PORT)
	local start_time = os.time()
	while (s == nil and os.difftime(os.time(), start_time) < TIMEOUT) do
		s = socket.connect(CONNECT_IP, CONNECT_PORT)
		sleep(0.1)
	end
	
	if (s == nil) then
		echo("Could not connect.")
		return
	else
		local ip,port = s:getpeername()
		echo("Connected at port "..port)
	end
	
    s:settimeout(TIMEOUT)
       
    -- Make sure there are no hooks with these names
    remove_hook("end_game", "remotecontrol")
    remove_hook("enter_freeze", "remotecontrol")
    
    -- Add hook for doing action once we go to freeze
    add_hook("enter_freeze", "remotecontrol", simulation_next_turn)
    -- Add hook for when game ends
    add_hook("end_game", "remotecontrol", send_end_and_quit)
    
    -- Do the initial step
    simulation_next_turn()
end

run_controlled()
