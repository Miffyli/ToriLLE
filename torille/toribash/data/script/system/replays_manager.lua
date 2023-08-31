-- Replays manager

local SELECTED_REPLAY = { element = nil, defaultColor = nil, time = 0, replay = nil }
local TB_MENU_REPLAYS = { name = "replay", fullname = "replay" }
local TB_MENU_REPLAYS_LOADED = false

SERVER_REPLAYS = SERVER_REPLAYS or { action = 1, offset = 1, search = "", id = 0 }
SELECTED_FOLDER = SELECTED_FOLDER and { fullname = SELECTED_FOLDER.fullname } or { fullname = "replay" }
SELECTED_SERVER_REPLAY = SELECTED_SERVER_REPLAY or { id = 0 }

local MAXFOLDERLEVELS = 4

REPLAY_VOTE = 101

REPLAY_TEMPNAME = "--onlinereplaytempfile"
REPLAY_SAVETEMPNAME = "--localreplaytempfile"

do
	Replays = {}
	Replays.__index = Replays
	local cln = {}
	setmetatable(cln, Replays)
	
	function Replays:quit()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		if (get_option("newmenu") == 0) then
			FRIENDSLIST_OPEN = false
			tbMenuMain:kill()
			remove_hooks("tbMainMenuVisual")
			return
		end
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Replays:getNavigationButtons(isOnline)
		local buttonText = get_option("newmenu") == 0 and TB_MENU_LOCALIZED.NAVBUTTONEXIT or TB_MENU_LOCALIZED.NAVBUTTONTOMAIN
		local navigation = {
			{ 
				text = buttonText, 
				action = function() Replays:quit() end, 
				width = get_string_length(buttonText, FONTS.BIG) * 0.65 + 30 
			}
		}
		if (isOnline) then
			table.insert(navigation, {
				text = TB_MENU_LOCALIZED.REPLAYSLOCAL,
				action = function() Replays:showMain(tbMenuCurrentSection) end,
				width = get_string_length(TB_MENU_LOCALIZED.REPLAYSLOCAL, FONTS.BIG) * 0.65 + 30,
				right = true
			})
			table.insert(navigation, {
				text = TB_MENU_LOCALIZED.REPLAYSSEARCH,
				action = function() Replays:showSearchWindow() end,
				width = get_string_length(TB_MENU_LOCALIZED.REPLAYSSEARCH, FONTS.BIG) * 0.65 + 30,
				right = true
			})
		else
			table.insert(navigation, {
				text = TB_MENU_LOCALIZED.REPLAYSCOMMUNITY,
				action = function() Replays:getServerReplays() end,
				width = get_string_length(TB_MENU_LOCALIZED.REPLAYSCOMMUNITY, FONTS.BIG) * 0.65 + 30,
				right = true
			})
		end
		return navigation
	end
	
	function Replays:getReplayInfo(path)
		local replay = Files:new("../" .. path, FILES_MODE_READONLY)
		local rplInfo = {}
		local hasDecap = false
		local hasMadman = false
		local version = 0
		
		if (replay.data) then
			for ln in replay.data:lines() do
				if (ln:match("FIGHTNAME 0;")) then
					-- We base version off second replay line instead of actual VERSION
					version = 10
				elseif (ln:match("AUTHOR 0;")) then
					rplInfo.author = ln:gsub("AUTHOR 0;", "")
					rplInfo.author = PlayerInfo:getUser(rplInfo.author:gsub("^ ", ""):gsub("\r", ""))
				elseif (ln:match("NEWGAME %d;")) then
					local mod = ln:gsub("NEWGAME %d;", ""):gsub("\r", "")
					rplInfo.mod = mod:match("/*%S*%.tbm")
					rplInfo.mod = rplInfo.mod and rplInfo.mod:gsub("/", "") or "classic"
				elseif (ln:match("CRUSH %d; 0") and not hasDecap) then
					rplInfo.hiddentags = rplInfo.hiddentags and rplInfo.hiddentags .. " decap" or "decap"
					hasDecap = true
				elseif (ln:match("CRUSH %d; %d %d %d %d %d %d") and not hasMadman) then
					rplInfo.hiddentags = rplInfo.hiddentags and rplInfo.hiddentags .. " madman" or "madman"
					hasMadman = true
				end
				
				if (version > 9) then
					if (ln:match("FIGHTNAME 0;")) then
						rplInfo.name = ln:gsub("FIGHTNAME 0;", "")
						rplInfo.name = rplInfo.name:gsub("^ ", ""):gsub("\r", "")
					elseif (ln:match("BOUT 0;")) then
						rplInfo.bout0 = ln:gsub("BOUT 0;", ""):gsub("\r", "")
						rplInfo.bout0 = PlayerInfo:getUser(rplInfo.bout0:gsub("^ ", ""))
					elseif (ln:match("BOUT 1;")) then
						rplInfo.bout1 = ln:gsub("BOUT 1;", ""):gsub("\r", "")
						rplInfo.bout1 = PlayerInfo:getUser(rplInfo.bout1:gsub("^ ", ""))
					end
				else
					if (ln:match("FIGHT %d;")) then
						local info = ln:gsub("FIGHT %d; ", ""):gsub("\r", "")
						rplInfo.bout1 = PlayerInfo:getUser(info:match("[^ ]+$"))
						info = info:gsub(" [^ ]+$", "")
						rplInfo.bout0 = PlayerInfo:getUser(info:match("[^ ]+$"))
						rplInfo.name = info:gsub(" [^ ]+$", "")
					end
				end
			end
		end
		
		local infodata = { name = path, bout0 = " ", bout1 = " ", author = "autosave", mod = "classic", tags = " ", hiddentags = " ", uploaded = 0 }
		for i,v in pairs(infodata) do
			if (not rplInfo[i] or rplInfo[i] == "") then
				rplInfo[i] = v
			end
		end
		
		-- Create replay names for autosave replays
		if (rplInfo.name == "vs") then
			if (path:find(".*_vs_.+%d+_%d+")) then
				local name = path:gsub("^.*/", "")
				name = name:gsub(".rpl$", "")
				local score = string.gsub(name:match("%d+_%d+$"), "_", " - ")
				name = name:sub(0, -string.len(score))
				local bout1 = string.gsub(name:match("_vs_.*$"), "_vs_", "")
				local bout0 = string.gsub(name:match("^.*_vs_"), "_vs_", "")
				bout0 = bout0:gsub("%d+-%d+-", "")
				
				rplInfo.name = bout0 .. " vs " .. bout1 .. " (" .. score .. ")"
			else 
				rplInfo.name = string.gsub(path:gsub("^.*/", ""), ".rpl$", "")
			end
		end
				
		replay:close()
		return rplInfo
	end
	
	function Replays:fetchReplayData(folder, level, file, filedata)
		local folder = folder or "replay"
		local rplTable = level or TB_MENU_REPLAYS
		
		if (not rplTable.replays) then
			rplTable.replays = {}
			rplTable.folders = {}
		end
		
		local files = get_files(folder, "")
		local count, frame = 1, 0
		replayUpdateWindow.replayfolders = replayUpdateWindow.replayfolders or {}
		replayUpdateWindow:addCustomDisplay(true, function()
				if (not replayUpdateWindow.customDisplayTrue) then
					replayUpdateWindow:uiText(TB_MENU_LOCALIZED.REPLAYSUPDATINGCACHE .. " (" .. folder .. " folder)\n" .. math.ceil(count / #files * 100) .. "% " .. TB_MENU_LOCALIZED.WORDDONE, nil, nil, nil, nil, 0.8)
				end
				
				while (1) do
					local v = files[count]
					if (v:match(REPLAY_TEMPNAME) or v:match(REPLAY_SAVETEMPNAME)) then
						count = count + 1
					elseif (v:match(".rpl$")) then
						local replaydata = { filename = v:lower() }
						local replaypath = folder and string.lower(folder .. "/" .. v) or replaydata.filename
						local replaypathfull = folder and (folder .. "/" .. v) or v
						local replaydatapath = replaypath:gsub(" ", "_")
						if (filedata[replaydatapath]) then
							replaydata.name = filedata[replaydatapath].name
							replaydata.author = filedata[replaydatapath].author
							replaydata.mod = filedata[replaydatapath].mod
							replaydata.bout0 = filedata[replaydatapath].bout0
							replaydata.bout1 = filedata[replaydatapath].bout1
							replaydata.tags = filedata[replaydatapath].tags
							replaydata.hiddentags = filedata[replaydatapath].hiddentags
							replaydata.uploaded = filedata[replaydatapath].uploaded
							table.insert(rplTable.replays, {
								filename = folder == "replay" and replaydata.filename or folder:gsub("^replay/", "") .. "/" .. replaydata.filename,
								name = replaydata.name,
								author = replaydata.author,
								mod = replaydata.mod,
								bouts = { replaydata.bout0, replaydata.bout1 },
								tags = replaydata.tags,
								hiddentags = replaydata.hiddentags,
								uploaded = replaydata.uploaded == 1
							})
							count = count + 1
						else
							replayUpdateWindow.customDisplayTrue = false
							if (frame % 2 == 0) then
								replaydata = Replays:getReplayInfo(replaypathfull)
								replaydata.filename = v:lower()
								file.data:write(replaypath .. "\t" ..
												replaydata.name .. "\t" ..
												replaydata.author .. "\t" ..
												replaydata.mod .. "\t" ..
												replaydata.bout0 .. "\t" ..
												replaydata.bout1 .. "\t" ..
												replaydata.tags .. "\t" ..
												replaydata.hiddentags .. "\t" ..
												replaydata.uploaded .. "\t" ..
												"\n")
								table.insert(rplTable.replays, {
									filename = folder == "replay" and replaydata.filename or folder:gsub("^replay/", "") .. "/" .. replaydata.filename,
									name = replaydata.name,
									author = replaydata.author,
									mod = replaydata.mod,
									bouts = { replaydata.bout0, replaydata.bout1 },
									tags = replaydata.tags,
									hiddentags = replaydata.hiddentags,
									uploaded = replaydata.uploaded == 1
								})
								count = count + 1
							end
							break
						end
					elseif (not v:find("^%.+[%s%S]*$") and v ~= "system" and not v:find("%.%a+$")) then
						table.insert(rplTable.folders, {
							parent = rplTable,
							name = v,
							fullname = rplTable.fullname .. "/" .. v
						})
						table.insert(replayUpdateWindow.replayfolders, { fname = folder .. "/" .. v, rpltbl = rplTable.folders[#rplTable.folders] })
						if (rplTable.fullname .. "/" .. v == SELECTED_FOLDER.fullname) then
							SELECTED_FOLDER = rplTable.folders[#rplTable.folders]
						end
						count = count + 1
					else
						count = count + 1
					end
					
					if (count > #files) then
						break
					end
				end
				if (count > #files) then
					rplTable.replays = UIElement:qsort(rplTable.replays, "filename")
					if (#replayUpdateWindow.replayfolders > 0) then
						local fname = replayUpdateWindow.replayfolders[1].fname
						local rpltbl = replayUpdateWindow.replayfolders[1].rpltbl
						table.remove(replayUpdateWindow.replayfolders, 1)
						Replays:fetchReplayData(fname, rpltbl, file, filedata)
					else
						file:close()
						replayUpdateWindow:kill()
						if (not SELECTED_FOLDER.name) then
							SELECTED_FOLDER = TB_MENU_REPLAYS
						end
						TB_MENU_REPLAYS_LOADED = true
					end
				end
				frame = frame + 1
			end)
		
		-- Old loading method - may freeze the client when too many new replays is encountered
		--[[for i, v in pairs(get_files(folder, "")) do
			if (v:match(".rpl$")) then
				local replaydata = { filename = v:lower() }
				local replaypath = folder and string.lower(folder .. "/" .. v) or replaydata.filename
				local replaydatapath = replaypath:gsub(" ", "_")
				if (filedata[replaydatapath]) then
					replaydata.name = filedata[replaydatapath].name
					replaydata.author = filedata[replaydatapath].author
					replaydata.mod = filedata[replaydatapath].mod
					replaydata.bout0 = filedata[replaydatapath].bout0
					replaydata.bout1 = filedata[replaydatapath].bout1
					replaydata.tags = filedata[replaydatapath].tags
					replaydata.hiddentags = filedata[replaydatapath].hiddentags
					replaydata.uploaded = filedata[replaydatapath].uploaded
				else 
					replaydata = Replays:getReplayInfo(replaypath)
					replaydata.filename = v:lower()
					file.data:write(replaypath .. "\t" ..
									replaydata.name .. "\t" ..
									replaydata.author .. "\t" ..
									replaydata.mod .. "\t" ..
									replaydata.bout0 .. "\t" ..
									replaydata.bout1 .. "\t" ..
									replaydata.tags .. "\t" ..
									replaydata.hiddentags .. "\t" ..
									replaydata.uploaded .. "\t" ..
									"\n")
				end
				table.insert(rplTable.replays, {
					filename = folder == "replay" and replaydata.filename or folder:gsub("^replay/", "") .. "/" .. replaydata.filename,
					name = replaydata.name,
					author = replaydata.author,
					mod = replaydata.mod,
					bouts = { replaydata.bout0, replaydata.bout1 },
					tags = replaydata.tags,
					hiddentags = replaydata.hiddentags,
					uploaded = replaydata.uploaded == 1
				})
			elseif (v ~= "." and v ~= ".." and v ~= "system" and not v:find("%.%a+$")) then
				if (is_folder(rplTable.fullname .. "/" .. v)) then
					table.insert(rplTable.folders, {
						parent = rplTable,
						name = v,
						fullname = rplTable.fullname .. "/" .. v
					})
					Replays:fetchReplayData(folder .. "/" .. v, rplTable.folders[#rplTable.folders], file, filedata)
					if (rplTable.fullname .. "/" .. v == SELECTED_FOLDER.fullname) then
						SELECTED_FOLDER = rplTable.folders[#rplTable.folders]
					end
				end
			end
		end
		rplTable.replays = UIElement:qsort(rplTable.replays, "filename")--]]
	end
	
	function Replays:updateReplayFile(replay)
		local file = Files:new("../replay/" .. replay.filename, FILES_MODE_READONLY)
		if (not file.data) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORREADINGFILE)
			return false
		end
		local replaydata = {}
		for ln in file.data:lines() do
			if (ln:find("^FIGHTNAME %d;")) then
				table.insert(replaydata, ln:gsub(";.*$", "; ") .. replay.name)
			elseif (ln:find("^FIGHT %d;")) then
				table.insert(replaydata, ln:gsub(";.*$", "; ") .. replay.name .. " " .. replay.bouts[1] .. " " .. replay.bouts[2])
			else
				table.insert(replaydata, ln)
			end
		end
		file:close()
		
		local file = Files:new("../replay/" .. replay.filename, FILES_MODE_WRITE)
		if (not file.data) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORUPDATINGFILE)
			return false
		end
		for i, line in pairs(replaydata) do
			file.data:write(line .. "\n")
		end
		file:close()
		
		return true
	end
	
	function Replays:updateReplayCache(replay, newreplay)
		local matchFound = false
		if (newreplay) then
			if (replay.name ~= newreplay.name) then
				if (not Replays:updateReplayFile(newreplay)) then
					TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORUPDATINGNAME)
					return false
				end
			end
		end
		
		local file = Files:new("../replay/replaycache.dat", FILES_MODE_READONLY)
		if (not file.data) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORREADINGCACHE)
			return false
		end
		
		local filedata = {}
		for ln in file.data:lines() do
			if (ln:find("^" .. strEsc("replay/" .. replay.filename))) then
				if (newreplay and not matchFound) then
					matchFound = true
					table.insert(filedata, 
						"replay/" .. newreplay.filename .. "\t" ..
						newreplay.name .. "\t" ..
						newreplay.author .. "\t" ..
						newreplay.mod .. "\t" ..
						newreplay.bouts[1] .. "\t" ..
						newreplay.bouts[2] .. "\t" ..
						newreplay.tags .. "\t" ..
						newreplay.hiddentags .. "\t" ..
						(newreplay.uploaded and "1\t" or "0\t"))
				end
			else
				table.insert(filedata, ln)
			end
		end
		file:close()
		
		local file = Files:new("../replay/replaycache.dat", FILES_MODE_WRITE)
		if (not file.data) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORUPDATINGTAGS)
			return false
		end
		for i, line in pairs(filedata) do
			file.data:write(line .. "\n")
		end
		file:close()
		
		return true
	end
	
	function Replays:getReplayFolders(folder, level, levelint)
		local folders = folder or {}
		local level = level or TB_MENU_REPLAYS
		local levelint = levelint or 1
		
		if (#folders < 1) then
			table.insert(folders, { name = "replay [root]", fullname = "replay", level = 1 })
		end
		
		local parentFolder = folders[#folders]
				
		for i,v in pairs(level.folders) do
			table.insert(folders, { name = v.name, fullname = parentFolder.fullname .. "/" .. v.name, level = levelint })
			Replays:getReplayFolders(folders, v, levelint + 1)
		end
		return folders
	end
	
	function Replays:getReplayFiles()
		TB_MENU_REPLAYS_LOADED = false
		
		-- Make sure replays table is flushed first
		TB_MENU_REPLAYS = { name = "replay", fullname = "replay" }
		
		local file = Files:new("../replay/replaycache.dat", FILES_MODE_READWRITE)
		if (not file.data) then
			file = Files:new("../replay/replaycache.dat", FILES_MODE_WRITE)
			if (not file.data) then
				TBMenu:showDataError(TB_MENU_LOCALIZED.ERRORCREATINGFILE)
			end
		end
		
		local filedata = {}
		for i, ln in pairs(file:readAll()) do
			local segments = 8
			local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
			local filename = string.lower(data_stream[1]:gsub(" ", "_"))
			filedata[filename] = { 
				name = data_stream[2], 
				author = data_stream[3], 
				mod = data_stream[4]:lower(), 
				bout0 = data_stream[5], 
				bout1 = data_stream[6],
			 	tags = data_stream[7]:lower(),
				hiddentags = data_stream[8]:lower(),
				uploaded = tonumber(data_stream[9])
			}
		end
		replayUpdateWindow = UIElement:new({
			parent = tbMenuMain,
			pos = { tbMenuMain.size.w / 3, -100 },
			size = { tbMenuMain.size.w / 3, 100 },
			bgColor = { 0, 0, 0, 0.6 }
		})
		Replays:fetchReplayData(nil, nil, file, filedata)
	end
	
	function Replays:getServerReplaysData(lines)
		for i, ln in pairs(lines) do
			if (ln:match("^#Total")) then
				SERVER_REPLAYS.total = ln:gsub("%D", "") + 0
			elseif (not ln:match("^#")) then
				local segments = 10
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local info = {
					id = tonumber(data_stream[1]),
					rplname = data_stream[2],
					uploader = data_stream[3],
					date = data_stream[4],
					description = data_stream[5]:gsub("\\'", "'"):gsub("\\\"", "\""):gsub("\\r", ""),
					downloads = data_stream[6] + 0,
					score = tonumber(data_stream[7]),
					votes = tonumber(data_stream[8]),
					tags = data_stream[9],
					uservote = tonumber(data_stream[10])
				}
				table.insert(SERVER_REPLAYS, info)
			end
		end
	end
	
	function Replays:getReplayComments(lines)
		local comments = {}
		for i, ln in pairs(lines) do
			if (ln:match("^#Total")) then
				comments.total = ln:gsub("%D", "") + 0
			elseif (not ln:match("^#")) then
				local segments = 5
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local comment = {
					id = tonumber(data_stream[1]),
					user = data_stream[2],
					score = tonumber(data_stream[3]),
					comment = data_stream[4]:gsub("\\'", "'"):gsub("\\\"", "\""),
					date = data_stream[5]
				}
				table.insert(comments, comment)
			end
		end
		return comments
	end
	
	function Replays:getServerReplays(action, offset, searchStr)
		TB_MENU_REPLAYS_ONLINE = 1
		local action = action or SERVER_REPLAYS.action
		local offset = offset or SERVER_REPLAYS.offset
		local searchStr = searchStr and searchStr:lower() or SERVER_REPLAYS.search
		if (action ~= SERVER_REPLAYS.action) then
			SELECTED_SERVER_REPLAY.id = 0
		end
		
		download_replay_result(action, offset, searchStr)
		local overlay = TBMenu:spawnWindowOverlay()
		local waitNotification = UIElement:new({
			parent = overlay,
			pos = { overlay.size.w / 3, overlay.size.h / 2 - 100 },
			size = { overlay.size.w / 3, 200 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local waitMessage = UIElement:new({
			parent = waitNotification,
			pos = { 10, 10 },
			size = { waitNotification.size.w - 20, waitNotification.size.h / 2 }
		})
		waitMessage:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSUPDATINGCOMMUNITY)
		local waitAnimation = UIElement:new({
			parent = waitNotification,
			pos = { waitNotification.size.w / 2 - 25, waitMessage.size.h + waitMessage.shift.y },
			size = { 50, waitNotification.size.h - waitMessage.size.h - waitMessage.shift.y * 3 }
		})
		local infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSDATE
		if (action == 2) then
			infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSRATING
		elseif (action == 3) then
			infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSPOPULARITY
		elseif (action == 4) then
			infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSTAGGED .. " \"" .. searchStr .. "\""
		elseif (action == 5) then
			infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSBY .. " " .. searchStr
		end
		local serverReplays = Files:new("../data/script/system/rplres.txt", FILES_MODE_READONLY)
		local rot, scale, time = 10, 90, os.clock()
		waitAnimation:addCustomDisplay(true, function()
				set_color(1, 1, 1, 0.8)
				draw_disk(waitAnimation.pos.x + waitAnimation.size.w / 2, waitAnimation.pos.y + waitAnimation.size.w / 2, waitAnimation.size.w / 4, waitAnimation.size.w / 2, 200, 1, rot, scale, 0)
				rot = rot + 2.5
				scale = scale > 359 and -360 or scale + 5
				if (os.clock() - time > 0.5) then
					if (not serverReplays:isDownloading()) then
						serverReplays:reopen()
						local filedata = serverReplays:readAll()
						serverReplays:close()
						overlay:kill()
						SERVER_REPLAYS = {}
						SERVER_REPLAYS.total = 0
						SERVER_REPLAYS.action = action
						SERVER_REPLAYS.offset = offset
						SERVER_REPLAYS.search = searchStr
						SERVER_REPLAYS.info = infoMessage
						if (filedata) then
							Replays:getServerReplaysData(filedata)
						end
						Replays:showServerReplays()
					end
				end
			end)
	end
	
	function Replays:getPopularTags()
		return {
			"multiplayer",
			"kick",
			"sparring",
			"aikido",
			"parkour",
			"madman",
			"tricking",
			"manipulation",
			"realism",
			"awesome",
			"punch",
			"split",
			"jump",
			"judo",
			"running"
		}
	end
	
	function Replays:findReplays(searchString, rplTable, searchResults)
		local replays = rplTable or TB_MENU_REPLAYS
		local searchResults = searchResults or { name = {}, filename = {}, author = {}, bouts = {}, mod = {}, tags = {}, hiddentags = {} }
		local searchString = type(searchString) == "table" and searchString[1]:lower() or searchString:lower()
		
		for i, folder in pairs(rplTable.folders) do
			Replays:findReplays(searchString, folder, searchResults)
		end
		for i, replay in pairs(rplTable.replays) do
			if (string.find(replay.name:lower(), searchString)) then
				table.insert(searchResults.name, replay)
			elseif (string.find(replay.filename:lower(), searchString)) then
				table.insert(searchResults.filename, replay)
			elseif (string.find(replay.author:lower(), searchString)) then
				table.insert(searchResults.author, replay)
			elseif (string.find(replay.mod:lower(), searchString)) then
				table.insert(searchResults.mod, replay)
			elseif (string.find(replay.tags:lower(), searchString)) then
				table.insert(searchResults.tags, replay)
			elseif (string.find(replay.hiddentags:lower(), searchString)) then
				table.insert(searchResults.hiddentags, replay)
			else
				for k, bout in pairs(replay.bouts) do
					if (string.find(bout:lower(), searchString)) then
						table.insert(searchResults.bouts, replay)
					end
				end
			end
		end
		return searchResults
	end
	
	function Replays:showSearchList(viewElement, replayInfo, toReload, replays)
		viewElement:kill(true)		
		local posY, elementHeight = 0, 40
		
		local listingHolder = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w - 20, viewElement.size.h }
		})
		
		local listing = {}
		local goBack = UIElement:new({
			parent = listingHolder,
			pos = { 0, posY },
			size = { listingHolder.size.w, elementHeight },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.3 }
		})
		goBack:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSBACKTOALLREPLAYS, nil, nil, 4, nil, 0.6)
		goBack:addMouseHandlers(nil, function()
				Replays:showList(viewElement.parent, replayInfo, SELECTED_FOLDER)
			end)
		posY = posY + elementHeight
		table.insert(listing, goBack)
		
		for section, replayList in pairs(replays) do
			if (#replayList > 0) then
				local sectionName = UIElement:new({
					parent = listingHolder,
					pos = { 10, posY },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				local sectionStr = TB_MENU_LOCALIZED.REPLAYSMATCHBY .. " " .. section
				if (section == "hiddentags") then
					sectionStr = "hidden tags"
				end
				sectionName:addCustomDisplay(true, function()
						sectionName:uiText(sectionStr, nil, nil, nil, LEFTMID)
					end)
				posY = posY + elementHeight
				table.insert(listing, sectionName)
				for i, replay in pairs(replayList) do
					local replayElement = UIElement:new({
						parent = listingHolder,
						pos = { 0, posY },
						size = { listingHolder.size.w, elementHeight },
						interactive = true,
						bgColor = i % 2 ~= 0 and TB_MENU_DEFAULT_DARKER_COLOR or TB_MENU_DEFAULT_BG_COLOR,
						hoverColor = { 0, 0, 0, 0.3 },
						pressedColor = { 1, 1, 1, 0.2 }
					})
					if (SELECTED_REPLAY.replay and SELECTED_REPLAY.replay.filename == replay.filename or i == 1) then
						SELECTED_REPLAY.element = replayElement
						SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
					end
					replayElement:addMouseHandlers(nil, function()
							if (SELECTED_REPLAY.element == replayElement and SELECTED_REPLAY.time + 0.5 > os.clock()) then
								Replays:playReplay(replay)
								return
							end
							SELECTED_REPLAY.time = os.clock()
							SELECTED_REPLAY.element.bgColor = { SELECTED_REPLAY.defaultColor[1], SELECTED_REPLAY.defaultColor[2], SELECTED_REPLAY.defaultColor[3], SELECTED_REPLAY.defaultColor[4] }
							SELECTED_REPLAY.element = replayElement
							SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
							Replays:showReplayInfo(replayInfo, replay)
						end)
					table.insert(listing, replayElement)
					
					local replayName = UIElement:new({
						parent = replayElement,
						pos = { 10, 0 },
						size = { replayElement.size.w / 2 - 20, replayElement.size.h }
					})
					replayName:addCustomDisplay(true, function()
							replayName:uiText(replay.name, nil, nil, 4, LEFTMID, 0.65)
						end)
					local replayNameSeparator = UIElement:new({
						parent = replayElement,
						pos = { replayName.shift.x + replayName.size.w, replayElement.size.h / 4 },
						size = { 1, replayElement.size.h / 2 },
						bgColor = { 1, 1, 1, 0.2 }
					})
					local replayAuthor = UIElement:new({
						parent = replayElement,
						pos = { replayNameSeparator.shift.x, 0 },
						size = { replayElement.size.w / 6, replayElement.size.h }
					})
					local replayAuthorStr = replay.author == "autosave" and TB_MENU_LOCALIZED.REPLAYSAUTHORAUTOSAVE or TB_MENU_LOCALIZED.REPLAYSAUTHORBY .. " " .. replay.author
					replayAuthor:addCustomDisplay(true, function()
							replayAuthor:uiText(replayAuthorStr, nil, nil, 4, nil, 0.65)
						end)
					local replayAuthorSeparator = UIElement:new({
						parent = replayElement,
						pos = { replayAuthor.shift.x + replayAuthor.size.w, replayElement.size.h / 4 },
						size = { 1, replayElement.size.h / 2 },
						bgColor = { 1, 1, 1, 0.2 }
					})
					local replayMod = UIElement:new({
						parent = replayElement,
						pos = { replayAuthorSeparator.shift.x, 0 },
						size = { replayElement.size.w - replayAuthorSeparator.shift.x, replayElement.size.h }
					})
					replayMod:addCustomDisplay(true, function()
							replayMod:uiText(replay.mod, nil, nil, 4, nil, 0.65)
						end)
					posY = posY + elementHeight
				end
			end
		end
		
		for i,v in pairs(listing) do
			v:hide()
		end
		
		local listingScrollBG = UIElement:new({
			parent = viewElement,
			pos = { -(viewElement.size.w - listingHolder.size.w), 0 },
			size = { viewElement.size.w - listingHolder.size.w, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local listingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listing, elementHeight)
		listingScrollBar:makeScrollBar(listingHolder, listing, toReload)
	end
	
	function Replays:playReplay(replay)
		local whiteoverlay = TBMenu:spawnWindowOverlay()
		
		local loading = UIElement:new({
			parent = whiteoverlay,
			pos = { WIN_W / 4, WIN_H / 7 * 3 },
			size = { WIN_W / 2, WIN_H / 7 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		if (replay.mod ~= "classic") then
			local files = get_files("data/mod", "")
			local folders = {}
			for i,v in pairs(files) do
				if (not v:find("^%.+[%s%S]*$") and not v:find("%.%a+$") and not v:find("^.*%.tbm$")) then
					table.insert(folders, v)
				end
			end
			local modFile = Files:new("../data/mod/" .. replay.mod)
			local id = 1
			while (not modFile.data and id < #folders) do
				modFile = Files:new("../data/mod/" .. folders[id] .. "/" .. replay.mod)
				id = id + 1
			end
			if (not modFile.data) then
				modFile = Files:new("../data/mod/downloads/" .. replay.mod)
				loading:addAdaptedText(false, TB_MENU_LOCALIZED.MODSDOWNLOADINGMOD)
				local modname = replay.mod:gsub("%.tbm$", "")
				download_mod(modname)
				local downloadWait = UIElement:new({
					parent = loading,
					pos = { 0, 0 },
					size = { 0, 0 }
				})
				local wait = 0
				downloadWait:addCustomDisplay(true, function()
						wait = wait + 1
						if (not modFile:isDownloading() and wait > 5) then
							loading:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
							local framesN = 0
							downloadWait:addCustomDisplay(true, function()
									framesN = framesN + 1
									if (framesN > 4) then
										UIElement:runCmd("loadreplay " .. replay.filename)
										close_menu()
									end
								end)
						end
					end)
			else
				modFile:close()
				local wait = 0
				loading:addCustomDisplay(false, function()
						loading:uiText(TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
						wait = wait + 1
						if (wait > 4) then
							UIElement:runCmd("loadreplay " .. replay.filename)
							close_menu()
						end
					end)
			end
		else
			local wait = 0
			loading:addCustomDisplay(false, function()
					loading:uiText(TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
					wait = wait + 1
					if (wait > 4) then
						UIElement:runCmd("loadreplay " .. replay.filename)
						close_menu()
					end
				end)
		end
	end
	
	function Replays:showList(viewElement, replayInfo, level)
		viewElement:kill(true)
		
		local posY, elementHeight = 0, 35
		local rplTable = level or TB_MENU_REPLAYS
		SELECTED_FOLDER = rplTable
		
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 50, elementHeight, 20)
		
		local bottomSmudge = TBMenu:addBottomBloodSmudge(botBar, 1)
		
		local replaysTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w / 3 * 2 - 20, topBar.size.h }
		})
		local replaysTitleStr = TB_MENU_LOCALIZED.MAINMENUREPLAYSNAME
		if (rplTable.fullname ~= "replay") then
			replaysTitleStr = replaysTitleStr .. " - " .. rplTable.name
		end
		replaysTitle:addAdaptedText(true, replaysTitleStr, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.2)
			
		if (level.fullname ~= "replay/autosave") then
			local posX = 0
			if (level.fullname ~= "replay/my replays" and level.fullname ~= "replay") then
				local editFolderButton = UIElement:new({
					parent = topBar,
					pos = { -topBar.size.h + 5, 5 },
					size = { topBar.size.h - 10, topBar.size.h - 10 },
					interactive = true,
					bgColor = { 0, 0, 0, 0.1 },
					hoverColor = { 0, 0, 0, 0.3 },
					pressedColor = { 1, 1, 1, 0.2 },
					bgImage = "../textures/menu/general/buttons/edit.tga"
				})
				posX = editFolderButton.shift.x
				editFolderButton:addMouseHandlers(nil, function()
						Replays:showEditFolderWindow()
					end)
			elseif (level.fullname == "replay") then
				local refreshCacheButton = UIElement:new({
					parent = topBar,
					pos = { -topBar.size.h + 5, 5 },
					size = { topBar.size.h - 10, topBar.size.h - 10 },
					interactive = true,
					bgColor = { 0, 0, 0, 0.1 },
					hoverColor = { 0, 0, 0, 0.3 },
					pressedColor = { 1, 1, 1, 0.2 },
					bgImage = "../textures/menu/general/buttons/settingsreset.tga"
				})
				posX = refreshCacheButton.shift.x
				refreshCacheButton:addMouseHandlers(nil, function()
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSREFRESHCACHEPROMPT, function()
								local file = Files:new("../replay/replaycache.dat", FILES_MODE_WRITE)
								if (not file.data) then
									TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORREFRESHINGCACHE)
								end
								file:close()
								TB_MENU_REPLAYS = { name = "replay", fullname = "replay" }
								SELECTED_FOLDER = { fullname = "replay" }
								Replays:showMain(tbMenuCurrentSection)
							end)
					end)
			end
			
			local addFolderButton = UIElement:new({
				parent = topBar,
				pos = { topBar.size.w / 3 * 2 + 10, 5 },
				size = { topBar.size.w / 3 - 15 + posX, topBar.size.h - 10 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			addFolderButton:addCustomDisplay(false, function()
					addFolderButton:uiText(TB_MENU_LOCALIZED.REPLAYSADDFOLDER)
				end)
			addFolderButton:addMouseHandlers(nil, function()
					Replays:showNewFolderWindow()
				end)
		end
		
		local searchInputField = TBMenu:spawnTextField(botBar, 10, 10, botBar.size.w - 20, botBar.size.h - 5, nil, nil, nil, 0.65, UICOLORWHITE, TB_MENU_LOCALIZED.SEARCHNOTE)
		
		
		local searchFunction = function()
			if (searchInputField.textfieldstr[1] == "") then
				Replays:showList(viewElement, replayInfo, level)
			else
				Replays:showSearchList(listingView, replayInfo, toReload, Replays:findReplays(searchInputField.textfieldstr, rplTable))
			end
		end
		searchInputField:addKeyboardHandlers(nil, searchFunction)
		
		local listing = {}
		if (rplTable ~= TB_MENU_REPLAYS) then
			local folderElement = UIElement:new({
				parent = listingHolder,
				pos = { 0, posY },
				size = { listingHolder.size.w, elementHeight },
				interactive = true,
				bgColor = posY % (elementHeight * 2) == 0 and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			table.insert(listing, folderElement)
			folderElement:addMouseHandlers(nil, function()
					SELECTED_REPLAY.replay = nil
					Replays:showList(viewElement, replayInfo, rplTable.parent)
				end)
			local folderIcon = UIElement:new({
				parent = folderElement,
				pos = { 10, 0 },
				size = { folderElement.size.h, folderElement.size.h },
				bgImage = "../textures/menu/general/back.tga"
			})
			local folderName = UIElement:new({
				parent = folderElement,
				pos = { folderIcon.shift.x * 2 + folderElement.size.h, 0 },
				size = { folderElement.size.w - folderElement.size.h - folderIcon.shift.x * 3, folderElement.size.h }
			})
			folderName:addCustomDisplay(true, function()
					folderName:uiText(rplTable.parent.name, nil, nil, 4, LEFTMID, 0.8)
				end)
			posY = posY + elementHeight
		end
		for i, folder in pairs(rplTable.folders) do
			local folderElement = UIElement:new({
				parent = listingHolder,
				pos = { 0, posY },
				size = { listingHolder.size.w, elementHeight },
				interactive = true,
				bgColor = posY % (elementHeight * 2) == 0 and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			table.insert(listing, folderElement)
			folderElement:addMouseHandlers(nil, function()
					SELECTED_REPLAY.replay = nil
					Replays:showList(viewElement, replayInfo, folder)
				end)
			local folderIcon = UIElement:new({
				parent = folderElement,
				pos = { 10, 0 },
				size = { folderElement.size.h, folderElement.size.h },
				bgImage = "../textures/menu/general/folder.tga"
			})
			local folderName = UIElement:new({
				parent = folderElement,
				pos = { folderIcon.shift.x * 2 + folderElement.size.h, 0 },
				size = { folderElement.size.w - folderElement.size.h - folderIcon.shift.x * 3, folderElement.size.h }
			})
			folderName:addCustomDisplay(true, function()
					folderName:uiText(folder.name, nil, nil, 4, LEFTMID, 0.8)
				end)
			posY = posY + elementHeight
		end
		for i, replay in pairs(rplTable.replays) do
			local replayElement = UIElement:new({
				parent = listingHolder,
				pos = { 0, posY },
				size = { listingHolder.size.w, elementHeight },
				interactive = true,
				bgColor = posY % (elementHeight * 2) == 0 and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			if (SELECTED_REPLAY.replay and SELECTED_REPLAY.replay.filename == replay.filename or i == 1) then
				SELECTED_REPLAY.element = replayElement
				SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
			end
			replayElement:addMouseHandlers(nil, function()
					if (SELECTED_REPLAY.element == replayElement and SELECTED_REPLAY.time + 0.5 > os.clock()) then
						Replays:playReplay(replay)
						return
					end
					SELECTED_REPLAY.time = os.clock()
					SELECTED_REPLAY.element.bgColor = { SELECTED_REPLAY.defaultColor[1], SELECTED_REPLAY.defaultColor[2], SELECTED_REPLAY.defaultColor[3], SELECTED_REPLAY.defaultColor[4] }
					SELECTED_REPLAY.element = replayElement
					SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
					Replays:showReplayInfo(replayInfo, replay)
				end)
			table.insert(listing, replayElement)
			
			local replayName = UIElement:new({
				parent = replayElement,
				pos = { 10, 0 },
				size = { replayElement.size.w / 2 - 20, replayElement.size.h }
			})
			replayName:addCustomDisplay(true, function()
					replayName:uiText(replay.name, nil, nil, 4, LEFTMID, 0.65)
				end)
			local replayNameSeparator = UIElement:new({
				parent = replayElement,
				pos = { replayName.shift.x + replayName.size.w, replayElement.size.h / 4 },
				size = { 1, replayElement.size.h / 2 },
				bgColor = { 1, 1, 1, 0.2 }
			})
			local replayAuthor = UIElement:new({
				parent = replayElement,
				pos = { replayNameSeparator.shift.x, 0 },
				size = { replayElement.size.w / 6, replayElement.size.h }
			})
			local replayAuthorStr = replay.author == "autosave" and TB_MENU_LOCALIZED.REPLAYSAUTHORAUTOSAVE or TB_MENU_LOCALIZED.REPLAYSAUTHORBY .. " " .. replay.author
			replayAuthor:addCustomDisplay(true, function()
					replayAuthor:uiText(replayAuthorStr, nil, nil, 4, nil, 0.65)
				end)
			local replayAuthorSeparator = UIElement:new({
				parent = replayElement,
				pos = { replayAuthor.shift.x + replayAuthor.size.w, replayElement.size.h / 4 },
				size = { 1, replayElement.size.h / 2 },
				bgColor = { 1, 1, 1, 0.2 }
			})
			local replayMod = UIElement:new({
				parent = replayElement,
				pos = { replayAuthorSeparator.shift.x, 0 },
				size = { replayElement.size.w - replayAuthorSeparator.shift.x, replayElement.size.h }
			})
			replayMod:addCustomDisplay(true, function()
					replayMod:uiText(replay.mod, nil, nil, 4, nil, 0.65)
				end)
			posY = posY + elementHeight
		end
		
		for i,v in pairs(listing) do
			v:hide()
		end
		
		local listingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listing, elementHeight)
		listingScrollBar:makeScrollBar(listingHolder, listing, toReload)
		Replays:showReplayInfo(replayInfo, SELECTED_REPLAY.replay or rplTable.replays[1])
	end
	
	function Replays:showReplayTaglistTag(viewElement, updatedTags, tag, elementHeight, posInfo, popularTags)
		local width = get_string_length(tag, 4) * 0.7 + 34
		if (width > viewElement.size.w) then
			width = viewElement.size.w
		end
		if (width + posInfo.x > viewElement.size.w) then
			posInfo.x = 0
			posInfo.y = posInfo.y + elementHeight
		end
		local replayTag = UIElement:new({
			parent = viewElement,
			pos = { posInfo.x, posInfo.y },
			size = { width, elementHeight }
		})
		local replayTagName = UIElement:new({
			parent = replayTag,
			pos = { 10, 0 },
			size = { replayTag.size.w, replayTag.size.h }
		})
		replayTagName:addCustomDisplay(true, function()
				replayTagName:uiText(tag, nil, nil, 4, LEFTMID, 0.7)
			end)
		local replayTagRemoveButton = UIElement:new({
			parent = replayTag,
			pos = { -24, 3 },
			size = { 24, 24 },
			shapeType = ROUNDED,
			rounded = 3,
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		local tagRemoveIcon = UIElement:new({
			parent = replayTagRemoveButton,
			pos = { 4, 4 },
			size = { 16, 16 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		replayTagRemoveButton:addMouseHandlers(nil, function()
				for i,v in pairs(updatedTags) do
					if (v == tag) then
						table.remove(updatedTags, i)
						for j, k in pairs(popularTags) do
							if (j == tag) then
								Replays:tagButtonActivate(k)
								break
							end
						end
						break
					end
				end
				viewElement:kill(true)
				posInfo.x, posInfo.y = 0, 0
				for i,tag in pairs(updatedTags) do
					Replays:showReplayTaglistTag(viewElement, updatedTags, tag, elementHeight, posInfo, popularTags)
				end
			end)
		posInfo.x = posInfo.x + width
	end
	
	function Replays:tagButtonDeactivate(tagAdd)
		tagAdd:deactivate()
		tagAdd:addCustomDisplay(false, function() end)
		tagAdd:updateImage("../textures/menu/general/buttons/checkmark.tga")
		tagAdd.bgColor = { 1, 1, 1, 0.2 }
	end
	
	function Replays:tagButtonActivate(tagAdd)
		tagAdd:updateImage(nil)
		tagAdd:activate()
		tagAdd:addCustomDisplay(false, function()
				set_color(1, 1, 1, 0.8)
				draw_quad(	tagAdd.pos.x + tagAdd.size.w / 2 - 1,
							tagAdd.pos.y + 4,
							2,
							tagAdd.size.h - 8	)
				draw_quad(	tagAdd.pos.x + 4,
							tagAdd.pos.y + tagAdd.size.h / 2 - 1,
							tagAdd.size.w - 8,
							2	)
			end)
		tagAdd.bgColor = { 0, 0, 0, 0.3 }
	end
	
	function Replays:showTags(replayInfoView, replay)
		local updatedTags = {}
		for i in string.gmatch(replay.tags, "%S+") do
			table.insert(updatedTags, i)
		end
		
		local tagsOverlay = TBMenu:spawnWindowOverlay()
		local tagsView = UIElement:new({
			parent = tagsOverlay,
			pos = { tagsOverlay.size.w / 8, tagsOverlay.size.h / 6 },
			size = { tagsOverlay.size.w / 8 * 6, tagsOverlay.size.h / 6 * 4 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local tagsTitle = UIElement:new({
			parent = tagsView,
			pos = { 10, 0 },
			size = { tagsView.size.w - 20, tagsView.size.h / 8 }
		})
		tagsTitle:addCustomDisplay(true, function()
				tagsTitle:uiText(TB_MENU_LOCALIZED.REPLAYSTAGSMODIFYING .. " " .. replay.name ..  " " .. TB_MENU_LOCALIZED.REPLAYSTAGSNAME)
			end)
		
		local popularTagsView = UIElement:new({
			parent = tagsView,
			pos = { 10, tagsTitle.size.h },
			size = { tagsView.size.w / 2 - 20, tagsView.size.h - tagsTitle.size.h * 2 - 10 }
		})
		local replayTags = UIElement:new({
			parent = tagsView,
			pos = { tagsView.size.w / 2 + 10, tagsTitle.size.h },
			size = { tagsView.size.w / 2 - 20, tagsView.size.h / 8 * 7 - tagsTitle.size.h - 10 }
		})
		local tagsSeparator = UIElement:new({
			parent = tagsView,
			pos = { tagsView.size.w / 2 - 1, tagsTitle.size.h + 20 },
			size = { 1, tagsView.size.h - tagsTitle.size.h - 40 },
			bgColor = { 1, 1, 1, 0.2 }
		})		
		
		local posY, elementHeight = 30, 30
		local replayTagListInfo = { y = 0, x = 0 }
		
		local popularTagsName = UIElement:new({
			parent = popularTagsView,
			pos = { 10, 0 },
			size = { popularTagsView.size.w - 20, elementHeight }
		})
		popularTagsName:addCustomDisplay(true, function()
				popularTagsName:uiText(TB_MENU_LOCALIZED.REPLAYSPOPULARTAGS)
			end)
		local replayTagsName = UIElement:new({
			parent = replayTags,
			pos = { 10, 0 },
			size = { replayTags.size.w - 20, elementHeight }
		})
		replayTagsName:addCustomDisplay(true, function()
				replayTagsName:uiText(TB_MENU_LOCALIZED.REPLAYSASSIGNEDTAGS)
			end)
		local replayTagsView = UIElement:new({
			parent = replayTags,
			pos = { 0, replayTagsName.size.h },
			size = { replayTags.size.w, replayTags.size.h - replayTagsName.size.h }
		})
		
		local popularTagsButtons = {}
		for i, tag in pairs(Replays:getPopularTags()) do
			if (posY + elementHeight < popularTagsView.size.h) then
				local tagElement = UIElement:new({
					parent = popularTagsView,
					pos = { 0, posY },
					size = { popularTagsView.size.w, elementHeight }
				})
				local tagName = UIElement:new({
					parent = tagElement,
					pos = { 0, 0 },
					size = { tagElement.size.w - 30, tagElement.size.h }
				})
				tagName:addCustomDisplay(true, function()
						tagName:uiText(tag, nil, nil, 4, LEFTMID, 0.7)
					end)
				local tagAdd = UIElement:new({
					parent = tagElement,
					pos = { tagElement.size.w - 24, 3 },
					size = { 24, 24 },
					shapeType = ROUNDED,
					rounded = 3,
					interactive = true,
					bgColor = { 0, 0, 0, 0.3 },
					hoverColor = { 0, 0, 0, 0.5 },
					pressedColor = { 1, 1, 1, 0.2 }
				})
				tagAdd:addMouseHandlers(nil, function()
						table.insert(updatedTags, tag)
						Replays:showReplayTaglistTag(replayTagsView, updatedTags, tag, elementHeight, replayTagListInfo, popularTagsButtons)
						Replays:tagButtonDeactivate(tagAdd)
					end)
				if (not replay.tags:find(tag)) then
					Replays:tagButtonActivate(tagAdd)
				else
					Replays:tagButtonDeactivate(tagAdd)
				end
				popularTagsButtons[tag] = tagAdd
			else 
				break
			end
			posY = posY + elementHeight
		end
		
		local tagInputFieldView = UIElement:new({
			parent = tagsView,
			pos = { 10, -50 },
			size = { tagsView.size.w / 2 - 100, 40 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local tagInputFieldBG = UIElement:new({
			parent = tagInputFieldView,
			pos = { 1, 1 },
			size = { tagInputFieldView.size.w - 2, tagInputFieldView.size.h - 2 },
			bgColor = { 1, 1, 1, 0.5 }
		})
		local tagInputField = UIElement:new({
			parent = tagInputFieldBG,
			pos = { 10, 0 },
			size = { tagInputFieldBG.size.w - 20, tagInputFieldBG.size.h },
			interactive = true,
			textfield = true,
			textfieldsingleline = true
		})
		tagInputField:addMouseHandlers(function()
				TBMenu:enableMenuKeyboard(tagInputField)
			end)
		TBMenu:displayTextfield(tagInputField, FONTS.SMALL, 1, UICOLORBLACK, TB_MENU_LOCALIZED.REPLAYSINPUTTAGHERE)
			
		local tagAddFunction = function()
				local tagString = tagInputField.textfieldstr[1]
				if (tagString:gsub("%A", "") == "" or tagString:len() < 2) then
					TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSTAGERRORSHORT)
					return
				end
				for i,v in pairs(updatedTags) do
					if (v == tagString) then
						TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSTAGERRORDUPLICATE)
						return
					end
				end
				tagInputField:clearTextfield()
				table.insert(updatedTags, tagString)
				Replays:showReplayTaglistTag(replayTagsView, updatedTags, tagString, elementHeight, replayTagListInfo, popularTagsButtons)
			end
		tagInputField:addEnterAction(tagAddFunction)
		
		local tagButton = UIElement:new({
			parent = tagsView,
			pos = { tagsView.size.w / 2 - 90, -50 },
			size = { 80, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		tagButton:addCustomDisplay(false, function()
				tagButton:uiText(TB_MENU_LOCALIZED.BUTTONADD)
			end)
		tagButton:addMouseHandlers(nil, tagAddFunction)
		
		
		for i, tag in pairs(updatedTags) do
			Replays:showReplayTaglistTag(replayTagsView, updatedTags, tag, elementHeight, replayTagListInfo, popularTagsButtons)
		end
		
		local buttonCancel = UIElement:new({
			parent = tagsView,
			pos = { tagsView.size.w / 2 + 10, -50 },
			size = { tagsView.size.w / 4 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		buttonCancel:addCustomDisplay(false, function()
				buttonCancel:uiText(TB_MENU_LOCALIZED.BUTTONCANCEL)
			end)
		buttonCancel:addMouseHandlers(nil, function()
				tagsOverlay:kill()
			end)
		local buttonSave = UIElement:new({
			parent = tagsView,
			pos = { tagsView.size.w / 4 * 3, -50 },
			size = { tagsView.size.w / 4 - 10, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		buttonSave:addCustomDisplay(false, function()
				buttonSave:uiText(TB_MENU_LOCALIZED.BUTTONSAVE)
			end)
		buttonSave:addMouseHandlers(nil, function()
				local tagsString
				for i,v in pairs(updatedTags) do
					if (i > 1) then
						tagsString = tagsString .. " " .. v
					else
						tagsString = v
					end
				end
				if (not tagsString) then
					tagsString = " "
				end
				
				local newreplay = cloneTable(replay)
				newreplay.tags = tagsString
				
				if (Replays:updateReplayCache(replay, newreplay)) then
					replay.tags = newreplay.tags
				end
				tagsOverlay:kill()
				Replays:showMain(tbMenuCurrentSection)
			end)
	end
	
	function Replays:showEditFolderWindow()
		local editFolderOverlay = TBMenu:spawnWindowOverlay()
		local editFolderView = UIElement:new({
			parent = editFolderOverlay,
			pos = { editFolderOverlay.size.w / 4, editFolderOverlay.size.h / 2 - 100 },
			size = { editFolderOverlay.size.w / 2, 200 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local editFolderTitle = UIElement:new({
			parent = editFolderView,
			pos = { 10, 0 },
			size = { editFolderView.size.w - 20, 50 }
		})
		editFolderTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSTAGSMODIFYING .. " " .. SELECTED_FOLDER.fullname .. " " .. TB_MENU_LOCALIZED.REPLAYSMODIFYINGFOLDER, nil, nil, FONTS.BIG)
		local newFolderInputBG = UIElement:new({
			parent = editFolderView,
			pos = { 10, editFolderView.size.h / 2 - 20 },
			size = { editFolderView.size.w - 20, 40 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local newFolderInputOverlay = UIElement:new({
			parent = newFolderInputBG,
			pos = { 1, 1 },
			size = { newFolderInputBG.size.w - 2, newFolderInputBG.size.h - 2 },
			bgColor = { 1, 1, 1, 0.5 }
		})
		local newFolderInput = UIElement:new({
			parent = newFolderInputOverlay,
			pos = { 10, 0 },
			size = { newFolderInputOverlay.size.w - 20, newFolderInputOverlay.size.h },
			interactive = true,
			textfield = true,
			textfieldstr = { SELECTED_FOLDER.name }
		})
		newFolderInput:addMouseHandlers(function()
				TBMenu:enableMenuKeyboard(newFolderInput)
			end)
		TBMenu:displayTextfield(newFolderInput, FONTS.SMALL, nil, UICOLORBLACK, TB_MENU_LOCALIZED.REPLAYSFOLDERNAME)
		
		local posX = 0
		local deleteButton = UIElement:new({
			parent = editFolderView,
			pos = { -50, -50 },
			size = { 40, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 },
			bgImage = "../textures/menu/general/buttons/trash.tga"
		})
		deleteButton:addMouseHandlers(nil, function()
				local function delete_folder(folder)
					local parentFolder = folder.fullname:gsub("/" .. folder.name .. "$", "")
					local error = remove_replay_subfolder(folder.fullname:gsub("^replay/", ""))
					if (error) then
						TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORDELETING .. " " .. TB_MENU_LOCALIZED.REPLAYSERRORDELETINGFOLDER .. " " .. folder.fullname .. ": " .. error)
						return
					end
					SELECTED_FOLDER = { fullname = parentFolder }
				end
				if (#SELECTED_FOLDER.replays == 0 and #SELECTED_FOLDER.folders == 0) then
					delete_folder(SELECTED_FOLDER)
					editFolderOverlay:kill()
					Replays:showMain(tbMenuCurrentSection)
				else
					local function delete_folder_with_files(folder, targetFolder)
						local targetFolder = targetFolder or folder.fullname:gsub("^replay/", ""):gsub(folder.name .. ".*$", "")
						for i,v in pairs(folder.folders) do
							delete_folder_with_files(v, targetFolder)
						end
						for i,v in pairs(folder.replays) do
							local error = move_replay(v.filename, targetFolder .. v.filename:gsub("^.*/", ""))
							if (error) then
								TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORMOVING .. " " .. v.filename .. " " .. TB_MENU_LOCALIZED.REPLAYSERRORMOVINGTO .. " " .. newPath .. ": " .. error)
								return
							end
						end
						delete_folder(folder)
					end
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSFOLDERNOTEMPTYDELETEWARNING, function() delete_folder_with_files(SELECTED_FOLDER) editFolderOverlay:kill() Replays:showMain(tbMenuCurrentSection) end)
				end
			end)
		local cancelButton = UIElement:new({
			parent = editFolderView,
			pos = { 10, -50 },
			size = { editFolderView.size.w / 2 - 40, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addCustomDisplay(false, function()
				cancelButton:uiText(TB_MENU_LOCALIZED.BUTTONCANCEL)
			end)
		cancelButton:addMouseHandlers(nil, function()
				editFolderOverlay:kill()
			end)
		local saveButton = UIElement:new({
			parent = editFolderView,
			pos = { editFolderView.size.w / 2 - 20, -50 },
			size = { editFolderView.size.w / 2 - 40, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		saveButton:addCustomDisplay(false, function()
				saveButton:uiText(TB_MENU_LOCALIZED.BUTTONSAVE)
			end)
		saveButton:addMouseHandlers(nil, function()
				local newFolderName = newFolderInput.textfieldstr[1]:gsub("%s+$", ""):gsub("^%s+", "")
				local parentFolder = SELECTED_FOLDER.fullname:gsub(SELECTED_FOLDER.name .. "$", "")
				if (SELECTED_FOLDER.name == newFolderName) then
					editFolderOverlay:kill()
					return
				end
				local error = rename_replay_subfolder(SELECTED_FOLDER.fullname:gsub("^replay/", ""), parentFolder:gsub("^replay/", "") .. newFolderName)
				if (error) then
					TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORRENAMINGFOLDER .. ": " .. error)
					return
				end
				SELECTED_FOLDER = { fullname = parentFolder .. newFolderName }
				editFolderOverlay:kill()
				Replays:showMain(tbMenuCurrentSection)
			end)
	end
	
	function Replays:showNewFolderWindow()
		local _, level = SELECTED_FOLDER.fullname:gsub("/", "")
		if (level > MAXFOLDERLEVELS - 1) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSFOLDERLEVELERROR1 ..  " " .. MAXFOLDERLEVELS .. " " .. TB_MENU_LOCALIZED.REPLAYSFOLDERLEVELERROR2)
			return
		end
		local newFolderOverlay = TBMenu:spawnWindowOverlay()
		local newFolderView = UIElement:new({
			parent = newFolderOverlay,
			pos = { newFolderOverlay.size.w / 4, newFolderOverlay.size.h / 2 - 100 },
			size = { newFolderOverlay.size.w / 2, 200 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local newFolderTitle = UIElement:new({
			parent = newFolderView,
			pos = { 10, 0 },
			size = { newFolderView.size.w - 20, 50 }
		})
		newFolderTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSADDINGFOLDER .. " " .. SELECTED_FOLDER.fullname, nil, nil, FONTS.BIG)
		local newFolderInputBG = UIElement:new({
			parent = newFolderView,
			pos = { 10, newFolderView.size.h / 2 - 20 },
			size = { newFolderView.size.w - 20, 40 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local newFolderInputOverlay = UIElement:new({
			parent = newFolderInputBG,
			pos = { 1, 1 },
			size = { newFolderInputBG.size.w - 2, newFolderInputBG.size.h - 2 },
			bgColor = { 1, 1, 1, 0.5 }
		})
		local newFolderInput = UIElement:new({
			parent = newFolderInputOverlay,
			pos = { 10, 0 },
			size = { newFolderInputOverlay.size.w - 20, newFolderInputOverlay.size.h },
			interactive = true,
			textfield = true,
			textfieldsingleline = true
		})
		newFolderInput:addMouseHandlers(function()
				TBMenu:enableMenuKeyboard(newFolderInput)
			end)
		TBMenu:displayTextfield(newFolderInput, FONTS.SMALL, nil, UICOLORBLACK, TB_MENU_LOCALIZED.REPLAYSNEWFOLDERNAME)
		local cancelButton = UIElement:new({
			parent = newFolderView,
			pos = { 10, -50 },
			size = { newFolderView.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addCustomDisplay(false, function()
				cancelButton:uiText(TB_MENU_LOCALIZED.BUTTONCANCEL)
			end)
		cancelButton:addMouseHandlers(nil, function()
				newFolderOverlay:kill()
			end)
		local saveButton = UIElement:new({
			parent = newFolderView,
			pos = { newFolderView.size.w / 2 + 5, -50 },
			size = { newFolderView.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		saveButton:addCustomDisplay(false, function()
				saveButton:uiText(TB_MENU_LOCALIZED.BUTTONCREATE)
			end)
		local function spawnNewFolder()
			if (newFolderInput.textfieldstr[1] ~= newFolderInput.textfieldstr[1]:match("[^ ][%w+ ]+")) then
				TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSFOLDERALPHANUMERIC)
				return
			end
			local parentFolder = SELECTED_FOLDER.fullname:gsub("^replay/*", "")
			parentFolder = parentFolder:len() > 0 and parentFolder .. "/" or parentFolder
			local newFolderName = parentFolder .. newFolderInput.textfieldstr[1]:gsub(" +$", "")
			local result = add_replay_subfolder(newFolderName)
			if (result) then
				TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORADDINGFOLDER .. ": " .. result)
				return
			end
			newFolderOverlay:kill()
			SELECTED_FOLDER = { fullname = "replay/" .. newFolderName }
			Replays:showMain(tbMenuCurrentSection)
		end
		newFolderInput:addEnterAction(spawnNewFolder)
		saveButton:addMouseHandlers(nil, spawnNewFolder)
	end
	
	function Replays:showUploadWindow(replayInfoView, replay)
		local uploadOverlay = TBMenu:spawnWindowOverlay()
		local uploadView = UIElement:new({
			parent = uploadOverlay,
			pos = { uploadOverlay.size.w / 6, uploadOverlay.size.h / 5 },
			size = { uploadOverlay.size.w / 6 * 4, uploadOverlay.size.h / 5 * 3 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local uploadTitle = UIElement:new({
			parent = uploadView,
			pos = { 10, 0 },
			size = { uploadView.size.w - 20, uploadView.size.h / 8 }
		})
		uploadTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSUPLOAD .. " " .. replay.name ..  " " .. TB_MENU_LOCALIZED.REPLAYSUPLOADTORIBASHSERVERS, nil, nil, FONTS.BIG, nil, 0.7)
		
		local replayUploadInfoView = UIElement:new({
			parent = uploadView,
			pos = { 10, uploadTitle.size.h },
			size = { uploadView.size.w - 20, uploadView.size.h * 7 / 8 - uploadTitle.size.h }
		})
		
		local replayData = {
			{
				name = TB_MENU_LOCALIZED.REPLAYSNAME,
				desc = TB_MENU_LOCALIZED.REPLAYSNAMEINFO,
				value = { replay.name },
				input = false
			},
			{
				name = TB_MENU_LOCALIZED.REPLAYSDESC,
				desc = TB_MENU_LOCALIZED.REPLAYSDESCINFO,
				tip = TB_MENU_LOCALIZED.REPLAYSDESCTIP,
				value = { "" },
				input = true,
				fulltext = true
			},
			{
				name = TB_MENU_LOCALIZED.REPLAYSTAGS,
				desc = TB_MENU_LOCALIZED.REPLAYSTAGSINFO,
				value = { string.gsub(replay.tags .. " " .. replay.hiddentags, "^ +", "") },
				tip = TB_MENU_LOCALIZED.REPLAYSTAGSTIP,
				input = true
			}
		}
		
		
		posY, elementHeight = 0, 90
		for i,v in pairs(replayData) do
			local replayUploadInfoHolder = UIElement:new({
				parent = replayUploadInfoView,
				pos = { 0, posY },
				size = { replayUploadInfoView.size.w, elementHeight }
			})
			local replayUploadInfoNameTitle = UIElement:new({
				parent = replayUploadInfoHolder,
				pos = { 0, 0 },
				size = { replayUploadInfoHolder.size.w / 3, replayUploadInfoHolder.size.h / 3 }
			})
			replayUploadInfoNameTitle:addCustomDisplay(true, function()
					replayUploadInfoNameTitle:uiText(v.name, nil, nil, nil, LEFTBOT)
				end)
			local replayUploadInfoNameDesc = UIElement:new({
				parent = replayUploadInfoHolder,
				pos = { 0, replayUploadInfoNameTitle.size.h },
				size = { replayUploadInfoNameTitle.size.w, replayUploadInfoHolder.size.h - replayUploadInfoNameTitle.size.h }
			})
			replayUploadInfoNameDesc:addCustomDisplay(true, function()
					replayUploadInfoNameDesc:uiText(v.desc, nil, nil, 4, LEFT, 0.7)
				end)
			local replayUploadInfoDataField = UIElement:new({
				parent = replayUploadInfoHolder,
				pos = { replayUploadInfoHolder.size.w * 2 / 5, 0 },
				size = { replayUploadInfoHolder.size.w * 3 / 5, replayUploadInfoHolder.size.h }
			})
			local replayUploadInfoDataInputBG = UIElement:new({
				parent = replayUploadInfoDataField,
				pos = { 10, 10 },
				size = { replayUploadInfoDataField.size.w - 20, v.fulltext and replayUploadInfoDataField.size.h - 20 or 30 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			if (v.input) then
				local replayUploadInfoDataInputOverlay = UIElement:new({
					parent = replayUploadInfoDataInputBG,
					pos = { 1, 1 },
					size = { replayUploadInfoDataInputBG.size.w - 2, replayUploadInfoDataInputBG.size.h - 2 },
					bgColor = { 1, 1, 1, 0.5 }
				})
				local replayUploadInfoDataInput = UIElement:new({
					parent = replayUploadInfoDataInputOverlay,
					pos = { 10, 5 },
					size = { replayUploadInfoDataInputOverlay.size.w - 20, replayUploadInfoDataInputOverlay.size.h - 10 },
					interactive = true,
					textfield = true,
					textfieldstr = v.value,
					textfieldsingleline = not v.fulltext
				})
				replayUploadInfoDataInput:addMouseHandlers(function()
						TBMenu:enableMenuKeyboard(replayUploadInfoDataInput)
					end)
				TBMenu:displayTextfield(replayUploadInfoDataInput, FONTS.SMALL, nil, UICOLORBLACK, v.tip, v.fulltext and LEFT)
			else
				local replayUploadInfoData = UIElement:new({
					parent = replayUploadInfoDataInputBG,
					pos = { 1, 1 },
					size = { replayUploadInfoDataInputBG.size.w - 2, replayUploadInfoDataInputBG.size.h - 2 },
					bgColor = { 1, 1, 1, 0.3 }
				})
				local replayUploadInfoDataText = UIElement:new({
					parent = replayUploadInfoData,
					pos = { 10, 5 },
					size = { replayUploadInfoData.size.w - 20, replayUploadInfoData.size.h - 10 }
				})
				replayUploadInfoDataText:addCustomDisplay(true, function()
						replayUploadInfoDataText:uiText(v.value[1], nil, nil, 4, LEFTMID, 0.6, nil, nil, UICOLORBLACK)
					end)
			end
			
			posY = posY + elementHeight
		end
		
		local cancelButton = UIElement:new({
			parent = uploadView,
			pos = { 10, -uploadView.size.h / 8 },
			size = { uploadView.size.w / 2 - 15, uploadView.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addCustomDisplay(false, function()
				cancelButton:uiText(TB_MENU_LOCALIZED.BUTTONCANCEL)
			end)
		cancelButton:addMouseHandlers(nil, function()
				uploadOverlay:kill()
			end)
		local uploadButton = UIElement:new({
			parent = uploadView,
			pos = { uploadView.size.w / 2 + 5, -uploadView.size.h / 8 },
			size = { uploadView.size.w / 2 - 15, uploadView.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		uploadButton:addCustomDisplay(false, function()
				if (replayData[1].value[1] == "" or replayData[2].value[1] == "" or replayData[3].value[1] == "") then
					uploadButton:deactivate()
					uploadButton.bgColor = { 0, 0, 0, 0.1 }
				else
					uploadButton:activate()
					uploadButton.bgColor = { 0, 0, 0, 0.3 }
				end
				uploadButton:uiText(TB_MENU_LOCALIZED.BUTTONUPLOAD)
			end)
		uploadButton:addMouseHandlers(nil, function()
				open_upload_replay(	TB_MENU_LOCALIZED.REPLAYSUPLOADCONFIRM,
									replayData[1].value[1],
									replayData[2].value[1],
									replayData[3].value[1],
									"replay/" .. replay.filename
								)
				local overlay = UIElement:new({
					pos = { 0, 0 },
					size = { WIN_W, WIN_H }
				})
				local left = UIElement:new({
					parent = overlay,
					pos = { 0, 0 },
					size = { overlay.size.w / 2, overlay.size.h },
					interactive = true
				})
				left:addMouseHandlers(nil, nil, function()
						overlay:kill()
					end)
				local right = UIElement:new({
					parent = overlay,
					pos = { overlay.size.w / 2, 0 },
					size = { overlay.size.w / 2, overlay.size.h },
					interactive = true
				})
				right:addMouseHandlers(nil, nil, function()
						overlay:kill()
						uploadOverlay:kill()
						Replays:showReplayInfo(replayInfoView, replay)
					end)
			end)
	end
	
	function Replays:showFolderDropdown(viewElement, folderdata)
		local entries = #folderdata.data
		local entryHeight = 30
		local dropdownHeight = entries * entryHeight
		local dropdownScrollable = false
		if (dropdownHeight > WIN_H / 2) then
			dropdownHeight = WIN_H / 2
			dropdownScrollable = true
		end
		
		local dropdownOverlay = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H },
			interactive = true
		})		
		local dropdownView = UIElement:new({
			parent = viewElement,
			pos = { 0, -viewElement.size.h / 2 - dropdownHeight / 2 },
			size = { viewElement.size.w, dropdownHeight},
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		dropdownOverlay:addMouseHandlers(nil, function()
				dropdownOverlay:kill()
				dropdownView:kill()
			end)
		if (not dropdownScrollable) then
			for i,v in pairs(folderdata.data) do
				local folder = UIElement:new({
					parent = dropdownView,
					pos = { 0, (i - 1) * entryHeight },
					size = { dropdownView.size.w, entryHeight },
					interactive = true,
					bgColor = { 0, 0, 0, 0 },
					hoverColor = { 0, 0, 0, 0.2 },
					pressedColor = { 1, 1, 1, 0.2 }
				})
				local infoHolder = UIElement:new({
					parent = folder,
					pos = { (v.level - 1) / 2 * entryHeight, 0 },
					size = { folder.size.w - (v.level - 1) / 2 * entryHeight, folder.size.h }
				})
				local folderIcon = UIElement:new({
					parent = infoHolder,
					pos = { 0, 0 },
					size = { entryHeight, entryHeight },
					bgImage = "../textures/menu/general/folder.tga"
				})
				local folderText = UIElement:new({
					parent = infoHolder,
					pos = { entryHeight + 10, 0 },
					size = { infoHolder.size.w - entryHeight - 20, infoHolder.size.h }
				})
				folderText:addCustomDisplay(true, function()
						folderText:uiText(v.name, nil, nil, 4, LEFTMID, 0.6)
					end)
				folder:addMouseHandlers(nil, function()
						folderdata.value = v.fullname:gsub("^replay/", "")
						dropdownOverlay:kill()
						dropdownView:kill()
					end)
			end
		end
	end
	
	function Replays:showReplayManageWindow(replayInfoView, replay)
		local manageOverlay = TBMenu:spawnWindowOverlay()
		local manageView = UIElement:new({
			parent = manageOverlay,
			pos = { manageOverlay.size.w / 6, manageOverlay.size.h / 2 - 130 },
			size = { manageOverlay.size.w / 6 * 4, 260 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local manageTitle = UIElement:new({
			parent = manageView,
			pos = { 10, 0 },
			size = { manageView.size.w - 20, 50 }
		})
		manageTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSMANAGE .. " " .. replay.name .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY, nil, nil, FONTS.BIG, nil, 0.7, nil, 0.2)
		local replayManageInfoView = UIElement:new({
			parent = manageView,
			pos = { 10, manageTitle.size.h },
			size = { manageView.size.w - 20, manageView.size.h * 7 / 8 - manageTitle.size.h }
		})
		
		
		local _, dirlevel = replay.filename:gsub("/", "")
		local replayData = {
			{
				name = TB_MENU_LOCALIZED.FILENAME,
				sysname = "filename",
				value = { replay.filename:gsub("^.*/", ""):gsub("%.rpl$", "") },
				input = true
			},
			{
				name = TB_MENU_LOCALIZED.REPLAYSREPLAYNAME,
				sysname = "rpltitle",
				value = { replay.name },
				input = true
			},
			{
				name = TB_MENU_LOCALIZED.REPLAYSREPLAYDIR,
				sysname = "dir",
				dirlevel = dirlevel,
				value = dirlevel == 0 and "replay" or "replay/" .. replay.filename:gsub("/[^/]+$", ""),
				dropdown = true,
				data = Replays:getReplayFolders()
			}
		}
		
		
		posY, elementHeight = 0, 50
		for i,v in pairs(replayData) do
			local replayManageInfoHolder = UIElement:new({
				parent = replayManageInfoView,
				pos = { 0, posY },
				size = { replayManageInfoView.size.w, elementHeight }
			})
			local replayManageInfoNameTitle = UIElement:new({
				parent = replayManageInfoHolder,
				pos = { 0, 0 },
				size = { replayManageInfoHolder.size.w / 3, replayManageInfoHolder.size.h }
			})
			replayManageInfoNameTitle:addCustomDisplay(true, function()
					replayManageInfoNameTitle:uiText(v.name, nil, nil, nil, LEFTMID)
				end)
			local replayManageInfoDataField = UIElement:new({
				parent = replayManageInfoHolder,
				pos = { replayManageInfoHolder.size.w * 2 / 5, 0 },
				size = { replayManageInfoHolder.size.w * 3 / 5, replayManageInfoHolder.size.h }
			})
			if (v.input) then
				local replayManageInfoDataInputBG = UIElement:new({
					parent = replayManageInfoDataField,
					pos = { 10, 10 },
					size = { replayManageInfoDataField.size.w - 20, 30 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				local replayManageInfoDataInputOverlay = UIElement:new({
					parent = replayManageInfoDataInputBG,
					pos = { 1, 1 },
					size = { replayManageInfoDataInputBG.size.w - 2, replayManageInfoDataInputBG.size.h - 2 },
					bgColor = { 1, 1, 1, 0.5 }
				})
				local replayManageInfoDataInput = UIElement:new({
					parent = replayManageInfoDataInputOverlay,
					pos = { 10, 5 },
					size = { replayManageInfoDataInputOverlay.size.w - 20, replayManageInfoDataInputOverlay.size.h - 10 },
					interactive = true,
					textfield = true,
					textfieldstr = v.value,
					textfieldsingleline = true
				})
				replayManageInfoDataInput:addMouseHandlers(function()
						TBMenu:enableMenuKeyboard(replayManageInfoDataInput)
					end)
				TBMenu:displayTextfield(replayManageInfoDataInput, FONTS.SMALL, nil, UICOLORBLACK, v.tip)
			elseif (v.dropdown) then
				local replayManageInfoDataDropdownButtonBG = UIElement:new({
					parent = replayManageInfoDataField,
					pos = { 10, 10 },
					size = { replayManageInfoDataField.size.w - 20, 30 },
					bgColor = { 0, 0, 0, 0.5}
				})
				local replayManageInfoDataDropdownButton = UIElement:new({
					parent = replayManageInfoDataDropdownButtonBG,
					pos = { 1, 1 },
					size = { replayManageInfoDataDropdownButtonBG.size.w - 2, replayManageInfoDataDropdownButtonBG.size.h - 2 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = { 1, 0.7, 0.7, 0.6 }
				})
				local replayManageInfoDataDropdownButtonText = UIElement:new({
					parent = replayManageInfoDataDropdownButton,
					pos = { 10, 0 },
					size = { replayManageInfoDataDropdownButton.size.w - 20, replayManageInfoDataDropdownButton.size.h }
				})
				replayManageInfoDataDropdownButtonText:addCustomDisplay(false, function()
						replayManageInfoDataDropdownButtonText:uiText(v.value, nil, nil, 4, LEFTMID, 0.7)
					end)
				replayManageInfoDataDropdownButton:addMouseHandlers(nil, function()
						Replays:showFolderDropdown(replayManageInfoDataDropdownButtonBG, v)
					end)
			end
			
			posY = posY + elementHeight
		end
		
		local cancelButton = UIElement:new({
			parent = manageView,
			pos = { 10, -50 },
			size = { manageView.size.w / 2 - 40, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addCustomDisplay(false, function()
				cancelButton:uiText(TB_MENU_LOCALIZED.BUTTONCANCEL)
			end)
		cancelButton:addMouseHandlers(nil, function()
				manageOverlay:kill()
			end)
		local saveButton = UIElement:new({
			parent = manageView,
			pos = { manageView.size.w / 2 - 20, -50 },
			size = { manageView.size.w / 2 - 40, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		saveButton:addCustomDisplay(false, function()
				saveButton:uiText(TB_MENU_LOCALIZED.BUTTONSAVE)
			end)
		saveButton:addMouseHandlers(nil, function()
				local errors = 0
				local fileMove = false
				local newDirectory = nil
				local newReplay = cloneTable(replay)
				
				for i, v in pairs(tableReverse(replayData)) do
					if (v.sysname == "dir") then
						local directory = v.dirlevel == 0 and "replay" or "replay/" .. replay.filename:gsub("/.+$", "")
						if (directory ~= v.value) then
							fileMove = true
							newDirectory = v.value == "replay" and "" or v.value .. "/"
						end
					elseif (v.sysname == "rpltitle") then
						if (v.value[1] ~= replay.name) then
							newReplay.name = v.value[1]
						end
					elseif (v.sysname == "filename") then
						if (v.value[1] ~= replay.filename:gsub("^.*/", ""):gsub("%.rpl$", "") or fileMove) then
							local fileDirectory = replay.filename:find("/") and replay.filename:gsub("/.+$", "/") or "" 
							local newname = (newDirectory or fileDirectory) .. v.value[1] .. ".rpl"
							if (not fileMove) then
								local result = rename_replay(replay.filename, newname)
								if (result) then
									errors = errors + 1
									TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORRENAMINGREPLAY .. ": " .. result)
								else
									newReplay.filename = newname
								end
							else
								local result = move_replay(replay.filename, newname)
								if (result) then
									errors = errors + 1
									TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORMOVINGREPLAY .. ": " .. result)
								else
									newReplay.filename = newname
									SELECTED_FOLDER = { fullname = "replay/" .. newDirectory:gsub("/$", "") }
								end
							end
						end
					end
				end
				if (errors == 0) then
					Replays:updateReplayCache(replay, newReplay)
					manageOverlay:kill()
					SELECTED_REPLAY.replay = newReplay
					Replays:showMain(tbMenuCurrentSection)
				end
			end)
			
		local deleteButton = UIElement:new({
			parent = manageView,
			pos = { -50, -50 },
			size = { 40, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 },
			bgImage = "../textures/menu/general/buttons/trash.tga"
		})
		deleteButton:addMouseHandlers(nil, function()
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSCONFIRMDELETION .. " " .. replay.filename .. " " .. TB_MENU_LOCALIZED.REPLAYSCONFIRMDELETION2, function()
						local result = delete_replay(replay.filename)
						if (result) then
							TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORDELETING .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY)
							return
						end
						manageOverlay:kill()
						Replays:updateReplayCache(replay, nil)
						SELECTED_REPLAY.replay = nil
						Replays:showMain(tbMenuCurrentSection)
					end)
			end)
	end
	
	function Replays:canUploadReplay(replay)
		if (replay.uploaded == 1) then
			return false
		end
		
		local isInReplay = false
		if (replay.author == TB_MENU_PLAYER_INFO.username) then
			isInReplay = true
		end
		for i,v in pairs(replay.bouts) do
			if (v == TB_MENU_PLAYER_INFO.username) then
				isInReplay = true
			end
		end
		return isInReplay
	end
	
	function Replays:showAutosaveToggle(viewElement)
		local autosaveStatus = get_option("autosave")
		local autosaveView = UIElement:new({
			parent = viewElement,
			pos = { 10, -viewElement.size.h / 8 },
			size = { viewElement.size.w - 20, viewElement.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		local autosaveCheckbox = UIElement:new({
			parent = autosaveView,
			pos = { 0, 0 },
			size = { autosaveView.size.h, autosaveView.size.h }
		})
		autosaveView:addCustomDisplay(true, function()
				if (autosaveView.hoverState == BTN_DN) then
					set_color(unpack(autosaveView.pressedColor))
				else
					set_color(unpack(autosaveView.animateColor))
				end
				draw_quad(	autosaveView.pos.x + autosaveCheckbox.shift.x,
							autosaveView.pos.y + autosaveCheckbox.shift.y,
							autosaveCheckbox.size.w,
							autosaveCheckbox.size.h	)
			end)
		local autosaveIcon = UIElement:new({
			parent = autosaveCheckbox,
			pos = { 2, 2 },
			size = { autosaveCheckbox.size.w - 4, autosaveCheckbox.size.h - 4 },
			bgImage = "../textures/menu/general/buttons/checkmark.tga"
		})
		if (autosaveStatus == 0) then
			autosaveIcon:hide()
		end
		autosaveView:addMouseHandlers(nil, function()
				autosaveStatus = 1 - autosaveStatus
				set_option("autosave", autosaveStatus)
				if (autosaveStatus == 1) then
					autosaveIcon:show()
				else
					autosaveIcon:hide()
				end
			end)
		local autosaveText = UIElement:new({
			parent = autosaveView,
			pos = { 50, 0 },
			size = { autosaveView.size.w - 60, autosaveView.size.h }
		})
		autosaveText:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSAUTOSAVEOPTION)
	end
	
	function Replays:showReplayInfo(viewElement, replay)
		viewElement:kill(true)
		local bottomSmudge = TBMenu:addBottomBloodSmudge(viewElement, 2)
		if (not replay) then
			local heightMod = 0
			if (SELECTED_FOLDER.fullname == "replay/autosave") then
				Replays:showAutosaveToggle(viewElement)
				heightMod = viewElement.size.h / 8
			end
			local noReplaysFound = UIElement:new({
				parent = viewElement,
				pos = { 10, 10 },
				size = { viewElement.size.w - 20, viewElement.size.h - 20 - heightMod }
			})
			noReplaysFound:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSEMPTYFOLDER)
			return
		end
		
		SELECTED_REPLAY.replay = replay
		SELECTED_REPLAY.element.bgColor = { 1, 1, 1, 0.3 }
		
		local replayName = UIElement:new({
			parent = viewElement,
			pos = { 10, 0 },
			size = { viewElement.size.w - 20, viewElement.size.h / 8 }
		})
		replayName:addAdaptedText(true, replay.name, nil, nil, FONTS.BIG, nil, 0.65, 0.4, 0.2)
		local replayAuthor = UIElement:new({
			parent = viewElement,
			pos = { 10, replayName.shift.y + replayName.size.h },
			size = { viewElement.size.w - 20, viewElement.size.h / 10 }
		})
		local replayAuthorStr = replay.author == "autosave" and "autosave" or TB_MENU_LOCALIZED.REPLAYSBY .. " " .. replay.author
		replayAuthor:addCustomDisplay(true, function()
				replayAuthor:uiText(replayAuthorStr, nil, nil, 4, nil, 0.8)
			end)
		local replayBouts = UIElement:new({
			parent = viewElement,
			pos = { 10, replayAuthor.shift.y + replayAuthor.size.h },
			size = { viewElement.size.w - 20, viewElement.size.h / 16 }
		})
		local replayBoutsStr = replay.bouts[1] ~= " " and replay.bouts[1] or TB_MENU_LOCALIZED.REPLAYSDATACORRUPT
		for i = 2, #replay.bouts do
			replayBoutsStr = replay.bouts[i] ~= " " and replayBoutsStr .. " " .. TB_MENU_LOCALIZED.WORDVS .. " " .. replay.bouts[i] or replayBoutsStr
		end
		replayBouts:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSPLAYERS .. ": " .. replayBoutsStr, nil, nil, 4, LEFTBOT, 0.7)
		local replayMod = UIElement:new({
			parent = viewElement,
			pos = { 10, replayBouts.shift.y + replayBouts.size.h },
			size = { viewElement.size.w - 20, viewElement.size.h / 16 }
		})
		replayMod:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSMOD .. ": " .. replay.mod, nil, nil, 4, LEFTMID, 0.7)
		local replayTags = UIElement:new({
			parent = viewElement,
			pos = { 10, replayMod.shift.y + replayMod.size.h },
			size = { viewElement.size.w - 20, viewElement.size.h / 8 }
		})
		local tagsText = replay.tags == " " and TB_MENU_LOCALIZED.WORDNONE or replay.tags
		replayTags:addCustomDisplay(true, function()
				replayTags:uiText(TB_MENU_LOCALIZED.REPLAYSTAGS .. ": " .. tagsText, nil, nil, 4, LEFT, 0.7)
			end)
			
		local tagsAdapted = textAdapt(TB_MENU_LOCALIZED.REPLAYSTAGS .. ": " .. tagsText, 4, 0.7, viewElement.size.w - 20)
		local tagsDispositionX = get_string_length(tagsAdapted[#tagsAdapted], 4) * 0.7
		local tagsDispositionY = math.ceil((#tagsAdapted - 1) * 16.8) + 1
		local linesBack = 0
		while (tagsDispositionY + 18 > replayTags.size.h) do
			tagsDispositionY = tagsDispositionY - 18
			linesBack = linesBack + 1
			tagsDispositionX = get_string_length(tagsAdapted[#tagsAdapted - linesBack], 4) * 0.7
		end
		if (tagsDispositionX + 10 > replayTags.size.w) then
			tagsDispositionX = 0
			tagsDispositionY = tagsDispositionY + 18
		end
		local replayTagsAdd = UIElement:new({
			parent = replayTags,
			pos = { tagsDispositionX, tagsDispositionY },
			size = { 18, 18 },
			shapeType = ROUNDED,
			rounded = 3,
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		replayTagsAdd:addCustomDisplay(false, function()
				set_color(1, 1, 1, 0.8)
				draw_quad(	replayTagsAdd.pos.x + replayTagsAdd.size.w / 2 - 1,
							replayTagsAdd.pos.y + 4,
							2,
							replayTagsAdd.size.h - 8	)
				draw_quad(	replayTagsAdd.pos.x + 4,
							replayTagsAdd.pos.y + replayTagsAdd.size.h / 2 - 1,
							replayTagsAdd.size.w - 8,
							2	)
			end)
		replayTagsAdd:addMouseHandlers(false, function()
				Replays:showTags(viewElement, replay)
			end)
		
		local posY = 0
		if (SELECTED_FOLDER.fullname == "replay/autosave") then
			Replays:showAutosaveToggle(viewElement)
			posY = -viewElement.size.h / 8
		end
		
		local replayManageButton = UIElement:new({
			parent = viewElement,
			pos = { 10, -viewElement.size.h / 8 + posY },
			size = { viewElement.size.w - 20, viewElement.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.3 }
		})
		replayManageButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSMANAGE)
		replayManageButton:addMouseHandlers(nil, function()
				Replays:showReplayManageWindow(viewElement, replay)
			end)
		posY = replayManageButton.shift.y
		
		if (Replays:canUploadReplay(replay)) then
			local replayUploadButton = UIElement:new({
				parent = viewElement,
				pos = { 10, -viewElement.size.h / 8 + posY },
				size = { viewElement.size.w - 20, viewElement.size.h / 10 },
				interactive = not replay.uploaded,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.3 }
			})
			replayUploadButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONUPLOAD)
			replayUploadButton:addMouseHandlers(nil, function()
					Replays:showUploadWindow(viewElement, replay)
				end)
			posY = replayUploadButton.shift.y
		end
			
		local replayViewButton = UIElement:new({
			parent = viewElement,
			pos = { 10, -viewElement.size.h / 8 + posY },
			size = { viewElement.size.w - 20, viewElement.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.3 }
		})
		replayViewButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONVIEW)
		replayViewButton:addMouseHandlers(nil, function()
				Replays:playReplay(replay)
			end)
	end
	
	function Replays:showSearchWindow()
		local searchOverlay = TBMenu:spawnWindowOverlay()
		local searchView = UIElement:new({
			parent = searchOverlay,
			pos = { searchOverlay.size.w / 6, searchOverlay.size.h / 2 - 200 },
			size = { searchOverlay.size.w / 3 * 2, 400 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local searchTitle = UIElement:new({
			parent = searchView,
			pos = { 10, 0 },
			size = { searchView.size.w - 20, 50 }
		})
		searchTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYTITLEINFO, nil, nil, FONTS.BIG, nil, 0.65)
		
		local searchByDate = UIElement:new({
			parent = searchView,
			pos = { 10, searchTitle.shift.y + searchTitle.size.h + 10 },
			size = { (searchView.size.w - 30) / 2, 70 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }			
		})
		searchByDate:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSFILTERSDATE)
		searchByDate:addMouseHandlers(nil, function()
				searchOverlay:kill()
				Replays:getServerReplays(1, 1)
			end)
		
		--[[local searchByRating = UIElement:new({
			parent = searchView,
			pos = { searchByDate.shift.x + searchByDate.size.w + 10, searchTitle.shift.y + searchTitle.size.h + 10 },
			size = { (searchView.size.w - 40) / 3, 70 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }			
		})
		searchByRating:addAdaptedText(false, "By rating")
		searchByRating:addMouseHandlers(nil, function()
				searchOverlay:kill()
				Replays:getServerReplays(2, 1)
			end)]]
		
		local searchByPopularity = UIElement:new({
			parent = searchView,
			pos = { searchByDate.shift.x + searchByDate.size.w + 10, searchTitle.shift.y + searchTitle.size.h + 10 },
			size = { (searchView.size.w - 30) / 2, 70 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }			
		})
		searchByPopularity:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSFILTERSPOPULARITY)
		searchByPopularity:addMouseHandlers(nil, function()
				searchOverlay:kill()
				Replays:getServerReplays(3, 1)
			end)
			
		local searchByTagTitle = UIElement:new({
			parent = searchView,
			pos = { 10, searchByDate.shift.y + searchByDate.size.h + 20 },
			size = { searchView.size.w - 20, 25 }
		})
		searchByTagTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSFILTERSBYTAG, nil, nil, nil, LEFTMID)
		local searchByTagView = UIElement:new({
			parent = searchView,
			pos = { 10, searchByTagTitle.shift.y + searchByTagTitle.size.h + 5 },
			size = { searchView.size.w - 20, 40 }
		})
		local searchByTagInputBG = UIElement:new({
			parent = searchByTagView,
			pos = { 0, 0 },
			size = { searchByTagView.size.w - 160, searchByTagView.size.h },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local searchByTagInputOverlay = UIElement:new({
			parent = searchByTagInputBG,
			pos = { 1, 1 },
			size = { searchByTagInputBG.size.w - 2, searchByTagInputBG.size.h - 2 },
			bgColor = { 1, 1, 1, 0.4 },
		})
		local searchByTagInput = UIElement:new({
			parent = searchByTagInputOverlay,
			pos = { 10, 0 },
			size = { searchByTagInputOverlay.size.w - 20, searchByTagInputOverlay.size.h },
			interactive = true,
			textfield = true,
			textfieldsingleline = true
		})
		searchByTagInput:addMouseHandlers(function()
				TBMenu:enableMenuKeyboard(searchByTagInput)
			end)
		TBMenu:displayTextfield(searchByTagInput, 4, 0.7, UICOLORBLACK, TB_MENU_LOCALIZED.SEARCHNOTE)
		local searchByTagButton = UIElement:new({
			parent = searchByTagView,
			pos = { searchByTagInputBG.size.w + 10, 0 },
			size = { searchByTagView.size.w - searchByTagInputBG.size.w - 10, searchByTagView.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		searchByTagButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSEARCH)
		searchByTagButton:addMouseHandlers(nil, function()
				searchOverlay:kill()
				Replays:getServerReplays(4, 1, searchByTagInput.textfieldstr[1])
			end)
		
		local searchByUserTitle = UIElement:new({
			parent = searchView,
			pos = { 10, searchByTagView.shift.y + searchByTagView.size.h + 20 },
			size = { searchView.size.w - 20, 25 }
		})
		searchByUserTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSFILTERSUPLOADER, nil, nil, nil, LEFTMID)
		local searchByUserView = UIElement:new({
			parent = searchView,
			pos = { 10, searchByUserTitle.shift.y + searchByUserTitle.size.h + 5 },
			size = { searchView.size.w - 20, 40 }
		})
		local searchByUserInputBG = UIElement:new({
			parent = searchByUserView,
			pos = { 0, 0 },
			size = { searchByUserView.size.w - 160, searchByUserView.size.h },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local searchByUserInputOverlay = UIElement:new({
			parent = searchByUserInputBG,
			pos = { 1, 1 },
			size = { searchByUserInputBG.size.w - 2, searchByUserInputBG.size.h - 2 },
			bgColor = { 1, 1, 1, 0.4 },
		})
		local searchByUserInput = UIElement:new({
			parent = searchByUserInputOverlay,
			pos = { 10, 0 },
			size = { searchByUserInputOverlay.size.w - 20, searchByUserInputOverlay.size.h },
			interactive = true,
			textfield = true,
			textfieldsingleline = true
		})
		searchByUserInput:addMouseHandlers(function()
				TBMenu:enableMenuKeyboard(searchByUserInput)
			end)
		TBMenu:displayTextfield(searchByUserInput, 4, 0.7, UICOLORBLACK, TB_MENU_LOCALIZED.SEARCHNOTE)
		local searchByUserButton = UIElement:new({
			parent = searchByUserView,
			pos = { searchByUserInputBG.size.w + 10, 0 },
			size = { searchByUserView.size.w - searchByUserInputBG.size.w - 10, searchByUserView.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		searchByUserButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSEARCH)
		searchByUserButton:addMouseHandlers(nil, function()
				searchOverlay:kill()
				Replays:getServerReplays(5, 1, searchByUserInput.textfieldstr[1])
			end)
		
		local cancelButton = UIElement:new({
			parent = searchView,
			pos = { searchView.size.w / 4, -50 },
			size = { searchView.size.w / 2, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
		cancelButton:addMouseHandlers(nil, function()
				searchOverlay:kill()
			end)
	end
	
	function Replays:showServerReplayPreview()
		local previewOverlay = TBMenu:spawnWindowOverlay()
		local previewView = UIElement:new({
			parent = previewOverlay,
			pos = { previewOverlay.size.w / 3, previewOverlay.size.h / 2 - 50 },
			size = { previewOverlay.size.w / 3, 100 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSDOWNLOADINGREPLAY)
		local downloadWait = UIElement:new({
			parent = previewView,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		
		local frames = 0
		local replayFile = nil
		downloadWait:addCustomDisplay(true, function()
				frames = frames + 1
				if (frames == 10) then
					replayFile = Files:new("../replay/downloads/" .. REPLAY_TEMPNAME .. ".rpl", FILES_MODE_READONLY)
				end
				if (replayFile) then
					if (not replayFile:isDownloading()) then
						replayFile:close()
						local replaydata = Replays:getReplayInfo(replayFile.path)
						if (replaydata.mod ~= "classic") then
							local files = get_files("data/mod", "")
							local folders = {}
							for i,v in pairs(files) do
								if (not v:find("^%.+[%s%S]*$") and not v:find("%.%a+$") and not v:find("^.*%.tbm$")) then
									table.insert(folders, v)
								end
							end
							local modFile = Files:new("../data/mod/" .. replaydata.mod)
							local id = 1
							while (not modFile.data and id < #folders) do
								modFile = Files:new("../data/mod/" .. folders[id] .. "/" .. replaydata.mod)
								id = id + 1
							end
							if (not modFile.data) then
								modFile = Files:new("../data/mod/downloads/" .. replaydata.mod)
								previewView:addAdaptedText(false, TB_MENU_LOCALIZED.MODSDOWNLOADINGMOD)
								local modname = replaydata.mod:gsub("%.tbm$", "")
								download_mod(modname)
								local wait = 0
								downloadWait:addCustomDisplay(true, function()
										wait = wait + 1
										if (not modFile:isDownloading() and wait > 5) then
											previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
											local framesN = 0
											downloadWait:addCustomDisplay(true, function()
													framesN = framesN + 1
													if (framesN > 4) then
														UIElement:runCmd("loadreplay downloads/" .. REPLAY_TEMPNAME .. ".rpl")
														close_menu()
													end
												end)
										end
									end)
							else
								modFile:close()
								downloadWait:addCustomDisplay(false, function()
										previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
										local framesN = 0
										downloadWait:addCustomDisplay(true, function()
												framesN = framesN + 1
												if (framesN > 4) then
													UIElement:runCmd("loadreplay downloads/" .. REPLAY_TEMPNAME .. ".rpl")
													close_menu()
												end
											end)
									end)
							end
						else
							local wait = 0
							downloadWait:addCustomDisplay(false, function()
									previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
									local framesN = 0
									downloadWait:addCustomDisplay(true, function()
											framesN = framesN + 1
											if (framesN > 4) then
												UIElement:runCmd("loadreplay downloads/" .. REPLAY_TEMPNAME .. ".rpl")
												close_menu()
											end
										end)
								end)
						end
					end
				end
			end)
	end
	
	function Replays:showReplayDownloadPopup(rplname)
		local notificationView = UIElement:new({
			parent = tbMenuMain,
			pos = { tbMenuMain.size.w / 3, -60 },
			size = { tbMenuMain.size.w / 3, 60 },
			bgColor = { 0, 0, 0, 0.8 }
		})
		notificationView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSDOWNLOADINGREPLAY, nil, nil, nil, nil, nil, nil, nil, nil, { 1, 1, 1, notificationView.bgColor[4] })
		
		local downloadWait = UIElement:new({
			parent = notificationView,
			pos = { 0, 0 },
			size = { 0, 0 }
		})		
		local frames = 0
		local replayFile = nil
		downloadWait:addCustomDisplay(true, function()
				frames = frames + 1
				if (frames == 10) then
					replayFile = Files:new("../replay/downloads/" .. rplname .. ".rpl", FILES_MODE_READONLY)
				end
				if (replayFile) then
					if (not replayFile:isDownloading()) then
						replayFile:close()
						notificationView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSREPLAYSAVEDINFO, nil, nil, nil, nil, nil, nil, nil, nil, { 1, 1, 1, notificationView.bgColor[4] })
						local framesN = 0
						downloadWait:addCustomDisplay(true, function()
								framesN = framesN + 1
								if (framesN > 30) then
									notificationView.bgColor[4] = notificationView.bgColor[4] - 0.05
									notificationView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSREPLAYSAVEDINFO, nil, nil, nil, nil, nil, nil, nil, nil, { 1, 1, 1, notificationView.bgColor[4] })
								end
								if (notificationView.bgColor[4] <= 0) then
									notificationView:kill()
								end
							end)
					end
				end
			end)
	end
	
	function Replays:showServerReplayList(replaysList, replayInfo)
		SELECTED_SERVER_REPLAY.element = nil
		SELECTED_SERVER_REPLAY.replay = nil
		SELECTED_SERVER_REPLAY.displayid = nil
		
		local posX, elementHeight = 0, 25
		local toReload, topBar, botBar, replayListing, replayHolder, scrollBG = TBMenu:prepareScrollableList(replaysList, 50, 35, 20)
		TBMenu:addBottomBloodSmudge(botBar, 1)
		
		local helpButton = UIElement:new({
			parent = topBar,
			pos = { 10, 10 },
			size = { topBar.size.h - 20, topBar.size.h - 20 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.2 },
			hoverColor = { 1, 1, 1, 0.2 },
			pressedColor = { 1, 1, 1, 0.2 },
			shapeType = ROUNDED,
			rounded = topBar.size.h
		})
		TBMenu:displayHelpPopup(helpButton, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYDOUBLECLICKINFO, true)
		
		local listTitle = UIElement:new({
			parent = topBar,
			pos = { helpButton.shift.x + helpButton.size.w + 10, 0 },
			size = { topBar.size.w - 20 - helpButton.shift.x - helpButton.size.w, topBar.size.h }
		})
		if (SERVER_REPLAYS.total == 0) then
			listTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYNOFOUND, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.2)
		else
			local currentPage, totalPages = math.ceil(SERVER_REPLAYS.offset / 100), math.floor(SERVER_REPLAYS.total / 100)
			listTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSREPLAYS .. " " .. SERVER_REPLAYS.info .. ": " .. TB_MENU_LOCALIZED.PAGINATIONPAGE .. " " .. currentPage .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF .. " " .. totalPages, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.2)
		end
		
		local replayElements = {}
		local tempHolder = nil
		if (SERVER_REPLAYS.offset > 1) then
			local offset = SERVER_REPLAYS.offset - 100 > 0 and SERVER_REPLAYS.offset - 100 or 1
			local offsetDecrementButton = UIElement:new({
				parent = replayHolder,
				pos = { 0, posX },
				size = { replayHolder.size.w, elementHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			table.insert(replayElements, offsetDecrementButton)
			offsetDecrementButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADPREVIOUS .. " " .. SERVER_REPLAYS.offset - offset .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAYS:upper(), nil, nil, 4, nil, 0.7)
			offsetDecrementButton:addMouseHandlers(nil, function()
					Replays:getServerReplays(SERVER_REPLAYS.action, offset, SERVER_REPLAYS.search)
				end)
			posX = posX + elementHeight
		end
		for i,v in pairs(SERVER_REPLAYS) do
			if (type(i) == "number") then
				local replayElementHolder = UIElement:new({
					parent = replayHolder,
					pos = { 0, posX },
					size = { replayHolder.size.w, elementHeight * 2 },
					interactive = true,
					bgColor = i % 2 == 1 and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = { 0, 0, 0, 0.3 },
					pressedColor = { 1, 1, 1, 0.2 }
				})
				if (i == 1) then
					tempHolder = replayElementHolder
				end
				local dispid = #replayElements
				if (v.id == SELECTED_SERVER_REPLAY.id) then
					SELECTED_SERVER_REPLAY = { element = replayElementHolder, color = { unpack(replayElementHolder.bgColor) }, id = v.id, replay = v, displayid = dispid }
					replayElementHolder.bgColor = replayElementHolder.pressedColor
				end
				replayElementHolder:addCustomDisplay(true, function()
						if (replayElementHolder.pos.y < topBar.pos.y or replayElementHolder.pos.y > botBar.pos.y) then
							replayElementHolder:deactivate()
						else
							replayElementHolder:activate()
						end
					end)
				local replayElement = UIElement:new({
					parent = replayHolder,
					pos = { 0, posX },
					size = { replayHolder.size.w, elementHeight }
				})
				table.insert(replayElements, replayElement)
				posX = posX + elementHeight
				local replayName = UIElement:new({
					parent = replayElement,
					pos = { 10, 0 },
					size = { replayElement.size.w / 2 - 20, replayElement.size.h }
				})
				replayName:addAdaptedText(true, v.rplname, nil, nil, 4, LEFTMID, 0.65)
				local nameSeparator = UIElement:new({
					parent = replayName,
					pos = { replayName.size.w + replayName.shift.x / 2, replayName.size.h / 4 },
					size = { 1, replayName.size.h / 2 },
					bgColor = { 1, 1, 1, 0.2 }
				})
				local replayRating = UIElement:new({
					parent = replayElement,
					pos = { replayName.shift.x * 2 + replayName.size.w, 0 },
					size = { (replayElement.size.w - replayName.size.w - replayName.shift.x * 5) / 3, replayElement.size.h }
				})
				Replays:showReplayRating(replayRating, v.score, v.votes)
				local ratingSeparator = UIElement:new({
					parent = replayRating,
					pos = { replayRating.size.w + replayName.shift.x / 2, replayRating.size.h / 4 },
					size = { 1, replayRating.size.h / 2 },
					bgColor = { 1, 1, 1, 0.2 }
				})
				local replayUploader = UIElement:new({
					parent = replayElement,
					pos = { -(replayRating.size.w + replayName.shift.x) * 2, 0 },
					size = { replayRating.size.w, replayElement.size.h }
				})
				replayUploader:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSBY .. " " .. v.uploader, nil, nil, 4, nil, 0.65)
				local uploaderSeparator = UIElement:new({
					parent = replayUploader,
					pos = { replayUploader.size.w + replayName.shift.x / 2, replayUploader.size.h / 4 },
					size = { 1, replayUploader.size.h / 2 },
					bgColor = { 1, 1, 1, 0.2 }
				})
				local replayDate = UIElement:new({
					parent = replayElement,
					pos = { -(replayRating.size.w + replayName.shift.x), 0 },
					size = { replayUploader.size.w, replayElement.size.h }
				})
				replayDate:addAdaptedText(true, v.date, nil, nil, 4, nil, 0.65)
				local replayTags = UIElement:new({
					parent = replayHolder,
					pos = { 0, posX },
					size = { replayHolder.size.w, elementHeight }
				})
				replayElement:addCustomDisplay(true, function()
						if ((replayElementHolder.hoverState == BTN_DN and replayTags:isDisplayed()) or (replayElementHolder.hoverState == BTN_DN and MOUSE_Y <= replayElement.pos.y + replayElement.size.h)) then
							set_color(unpack(replayElementHolder.pressedColor))
						elseif (MOUSE_Y > replayElement.pos.y + replayElement.size.h and not replayTags:isDisplayed()) then
							set_color(unpack(replayElementHolder.bgColor))
						else
							set_color(unpack(replayElementHolder.animateColor))
						end
						draw_quad(replayElement.pos.x, replayElement.pos.y, replayElement.size.w, replayElement.size.h)
					end)
				replayTags:addCustomDisplay(true, function()
						if ((replayElementHolder.hoverState == BTN_DN and replayElement:isDisplayed()) or (replayElementHolder.hoverState == BTN_DN and MOUSE_Y >= replayTags.pos.y)) then
							set_color(unpack(replayElementHolder.pressedColor))
						elseif (MOUSE_Y < replayTags.pos.y and not replayElement:isDisplayed()) then
							set_color(unpack(replayElementHolder.bgColor))
						else
							set_color(unpack(replayElementHolder.animateColor))
						end
						draw_quad(replayTags.pos.x, replayTags.pos.y, replayTags.size.w, replayTags.size.h)
					end)
				replayElementHolder.lastPress = 0
				replayElementHolder:addMouseHandlers(nil, function(s, x, y) 
						if (y < botBar.pos.y and y > topBar.pos.y + topBar.size.h) then
							if (os.clock() - replayElementHolder.lastPress < 0.5) then
								download_replay(v.id, REPLAY_TEMPNAME)
								Replays:showServerReplayPreview()
								return
							end
							replayElementHolder.lastPress = os.clock()
							if (SELECTED_SERVER_REPLAY.element) then
								SELECTED_SERVER_REPLAY.element.bgColor = { unpack(SELECTED_SERVER_REPLAY.color) }
							end
							SELECTED_SERVER_REPLAY = { element = replayElementHolder, color = { unpack(replayElementHolder.bgColor) }, id = v.id, replay = v, displayid = dispid }
							replayElementHolder.bgColor = replayElementHolder.pressedColor
							Replays:showServerReplayInfo(replayInfo, v)
						end 
					end)
				table.insert(replayElements, replayTags)
				posX = posX + replayTags.size.h
				local replayTagsStr = UIElement:new({
					parent = replayTags,
					pos = { 10, 0 },
					size = { replayTags.size.w / 6 * 5 - 20, replayTags.size.h }
				})
				replayTagsStr:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSTAGS .. ": " .. v.tags, nil, nil, 4, LEFTMID, 0.6)
				local replayDownloads = UIElement:new({
					parent = replayTags,
					pos = { -replayTags.size.w / 6, 0 },
					size = { replayTags.size.w / 6 - 20, replayTags.size.h }
				})
				replayDownloads:addAdaptedText(true, v.downloads .. (v.downloads == 1 and " " .. TB_MENU_LOCALIZED.REPLAYSDOWNLOAD or " " .. TB_MENU_LOCALIZED.REPLAYSDOWNLOADS), nil, nil, 4, RIGHTMID, 0.6)
			end
		end
		if (SERVER_REPLAYS.offset + 100 < SERVER_REPLAYS.total) then
			local offsetIncrementButton = UIElement:new({
				parent = replayHolder,
				pos = { 0, posX },
				size = { replayHolder.size.w, elementHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			table.insert(replayElements, offsetIncrementButton)
			offsetIncrementButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADNEXT .. " " .. (SERVER_REPLAYS.total - SERVER_REPLAYS.offset >= 100 and 100 or SERVER_REPLAYS.total - SERVER_REPLAYS.offset) .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAYS:upper(), nil, nil, 4, nil, 0.7)
			offsetIncrementButton:addMouseHandlers(nil, function()
					Replays:getServerReplays(SERVER_REPLAYS.action, SERVER_REPLAYS.offset + 100, SERVER_REPLAYS.search)
				end)
		end
		for i,v in pairs(replayElements) do
			v:hide()
		end
		
		local scrollBar = TBMenu:spawnScrollBar(replayHolder, #replayElements, elementHeight)
		if (SERVER_REPLAYS.total > 0) then
			scrollBar:makeScrollBar(replayHolder, replayElements, toReload)
		end
		
		if (SELECTED_SERVER_REPLAY.displayid and replayHolder.size.h < elementHeight * 2 * SELECTED_SERVER_REPLAY.displayid) then
			scrollBar.btnDown(4, 0, -SELECTED_SERVER_REPLAY.displayid)
		end
		
		if (not SELECTED_SERVER_REPLAY.replay) then
			SELECTED_SERVER_REPLAY = { element = tempHolder, color = { unpack(tempHolder.bgColor) }, id = SERVER_REPLAYS[1].id, replay = SERVER_REPLAYS[1], displayid = 1 }
			tempHolder.bgColor = tempHolder.pressedColor
		end
		Replays:showServerReplayInfo(replayInfo, SELECTED_SERVER_REPLAY.replay)
	end
	
	function Replays:showReplayRating(viewElement, score, votes, uservote)
		local votes = votes
		local score = score
		local scale = math.floor(viewElement.size.w / 5 > viewElement.size.h and viewElement.size.h or viewElement.size.w / 5)
		local displaynum = votes > 0 and math.floor(score / votes + 0.5) or 0
		local leftShift = (viewElement.size.w - scale * 5) / 2
		local uservote = uservote or 0
		
		for i = 1, displaynum do
			local ratingStar = UIElement:new({
				parent = viewElement,
				pos = { leftShift + (i - 1) * scale, (viewElement.size.h - scale) / 2 },
				size = { scale, scale },
				bgImage = scale > 32 and "../textures/menu/general/buttons/star.tga" or "../textures/menu/general/buttons/startiny.tga"
			})
			if (uservote >= i) then
				local ratingSign = UIElement:new({
					parent = ratingStar,
					pos = { 0, 0 },
					size = { ratingStar.size.w, ratingStar.size.h },
					bgImage = "../textures/menu/general/buttons/starborderglow.tga"
				})
			end
		end
		for i = displaynum + 1, 5 do
			local ratingStarTransparent = UIElement:new({
				parent = viewElement,
				pos = { leftShift + (i - 1) * scale, (viewElement.size.h - scale) / 2 },
				size = { scale, scale },
				bgImage = uservote >= i and "../textures/menu/general/buttons/starborderglow.tga" or (scale > 32 and "../textures/menu/general/buttons/starborder.tga" or "../textures/menu/general/buttons/starbordertiny.tga")
			})
		end
	end
	
	function Replays:showReplayRatingVote(viewElement, vote)
		local scale = math.floor(viewElement.size.w / 5) > viewElement.size.h - 10 and viewElement.size.h - 10 or math.floor(viewElement.size.w / 5)
		local width = (viewElement.size.w - 50) / 5 > scale and (viewElement.size.w - 50) / 5 or scale
		local posX = (viewElement.size.w - width * 5) / 2
		local stars = { transparent = {}, colored = {} }
		for i = 5, 1, -1 do
			local starView = UIElement:new({
				parent = viewElement,
				pos = { posX + (5 - i) * width, (viewElement.size.h - scale) / 2 },
				size = { width, scale },
				interactive = true
			})
			starView.starid = 6 - i
			local starTransparent = UIElement:new({
				parent = starView,
				pos = { (starView.size.w - scale) / 2, 0 },
				size = { scale, scale },
				bgImage = "../textures/menu/general/buttons/startransparenthuge.tga"
			})
			local starColoredTransparent = UIElement:new({
				parent = starView,
				pos = { (starView.size.w - scale) / 2, 0 },
				size = { scale, scale },
				bgImage = "../textures/menu/general/buttons/startransparentcoloredhuge.tga"				
			})
			local starColored = UIElement:new({
				parent = starView,
				pos = { (starView.size.w - scale) / 2, 0 },
				size = { scale, scale },
				bgImage = "../textures/menu/general/buttons/starhuge.tga"
			})
			starColoredTransparent:hide()
			starColored:hide()
			table.insert(stars.transparent, starColoredTransparent)
			table.insert(stars.colored, starColored)
			starView:addMouseHandlers(nil, function()
					vote.score = starView.starid
					for i = 1, starView.starid do
						stars.colored[i]:show(true)
					end
					for i = starView.starid + 1, 5 do
						stars.colored[i]:hide(true)
					end
				end)
			starView:addCustomDisplay(false, function()
					if (starView.hoverState == BTN_HVR) then
						for i = 1, starView.starid do
							stars.transparent[i]:show()
						end
						for i = starView.starid + 1, 5 do
							stars.transparent[i]:hide()
						end
					else
						stars.transparent[starView.starid]:hide()
					end
				end)
		end
	end
	
	function Replays:showReplayVoteWindow(replay)
		local voteOverlay = TBMenu:spawnWindowOverlay()
		local voteView = UIElement:new({
			parent = voteOverlay,
			pos = { voteOverlay.size.w / 4, voteOverlay.size.h / 2 - 200 },
			size = { voteOverlay.size.w / 2, 400 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local voteTitle = UIElement:new({
			parent = voteView,
			pos = { 10, 0 },
			size = { voteView.size.w - 20, 50 }
		})
		voteTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSVOTINGON .. " " .. replay.rplname .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY, nil, nil, FONTS.BIG, nil, 0.65)
		local voteScoreView = UIElement:new({
			parent = voteView,
			pos = { 10, voteTitle.shift.y + voteTitle.size.h },
			size = { voteView.size.w - 20, 80 }
		})
		local replayVote = { score = 0 }
		Replays:showReplayRatingVote(voteScoreView, replayVote)
		
		local voteCommentBG = UIElement:new({
			parent = voteView,
			pos = { 10, voteScoreView.shift.y + voteScoreView.size.h + 10 },
			size = { voteView.size.w - 20, 200 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local voteCommentOverlay = UIElement:new({
			parent = voteCommentBG,
			pos = { 1, 1 },
			size = { voteCommentBG.size.w - 2, voteCommentBG.size.h - 2 },
			bgColor = { 1, 1, 1, 0.4 }
		})
		local voteCommentInput = UIElement:new({
			parent = voteCommentOverlay,
			pos = { 10, 10 },
			size = { voteCommentOverlay.size.w - 20, voteCommentOverlay.size.h - 20 },
			textfield = true,
			interactive = true
		})
		voteCommentInput:addMouseHandlers(nil, function()
				TBMenu:enableMenuKeyboard(voteCommentInput)
			end)
		TBMenu:displayTextfield(voteCommentInput, FONTS.SMALL, 1, UICOLORBLACK, TB_MENU_LOCALIZED.REPLAYSCOMMENT .. " (" .. TB_MENU_LOCALIZED.WORDOPTIONAL .. ")", LEFT)
		
		local voteCancel = UIElement:new({
			parent = voteView,
			pos = { 10, -50 },
			size = { voteView.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		voteCancel:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
		voteCancel:addMouseHandlers(false, function()
				voteOverlay:kill()
			end)
		local voteSubmit = UIElement:new({
			parent = voteView,
			pos = { voteView.size.w / 2 + 5, -50 },
			size = { voteView.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		voteSubmit:deactivate()
		voteSubmit:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSUBMIT)
		voteSubmit:addMouseHandlers(nil, function()
				local info = replay.id .. ";" .. replayVote.score .. ";" .. voteCommentInput.textfieldstr[1]
				show_dialog_box(REPLAY_VOTE, TB_MENU_LOCALIZED.REPLAYSVOTECONFIRM1 .. " " .. replayVote.score .. " " .. TB_MENU_LOCALIZED.REPLAYSVOTECONFIRM2, info)
				local waitOverlay = UIElement:new({
					parent = tbMenuMain,
					pos = { 0, 0 },
					size = { tbMenuMain.size.w, tbMenuMain.size.h },
					interactive = true
				})
				waitOverlay:addMouseHandlers(nil, nil, function(x)
						if (x > WIN_W / 2) then
							voteOverlay:kill()
						end
						waitOverlay:kill()
					end)
			end)
		local waitForVote = UIElement:new({
			parent = voteView,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		waitForVote:addCustomDisplay(true, function()
				if (replayVote.score > 0) then
					voteSubmit:activate()
					voteSubmit.bgColor = { 0, 0, 0, 0.3 }
					waitForVote:kill()
				end
			end)
	end
	
	function Replays:showReplayCommentList(listingHolder, toReload, elementHeight, comments)
		local commentElements = {}
		for i, comment in pairs(comments) do
			if (type(i) == "number") then
				local commentTop = UIElement:new({
					parent = listingHolder,
					pos = { 0, #commentElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(commentElements, commentTop)
				local commentUserWithDate = UIElement:new({
					parent = commentTop,
					pos = { 10, 0 },
					size = { commentTop.size.w / 2 - 10, commentTop.size.h }
				})
				commentUserWithDate:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSBY .. " " .. comment.user .. " (" .. comment.date .. ")", nil, nil, nil, LEFTMID, nil, nil, 0.2)
				local ratingWidth = commentTop.size.w / 3 > commentTop.size.h * 6 and commentTop.size.h * 6 or commentTop.size.w / 3
				local commentRating = UIElement:new({
					parent = commentTop,
					pos = { -ratingWidth, 0 },
					size = { ratingWidth, commentTop.size.h }
				})
				Replays:showReplayRating(commentRating, comment.score, 1)
				local comment = textAdapt(comment.comment, FONTS.SMALL, 1, listingHolder.size.w - 30)
				local rows = math.ceil(#comment / 2)
				for i = 1, rows do
					local commentBody = UIElement:new({
						parent = listingHolder,
						pos = { 0, #commentElements * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					commentBody:addCustomDisplay(true, function() end)
					table.insert(commentElements, commentBody)
					local commentText = UIElement:new({
						parent = commentBody,
						pos = { 10, 0 },
						size = { commentBody.size.w - 20, commentBody.size.h }
					})
					local string = comment[i * 2] and comment[i * 2 - 1] .. " " .. comment[i * 2] or comment[i * 2 - 1]
					commentText:addCustomDisplay(true, function()
							commentText:uiText(string, nil, nil, 1, LEFT)
						end)
				end
				if (i ~= #comments) then
					local separator = UIElement:new({
						parent = listingHolder,
						pos = { 0, #commentElements * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					local separatorLine = UIElement:new({
						parent = separator,
						pos = { 20, separator.size.h / 2 - 0.5 },
						size = { separator.size.w - 40, 1 },
						bgColor = { 1, 1, 1, 0.2 }
					})
					table.insert(commentElements, separator)
				end
			end
		end
		
		for i,v in pairs(commentElements) do
			v:hide()
		end
		
		local commentsScrollBar = TBMenu:spawnScrollBar(listingHolder, #commentElements, elementHeight)
		commentsScrollBar:makeScrollBar(listingHolder, commentElements, toReload)
	end
	
	function Replays:showReplayComments(replay)
		tbMenuCurrentSection:kill(true)
		local commentsView = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local elementHeight = 31
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(commentsView, 45, 50, 20)
		TBMenu:addBottomBloodSmudge(botBar, 1)
		
		local topBarTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w - 20, topBar.size.h }
		})
		topBarTitle:addAdaptedText(true, replay.rplname .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY .. " " .. replay.uploader, nil, nil, FONTS.BIG, LEFTMID, 0.65)
		
		local downloadWait = UIElement:new({
			parent = listingHolder,
			pos = { 0, 0 },
			size = { listingHolder.size.w, listingHolder.size.h }
		})
		local rot, scale = 0, 0
		download_replay_comments(replay.id)
		local commentsFile = Files:new("../data/script/system/rplcomments.txt", FILES_MODE_READONLY)
		downloadWait:addCustomDisplay(true, function()
				set_color(1, 1, 1, 0.8)
				draw_disk(downloadWait.pos.x + downloadWait.size.w / 2, downloadWait.pos.y + downloadWait.size.h / 2, 20, 30, 200, 1, rot, scale, 0)
				rot = rot + 2.5
				scale = scale > 359 and -360 or scale + 5
				if (not commentsFile:isDownloading()) then
					commentsFile:reopen()
					local comments = Replays:getReplayComments(commentsFile:readAll())
					commentsFile:close()
					topBarTitle:addAdaptedText(true, replay.rplname .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY .. " " .. replay.uploader, nil, nil, FONTS.BIG, LEFTMID, 0.65)
					local frame = 0
					downloadWait:addCustomDisplay(true, function()
							downloadWait:uiText(TB_MENU_LOCALIZED.REPLAYSCOMMENTSDOWNLOADING)
							frame = frame + 1
							if (frame >= 5) then
								downloadWait:kill()
								Replays:showReplayCommentList(listingHolder, toReload, elementHeight, comments)
							end
						end)
				end
			end)
		
		local backButton = UIElement:new({
			parent = botBar,
			pos = { -180, 10 },
			size = { 170, botBar.size.h - 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		backButton:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK)
		backButton:addMouseHandlers(nil, function()
				Replays:showServerReplays()
			end)
		if (replay.uploader:lower() ~= TB_MENU_PLAYER_INFO.username:lower() and replay.uservote == 0) then
			local voteButton = UIElement:new({
				parent = botBar,
				pos = { 10, 10 },
				size = { 170, botBar.size.h - 10 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			voteButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSADDCOMMENT)
			voteButton:addMouseHandlers(nil, function()
					Replays:showReplayVoteWindow(replay)
				end)
		end
	end
	
	function Replays:showServerReplayInfo(replayInfo, replay)
		replayInfo:kill(true)
		TBMenu:addBottomBloodSmudge(replayInfo, 2)
		
		if (not replay) then
			return
		end
		
		local replayInfoHolder = UIElement:new({
			parent = replayInfo,
			pos = { 0, 0 },
			size = { replayInfo.size.w, replayInfo.size.h / 8 * 5 }
		})
		local replayName = UIElement:new({
			parent = replayInfoHolder,
			pos = { 10, 0 },
			size = { replayInfoHolder.size.w - 20, replayInfoHolder.size.h / 4 }
		})
		replayName:addAdaptedText(true, replay.rplname, nil, nil, FONTS.BIG, nil, 0.65, nil, 0.2)
		local replayUploader = UIElement:new({
			parent = replayInfoHolder,
			pos = { 10, replayName.shift.y + replayName.size.h },
			size = { replayInfoHolder.size.w - 20, replayInfoHolder.size.h / 16 }
		})
		replayUploader:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSBY .. " " .. replay.uploader, nil, nil, 4, nil, 0.75)
		local replayDate = UIElement:new({
			parent = replayInfoHolder,
			pos = { 10, replayUploader.shift.y + replayUploader.size.h },
			size = { replayUploader.size.w, replayInfoHolder.size.h / 16 }
		})
		replayDate:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSUPLOADEDON .. " " .. replay.date, nil, nil, 4, nil, 0.75)
		local replayRating = UIElement:new({
			parent = replayInfoHolder,
			pos = { 10, replayDate.shift.y + replayDate.size.h + 10 },
			size = { replayUploader.size.w, replayInfoHolder.size.h / 4 - 20 },
			interactive = true,
			shapeType = ROUNDED,
			rounded = 5,
			bgColor = { 0, 0, 0, 0 },
			hoverColor = { 0, 0, 0, 0.1 },
			pressedColor = { 1, 1, 1, 0.1 }
		})
		replayRating:addMouseHandlers(nil, function()
				Replays:showReplayVoteWindow(replay)
			end)
		if (replay.uploader:lower() == TB_MENU_PLAYER_INFO.username:lower()) then
			replayRating:deactivate()
		end
		Replays:showReplayRating(replayRating, replay.score, replay.votes, replay.uservote)
		local replayDescription = UIElement:new({
			parent = replayInfoHolder,
			pos = { 10, replayRating.shift.y + replayRating.size.h + 10 },
			size = { replayDate.size.w, replayInfoHolder.size.h / 8 * 3 }
		})
		replayDescription:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSDESC .. ": " .. replay.description, nil, nil, 4, LEFT, 0.65, 0.65)
		
		local replayDownloadButton = UIElement:new({
			parent = replayInfo,
			pos = { 10, -replayInfo.size.h / 8 * 3 },
			size = { replayInfo.size.w - 20, replayInfo.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		replayDownloadButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSSAVEREPLAY)
		replayDownloadButton:addMouseHandlers(nil, function()
				download_replay(replay.id, replay.rplname:gsub("%s", "_"))
				Replays:showReplayDownloadPopup(replay.rplname:gsub("%s", "_"))
			end)
		local replayCommentsButton = UIElement:new({
			parent = replayInfo,
			pos = { 10, -replayInfo.size.h / 8 * 2 },
			size = { replayInfo.size.w - 20, replayInfo.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		replayCommentsButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSVIEWCOMMENTS)
		replayCommentsButton:addMouseHandlers(nil, function()
				Replays:showReplayComments(replay)
			end)
		
		local findReplaysByUserButton = UIElement:new({
			parent = replayInfo,
			pos = { 10, -replayInfo.size.h / 8 },
			size = { replayInfo.size.w - 20, replayInfo.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		findReplaysByUserButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSMOREBY .. " " .. replay.uploader)
		findReplaysByUserButton:addMouseHandlers(nil, function()
				Replays:getServerReplays(5, 1, replay.uploader)
			end)
	end
	
	function Replays:showServerReplays()
		local viewElement = tbMenuCurrentSection
		viewElement:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar(Replays:getNavigationButtons(true), true)
		
		local replaysList = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.75 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local replayInfo = UIElement:new({
			parent = viewElement,
			pos = { replaysList.size.w + 15, 0 },
			size = { viewElement.size.w * 0.25 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		
		Replays:showServerReplayList(replaysList, replayInfo)
	end
	
	function Replays:showMain(viewElement)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar(Replays:getNavigationButtons(), true)
		viewElement:kill(true)
		TB_MENU_REPLAYS_ONLINE = 0
		
		SELECTED_REPLAY = { replay = nil, element = nil, defaultcolor = nil, time = 0 }
		
		local replaysList = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.75 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local replayInfo = UIElement:new({
			parent = viewElement,
			pos = { replaysList.size.w + 15, 0 },
			size = { viewElement.size.w * 0.25 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(replaysList, 1)
		TBMenu:addBottomBloodSmudge(replayInfo, 2)
		Replays:getReplayFiles()
		replaysList:addCustomDisplay(false, function()
				if (TB_MENU_REPLAYS_LOADED) then
					replaysList:addCustomDisplay(false, function() end)
					Replays:showList(replaysList, replayInfo, SELECTED_FOLDER)
				end
			end)
	end
	
end
