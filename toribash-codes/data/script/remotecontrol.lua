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
    text = 0,
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
    text = 0,
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
local replay_file = "None"

-- Defines the currently played mode
local game_mod = "classic"

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
        echo("Server error on receive.")
        -- Using "/quit" command instead of os.exit
        -- because os.exit seems to be overwritten/blocked
        -- somewhere in the binary (does not work, even with
        -- adjustement in startup.lua)
        run_cmd("quit")
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
    local worldstate = get_world_state()
    -- Add selected player to the state.
    table.insert(state, worldstate.selected_player)
    -- Add number of frames in the game, frames passed 
    -- and number of frames of next turn
    table.insert(state, worldstate.game_frame)
    table.insert(state, worldstate.match_frame)
    table.insert(state, worldstate.match_turn_frame)
    state = table.concat(state, ",")
    return state
end

-- Send state to the connection, and receive actions
-- Actions will be a list of plr0/1 joint states that should be set
local function send_state_recv_actions(state)
    -- Send state
	local send_amount = s:send(state.."\n")
    if send_amount == nil then
        echo("Server error on send.")
        run_cmd("quit")
	end
    
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
    
    -- Set mode if it is different from current one
    if (settings[21] ~= game_mod) then
        game_mod = settings[21]
        run_cmd("set mod "..game_mod)
    end
    
    -- First check if we should change settings
    if (settings[1] ~= "0") then
        -- Not very pretty, could be done in some neat list
        -- But at least it is modifiable/readable ^^'
        run_cmd("set matchframes "..settings[2])
        -- We substract turnframes by one, because 
        -- calling step_game causes one extra step
        run_cmd("set turnframes "..settings[3])
        run_cmd("set engagedistance "..settings[4])
        run_cmd("set engageheight "..settings[5])
        run_cmd("set engagerotation "..settings[6])
        run_cmd("set gravity "..settings[7].." "..settings[8].." "..settings[9])
        run_cmd("set damage "..settings[10])
        run_cmd("set dismemberment "..settings[11])
        run_cmd("set dismemberthreshold "..settings[12])
        run_cmd("set fracture "..settings[13])
        run_cmd("set fracturethreshold "..settings[14])
        run_cmd("set disqualification "..settings[15])
        run_cmd("set dqflag "..settings[16])
        run_cmd("set dqtimeout "..settings[17])
        run_cmd("set dojotype "..settings[18])
        run_cmd("set dojosize "..settings[19])
    end
    -- Set replay file
    replay_file = settings[20]
end

-- Send message indicating end of episode, and receive
-- possible new settings
local function send_end_recv_settings()
    -- Send info that episode was terminated
    local state = build_state()
    local world_state = get_world_state()
    -- Add indicator of end state
    -- and add the winner of the game
    -- 0 = tie, 1 = red wins, 2 = blue wins
    -- (blue is uke, red is player)
    winner = world_state["winner"]+1
    state = "end:"..winner..","..state
	
    local send_amount = s:send(state.."\n")
    if send_amount == nil then
        echo("Server error on send")
        run_cmd("quit")
	end
    
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

-- This is used to communicate between
-- simulation_next_turn and check_if_should_step
-- when game should be step forward.
-- If we do this in simulation_next_turn, this causes
-- extra frames per turn
local should_step = false

-- Send state, get actions and set characters accordingly
local function simulation_next_turn()
    local state = build_state()
    
    local actions = send_state_recv_actions(state)
    make_move(actions)

    -- Proceed game
    should_step = true
end

local function check_if_should_step() 
   if (should_step == true) then
       should_step = false
       step_game()
   end
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
    remove_hook("pre_draw", "remotecontrol")
    start_new_game()
end

-- Used to detect first game, which is used to 
-- get new settings.
-- Setting rules/settings require game to be running (mod loaded),
-- which is why we are doing the settings stuff here
local first_game = true

-- Start a single game
local function start_game()
    -- Check if we should receive settings instead of playing game
    if (first_game == true) then
        first_game = false
        -- Receive settings and apply them
        recv_settings_and_apply()
        -- Reset game to apply settings
        run_cmd("reset")
        -- Define hook for end game here, because otherwise
        -- 'reset' above will trigger it
        add_hook("end_game", "remotecontrol", finish_game)
    else
        add_hook("enter_freeze", "remotecontrol_freeze", simulation_next_turn)
        add_hook("pre_draw", "remotecontrol", check_if_should_step)
        -- make the first turn
        simulation_next_turn()
    end
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
    -- Hook start new game
    add_hook("new_game", "remotecontrol", start_game)
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
    -- Set TCP_NODELAY, which potentially could speed things up
    -- (Disables Nagle's algorithm, which bunches up multiple packets 
    -- before sending)
    s:setoption("tcp-nodelay", true);
    
    -- Receive initial handshake, which determines 
    -- if we should display game or not
    local handshake = wait_for_data()
    handshake = split_comma_and_numerize(handshake)
    draw_game = handshake[1] == 1
    
    -- Make sure there are no hooks with these names
    remove_hook("end_game", "remotecontrol")
    remove_hook("new_game", "remotecontrol")
    remove_hook("enter_freeze", "remotecontrol_freeze")
    remove_hook("pre_draw", "menu_closer")
    remove_hook("pre_draw", "remotecontrol")
    
    -- This hook is to close main manu
    -- It can prevent playing the game, especially if this 
    -- script is launched from profile.tbs
    add_hook("pre_draw", "menu_closer", menu_closer_drawer)
end

close_menu()
run_controlled()
