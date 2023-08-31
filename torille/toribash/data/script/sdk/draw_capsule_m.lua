--draw_capsule_m(number pos_x, number pos_y, number pos_y, number height, number radius, table matrix_rot)
local height, radius = 0.5, 0.25

local function draw_capsule()
        set_color(1, 0.5, 0, 1)
        body = get_body_info(0, 0)
        draw_capsule_m(body.pos.x, body.pos.y, body.pos.z, height, radius, body.rot)
end

add_hook("draw3d", "draw_capsule", draw_capsule)
