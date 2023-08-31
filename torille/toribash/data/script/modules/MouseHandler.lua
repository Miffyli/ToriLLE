module("mouse", package.seeall)

x = 0
y = 0
down = {0,0,0}
dx = 0
dy = 0

add_hook("mouse_move", "_mousemodule",
	function(X, Y)
		x = X
		y = Y
	end
)

add_hook("mouse_button_down", "_mousemodule",
	function(button, X, Y)
		down[button] = 1
		dx = X
		dy = Y
	end
)

add_hook("mouse_button_up", "_mousemodule",
	function(button, X, Y)
		down[button] = 0
	end
)
