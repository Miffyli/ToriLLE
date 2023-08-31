-- matchmake manager class
-- DO NOT MODIFY THIS FILE

TB_MATCHMAKER_INFO = nil
TB_MATCHMAKER_SEARCHSTATUS = TB_MATCHMAKER_SEARCHSTATUS or nil

ELO_DIVISOR = 400
ELO_FACTOR = 2

do
	Matchmake = {}
    Matchmake.__index = Matchmake
	local cln = {}
	setmetatable(cln, Matchmake)
		
	function Matchmake:getMatchmaker()
		TB_MATCHMAKER_INFO = get_matchmaker().info
	end
	
	-- Connects to matchmake server in idle mode, do not instantly search for a fight
	function Matchmake:connect()
		if (TB_MENU_SPECIAL_SCREEN_ISOPEN == 2 and get_world_state().game_type == 0) then
			UIElement:runCmd("matchmake pause")
		end
		Matchmake:getMatchmaker()
	end
	
	function Matchmake:quit()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		TB_MATCHMAKER_SEARCHSTATUS = nil
		if (get_world_state().game_type == 0) then
			UIElement:runCmd("matchmake disconnect")
		end
		tbMenuCurrentSection:kill(true) 
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Matchmake:getNavigationButtons(showBack)
		local buttonsData = {
			{ 
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, 
				action = function() Matchmake:quit() end, 
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, FONTS.BIG) * 0.65 + 30 
			}
		}
		if (showBack) then
			table.insert(buttonsData, {
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function() Matchmake:showRanked() end,
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONBACK, FONTS.BIG) * 0.65 + 30
			})
		end
		return buttonsData
	end
	
	function Matchmake:fetchGlobalRanking(lines)
		local rankingData = {}
		for i,ln in pairs(lines) do
			if (not ln:match("^#")) then
				local segments = 5
				local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
				table.insert(rankingData, {
					username = data_stream[1],
					rank = tonumber(data_stream[2]),
					elo = tonumber(data_stream[3]),
					wins = tonumber(data_stream[4]),
					loses = tonumber(data_stream[5]),
					games = tonumber(data_stream[4]) + tonumber(data_stream[5])
				})
			end
		end
		return rankingData
	end
	
	function Matchmake:fetchRankingTrends(lines)
		local rankingTrends = {}
		local rankedMods = {}
		local topElo = 0
		local minElo = 10000
		
		local mods = true
		
		for i, ln in pairs(lines) do
			if (ln:find("^#NO DATA FOUND")) then
				table.insert(rankingTrends, { elo = 1610, rank = 0 })
				break
			end
			if (ln:find("^#ELO")) then
				mods = false
			end
			if (not ln:find("^#")) then
				if (mods) then
					local segments = 3
					local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
					local info = {
						name = data_stream[1],
						wins = tonumber(data_stream[2]),
						loses = tonumber(data_stream[3])
					}
					info.games = info.wins + info.loses
					table.insert(rankedMods, info)
				else
					local segments = 2
					local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
					local info = {
						elo = tonumber(data_stream[1]),
						rank = tonumber(data_stream[2])
					}
					if (info.elo > topElo) then
						topElo = info.elo
					end
					if (info.elo < minElo) then
						minElo = info.elo
					end
					table.insert(rankingTrends, info)
				end
			end
		end
		rankingTrends.topElo = topElo
		rankingTrends.minElo = minElo
		return rankingTrends, rankedMods
	end
	
	function Matchmake:showRankingTrendsWithHistory(viewElement)
		download_ranking_trends()
		local rankingFile = Files:new("../data/ranking_trends.txt")
		local playerTrends, modTrends = nil, nil
		
		local dataWait = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { 5, 5 }
		})
		local dataMessage = UIElement:new({
			parent = dataWait,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		dataMessage:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKEUPDATINGTRENDS)
		
		local function showTrendsWithHistory()
			local userTrendsView = UIElement:new({
				parent = viewElement,
				pos = { 0, 0 },
				size = { viewElement.size.w, viewElement.size.h / 3 - 5 }
			})
			local showMods = WIN_W >= 1150 and true or false
			local rankTrendView = UIElement:new({
				parent = userTrendsView,
				pos = { 0, 0 },
				size = { showMods and userTrendsView.size.w / 2 - 5 or userTrendsView.size.w, userTrendsView.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			local rankTrendTitle = UIElement:new({
				parent = rankTrendView,
				pos = { 0, 5 },
				size = { rankTrendView.size.w, 30 }
			})
			rankTrendTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKEGLOBALRANK, nil, nil, FONTS.BIG, nil, nil, nil, 0.1)
			local rankTrendTextView = UIElement:new({
				parent = rankTrendView,
				pos = { 10, rankTrendTitle.shift.y + rankTrendTitle.size.h + 10 },
				size = { rankTrendView.size.w - 20, rankTrendView.size.h - 20 - rankTrendTitle.shift.y - rankTrendTitle.size.h }
			})
			local trend = 0
			local currentRank = TB_MENU_PLAYER_INFO.ranking.rank
			local compareRank = playerTrends[#playerTrends - 10 < 1 and 1 or #playerTrends - 10].rank
			if (currentRank) then
				if (currentRank > compareRank) then
					trend = -1
				elseif (currentRank < compareRank) then
					trend = 1
				end
			else
				trend = nil
			end
			if (TB_MENU_PLAYER_INFO.ranking.qualifying) then
				local rankQualifying = UIElement:new({
					parent = rankTrendTextView,
					pos = { 40, 0 },
					size = { rankTrendTextView.size.w - 40, rankTrendTextView.size.h }
				})
				rankQualifying:uiText(TB_MENU_LOCALIZED.MATCHMAKEQUALIFYING, nil, nil, FONTS.BIG, nil, 0.65)
				rankQualifying:addCustomDisplay(true, function()
						rankQualifying:uiText(TB_MENU_LOCALIZED.MATCHMAKEQUALIFYING, nil, nil, FONTS.BIG, nil, 0.65)
					end)
				local maxLen = 0
				for i,v in pairs(rankQualifying.dispstr) do
					if (maxLen < get_string_length(v, FONTS.BIG) * 0.65) then
						maxLen = get_string_length(v, FONTS.BIG) * 0.65
					end
				end
				local rankQualifyingInfo = UIElement:new({
					parent = rankTrendTextView,
					pos = { (rankTrendTextView.size.w - maxLen) / 2 - 15, rankTrendTextView.size.h / 2 - 15 },
					size = { 30, 30 },
					interactive = true,
					bgColor = { 0, 0, 0, 0.2 },
					hoverColor = { 1, 1, 1, 0.2 },
					pressedColor = { 1, 1, 1, 0.2 },
					shapeType = ROUNDED,
					rounded = rankTrendTextView.size.h
				})
				TBMenu:displayHelpPopup(rankQualifyingInfo, TB_MENU_LOCALIZED.MATCHMAKEQUALIFICATIONINFO)
			elseif (not trend) then
				local rankUnavailable = UIElement:new({
					parent = rankTrendTextView,
					pos = { 40, 0 },
					size = { rankTrendTextView.size.w - 40, rankTrendTextView.size.h }
				})
				rankUnavailable:uiText(TB_MENU_LOCALIZED.MATCHMAKERANKUNAVAILABLE, nil, nil, FONTS.BIG, nil, 0.65)
				rankUnavailable:addCustomDisplay(true, function()
						rankUnavailable:uiText(TB_MENU_LOCALIZED.MATCHMAKERANKUNAVAILABLE, nil, nil, FONTS.BIG, nil, 0.65)
					end)
				local maxLen = 0
				for i,v in pairs(rankUnavailable.dispstr) do
					if (maxLen < get_string_length(v, FONTS.BIG) * 0.65) then
						maxLen = get_string_length(v, FONTS.BIG) * 0.65
					end
				end
				local rankUnavailableInfo = UIElement:new({
					parent = rankTrendTextView,
					pos = { (rankTrendTextView.size.w - maxLen) / 2 - 15, rankTrendTextView.size.h / 2 - 15 },
					size = { 30, 30 },
					interactive = true,
					bgColor = { 0, 0, 0, 0.2 },
					hoverColor = { 1, 1, 1, 0.2 },
					pressedColor = { 1, 1, 1, 0.2 },
					shapeType = ROUNDED,
					rounded = rankTrendTextView.size.h
				})
				TBMenu:displayHelpPopup(rankUnavailableInfo, TB_MENU_LOCALIZED.MATCHMAKEGOLDTIERREQUIREDFORRANKDISPLAY)
			else
				local scale = rankTrendTextView.size.h - 20 > 50 and 50 or rankTrendTextView.size.h - 20
				local rankTrendOldText = UIElement:new({
					parent = rankTrendTextView,
					pos = { 0, 0 },
					size = { (rankTrendTextView.size.w - scale) / 2 - 5, rankTrendTextView.size.h }
				})
				rankTrendOldText:addAdaptedText(true, compareRank, nil, nil, FONTS.BIG, RIGHTMID, 0.65)
				local rankTrendsSymbol = UIElement:new({
					parent = rankTrendTextView,
					pos = { trend == 0 and rankTrendTextView.size.w / 2 - scale / 4 or (rankTrendTextView.size.w - scale) / 2, (rankTrendTextView.size.h - scale) / 2 },
					size = { trend == 0 and scale / 2 or scale, scale },
					bgImage = trend > 0 and "../textures/menu/general/buttons/doublearrowup.tga" or (trend ~= 0 and "../textures/menu/general/buttons/doublearrowdown.tga" or "../textures/menu/general/buttons/arrowright.tga")
				})
				local rankTrendNewText = UIElement:new({
					parent = rankTrendTextView,
					pos = { -(rankTrendTextView.size.w - scale) / 2 + 5, 0 },
					size = { (rankTrendTextView.size.w - scale) / 2 - 5, rankTrendTextView.size.h }
				})
				rankTrendNewText:addAdaptedText(true, currentRank, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, nil, nil, { 0.55, 0.55, 1, 1 })
			end
			
			if (showMods) then
				local modTrendsView = UIElement:new({
					parent = userTrendsView,
					pos = { userTrendsView.size.w / 2 + 5, 0 },
					size = { userTrendsView.size.w / 2 - 5, userTrendsView.size.h },
					bgColor = TB_MENU_DEFAULT_BG_COLOR
				})
				local modTrendsTitle = UIElement:new({
					parent = modTrendsView,
					pos = { 10, 5 },
					size = { modTrendsView.size.w - 20, 30 }
				})
				modTrendsTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKEBESTRANKEDMODS, nil, nil, FONTS.BIG, nil, nil, nil, 0.1)
				
				local modListView = UIElement:new({
					parent = modTrendsView,
					pos = { 0, modTrendsTitle.shift.y + modTrendsTitle.size.h + 5 },
					size = { modTrendsView.size.w, modTrendsView.size.h - modTrendsTitle.shift.y - modTrendsTitle.size.h - 10 }
				})
				local height = 25
				local maxDisplay = math.floor(modListView.size.h / height)
				local modsToShow = #modTrends > maxDisplay and maxDisplay or #modTrends
				local posY = modListView.size.h / modsToShow
				if (#modTrends == 0) then
					modListView:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKEDMODSEMPTY)
				end
				for i, v in pairs(UIElement:qsort(modTrends, "games", true)) do
					if (i > maxDisplay) then
						break
					end
					local modTrend = UIElement:new({
						parent = modTrendsView,
						pos = { 10, modTrendsTitle.shift.y + modTrendsTitle.size.h + posY / 2 + (i - 1) * height },
						size = { modTrendsView.size.w - 20, height }
					})
					local modName = UIElement:new({
						parent = modTrend,
						pos = { 0, 0 },
						size = { modTrend.size.w / 2, modTrend.size.h }
					})
					modName:addAdaptedText(true, v.name, nil, nil, nil, LEFTMID, 0.8, nil, 0)
					local modStats = UIElement:new({
						parent = modTrend,
						pos = { modTrend.size.w / 2, 0 },
						size = { modTrend.size.w / 2, modTrend.size.h }
					})
					modStats:addAdaptedText(true, math.floor(v.wins / v.games * 10000) / 100 .. "% " .. TB_MENU_LOCALIZED.MATCHMAKEWINLOSE, nil, nil, nil, RIGHTMID, 0.8, nil, 0)
				end
			end
			
			local trendsView = UIElement:new({
				parent = viewElement,
				pos = { 0, userTrendsView.size.h + 10 },
				size = { viewElement.size.w, viewElement.size.h - userTrendsView.size.h - 10 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			local trendsTitle = UIElement:new({
				parent = trendsView,
				pos = { 10, 10 },
				size = { trendsView.size.w - 20, 35 }
			})
			trendsTitle:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKERANKINGTRENDS, nil, nil, FONTS.BIG)
			
			local trendsChartBG = UIElement:new({
				parent = trendsView,
				pos = { 0, trendsTitle.shift.y + trendsTitle.size.h + 20 },
				size = { trendsView.size.w, trendsView.size.h - trendsTitle.shift.y - trendsTitle.size.h - 20 }
			})
			TBMenu:addBottomBloodSmudge(trendsChartBG, 1)
			
			local trendsChartView = UIElement:new({
				parent = trendsChartBG,
				pos = { 10, 10 },
				size = { trendsChartBG.size.w - 20, trendsChartBG.size.h - 20 }
			})
			local eloScale = (playerTrends.topElo - playerTrends.minElo) / trendsChartView.size.h
			local width = trendsChartView.size.w / (#playerTrends - 1)
			if (#playerTrends < 4) then
				trendsChartView:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKEMOREGAMESREQUIREDFORTRENDS)
			end
			for i, info in pairs(playerTrends) do
				local elo = info.elo
				if (type(i) == "number") then
					if (not playerTrends[i + 1]) then
						break
					end
					local linePart = UIElement:new({
						parent = trendsChartView,
						pos = { (i - 1) * width, (playerTrends.topElo - elo) / eloScale },
						size = { i * width, (playerTrends.topElo - playerTrends[i + 1].elo) / eloScale }
					})
					linePart:addCustomDisplay(true, function()
							set_color(1, 1, 1, 0.7)
							draw_line(linePart.pos.x, linePart.pos.y, trendsChartView.pos.x + linePart.size.w, trendsChartView.pos.y + linePart.size.h, 2)
						end)
				end
			end
		end
		
		dataWait:addCustomDisplay(true, function()
				if (not rankingFile:isDownloading()) then
					rankingFile:reopen()
					playerTrends, modTrends = Matchmake:fetchRankingTrends(rankingFile:readAll())
					viewElement:kill(true)
					showTrendsWithHistory()
				end
			end)
	end
	
	function Matchmake:showGlobalRankToplist(viewElement)
		download_ranking_toplist()
		local elementHeight = 35
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 50, elementHeight, 20)
		TBMenu:addBottomBloodSmudge(botBar, 2)
		
		local rankingFile = Files:new("../data/ranking_toplist.txt")
		local playerRanking = nil
		
		local topPlayersTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w - 20, topBar.size.h }
		})
		topPlayersTitle:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKETOPRANKEDPLAYERS, nil, nil, FONTS.BIG, nil, 0.65)
		listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKEUPDATINGRANK)
		local listingWait = UIElement:new({
			parent = listingHolder,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		
		local function showGlobalList()
			local listElements = {}
			if (#playerRanking == 0) then
				listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKEDTOPEMPTY)
			end
			for i, player in pairs(playerRanking) do
				PlayerInfo:getRankTier(player)
				local playerView = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				playerView:addAdaptedText(true, player.username, nil, nil, nil, LEFTMID)
				table.insert(listElements, playerView)
				local playerRankView = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				table.insert(listElements, playerRankView)
				local playerRank = UIElement:new({
					parent = playerRankView,
					pos = { 0, 0 },
					size = { playerRankView.size.w / 2, playerRankView.size.h }
				})
				local rankString = player.rank and player.title .. " " .. TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. player.rank or player.title
				playerRank:addAdaptedText(true, rankString .. "\n" .. player.elo .. " " .. TB_MENU_LOCALIZED.MATCHMAKEELO, nil, nil, 4, LEFT, 0.6)
				local playerGames = UIElement:new({
					parent = playerRankView,
					pos = { playerRankView.size.w / 2, 0 },
					size = { playerRankView.size.w / 2, playerRankView.size.h }
				})
				playerGames:addAdaptedText(true, player.games .. " " .. TB_MENU_LOCALIZED.MATCHMAKEFIGHTSTOTAL .. "\n" .. math.floor(player.wins / player.games * 10000) / 100 .. "% " .. TB_MENU_LOCALIZED.MATCHMAKEWINLOSE, nil, nil, 4, RIGHT, 0.6)
				if (i < #playerRanking) then
					local separator = UIElement:new({
						parent = playerRankView,
						pos = { 10, -1 },
						size = { playerRankView.size.w - 20, 1 },
						bgColor = { 1, 1, 1, 0.2 }
					})
				end
			end
			for i,v in pairs(listElements) do
				v:hide()
			end
			
			local listingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
			listingScrollBar:makeScrollBar(listingHolder, listElements, toReload)
		end
		
		listingWait:addCustomDisplay(true, function()
				if (not rankingFile:isDownloading()) then
					rankingFile:reopen()
					playerRanking = Matchmake:fetchGlobalRanking(rankingFile:readAll())
					listingWait:kill()
					listingHolder:addCustomDisplay(false, function() end)
					showGlobalList()
				end
			end)		
	end
	
	function Matchmake:showGlobalRanking()
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Matchmake:getNavigationButtons(true), true)
		
		local playerRankingView = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w * 0.65 - 10, tbMenuCurrentSection.size.h }
		})
		Matchmake:showRankingTrendsWithHistory(playerRankingView)
		TBMenu:addBottomBloodSmudge(playerRankingView, 1)
		
		local rankingTopView = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { tbMenuCurrentSection.size.w * 0.65 + 5, 0 },
			size = { tbMenuCurrentSection.size.w * 0.35 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Matchmake:showGlobalRankToplist(rankingTopView)
	end
	
	function Matchmake:getRankedSeasonInfo()
		local function getRandom(list)
			local seed = math.random(1, #list)
			return list[seed]
		end
		
		local season = {
			{
				title = "Description",
				desc = "Toribash Ranking is based on a seasonal system.\nThere are three seasons per year, each 3 months long. Best players of each year's seasons will compete in Toribash World Championships for the title of the best player of the year.\nAt the end of each season, players who qualified for Silver Tier or higher receive unique prizes.\nThe higher you ranked during the season, the better prizes you'll receive - starting with mid-tier body colors and up to Elite Tier color packs with unique full body customization sets.",
			},
			{
				title = "How to play",
				desc = "To qualify for a rank tier during a season, you need to play at least 10 ranked games.\nMain way to earn rank is to play in Ranked Matchmaking mode. Additionally, there will be two public Ranked servers available for players below Platinum Tier until December. What's more, by winning ranked fights you not only climb up ranks but also earn additional XP for your clan!"
			},
			{
				title = "Prizes",
				desc = "At the end of the season, players who qualified for a rank tier will receive prizes:",
				prizes = {
					{
						title = "Rank 1",
						prizes = {
							items = { { itemid = 729, name = "Demon Pack" }, { itemid = 1389, name = "Mysterio Pack" } },
							tc = "450,000",
							st = 25,
							misc = "rank tier item rewards"
						}
					},
					{
						title = "Rank 2",
						prizes = {
							items = { { itemid = 1270, name = "Alpha Pack" }, { itemid = 1194, name = "Pure Pack" } },
							tc = "300,000",
							st = 20,
							misc = "rank tier item rewards"
						}
					},
					{
						title = "Rank 3",
						prizes = {
							items = { { itemid = 1070, name = "Elf Pack" }, { itemid = 1400, name = "Vortex Pack" } },
							tc = "200,000",
							st = 15,
							misc = "rank tier item rewards"
						}
					},
					{
						title = "Diamond Tier",
						prizes = {
							items = { { customicon = "season5dmnwr", name = "Upgradable 3D item set (TBA)" }, { itemid = 2857, name = "Diamond Tori 3D set" }, { itemid = 2996, name = "Comic Effects" }, { itemid = getRandom({ 2876, 2906, 2944, 3016, 3043 }), name = "Random Limited Edition Shiai Color Pack" } },
							tc = "100,000",
							st = 10
						}
					},
					{
						title = "Platinum Tier",
						prizes = {
							items = { { customicon = "season5dmnwr", name = "Upgradable 3D item set (TBA)" }, { itemid = 2996, name = "Comic Effects" }, { itemid = getRandom({ 2876, 2906, 2944, 3016, 3043 }), name = "Random Limited Edition Shiai Color Pack" } },
							st = 7
						}
					},
					{
						title = "Gold Tier",
						prizes = {
							items = { { customicon = "season5dmnwr", name = "Upgradable 3D item (TBA)" }, { itemid = getRandom({ 2859, 2896, 2934, 2958, 3006, 3033, 2861, 2890, 2928, 2960, 3000, 3027 }), name = "Random Limited Edition Shiai Joints" } },
							st = 5
						}
					},
					{
						title = "Silver Tier",
						prizes = {
							items = { { itemid = getRandom({ 2859, 2896, 2934, 2958, 3006, 3033 }), name = "Random Limited Edition Shiai Force" } },
							st = 3
						}
					}
				}
			}
		}
		return season
	end
	
	function Matchmake:showSeasonAboutWindow()
		local seasonOverlay = TBMenu:spawnWindowOverlay()
		local seasonViewHeight = seasonOverlay.size.h / 2 > 532 and 532 or seasonOverlay.size.h / 5 * 3
		if (seasonViewHeight > seasonOverlay.size.w / 8 * 3) then
			seasonViewHeight = seasonOverlay.size.w / 8 * 2
		end
		local seasonViewBackground = UIElement:new({
			parent = seasonOverlay,
			pos = { seasonOverlay.size.w / 8, seasonOverlay.size.h / 2 - seasonViewHeight / 2 },
			size = { seasonOverlay.size.w / 8 * 6, seasonViewHeight },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local seasonViewImage = UIElement:new({
			parent = seasonViewBackground,
			pos = { 10, 10 },
			size = { seasonViewHeight - 20, seasonViewHeight - 20 },
			bgImage = "../textures/menu/promo/season5block.tga"
		})
		local seasonView = UIElement:new({
			parent = seasonViewBackground,
			pos = { seasonViewHeight, 0 },
			size = { seasonViewBackground.size.w - seasonViewHeight, seasonViewBackground.size.h }
		})
		
		local seasonInfo = Matchmake:getRankedSeasonInfo()
		
		local elementHeight = 33.8
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(seasonView, 40, 45, 20)
		
		local seasonTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w - 20, topBar.size.h }
		})
		seasonTitle:addAdaptedText(true, "Toribash Season 5", nil, nil, FONTS.BIG)
		
		local backButton = UIElement:new({
			parent = botBar,
			pos = { -botBar.size.w / 3, 5 },
			size = { botBar.size.w / 3 - 20, botBar.size.h - 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		backButton:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK)
		backButton:addMouseHandlers(nil, function()
				seasonOverlay:kill()
			end)
			
		local listElements = {}
		local count = 0
		for i, info in pairs(seasonInfo) do
			count = count + 1
			local infoTitle = UIElement:new({
				parent = listingHolder,
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 20, elementHeight }
			})
			infoTitle:addAdaptedText(true, info.title, nil, nil, FONTS.BIG, LEFTMID)
			table.insert(listElements, infoTitle)
			if (info.desc) then
				local textString = textAdapt(info.desc, 4, 0.7, listingHolder.size.w - 30)
				local rows = math.ceil(#textString / 2)
				for i = 1, rows do
					local infoRow = UIElement:new({
						parent = listingHolder,
						pos = { 10, #listElements * elementHeight },
						size = { listingHolder.size.w - 20, elementHeight }
					})
					local string = textString[i * 2] and textString[i * 2 - 1] .. textString[i * 2] or textString[i * 2 - 1]
					infoRow:addCustomDisplay(true, function()
							infoRow:uiText(string, nil, nil, 4, LEFT, 0.7)
						end)
					table.insert(listElements, infoRow)
				end
			end
			if (info.prizes) then
				for k, prize in pairs(info.prizes) do
					local prizeTitleHolder = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					local prizeListSign = UIElement:new({
						parent = prizeTitleHolder,
						pos = { elementHeight / 3, elementHeight / 3 },
						size = { elementHeight / 3, elementHeight / 3 },
						shapeType = ROUNDED,
						rounded = elementHeight / 6,
						bgColor = UICOLORWHITE
					})
					local prizeTitle = UIElement:new({
						parent = prizeTitleHolder,
						pos = { elementHeight, 0 },
						size = { prizeTitleHolder.size.w - elementHeight, elementHeight }
					})
					prizeTitle:addAdaptedText(true, prize.title, nil, nil, nil, LEFTMID)
					table.insert(listElements, prizeTitleHolder)
					if (prize.prizes.items) then
						local count = 0
						local itemsRow = UIElement:new({
							parent = listingHolder,
							pos = { 40, #listElements * elementHeight },
							size = { listingHolder.size.w - 50, elementHeight }
						})
						table.insert(listElements, itemsRow)
						local currentRow = itemsRow
						for j, item in pairs(prize.prizes.items) do
							count = count + 1
							if (count * (elementHeight + 10) > listingHolder.size.w - 20) then
								local itemsRowNew = UIElement:new({
									parent = listingHolder,
									pos = { 40, #listingHolder * elementHeight },
									size = { listingHolder.size.w - 50, elementHeight }
								})
								table.insert(listElements, itemsRowNew)
								count = 1
								currentRow = itemsRowNew
							end
							local itemDisplay = UIElement:new({
								parent = currentRow,
								pos = { (count - 1) * (elementHeight + 10), 0 },
								size = { elementHeight, elementHeight },
								interactive = true,
								bgImage = item.customicon and "../textures/store/" .. item.customicon ..".tga" or "../textures/store/items/" .. item.itemid .. ".tga"
							})
							local itemInfo = UIElement:new({
								parent = itemDisplay,
								pos = { 5, 5 },
								size = { 250, 84 },
								bgColor = { 1, 1, 1, 0.85 },
								shapeType = ROUNDED,
								rounded = 5
							})
							local itemTexture = UIElement:new({
								parent = itemInfo,
								pos = { 10, 10 },
								size = { 64, 64 },
								bgImage = item.customicon and "../textures/store/" .. item.customicon ..".tga" or "../textures/store/items/" .. item.itemid .. ".tga"
							})
							local itemDescription = UIElement:new({
								parent = itemInfo,
								pos = { 84, 10 },
								size = { itemInfo.size.w - 94, itemInfo.size.h - 20 }
							})
							itemDescription:addAdaptedText(false, item.name, nil, nil, 4, nil, 0.7, nil, nil, nil, UICOLORBLACK)
							itemDisplay:addCustomDisplay(false, function()
									if (itemDisplay.hoverState) then
										itemInfo:show()
									else
										itemInfo:hide()
									end
								end)
						end
					end
					if (prize.prizes.tc) then
						local tcPrizeHolder = UIElement:new({
							parent = listingHolder,
							pos = { 40, #listElements * elementHeight },
							size = { listingHolder.size.w - 50, elementHeight }
						})
						table.insert(listElements, tcPrizeHolder)
						local tcSign = UIElement:new({
							parent = tcPrizeHolder,
							pos = { 0, 5 },
							size = { elementHeight - 10, elementHeight - 10 },
							bgImage = "../textures/store/toricredit_tiny.tga"
						})
						local tcPrize = UIElement:new({
							parent = tcPrizeHolder,
							pos = { elementHeight, 0 },
							size = { tcPrizeHolder.size.w - elementHeight, elementHeight }
						})
						tcPrize:addAdaptedText(true, prize.prizes.tc .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, nil, LEFTMID, 0.8)
					end
					if (prize.prizes.st) then
						local stPrizeHolder = UIElement:new({
							parent = listingHolder,
							pos = { 40, #listElements * elementHeight },
							size = { listingHolder.size.w - 50, elementHeight }
						})
						table.insert(listElements, stPrizeHolder)
						local stSign = UIElement:new({
							parent = stPrizeHolder,
							pos = { 0, 5 },
							size = { elementHeight - 10, elementHeight - 10 },
							bgImage = "../textures/store/shiaitoken_tiny.tga"
						})
						local stPrize = UIElement:new({
							parent = stPrizeHolder,
							pos = { elementHeight, 0 },
							size = { stPrizeHolder.size.w - elementHeight, elementHeight }
						})
						stPrize:addAdaptedText(true, prize.prizes.st .. " Shiai Tokens", nil, nil, nil, LEFTMID, 0.8)
					end
					if (prize.prizes.misc) then
						local miscPrize = UIElement:new({
							parent = listingHolder,
							pos = { 40, #listElements * elementHeight },
							size = { listingHolder.size.w - 50, elementHeight }
						})
						table.insert(listElements, miscPrize)
						miscPrize:addAdaptedText(true, "+ " .. prize.prizes.misc, nil, nil, nil, LEFTMID, 0.9)
					end
				end
			end
			if (count < #seasonInfo) then
				local separator = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				local separatorLine = UIElement:new({
					parent = separator,
					pos = { 10, separator.size.h / 2 - 0.5 },
					size = { separator.size.w - 20, 1 },
					bgColor = { 1, 1, 1, 0.2 }
				})
				table.insert(listElements, separator)
			end
		end
		
		for i,v in pairs(listElements) do
			v:hide()
		end
		
		local seasonInfoScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		seasonInfoScrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end
	
	function Matchmake:showRanked()
		local RATIO_WIDE = 1
		local RATIO_NORMAL = 2
		
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Matchmake:getNavigationButtons(), true)
		
		local seasonView = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w * 0.6 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(seasonView, 1)
		
		local promoRatio = (seasonView.size.w - 20) / 2 > seasonView.size.h / 4 * 3 - 20 and RATIO_WIDE or RATIO_NORMAL
		local promoImage = promoRatio == RATIO_WIDE and "../textures/menu/promo/season5wide.tga" or "../textures/menu/promo/season5.tga"
		local seasonPromo = UIElement:new({
			parent = seasonView,
			pos = { 10, 10 },
			size = { seasonView.size.w - 20, (seasonView.size.w - 20) / 2 },
			bgImage = promoImage
		})
		local seasonPromoAbout = UIElement:new({
			parent = seasonPromo,
			pos = { 0, 0 },
			size = { seasonPromo.size.w, promoRatio == RATIO_NORMAL and seasonPromo.size.h or seasonPromo.size.h / 1.65 },
			bgColor = { 0, 0, 0, 0.6 }
		})
		seasonPromoAbout:addAdaptedText(false, "Ranking cooldown period", nil, nil, FONTS.BIG)
		
		local posY = seasonPromo.shift.y + seasonPromo.size.h
		if (promoRatio == RATIO_WIDE) then
			posY = seasonPromo.shift.y + math.floor((seasonView.size.w - 20) / 3.3)
		end
		local seasonButtonsView = UIElement:new({
			parent = seasonView,
			pos = { 10, posY + 10 },
			size = { seasonView.size.w - 20, seasonView.size.h - posY - 20 }
		})
		local seasonButtonRankingList = UIElement:new({
			parent = seasonButtonsView,
			pos = { 0, 0 },
			size = { seasonButtonsView.size.w, (seasonButtonsView.size.h - 10)},
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		seasonButtonRankingList:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKEGLOBALRANKING)
		seasonButtonRankingList:addMouseHandlers(nil, function()
				Matchmake:showGlobalRanking()
			end)
		--[[local seasonButtonRankingThread = UIElement:new({
			parent = seasonButtonsView,
			pos = { 0, seasonButtonRankingList.size.h + 10 },
			size = { seasonButtonRankingList.size.w, seasonButtonRankingList.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		seasonButtonRankingThread:addAdaptedText(false, "Season 5 thread on forum", -15)
		local posX = get_string_length("Season 5 thread on forum", FONTS.MEDIUM)
		local onlineSign = UIElement:new({
			parent = seasonButtonRankingThread,
			pos = { seasonButtonRankingThread.size.w / 2 + posX / 2 - 10, seasonButtonRankingThread.size.h / 2 - 13 },
			size = { 26, 26 },
			bgImage = "../textures/menu/general/buttons/external.tga"
		})
		seasonButtonRankingThread:addMouseHandlers(nil, function()
				open_url("http://forum.toribash.com/showthread.php?t=620288")
			end)]]
		
		
		local viewElement = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { tbMenuCurrentSection.size.w * 0.6 + 5, 0 },
			size = { tbMenuCurrentSection.size.w * 0.4 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(viewElement, 2)
		
		if (TB_MENU_PLAYER_INFO.data.qi < 500) then
			local scale = viewElement.size.w > viewElement.size.h and viewElement.size.h / 2 or viewElement.size.w / 2
			local scale = scale > 256 and 256 or scale
			local availableBeltIcon = UIElement:new({
				parent = viewElement,
				pos = { (viewElement.size.w - scale) / 2, (viewElement.size.h / 3 * 2 - scale) / 2 },
				size = { scale, scale },
				bgImage = "../textures/menu/belts/brown.tga"
			})
			local availableBeltText = UIElement:new({
				parent = viewElement,
				pos = { 50, -viewElement.size.h / 3 },
				size = { viewElement.size.w - 100, viewElement.size.h / 4 }
			})
			availableBeltText:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKEDBELT, nil, nil, FONTS.BIG)
		else
			local mmRankedTitle = UIElement:new({
				parent = viewElement,
				pos = { 10, 0 },
				size = { viewElement.size.w - 20, viewElement.size.h / 8 }
			})
			mmRankedTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKEDMODE, nil, nil, FONTS.BIG, nil, 0.7)
			if (TB_MENU_PLAYER_INFO.ranking.elo) then
				local mmRankedInfo = UIElement:new({
					parent = viewElement,
					pos = { 10, mmRankedTitle.size.h + mmRankedTitle.shift.y },
					size = { viewElement.size.w - 20, TB_MENU_PLAYER_INFO.ranking.nextTierElo and viewElement.size.h / 16 * 7 or viewElement.size.h / 7 * 4 }
				})
				local iconScale = mmRankedInfo.size.w / 2 < mmRankedInfo.size.h and mmRankedInfo.size.w / 2 or mmRankedInfo.size.h
				if (iconScale > 64) then
					local mmRankedIcon = UIElement:new({
						parent = mmRankedInfo,
						pos = { 0, (mmRankedInfo.size.h - iconScale) / 2 },
						size = { iconScale, iconScale },
						bgImage = TB_MENU_PLAYER_INFO.ranking.image
					})
				else 
					iconScale = 0
				end
				
				local mmRankedInfoText = UIElement:new({
					parent = mmRankedInfo,
					pos = { iconScale, 0 },
					size = { mmRankedInfo.size.w - iconScale, mmRankedInfo.size.h }
				})
				local details = 3
				local mmRankedInfoTier = UIElement:new({
					parent = mmRankedInfoText,
					pos = { 0, 0 },
					size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
				})
				mmRankedInfoTier:addAdaptedText(true, TB_MENU_PLAYER_INFO.ranking.title, nil, nil, FONTS.BIG, CENTERBOT, 0.6)
				if (TB_MENU_PLAYER_INFO.ranking.rank) then
					local mmRankedInfoRank = UIElement:new({
						parent = mmRankedInfoText,
						pos = { 0, mmRankedInfoText.size.h / details * (details - 2) },
						size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
					})
					mmRankedInfoRank:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. TB_MENU_PLAYER_INFO.ranking.rank .. "\n(" .. string.format("%4.2f", TB_MENU_PLAYER_INFO.ranking.elo) .. " " .. TB_MENU_LOCALIZED.MATCHMAKEELO .. ")")
				else
					local mmRankedInfoElo = UIElement:new({
						parent = mmRankedInfoText,
						pos = { 0, mmRankedInfoText.size.h / details * (details - 2) },
						size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
					})
					mmRankedInfoElo:addAdaptedText(true, string.format("%4.2f", TB_MENU_PLAYER_INFO.ranking.elo) .. " " .. TB_MENU_LOCALIZED.MATCHMAKEELO)
				end
				local mmRankedInfoGames = UIElement:new({
					parent = mmRankedInfoText,
					pos = { 0, mmRankedInfoText.size.h / details * (details - 1) },
					size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
				})
				local games = TB_MENU_PLAYER_INFO.ranking.wins + TB_MENU_PLAYER_INFO.ranking.loses
				local winrate = games ~= 0 and math.floor(TB_MENU_PLAYER_INFO.ranking.wins / games * 100 + 0.5) or nil
				local gameInfoStr = games .. " " .. TB_MENU_LOCALIZED.MATCHMAKEFIGHTSTOTAL
				gameInfoStr = winrate and (gameInfoStr .. ", " .. winrate .. "% " .. TB_MENU_LOCALIZED.MATCHMAKEWINRATE) or gameInfoStr
				mmRankedInfoGames:addAdaptedText(true, gameInfoStr, nil, nil, 4, CENTER, 0.7)
			end
			
			if (TB_MENU_PLAYER_INFO.ranking.nextTierElo) then
				local gamesToNextTier = UIElement:new({
					parent = viewElement,
					pos = { 30, viewElement.size.h / 2 + viewElement.size.h / 16 },
					size = { viewElement.size.w - 30, viewElement.size.h / 8 }
				})
				
				local bestAverageOpponent = 1.01 * (TB_MENU_PLAYER_INFO.ranking.elo + 1600) / 2
				local worstAverageOpponent = (1600 / TB_MENU_PLAYER_INFO.ranking.elo) * (TB_MENU_PLAYER_INFO.ranking.elo + 1600) / 2
				
				local minGamesToNextTier = math.ceil((TB_MENU_PLAYER_INFO.ranking.nextTierElo - TB_MENU_PLAYER_INFO.ranking.elo) / (ELO_FACTOR * (1 - (1 / ( 1 + (math.pow(TB_MENU_PLAYER_INFO.ranking.elo, (bestAverageOpponent - TB_MENU_PLAYER_INFO.ranking.elo) / ELO_DIVISOR)))))))
				local maxGamesToNextTier = math.ceil((TB_MENU_PLAYER_INFO.ranking.nextTierElo - TB_MENU_PLAYER_INFO.ranking.elo) / (ELO_FACTOR * (1 - (1 / ( 1 + (math.pow(TB_MENU_PLAYER_INFO.ranking.elo, (worstAverageOpponent - TB_MENU_PLAYER_INFO.ranking.elo) / ELO_DIVISOR)))))))
				
				local winsToNextTierString = (minGamesToNextTier == maxGamesToNextTier and minGamesToNextTier or (minGamesToNextTier .. " - " .. maxGamesToNextTier)) .. " " .. TB_MENU_LOCALIZED.MATCHMAKEWINSTONEXTTIER
				gamesToNextTier:uiText(winsToNextTierString)
				gamesToNextTier:addCustomDisplay(true, function()
						gamesToNextTier:uiText(winsToNextTierString)
					end)
				
				local signScale = gamesToNextTier.size.h > 30 and 30 or gamesToNextTier.size.h
				local maxLen = 0
				for i,v in pairs(gamesToNextTier.dispstr) do
					if (maxLen < get_string_length(v, FONTS.MEDIUM)) then
						maxLen = get_string_length(v, FONTS.MEDIUM)
					end
				end
				local gamesToNextTierInfo = UIElement:new({
					parent = viewElement,
					pos = { (viewElement.size.w - maxLen) / 2 - 20, viewElement.size.h / 2 + viewElement.size.h / 16 + (gamesToNextTier.size.h - signScale) / 2 },
					size = { signScale, signScale },
					interactive = true,
					bgColor = { 0, 0, 0, 0.2 },
					hoverColor = { 1, 1, 1, 0.2 },
					pressedColor = { 1, 1, 1, 0.2 },
					shapeType = ROUNDED,
					rounded = signScale
				})
				TBMenu:displayHelpPopup(gamesToNextTierInfo, TB_MENU_LOCALIZED.MATCHMAKEELOGAININFO)
			end
			
			local rankedPlayers = UIElement:new({
				parent = viewElement,
				pos = { 10, -viewElement.size.h / 10 * 3 },
				size = { viewElement.size.w - 20, viewElement.size.h / 10 }
			})
			rankedPlayers:addCustomDisplay(false, function()
					if (TB_MATCHMAKER_INFO.ranked == 0 or TB_MATCHMAKER_INFO.ranked > 65535) then
						rankedPlayers:uiText(TB_MENU_LOCALIZED.MATCHMAKENOPLAYERS)
					elseif (TB_MATCHMAKER_INFO.ranked == 1) then
						rankedPlayers:uiText(TB_MATCHMAKER_INFO.ranked .. " " .. TB_MENU_LOCALIZED.MATCHMAKEPLAYERSEARCHING)
					else
						rankedPlayers:uiText(TB_MATCHMAKER_INFO.ranked .. " " .. TB_MENU_LOCALIZED.MATCHMAKEPLAYERSSEARCHING)
					end
				end)
			local rankedSearchButton = UIElement:new({
				parent = viewElement,
				pos = { 10, -viewElement.size.h / 5 },
				size = { viewElement.size.w - 20, viewElement.size.h / 5 - 10 },
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 },
				interactive = not rankedSearchDisabled,
				hoverSound = 31,
				downSound = 50
			})
			local rankedSearchProgress = UIElement:new({
				parent = viewElement,
				pos = { viewElement.size.w / 10, -viewElement.size.h / 10 * 3 },
				size = { viewElement.size.w / 10 * 8, viewElement.size.h / 10 },
			})
			local progress, rotation = 0, 0
			rankedSearchProgress:addCustomDisplay(false, function()
					rankedSearchProgress:uiText(TB_MENU_LOCALIZED.MATCHMAKESEARCHING)
					set_color(1,1,1,0.8)
					draw_disk(rankedSearchProgress.pos.x + rankedSearchProgress.size.w / 2 - get_string_length(TB_MENU_LOCALIZED.MATCHMAKESEARCHING, FONTS.MEDIUM) / 2 - rankedSearchProgress.size.h / 3 * 2, rankedSearchProgress.pos.y + rankedSearchProgress.size.h / 2, rankedSearchProgress.size.h / 5, rankedSearchProgress.size.h / 3, 500, 1, rotation, progress, 0)
					progress = progress == 360 and -360 or progress + 5
					rotation = rotation + 3
				end)
			local rankedSearchButtonStop = UIElement:new({
				parent = viewElement,
				pos = { 10, -viewElement.size.h / 5 },
				size = { viewElement.size.w - 20, viewElement.size.h / 5 - 10 },
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 },
				interactive = true,
				hoverSound = 31
			})
			if (TB_MATCHMAKER_SEARCHSTATUS == 1) then
				rankedSearchButton:hide()
				rankedPlayers:hide()
			else
				rankedSearchProgress:hide()
				rankedSearchButtonStop:hide()
			end
			rankedSearchButton:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKESEARCH, nil, nil, FONTS.BIG, nil, 0.65)
			rankedSearchButton:addMouseHandlers(nil, function()
					UIElement:runCmd("matchmake ranked continue")
					TB_MATCHMAKER_SEARCHSTATUS = 1
					Matchmake:getMatchmaker()
					progress = 0
					rankedSearchButton:hide()
					rankedSearchProgress:show()
					rankedPlayers:hide()
					rankedSearchButtonStop:show()
				end, nil)
			rankedSearchButtonStop:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKESTOPSEARCH, nil, nil, FONTS.BIG, nil, 0.65)
			rankedSearchButtonStop:addMouseHandlers(nil, function()
					UIElement:runCmd("matchmake on 8 0 1")
					TB_MATCHMAKER_SEARCHSTATUS = nil
					Matchmake:getMatchmaker()
					rankedSearchButton:show()
					rankedPlayers:show()
					rankedSearchProgress:hide()
					rankedSearchButtonStop:hide()
				end)
		end
	end
	
	function Matchmake:showMain()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 2
		tbMenuBottomLeftBar:hide()
		
		local mmTimeRefresh = os.time()
		local refreshLast = mmTimeRefresh
		local refreshElement = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		refreshElement:addCustomDisplay(true, function()
				if ((os.time() - mmTimeRefresh) % 5 == 0 and refreshLast ~= os.time()) then
					refreshLast = os.time()
					Matchmake:getMatchmaker()
				end
			end)
		Matchmake:showRanked()
	end
		
end
