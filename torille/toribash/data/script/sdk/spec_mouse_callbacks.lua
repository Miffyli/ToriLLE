-- SDK for spec mouse callbacks
-- the index is the spec[index].
local last_index = -1
local selected_name = ""

function down(index)
	last_index = index
	echo("Mouse clicked on " .. get_spectator_info(index).nick .. "!")
end
add_hook("spec_mouse_down", "down", down)

-- Execute any commands or menu etc at this function if index and last_index is same!
function up(index)
	if index == last_index then
		-- Use Name or ID or etc to pin him down. index will change !
		selected_name = get_spectator_info(index).nick
		echo ("** Selected Name: " .. selected_name .. " **")
	end
	last_index = -1
end
add_hook("spec_mouse_up", "up", up)


function over(index)
end
add_hook("spec_mouse_over", "over", over)


function outside(index)
	-- Make sure this callback belong to this player you interested in!
	if index == last_index then
		last_index = -1
	end
end
add_hook("spec_mouse_outside", "outside", outside)
