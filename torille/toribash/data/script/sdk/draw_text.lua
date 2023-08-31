-- draw__text(string text, number pos_y [, integer font_type])

-- USE: Draws text on the screen
-- NOTES: -

local function draw_text_example()
   set_color(0, 0, 0, 1)
   draw_text("THIS... IS... TORIBASH!", 100, 100)
end

add_hook("draw2d", "draw_text_example", draw_text_example)
