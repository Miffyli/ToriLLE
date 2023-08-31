-- draw_centered_text(string text, number pos_y [, integer font_type])

-- USE: Draws text that is centered on the screen
-- NOTES: -

local function draw_centered_text_example()
      set_color(0, 0, 0, 1)
      draw_centered_text("Welcome", 50, 1)
      draw_centered_text("to...", 100, 2)
      draw_centered_text("TORIBASH !", 150, 0)
end

add_hook("draw2d", "draw_centered_text_example", draw_centered_text_example)
