-- texid = load_texture(string texture_name)

-- USE: Loads in a texture and returns the ID of the texture.
-- NOTES: Textures can be used with draw_quad and should only be loaded in once.

texid = load_texture("example/tex1.tga")

function draw2d()
    set_color(1, 1, 1, 1)
    draw_quad(100, 100, 200, 200, texid)
end

add_hook("draw2d", "load_texture_example", draw2d)
