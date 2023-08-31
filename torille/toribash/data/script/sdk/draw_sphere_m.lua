--draw_sphere_m(number pos_x, number pos_y, number pos_z, number radius, table matrix_rot)
local radius = 0.3

local function draw_sphere()
        set_color(1, 0, 0, 1)
	body = get_body_info(0, 0)
        draw_sphere_m(body.pos.x, body.pos.y, body.pos.z, radius, body.rot)
end

add_hook("draw3d", "draw_sphere", draw_sphere)
