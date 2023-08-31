-- draw_capsule( number pos_x, number pos_y, number pos_z, number height, number radius, number rotation_x, rotation_y, rotation_z)

-- USE: Draws a capsule
-- NOTES: -

local pos_x, pos_y, pos_z = 1, 1, 1
local height, radius = 0.5, 0.25
local rotation_x, rotation_y, rotation_z = 0, 0, 0

local function draw_capsule_example()
	set_color(1, 0.5, 0, 1)
	draw_capsule(pos_x, pos_y, pos_z,
		 height, radius,
		 rotation_x, rotation_y, rotation_z)
	--Rotate the capsule
	rotation_x = rotation_x + 1
	if rotation_x >= 360 then rotation_x = 0 end
end

add_hook("draw3d", "draw_capsule_example", draw_capsule_example)