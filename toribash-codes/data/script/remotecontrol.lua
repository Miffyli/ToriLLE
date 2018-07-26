--[[
Based on the code by Siim Põder (2010): https://github.com/windo/toribash-evolver
Author: Anssi "Miffyli" Kanervisto, 2018

Toribash script to allow controlling of the character over pipes/TCP (e.g. from Python).
Specifically designed machine/reinforcement learning in mind.

Core loop: Send players' states (body parts etc), receive joint states, progress a step
]]

-- Toribash attempts to find remote controller at this address+port.
-- Change if needed
local CONNECT_IP = "127.0.0.1"
local CONNECT_PORT = 7788
local TIMEOUT = 300

-- This will be the TCP connection object
local s = nil

local NUM_JOINTS = 20
local NUM_LIMBS = 21
local NUM_SETTINGS = 19

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
    bloodstains = 0,
    avatar = 0,
    floortexture = 0,
}
-- Resolution for no rendering
local resolution_no_rendering = {400,300}

-- Options for rendering / watching
local options_rendering = { 
    fixedframerate = 1,
    antialiasing = 1,
    blood = 1,
    trails = 1,
    hud = 1,
    tori = 1,
    uke = 1,
    money = 0,
    score = 1,
    timer = 1,
    name = 1, 
    autoupdate = 0,
    smoothcam = 1,
    bloodstains = 1,
    avatar = 1,
    floortexture = 1,
}
-- Resolution for rendering
local resolution_rendering = {1280,720}

-- Determines if the game should be shown
-- If false: Training mode, i.e. as fast as possible, no drawing
-- If true: "enjoy" mode, i.e. draw game, limit fps
local draw_game = false;

-- If != "None", will save replay into this file
-- Given in settings.
local replay_file = "None";

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
    
	-- Wait for actions
	local actions = wait_for_data(s)
	actions = split_comma_and_numerize(actions)
    return actions
end

-- Receive settings and apply them
-- Note that many of these settings apply on _next_ round
local function recv_settings_and_apply()
    local settings = wait_for_data()
    settings = split_comma(settings)
    -- Not very pretty, could be done in some neat list
    -- But at least it is modifiable/readable ^^'
    run_cmd("set matchframes "..settings[1])
    run_cmd("set turnframes "..settings[2])
    run_cmd("set engagedistance "..settings[3])
    run_cmd("set engageheight "..settings[4])
    run_cmd("set engagerotation "..settings[5])
    run_cmd("set gravity "..settings[6].." "..settings[7].." "..settings[8])
    run_cmd("set damage "..settings[9])
    run_cmd("set dismemberment "..settings[10])
    run_cmd("set dismemberthreshold "..settings[11])
    run_cmd("set fracture "..settings[12])
    run_cmd("set fracturethreshold "..settings[13])
    run_cmd("set disqualification "..settings[14])
    run_cmd("set dqflag "..settings[15])
    run_cmd("set dqtimeout "..settings[16])
    run_cmd("set dojotype "..settings[17])
    run_cmd("set dojosize "..settings[18])
    replay_file = settings[19]
end

-- Send message indicating end of episode, and receive
-- possible new settings
local function send_end_recv_settings()
    -- Send info that episode was terminated
    local state = build_state()
    -- Add indicator of end state
    state = "end,"..state
	s:send(state.."\n")
    -- Receive new settings and apply them
    recv_settings_and_apply()
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

-- Executed after round is over (just start a new one)
local function finish_game(winType)
    -- Check if we should save replay
    if (replay_file ~= "None") then
        run_cmd("savereplay "..replay_file)
    end
    send_end_recv_settings()
    -- We need to redo hooks
    remove_hook("enter_freeze", "remotecontrol_freeze")
    start_new_game()
end

-- Used to detect first game, which is used to 
-- get new settings.
-- Setting rules/settings require game to be running (mod loaded),
-- which is why we are doing the settings stuff here
local first_game = true

-- Start a single game
local function start_game()
    if (first_game == true) then
        first_game = false
        -- Receive settings and apply them
        recv_settings_and_apply()
        -- Reset game to apply settings
        run_cmd("reset")
        -- Define hook for end game here, because otherwise
        -- 'reset' above will trigger it
        add_hook("end_game", "remotecontrol", finish_game)
    end
    -- Check if we should receive settings instead of playing game
    add_hook("enter_freeze", "remotecontrol_freeze", simulation_next_turn)
    -- make the first turn
    simulation_next_turn()
end

-- Initialize the game for running as fast as possible 
-- (minimize rendering etc)
function initialize_and_start()
    if (draw_game == true) then
        -- Enjoy mode: Draw game
        for opt, val in pairs(options_rendering) do
            set_option(opt, val)
        end
        -- Update 27.7.2018: Removing resolution change for now. This 
        -- may be crashing Toribash occasionally
        -- run_cmd("re "..resolution_rendering[1].." "..resolution_rendering[2])
    else 
        for opt, val in pairs(options_no_rendering) do
            set_option(opt, val)
        end
        -- Update 27.7.2018: Removing resolution change for now. This 
        -- may be crashing Toribash occasionally
        -- run_cmd("re "..resolution_no_rendering[1].." "..resolution_no_rendering[2])
    end
    -- Start the game by loading the mod
    run_cmd("loadmod classic")
end

-- Temporary drawing hook for closing menu
-- This is used to close main menu while booting straight to the script
-- Credits: hampa & Dranix
function menu_closer_drawer() 
    close_menu()
    remove_hooks("menu_closer")
    initialize_and_start()
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
    
    -- Receive initial handshake, which determines 
    -- if we should display game or not
    local handshake = wait_for_data()
    handshake = split_comma_and_numerize(handshake)
    draw_game = handshake[1] == 1
    
    -- Make sure there are no hooks with these names
    remove_hook("end_game", "remotecontrol")
    remove_hook("new_game", "remotecontrol")
    remove_hook("enter_freeze", "remotecontrol_freeze")
    remove_hook("draw3d", "menu_closer")
    
    -- Finish hook will be created later
    add_hook("new_game", "remotecontrol", start_game)
    -- This hook is to close main manu
    -- It can prevent playing the game, especially if this 
    -- script is launched from profile.tbs
    add_hook("draw3d", "menu_closer", menu_closer_drawer)
end

close_menu()
run_controlled()
