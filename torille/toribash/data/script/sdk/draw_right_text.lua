-- draw_right_text(string text, number pos_x, number pos_y [, integer font_type])

-- USE: Draws right aligned text.
-- NOTES: 2D.

local function draw_text_example()
      set_color(0, 0, 0, 1)
      draw_right_text("Hello World", 5, 200, 1)
end

add_hook("draw2d", "draw_right_text_example", draw_text_example)
