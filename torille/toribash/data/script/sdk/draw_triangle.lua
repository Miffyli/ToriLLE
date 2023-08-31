-- draw_triangle(number pos_x1, number pos_y1, number pos_z1,number pos_x2, number pos_y2, number pos_z2, number pos_x3, number pos_y3, number pos_z3)

-- USE: Draws an unculled triangle.
-- NOTES: Still need to draw in correct order for lighting to work properly, even if it isn't culled.

add_hook("draw3d","",
	function()
		set_color(0,1,0,0.4)
		draw_cube_triangles(2, 0, 1, 2, 2, 2)
	end
)

--Draws a cube out of triangles.
function draw_cube_triangles(x, y, z, w, h, d)
	--Draws each face as two triangles.
	
	--Bottom
	draw_triangle(x, y, z, x + w, y, z, x, y + h, z)
	draw_triangle(x + w, y + h, z, x, y + h, z, x + w, y, z)
	
	--Side
	draw_triangle(x, y, z, x + w, y, z, x, y, z + d)
	draw_triangle(x + w, y, z + d, x, y, z + d, x + w, y, z)
	
	--Side
	draw_triangle(x, y, z, x, y + h, z, x, y, z + d)
	draw_triangle(x, y + h, z + d, x, y, z + d, x, y + h, z)
	
	--Top
	draw_triangle(x + w, y + h, z + d, x, y + h, z + d, x + w, y, z + d)
	draw_triangle(x, y, z + d, x + w, y, z + d, x, y + h, z + d)
	
	--Side
	draw_triangle(x + w, y + h, z + d, x, y + h, z + d, x + w, y + h, z)
	draw_triangle(x, y + h, z, x + w, y + h, z, x, y + h, z + d)
	
	--Side
	draw_triangle(x + w, y + h, z + d, x + w, y, z + d, x + w, y + h, z)
	draw_triangle(x + w, y, z, x + w, y + h, z, x + w, y, z + d)
end