-- bouts = get_bouts()

-- USE: Returns an array of bout names
-- NOTES: -

local ghost_cache = get_ghost_cache(0);

echo ("ghost_cache = get_ghost_cache(0)")

for i=1,table.getn(ghost_cache) do
	for j=1,table.getn(ghost_cache[i].bodies) do
			echo( "Player " .. i .. " Body " .. j .. " Pos: " .. ghost_cache[i].bodies[j].pos[1] .. " " .. ghost_cache[i].bodies[j].pos[2] .. " " .. ghost_cache[i].bodies[j].pos[3] )
			echo( "Player " .. i .. " Body " .. j .. " Quat: " .. ghost_cache[i].bodies[j].quat[1] .. " " .. ghost_cache[i].bodies[j].quat[2] .. " " .. ghost_cache[i].bodies[j].quat[3] .. " " .. ghost_cache[i].bodies[j].quat[4] )
			echo( "Player " .. i .. " Body " .. j .. " Size: " .. ghost_cache[i].bodies[j].size[1] .. " " .. ghost_cache[i].bodies[j].size[2] .. " " .. ghost_cache[i].bodies[j].size[3] )
			echo( "Player " .. i .. " Body " .. j .. " Shape: " .. ghost_cache[i].bodies[j].shape )
	end
	for j=1,table.getn(ghost_cache[i].joints) do
			echo( "Player " .. i .. " Joint " .. j .. " Pos: " .. ghost_cache[i].joints[j].pos[1] .. " " .. ghost_cache[i].joints[j].pos[2] .. " " .. ghost_cache[i].joints[j].pos[3] )
			echo( "Player " .. i .. " Joint " .. j .. " Quat: " .. ghost_cache[i].joints[j].quat[1] .. " " .. ghost_cache[i].joints[j].quat[2] .. " " .. ghost_cache[i].joints[j].quat[3] .. " " .. ghost_cache[i].joints[j].quat[4] )
			echo( "Player " .. i .. " Joint " .. j .. " Size: " .. ghost_cache[i].joints[j].size[1] .. " " .. ghost_cache[i].joints[j].size[2] .. " " .. ghost_cache[i].joints[j].size[3] )
	end
end

for j=1,table.getn(ghost_cache.envs) do
		echo( "Env " .. j .. " Pos: " .. ghost_cache.envs[j].pos[1] .. " " .. ghost_cache.envs[j].pos[2] .. " " .. ghost_cache.envs[j].pos[3] )
		echo( "Env " .. j .. " Quat: " .. ghost_cache.envs[j].quat[1] .. " " .. ghost_cache.envs[j].quat[2] .. " " .. ghost_cache.envs[j].quat[3] .. " " .. ghost_cache.envs[j].quat[4] )
		echo( "Env " .. j .. " Size: " .. ghost_cache.envs[j].size[1] .. " " .. ghost_cache.envs[j].size[2] .. " " .. ghost_cache.envs[j].size[3] )
		echo( "Env " .. j .. " Shape: " .. ghost_cache.envs[j].shape )
end
