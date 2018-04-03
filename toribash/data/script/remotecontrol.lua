--[[
Based on the code by Siim Põder (2010): https://github.com/windo/toribash-evolver
Author: Anssi Kanervisto <anssi.kanervisto@uef.fi>, 2018

Toribash script to allow controlling of the character over pipes/TCP (e.g. from Python).
Specifically designed machine/reinforcement learning in mind.

Core loop: Send players' states (body parts etc), receive joint states, progress a step
]]

--[[Setup (25.3.2018)
1. Move "socket" directory and "socket.lua" to Toribash root
2. Replace "/data/script/startup.lua" with provided "startup.lua"
3. Place "remotecontrol.lua" under "/data/script" directory and launch it from game (Options->Utils->Scripts)]]

--[[
Toribash notes:

some options: http://forum.toribash.com/showthread.php?t=317900
functions: https://github.com/trittimo/ToriScriptAPI/blob/master/docs/toribash_docs.txt
Bodypart list: http://forum.toribash.com/showthread.php?t=9391
Previous attempt at NEAT: http://forum.toribash.com/showthread.php?t=170100
                          http://forum.toribash.com/showthread.php?t=167355
                          http://forum.toribash.com/showthread.php?t=25263

- Use "run_cmd(...)" to set rules (see "some options"). E.g. "run_cmd('set engagedistance 100')" sets engagement distance to 100 (default)
- Use "get_body_info(plr_index, body_index)" to get body info (pos, side?, rot?). 
- Use "get_joint_info(plr_index, joint_index)" to get get joint info (state)
- Use "set_joint_state(plr_index, joint_index, state)" to set joint state
- Use "get_player_info(plr_index).injury" to get the amount of injury (= score for the __OTHER__ player)
    - Stuff like ripping limbs apart does not seem to cause too much injury. Adjust to like in GA?
- File "profile.tbs" is executed on Toribash launch, can be used to load script ("ls remotecontrol.lua")

/re 10 10 -- lower resolution
/opt fixedframerate -- run as fast as possible


]]--


-- Joint states: 1,2,3,4
-- Grip states: 0,1
-- Limbs: 0-20 (N: 21)
-- Joints: 0-19 (N: 20)

--[[
State is a table that should contain following:
    - plr0 limbs (pos x,y,z) (NUM_LIMBS*3)
    - plr0 joints (states) (NUM_JOINTS)
    - plr0 injury 
    - plr1 limbs (pos x,y,z) (NUM_LIMBS*3)                    
    - plr1 joints (states) (NUM_JOINTS)
    - plr0 injury
Action is a table that contains following:
    - plr0 joint states (NUM_JOINTS)
    - plr0 left hand grip
    - plr0 right hand grip
    - plr1 joint states (NUM_JOINTS)
    - plr1 left hand grip
    - plr1 right hand grip
When game ends (in finish_game), send:
    - "end"
And then wait for settings from server,
These are sent over communication as comma-separated lists
]]--


local CONNECT_IP = "127.0.0.1"
local CONNECT_PORT = 7777
local TIMEOUT = 10

-- This will be the TCP connection object

local s = nil

local NUM_JOINTS = 20
local NUM_LIMBS = 21

-- Options for not rendering anything
local options_no_rendering = { 
    fixedframerate = 0,
    antialiasing = 0,
    blood = 0,
    trails = 0,
    hud = 0,
    tori = 0,
    uke = 0,
    money = 0,
    score = 0,
    timer = 0,
    name = 0, 
    autoupdate = 0,
    smoothcam = 0,
    reflection = 0,
    particles = 0,
}
-- Resolution for no rendering
local resolution_no_rendering = {10,10}

-- Options for rendering / watching
local options_rendering = { 
    fixedframerate = 1,
    antialiasing = 1,
    blood = 1,
    trails = 1,
    hud = 1,
    tori = 1,
    uke = 1,
    money = 1,
    score = 1,
    timer = 1,
    name = 1, 
    autoupdate = 0,
    smoothcam = 1
}
-- Resolution for rendering
local resolution_rendering = {1280,720}

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
           
