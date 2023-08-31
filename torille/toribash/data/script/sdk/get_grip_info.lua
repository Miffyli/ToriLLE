-- grip_info = get_grip_info(integer player_index, integer hand_id)

-- USE: Returns a value for grip of specified hand
-- NOTES: Valid hand_id's are 11 and 12

local player_index, hand_id = 0, 11
local grip_info = get_grip_info(player_index, hand_id)

echo (grip_info .. " = get_grip_info(" .. player_index .. ", " .. hand_id .. ")")
