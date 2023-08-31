-- Coding standard for toribash lua scripts sdk:
-- < function usage >
-- < empty line >
-- USE: < usage description >
-- NOTES: < additional notes; '-' if no notes >
-- < empty line >
-- < function execution >
-- < display the function execution and possible output in a clear lua style >
-- See below 2 examples: for setting parameters, and for getting parameters.

--========== Example 1: =========--
-- set_body_pos( integer player_index, integer body_index, number x, number y, number z )

set_body_pos(0, 0, 0, 0, 0)
echo ("set_body_pos(0, 0, 0, 0, 0)")
--========== Example 2: =========--
-- x,y = get_screen_pos(number x, number y, number z)

x, y, z = get_screen_pos(50, 50, 50)
echo (x .. ", " .. y .. ", " .. z .. " = get_screen_pos(50, 50, 50)")
