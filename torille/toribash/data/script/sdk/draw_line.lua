-- draw_line(number x, number y, number x2, number y2, number width)

-- USE: Draws a line on the screen.
-- NOTES: 2D.

local function draw_line_example()
      set_color(0, 0, 0, 1)
      draw_line(0, 0, 500, 500, 1)
end

add_hook("draw2d", "draw_centered_text_example", draw_line_example)
