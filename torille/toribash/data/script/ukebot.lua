-- ukebot.lua
-- Uke controlled by a learning AI


local injuryblue= 0
local injuryred = 0
local joint = 1
local pos = 1
local genes = {}
local frame = 5

function start()
choose()
end



function choose()
if frame == 5 then
--local number = math.random(0,14)
--local counter = 0
--print(number)
--while counter < number do
--local choice = math.random(0,20)
for k,v in pairs(JOINTS) do

	--if v == choice then
	local choice = math.random(0,4)
	--print("v - "..v.." - choice - "..choice)
	if choice == 3 then
		
		pos = math.random(1,4)
		--print("test "..pos)
		--while  pos ~= genes[k] do
		--	pos = math.random(1,4)
		--	print("test "..pos)
		--end
		set_joint_state(1, v, pos)
		joint = choice
	else
		if genes[k] == nil then
			genes[k] = 3
		end
		set_joint_state(1, v, genes[k])
	end
end
--counter = counter + 1
--end

local red = get_player_info(0)
if red.injury - injuryred > 2000 then
	genes[choice] = pos
	injuryred = red.injury
end
frame = 1
else
frame = frame + 1
end
end

add_hook("new_game", "random_lua", start)
add_hook("enter_freeze","lua_bot",choose)