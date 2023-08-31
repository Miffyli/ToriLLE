-- set_body_torque (integer player, integer bodypart, number x, number y, number z)

-- USE: Sets the torque of a specific body part
-- NOTES: -

local player, bodypart, x, y, z = 0, 0, 50, 50, 50
set_body_torque(player, bodypart, x, y, z)
echo ("set_body_torque(" .. player .. ", " .. bodypart .. ", " .. x .. ", " .. y .. ", " .. z .. ")")
