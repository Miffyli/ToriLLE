-- fires before every frame 

function ef()
	ws = get_world_state()
	echo("enter_frame:match_frame" .. ws.match_frame ) 
end

add_hook("enter_frame", "ef", ef)

