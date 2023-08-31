-- draw_sphere( number pos_x, number pos_y, number pos_z, number radius)

-- USE: Draws a sphere
-- NOTES: -

local pos_x, pos_y, pos_z = 1, 1, 1
local radius = 0.5

local function draw_sphere_example()
	set_color(1, 0, 0, 1)
	draw_sphere(pos_x, pos_y, pos_z,
		 radius)
end

add_hook("draw3d", "draw_sphere_example", draw_sphere_example)
