-- draw quad with textues

texid = load_texture("example/tex1.tga")

draw2d = function ()
       set_color(1, 1, 1, 1)
       draw_quad( 100, 100, 200, 200, texid )
end


add_hook ("draw2d", "draw_quad_wtextures.lua", draw2d )
