-- ui_manager.lua
-- A UI elements manager
dofile ("gui/timer.lua")

do
	if GUI==nil then GUI = { } end
	local UIManager = GUI.UIManager or { elements={ } }
	local dragged_element = nil
	local prev_focus, focus_element = nil, nil
	local old_x, old_y = 0, 0
	local cur_x, cur_y = 0, 0
	local prev_frame_time = 0

	function UIManager.add(ui_element)
		table.insert(UIManager.elements, ui_element)
	end

	function UIManager.remove(ui_element)
		for k,v in ipairs(UIManager.elements) do
			if (v == ui_element) then
				table.remove(UIManager.elements, k)
				return
			end
		end
	end

	function UIManager.get_mouse_pos()
		return cur_x, cur_y
	end

	function UIManager.release_drag()
		dragged_element = nil
	end

	function UIManager.set_drag(element)
		dragged_element = element
	end

	function UIManager.get_focus()
		return focus_element
	end

	function UIManager.set_focus(elem)
		prev_focus = focus_element
		focus_element = elem
	end

	function UIManager.get_prev_focus()
		return prev_focus
	end

	function UIManager.mouse_move(x, y)
		cur_x, cur_y = x, y
		if dragged_element ~= nil then
			dragged_element:translate(x-old_x, y-old_y)
			old_x, old_y = x, y
			return 1
		end

		old_x, old_y = x, y
		for k,v in ipairs(UIManager.elements) do
			local retVal = v:mouse_move(x, y)
			if retVal and retVal ~= 0 then
				return retVal
			end
		end
	end

	function UIManager.mouse_up(mousebtn, x, y)
		dragged_element = nil
		for k,v in ipairs(UIManager.elements) do
			local retVal = v:mouse_up(mousebtn, x, y)
			if (retVal and retVal ~= 0) then
				return retVal
			end
		end
	end

	function UIManager.mouse_down(mousebtn, x, y)
		for k,v in ipairs(UIManager.elements) do
			local retVal = v:mouse_down(mousebtn, x, y)
			if (retVal and retVal ~= 0) then
				return retVal
			end
			if v.draggable == true and v:hit(x,y) then
				dragged_element = v
				UIManager.set_focus(v)
				return 1
			end
		end
		UIManager.set_focus(nil)
	end

	function UIManager.draw()
		for k,v in ipairs(UIManager.elements) do
			v:draw()
		end
	end

	function UIManager.update(delta_time)
		for k,v in ipairs(UIManager.elements) do
			v:update(delta_time)
		end
	end

	function UIManager.set_hooks()
		add_hook("mouse_button_down",	"UIManager", UIManager.mouse_down)
		add_hook("mouse_button_up",	"UIManager", UIManager.mouse_up)
		add_hook("mouse_move",		"UIManager", UIManager.mouse_move)
		add_hook("draw2d",		"UIManager", function()
				local world = get_world_state()
				local delta = (world.frame_tick - prev_frame_time)
				prev_frame_time = world.frame_tick

				GUI.update_timeouts(1)
				UIManager.update(delta)
				UIManager.draw()
				end )
	end

	GUI.UIManager = UIManager
end

