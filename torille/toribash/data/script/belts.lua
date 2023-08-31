--belts.lua by yoyo

local w_state = get_world_state()
local g_rules = get_game_rules()
local bouts = get_bouts()
local p_info = {tori = get_player_info(0), uke = get_player_info(0)}
local window = {}; window.w, window.h = get_window_size()
local winning = ""
local winning_by = 0
local bet = {get_bet_info(0), get_bet_info(1)}

local function round(num)
	if num >= math.floor(num) + 0.5 then
		return math.ceil(num)
	else
		return math.floor(num)
	end
end

local function draw_rounded_quad(x, y, width, height, cornerRadius) --thanks lapsus - sdk/draw_rounded_quad.lua
	draw_disk(x + cornerRadius, y + cornerRadius, 0, cornerRadius, 32, 1, -90, -90, 0)
	draw_quad((x + cornerRadius), y, (width - cornerRadius * 2), height)
	draw_disk(x + (width - cornerRadius), y + cornerRadius, 0, cornerRadius, 32, 1, 180, -90, 0)
	draw_quad(x, (y + cornerRadius), cornerRadius, (height - cornerRadius * 2))
	draw_quad((x + (width - cornerRadius)), (y + cornerRadius), cornerRadius, (height - cornerRadius * 2))
	draw_disk(x + cornerRadius, y + cornerRadius + (height - cornerRadius * 2), 0, cornerRadius, 32, 1, 0, -90, 0)
	draw_disk(x + (width - cornerRadius), y + cornerRadius + (height - cornerRadius * 2), 0, cornerRadius, 32, 1, 0, 90, 0)
end

local function get_belt(qi) --thanks blam - customhud3.lua
	if(qi ~= nil) then
	if(qi < 20) then return {colour = {0.9, 0.9, 0.9, 1}, shortname = ""} end
	if(qi >= 1000 and qi < 2000) then return {colour = {0, 0, 0, 1}, shortname = "1"} end
	if(qi >= 2000 and qi < 3000) then return {colour = {0, 0, 0, 1}, shortname = "2"} end
	if(qi >= 3000 and qi < 4000) then return {colour = {0, 0, 0, 1}, shortname = "3"} end
	if(qi >= 4000 and qi < 5000) then return {colour = {0, 0, 0, 1}, shortname = "4"} end
	if(qi >= 5000 and qi < 6000) then return {colour = {0, 0, 0, 1}, shortname = "5"} end
	if(qi >= 6000 and qi < 7000) then return {colour = {0, 0, 0, 1}, shortname = "6"} end
	if(qi >= 7000 and qi < 8000) then return {colour = {0, 0, 0, 1}, shortname = "7"} end
	if(qi >= 8000 and qi < 9000) then return {colour = {0, 0, 0, 1}, shortname = "8"} end
	if(qi >= 9000 and qi < 10000) then return {colour = {0, 0, 0, 1}, shortname = "9"} end
	if(qi >= 10000 and qi < 15000) then return {colour = {0, 0, 0, 1}, shortname = "T"} end
	if(qi >= 15000 and qi < 20000) then return {colour = {0, 0, 0, 1}, shortname = "M"} end
	if(qi >= 20000 and qi < 50000) then return {colour = {0, 0, 0, 1}, shortname = "C"} end
	if(qi >= 50000) then return {colour = {0, 0, 0, 1}, shortname = "G"} end
	if(qi >= 20 and qi < 50) then return {colour = {1, 1, 0, 1}, shortname = ""} end
	if(qi >= 50 and qi < 100) then return {colour = {1, 0.75, 0, 1}, shortname = ""} end
	if(qi >= 100 and qi < 200) then return {colour = {0, 1, 0, 1}, shortname = ""} end
	if(qi >= 200 and qi < 500) then return {colour = {0, 0, 1, 1}, shortname = ""} end
	if(qi >= 500 and qi < 1000) then return {colour = {0.4, 0.15, 0, 1}, shortname = ""} end
	end
	return {colour = {0.8, 0.8, 0.8, 1}, shortname = "!"}
