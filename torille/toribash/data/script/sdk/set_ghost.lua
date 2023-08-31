-- set_ghost(number ghost_mode)

-- USE: Toggles ghosts
-- NOTES: 0 = no ghosts, 1 = ghost of selected tori, 2 = both ghosts

local ghost_mode = 2

set_ghost(ghost_mode)
echo ("set_ghost(" .. ghost_mode .. ")")
