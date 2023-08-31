-- draw_disk_3d(number pos_x, number pos_y, number pos_z, number inner, number outer, integer slices, integer loops, number start, number sweep, integer blend)\

-- USE: Draws a disk in 3d
-- NOTES: -

local function draw_disk_example()
	-- draw partial disk
	set_color(0.6, 0, 0, 1)
	x = 0 	-- x, y origo of the disk
	y = 0 
	inner = 2	-- Specifies the inner radius of the partial disk (can be 0).
	outer = 3	-- Specifies the outer radius of the partial disk.
	slices = 32 	-- Specifies the number of subdivisions around the z axis.
	loops = 1	-- Specifies the number of concentric rings about the origin into which the partial disk is subdivided.
	start = 0	-- Specifies the starting angle, in degrees, of the disk portion.
	sweep = 270 	-- Specifies the sweep angle, in degrees, of the disk portion.
	blend = 0	-- Blend background if transparent or not (menu background disk)
	draw_disk_3d(x, y, 0.1, inner, outer, slices, loops, start, sweep, blend)
end

-- must be called from the draw3d hook
add_hook("draw3d", "draw_disk_example", draw_disk_example)