end

local function enter_frame()
	w_state = get_world_state()
	g_rules = get_game_rules()
	p_info = {tori = get_player_info(0), uke = get_player_info(1)}
	
	if p_info.tori.score > p_info.uke.score then
		winning = p_info.tori.name
		winning_by = round(p_info.tori.score - p_info.uke.score)
	elseif p_info.uke.score > p_info.tori.score then
		winning = p_info.uke.name
		winning_by = round(p_info.uke.score - p_info.tori.score)
	else
		winning = "tie"
		winning_by = 0
	end
end

enter_frame() --starting up

local function new_mp_game()
	enter_frame() --data reset
	speedgraph_reset()
end

local function new_game()
	enter_frame()
	speedgraph_reset()
end

local function end_game()
	enter_frame()
	speedgraph_reset()
end

local function match_begin()
	enter_frame()
	speedgraph_reset()
end

local function draw()
	bouts = get_bouts()
	bet = {get_bet_info(0), get_bet_info(1)}

	set_color(0, 0, 0, 1)
	draw_right_text("Bet: " .. bet[1].tc .. " TC by " .. bet[1].num .. " players", 300, 5, 1)
	draw_text("Bet: " .. bet[2].tc .. " TC by " .. bet[2].num .. " players", 300, 5, 1)
	
	set_color(0.15, 0.15, 0.15, 0.80)
	draw_rounded_quad(5, 155, 235, 162, 10)
	
	set_color(0.15, 0.15, 0.15, 0.85)
	draw_rounded_quad(5, 155, 235, 30, 10)
	
	set_color(0.85, 0.85, 0.85, 0.65)
	draw_rounded_quad(10, 192, 225, 18, 9)
	draw_rounded_quad(10, 217, 225, 18, 9)
	draw_rounded_quad(10, 242, 225, 18, 9)
	draw_rounded_quad(10, 267, 225, 18, 9)
	draw_rounded_quad(10, 292, 225, 18, 9)
	
	set_color(0.8, 0.8, 0.8, 1)
	draw_text("Stats", 15, 157, 2)
	
	set_color(0, 0, 0, 1)
	draw_text("Winning: " .. winning, 15, 192, 1)
	draw_text("Winning by: " .. winning_by, 15, 217, 1)
	draw_text("Turnframes: " .. w_state.match_turn_frame, 15, 242, 1)
	draw_text("Mod: " .. g_rules.mod, 15, 267, 1)
	draw_text("Players: " .. #bouts, 15, 292, 1)
	
	for i = 0, #bouts-1 do
		local b_info = get_bout_info(i)
		local belt = get_belt(b_info.games_played)
		local length = get_string_length(b_info.nick, 1)

		set_color(0, 0, 0, 1)
		draw_quad(window.w - (length + 72 - 15), 145 + (i * 18), 16, 16)

		set_color(belt.colour[1], belt.colour[2], belt.colour[3], belt.colour[4])
		draw_quad(window.w - (length + 71 - 15), 146 + (i * 18), 14, 14)
		
		set_color(1, 1, 1, 0.3)
		draw_quad(window.w - (length + 71 - 15), 146 + (i * 18), 14, 7)
		
		set_color(1, 1, 1, 1)
		draw_text(belt.shortname, window.w - (length + 49 + (get_string_length(belt.shortname, 1)/2)), 144 + (i * 18), 1)
	end
end

add_hook("enter_frame", "y_c_hud", enter_frame)
add_hook("new_mp_game", "y_c_hud", new_mp_game)
add_hook("new_game", "y_c_hud", new_game)
add_hook("end_game", "y_c_hud", end_game)
add_hook("match_begin", "y_c_hud", match_begin)
add_hook("draw2d", "y_c_hud", draw)

echo("^07----------------------")
echo("^07belts.lua by yoyo.")
echo("^07custom hud with special stats.")
echo("^07----------------------")
