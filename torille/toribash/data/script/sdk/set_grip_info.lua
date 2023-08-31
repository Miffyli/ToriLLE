-- set_grip_info(integer player_index, integer hand_id, integer grip_state)

-- USE: Sets the grip state for a specified hand
-- NOTES: Valid hand_id's are 11 and 12

local player_index, hand_id, grip_state = 0, 11, 1

set_grip_info( player_index, hand_id, grip_state)
echo ("set_grip_info (" .. player_index .. ", " .. hand_id .. ", " .. grip_state .. ")")
