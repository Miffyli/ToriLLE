-- set_camera_lookat (number pos_x, number pos_y, number pos_z)

-- USE: Sets the position of the point the camera is looking at
-- NOTES: -

local pos_x, pos_y, pos_z = 100, 100, 100

echo ("set_camera_lookat (" .. pos_x .. ", " ..  pos_y .. ", " .. pos_z .. ")")
set_camera_lookat (pos_x, pos_y, pos_z)
