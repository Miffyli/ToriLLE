-- timer.lua
-- Timer script

do
	local globaltimeouts = { }
	local function set_timeout(timeout, fn)
		if fn then table.insert(globaltimeouts, { timeleft=timeout, func=fn } ) end
	end

	local function update_timeouts(delta)
		delta = delta or 1 -- Prevent it from being nil

		local final = { }
		for i,t in ipairs(globaltimeouts) do
			t.timeleft = t.timeleft - delta
			if (t.timeleft < 0) then
				t.func()
			else
				table.insert(final, t)
			end
		end
		globaltimeouts = final
	end

	GUI = GUI or { }
	GUI.set_timeout = set_timeout
	GUI.update_timeouts = update_timeouts
end

