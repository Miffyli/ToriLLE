-- state = get_shift_key_state()

-- USE: Returns the shift key state
-- NOTES: See example

local state = get_shift_key_state()
echo ("state = get_shift_key_state()")
if state == 0 then echo (state .. ": No shift key is down")
elseif state == 1 then echo (state .. ": Left shift key is down")
elseif state == 2 then echo (state .. ": Right shift key is down")
else echo (state .. ": Both shift keys are down")
end
