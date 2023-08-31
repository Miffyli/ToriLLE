-- draw_box( number pos_x, number pos_y, number pos_z, number size_x, number size_y, number size_z, number rotation_x, rotation_y, rotation_z)

-- USE: Draws a box
-- NOTES: -

local pos_x, pos_y, pos_z = 1, 1, 1
local size_x, size_y, size_z = 1, 1, 0.5
local rotation_x, rotation_y, rotation_z = 0, 0, 0

local function draw_box_example()
	set_color(0, 1, 1, 1)
	draw_box(pos_x, pos_y, pos_z,
		 size_x, size_y, size_z,
		 rotation_x, rotation_y, rotation_z)
	--Rotate the box
	rotation_x = rotation_x + 1
	if rotation_x >= 360 then rotation_x = 0 end
end

add_hook("draw3d", "draw_box_example", draw_box_example)
