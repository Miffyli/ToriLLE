-- draw_text_3d(string text, number x, number y, number z, number ax, number ay, number az, integer size, integer font_type)

-- USE: Draws text in a 3D environment
-- NOTES: Use with get_camera_info().perp to make it face the screen.

add_hook("draw3d", "",
    function()
        set_color(0,0,0,1)
        a = get_camera_info().perp
        draw_text_3d("Hello!", 1, 0, 1, a.x, a.y, a.z, 1, 3)
    end
)