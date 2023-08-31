-- draw_quad(number pos_x, number pos_y, number width, number height [, integer texture_id])

-- USE: Draws a quad
-- NOTES: -

local function draw_quad_example()
	-- draw center vertical line
	set_color(1, 0, 0, 0.4)
	draw_quad(400, 0, 1, 600)

	-- draw center horizontal line
	set_color(0, 1, 0, 0.4)
	draw_quad(0, 300, 800, 1)

	-- draw corner box	
	set_color(0, 0, 1, 0.4)
	draw_quad(1, 2, 100, 200)
end

add_hook("draw2d", "draw_quad_example", draw_quad_example)
