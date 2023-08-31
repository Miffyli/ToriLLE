-- This function will draw a nice rounded quad for you!  I'm sure that you'll be able to make your scripts prettier with this :3
-- The quad is seamless, and works perfectly with transparency. It can't do textures though.
-- Written by Lapsus Antepedis
-- It works just like the normal draw_quad, except that it has a cornerradius variable as well.

function draw()
	draw_rounded_quad(10, 10, 300, 200, 20)
end

function draw_rounded_quad(x, y, width, height, cornerRadius)

	--Top Left Corner
	draw_disk (x + cornerRadius, y + cornerRadius, 0, cornerRadius, 32, 1, -90, -90, 0)
	
	--Main Box
	draw_quad ((x + cornerRadius), y, (width - cornerRadius * 2), height)
	
	--Top Right Corner
	draw_disk (x + (width - cornerRadius), y + cornerRadius, 0, cornerRadius, 32, 1, 180, -90, 0)
	
	--Left Box
	draw_quad (x, (y + cornerRadius), cornerRadius, (height - cornerRadius * 2))
	
	--Right Box
	draw_quad ((x + (width - cornerRadius)), (y + cornerRadius), cornerRadius, (height - cornerRadius * 2))
	
	--Bottom Left Corner
	draw_disk (x + cornerRadius, y + cornerRadius + (height - cornerRadius * 2), 0, cornerRadius, 32, 1, 0, -90, 0)
	
	--Bottom Right Corner
	draw_disk (x + (width - cornerRadius), y + cornerRadius + (height - cornerRadius * 2), 0, cornerRadius, 32, 1, 0, 90, 0)
	
end

add_hook("draw2d", "draw_rounded_quad_example", draw)
