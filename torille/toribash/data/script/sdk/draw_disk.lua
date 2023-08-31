-- draw_disk(number pos_x, number pos_y, number inner, number outer, integer slices, integer loops, number start, number sweep, integer blend)

-- USE: Draws a disk
-- NOTES: -

local function draw_disk_example()
	-- draw partial disk
	set_color(0.6, 0, 0, 0.9)
	x = 200 	-- x, y origo of the disk
	y = 300 
	inner = 50	-- Specifies the inner radius of the partial disk (can be 0).
	outer = 100	-- Specifies the outer radius of the partial disk.
	slices = 32 	-- Specifies the number of subdivisions around the z axis.
	loops = 1	-- Specifies the number of concentric rings about the origin into which the partial disk is subdivided.
	start = 0	-- Specifies the starting angle, in degrees, of the disk portion.
	sweep = 270 	-- Specifies the sweep angle, in degrees, of the disk portion.
	blend = 0	-- Blend background if transparent or not (menu background disk)
	draw_disk(x, y, inner, outer, slices, loops, start, sweep, blend)

	-- triangle
	set_color(0, 0.6, 0, 0.9)
	x = 400 
	slices = 3 
	sweep = 360
	start = 60 
	blend = 1
	draw_disk(x, y, inner, outer, slices, loops, start, sweep, blend)

	-- square
	set_color(0, 0, 0.6, 0.9)
	x = 600 
	slices = 4 
	start = 45 
	sweep = 360
	blend = 0
	draw_disk(x, y, inner, outer, slices, loops, start, sweep, blend)
end

add_hook("draw2d", "draw_disk_example", draw_disk_example)
