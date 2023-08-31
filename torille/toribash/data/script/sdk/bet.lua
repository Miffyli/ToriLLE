-- get_bet_info(player) 
-- tc - amount of TC betted on the player
-- num - number of bets on the player
--
local w, h = get_window_size()

local function draw_bets()
	set_color(1.0, 0.0, 0.0, 0.4)

	local bet = get_bet_info(0)
	draw_right_text(bet.tc .. "tc " .. bet.num, 300, 5, 0)

	set_color(0.0, 0.0, 1.0, 0.4)
	local bet2 = get_bet_info(1)
	draw_text(bet2.tc .. "tc " .. bet2.num, 300, 5, 0)
end

add_hook("draw2d", "bet", draw_bets)