-- Build state current state representation
local function build_state()
    local state = {}
    local info = nil
    for plridx = 0,1 do
        -- Bodypart positions
        for bodyidx = 0,NUM_LIMBS-1 do
            info = get_body_info(plridx, bodyidx)
            table.insert(state, info.pos.x)
            table.insert(state, info.pos.y)
            table.insert(state, info.pos.z)
        end
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
    state = table.concat(state, ",")
    return state
end

-- Send state to the connection, and receive actions
-- Actions will be a list of plr0/1 joint states that should be set
local function send_state_recv_actions(state)
    -- Send state
	local send_amount = s:send(state.."\n")
	echo("sent "..send_amount)
    
	-- Wait for actions
	local actions = wait_for_data(s)
	actions = split_comma_and_numerize(actions)
    return actions
end

-- Send message indicating end of episode, and receive
-- possible new settings
local function send_end_recv_settings()
    -- Send info that episode was terminated
    local state = build_state()
    -- Add indicator of end state
    state = "end,"..state
	s:send(state.."\n")
	-- Receive new settings
	local settings = wait_for_data()
    settings = split_comma_and_numerize(settings)
    -- TODO apply settings
    run_cmd("set ed "..math.random(10,1000))
end

-- Set joins according to given action
-- Actions is a list of joint states for plr0 and plr1
local function make_move(actions)
    local offset = 1 -- +1 to make [0,...n] -> [1, ...n+1] for table indexing
    -- plr0 joint states
    for jointIdx = 0,NUM_JOINTS-1 do
        set_joint_state(0, jointIdx, actions[jointIdx+offset])
    end
    -- Hand grips
    set_grip_info(0, BODYPARTS.L_HAND, actions[NUM_JOINTS+offset])
    set_grip_info(0, BODYPARTS.R_HAND, actions[NUM_JOINTS+1+offset])
    
    offset = 1 + NUM_JOINTS + 2
    -- plr1 joint states
    for jointIdx = 0,NUM_JOINTS-1 do
        set_joint_state(1, jointIdx, actions[jointIdx+offset])
    end
    -- Hand grips
    set_grip_info(1, BODYPARTS.L_HAND, actions[NUM_JOINTS+offset])
    set_grip_info(1, BODYPARTS.R_HAND, actions[NUM_JOINTS+1+offset])
end

-- During simulation, make moves and advance the turn
local function simulation_next_turn()
    local state = build_state()
    
    local actions = send_state_recv_actions(state)
    make_move(actions)

    -- continue simulation
    step_game()
end

-- Start a single game
local function start_game()
    add_hook("enter_freeze", "remotecontrol_freeze", simulation_next_turn)
    -- make the first turn
    simulation_next_turn()
end

-- Executed after round is over (just start a new one)
local function finish_game(winType)
    send_end_recv_settings()
    remove_hook("enter_freeze", "remotecontrol_freeze")
    start_new_game()
end

-- Initialize the game for running as fast as possible 
-- (minimize rendering etc)
function initialize_and_start()
    -- TODO make these changeable via settings
    for opt, val in pairs(options_no_rendering) do
        set_option(opt, val)
    end
    run_cmd("re "..resolution_no_rendering[1].." "..resolution_no_rendering[2])
    -- Start the game by loading mod
    run_cmd("loadmod classic")
    -- Set rules
    run_cmd("set turnframes 1")
    run_cmd("set matchframes 1000")
end

-- Temporary drawing hook for closing menu
-- This is used to close main menu while booting straight to the script
-- Credits: hampa & Dranix
function menu_closer_drawer() 
    close_menu()
    initialize_and_start()
    remove_hooks("menu_closer")
end

--Starup
local function run_controlled(configuration)
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
    remove_hook("new_game", "remotecontrol")
    remove_hook("enter_freeze", "remotecontrol_freeze")
    remove_hook("draw3d", "menu_closer")
    
    add_hook("end_game", "remotecontrol", finish_game)
    add_hook("new_game", "remotecontrol", start_game)
    -- This hook is to close main manu
    -- It can prevent playing the game, especially if this 
    -- script is launched from profile.tbs
    add_hook("draw3d", "menu_closer", menu_closer_drawer)
    
    initialize_and_start()
end

run_controlled()
