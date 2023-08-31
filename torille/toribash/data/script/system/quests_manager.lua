QUESTS_UPDATE_CLOCK = QUESTS_UPDATE_CLOCK or nil

do
	Quests = {}
	Quests.__index = Quests
	local cln = {}
	setmetatable(cln, Quests)
	
	function Quests:getQuests()
		local file = Files:new("../data/quest.txt")
		if (not file.data) then
			return false
		end
		local questData = {}
		local dataTypes = {
			{ "id", numeric = true },
			{ "type", numeric = true },
			{ "progress", numeric = true },
			{ "requirement", numeric = true },
			{ "timeleft", numeric = true },
			{ "modid", numeric = true },
			{ "modname" },
			{ "decap", boolean = true },
			{ "matchmake", boolean = true },
			{ "official", boolean = true },
			{ "reward", numeric = true },
			{ "rewardid", numeric = true },
			{ "name" }
		}
		for i, ln in pairs(file:readAll()) do
			if (not ln:find("^#")) then
				local _, segments = ln:gsub("([^\t]*)\t?", "")
				local dataStream = { ln:match(("([^\t]*)\t?"):rep(segments)) }
				local quest = {}
				for i,v in pairs(dataTypes) do
					if (v.numeric or v.boolean) then
						quest[v[1]] = tonumber(dataStream[i])
						if (v.boolean) then
							quest[v[1]] = quest[v[1]] == 1
						end
					else
						quest[v[1]] = dataStream[i]
					end
				end
				table.insert(questData, quest)
			end
		end
		file:close()
		return questData
	end
	
	function Quests:getQuestById(id)
		if (not QUESTS_DATA) then
			QUESTS_DATA = Quests:getQuests()
		end
		for i,v in pairs(QUESTS_DATA) do
			if (v.id == id) then
				return v
			end
		end
		return false
	end
	
	function Quests:setQuestProgress(quest, progress)
		quest.progress = quest.requirement < progress and quest.requirement or progress
	end
	
	function Quests:getQuestName(v)
		if (v.name and v.name:len() > 1) then
			return v.name
		end
		if (v.type == 1) then
			return TB_MENU_LOCALIZED.QUESTSNAMETYPE1
		elseif (v.type == 2) then
			return TB_MENU_LOCALIZED.QUESTSNAMETYPE2
		elseif (v.type == 3) then
			return TB_MENU_LOCALIZED.QUESTSNAMETYPE3
		elseif (v.type == 4) then
			if (v.decap) then
				return TB_MENU_LOCALIZED.QUESTSNAMETYPEDECAP
			else
				return TB_MENU_LOCALIZED.QUESTSNAMETYPE4
			end
		end
	end
	
	function Quests:getQuestTarget(v)
		local targetText = ""
		if (v.type == 1) then
			targetText = TB_MENU_LOCALIZED.QUESTSPLAYREQ .. " " .. v.requirement .. " " .. TB_MENU_LOCALIZED.WORDGAMES
		elseif (v.type == 2) then
			targetText = TB_MENU_LOCALIZED.QUESTSWINREQ .. " " .. v.requirement .. " " .. TB_MENU_LOCALIZED.WORDFIGHTS
			if (v.decap) then
				targetText = targetText .. " " .. TB_MENU_LOCALIZED.QUESTSBYDECAP
			end
		elseif (v.type == 3) then
			targetText = TB_MENU_LOCALIZED.QUESTSGETREQ .. " " .. v.requirement .. " " .. TB_MENU_LOCALIZED.QUESTSGETREQ2
		elseif (v.type == 4) then
			if (v.decap) then
				targetText = TB_MENU_LOCALIZED.QUESTSDECAPREQ .. " " .. v.requirement .. " " .. TB_MENU_LOCALIZED.WORDTIMES
			else
				targetText = TB_MENU_LOCALIZED.QUESTSDISMEMBERREQ .. " " .. v.requirement .. " " .. TB_MENU_LOCALIZED.WORDTIMES
			end
		end
		if (v.modid ~= 0) then
			targetText = targetText .. " " .. TB_MENU_LOCALIZED.WORDIN .. " " .. v.modname
		end
		if (v.matchmake) then
			targetText = targetText .. " " .. TB_MENU_LOCALIZED.QUESTSMATCHMAKEREQ
		elseif (v.official) then
			targetText = targetText .. " " .. TB_MENU_LOCALIZED.QUESTSOFFICIALREQ
		end
		return targetText
	end
	
	function Quests:getReward(v)
		if (v.rewardid == 0) then
			return v.reward .. " " .. TB_MENU_LOCALIZED.WORDTC
		end
		local item = Torishop:getItemInfo(v.rewardid)
		return item.shortname or "???"
	end
	
	function Quests:drawRewardText(quest, questReward)
		local rewardText = Quests:getReward(quest)
		if (rewardText) then
			local iconSize = questReward.size.h > 32 and 32 or questReward.size.h
			local questRewardText = UIElement:new({
				parent = questReward,
				pos = { iconSize + 20, 0 },
				size = { questReward.size.w - iconSize - 20, questReward.size.h }
			})
			questRewardText:addAdaptedText(true, rewardText)
			local textWidth = 0
			for i,v in pairs(questRewardText.dispstr) do
				local w = questRewardText.textScale * get_string_length(v, FONTS.MEDIUM)
				if (w > textWidth) then
					textWidth = w
				end
			end
					
			local questRewardIcon = UIElement:new({
				parent = questReward,
				pos = { (questReward.size.w - textWidth - iconSize - 10) / 2, (questReward.size.h - iconSize) / 2 },
				size = { iconSize, iconSize },
				bgImage = quest.rewardid == 0 and "../textures/store/toricredit_tiny.tga" or "../textures/store/items/" .. quest.rewardid .. ".tga"
			})
		end
	end
	
	function Quests:showQuests()
		tbMenuCurrentSection:kill(true)
		if (TB_MENU_QUESTS_NEW) then
			TB_MENU_QUESTS_NEW = false
			TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT - 1
		end
		for i, quest in pairs(QUESTS_DATA) do
			local questView = UIElement:new({
				parent = tbMenuCurrentSection,
				pos = { 5 + (i - 1) * tbMenuCurrentSection.size.w / #QUESTS_DATA, 0 },
				size = { tbMenuCurrentSection.size.w / #QUESTS_DATA - 10, tbMenuCurrentSection.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			local bottomSmudge = TBMenu:addBottomBloodSmudge(questView, i)
			local bgScale = questView.size.w - 10 > questView.size.h / 5 * 3 - 10 and questView.size.h / 5 * 3 - 10 or questView.size.w - 10
			local questBackground = UIElement:new({
				parent = questView,
				pos = { (questView.size.w - bgScale) / 2, 5 },
				size = { bgScale, bgScale },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				shapeType = ROUNDED,
				rounded = bgScale
			})
			local qType = (quest.type == 4 and quest.decap) and "decap" or quest.type
			local questIcon = UIElement:new({
				parent = questBackground,
				pos = { bgScale / 5, bgScale / 5 },
				size = { bgScale / 5 * 3, bgScale / 5 * 3 },
				bgImage = "../textures/menu/general/quests/qtype" .. qType .. ".tga"
			})
			local progress = quest.progress / quest.requirement
			progress = progress > 1 and 1 or progress
			questBackground:addCustomDisplay(false, function()
					set_color(unpack(TB_MENU_DEFAULT_LIGHTER_COLOR))
					draw_disk(questBackground.pos.x + questBackground.size.w / 2, questBackground.pos.y + questBackground.size.h / 2, questBackground.size.h / 2 - 25, questBackground.size.h / 2 - 5, 100, 1, -60, -240, 0)
					set_color(unpack(UICOLORWHITE))
					draw_disk(questBackground.pos.x + questBackground.size.w / 2, questBackground.pos.y + questBackground.size.h / 2, questBackground.size.h / 2 - 25, questBackground.size.h / 2 - 5, 100, 1, -60, -240 * progress, 0)
				end)
			if (quest.timeleft < 0) then
				local progressText = UIElement:new({
					parent = questBackground,
					pos = { questBackground.size.w / 5, -questBackground.size.h / 5 },
					size = { questBackground.size.w / 5 * 3, questBackground.size.h / 8 }
				})
				progressText:addAdaptedText(true, quest.progress .. " / " .. quest.requirement)
			else
				quest.timetick = quest.timetick or os.time()
				local progressText = UIElement:new({
					parent = questBackground,
					pos = { questBackground.size.w / 5, -questBackground.size.h / 3 },
					size = { questBackground.size.w / 5 * 3, questBackground.size.h / 8 },
					bgColor = cloneTable(TB_MENU_DEFAULT_DARKEST_COLOR)
				})
				progressText.bgColor[4] = 0.7
				progressText:addAdaptedText(false, quest.progress .. " / " .. quest.requirement)
				local timeleftText = UIElement:new({
					parent = questBackground,
					pos = { questBackground.size.w / 5, -questBackground.size.h / 5 },
					size = { questBackground.size.w / 5 * 3, questBackground.size.h / 7 }
				})
				timeleftText:addAdaptedText(true, TBMenu:getTime(quest.timeleft - (os.time() - quest.timetick), 2) .. " left")
				timeleftText:addCustomDisplay(true, function()
						timeleftText:uiText(TBMenu:getTime(quest.timeleft - (os.time() - quest.timetick), 2) .. " left", nil, nil, nil, nil, timeleftText.textScale)
					end)
			end
			local questName = UIElement:new({
				parent = questView,
				pos = { 10, questView.size.h / 5 * 3 },
				size = { questView.size.w - 20, questView.size.h / 10 }
			})
			questName:addAdaptedText(true, Quests:getQuestName(quest), nil, nil, FONTS.BIG, nil, 0.7)
			local questTarget = UIElement:new({
				parent = questView,
				pos = { 10, questView.size.h / 10 * 7 },
				size = { questView.size.w - 20, questView.size.h / 5 }
			})
			questTarget:addAdaptedText(true, Quests:getQuestTarget(quest))
			local questReward = UIElement:new({
				parent = questView,
				pos = { 5, questView.size.h / 10 * 9 },
				size = { questView.size.w - 10, questView.size.h / 10 }
			})
			Quests:drawRewardText(quest, questReward)
			if (quest.progress >= quest.requirement) then
				local questClaimBg = UIElement:new({
					parent = questView,
					pos = { 0, 0 },
					size = { questView.size.w, questView.size.h },
					bgColor = { 0, 0, 0, 0.2 }
				})
				local questClaim = UIElement:new({
					parent = questClaimBg,
					pos = { 10, (questClaimBg.size.h + 32) / 3 },
					size = { questClaimBg.size.w - 20, (questClaimBg.size.h + 32) / 3 },
					shapeType = ROUNDED,
					rounded = 5,
					innerShadow = { 0, 5 },
					shadowColor = TB_MENU_DEFAULT_ORANGE,
					bgColor = TB_MENU_DEFAULT_YELLOW,
					interactive = true,
					pressedColor = { 0.902, 0.738, 0.269, 1 },
					hoverColor = { 0.969, 0.781, 0.199, 1 }
				})
				questClaim:addMouseHandlers(nil, function()
						claim_quest(quest.id)
						update_tc_balance()
						TB_MENU_DOWNLOAD_INACTION = true
						tcUpdate = true
						Quests:showMain(true)
					end)
				local claimText = UIElement:new({
					parent = questClaim,
					pos = { 10, 0 },
					size = { questClaim.size.w - 20, questClaim.size.h / 2 }
				})
				claimText:addAdaptedText(false, TB_MENU_LOCALIZED.QUESTSCLAIMREWARD, nil, nil, FONTS.BIG, nil, 0.7, nil, nil, 1.8)
				local buttonSize = questClaim.size.h - 15 > 40 and 40 or questClaim.size.h - 15
				local claimButton = UIElement:new({
					parent = questClaim,
					pos = { 10, -5 - (questClaim.size.h / 2 + buttonSize) / 2 },
					size = { questClaim.size.w - 20, buttonSize },
					shapeType = ROUNDED,
					rounded = 5,
					bgColor = { 0.594, 0.418, 0.14, 1 }
				})
				Quests:drawRewardText(quest, claimButton)
				bottomSmudge:reload()
			end
		end
	end
	
	function Quests:showMain(reload)
		tbMenuCurrentSection:kill(true)
		if (QUESTS_DATA and not reload and not TB_MENU_DEBUG) then
			Quests:showQuests()
		else
			if (reload or TB_MENU_DEBUG) then
				QUESTS_UPDATE_CLOCK = os.clock()
				download_quest(TB_MENU_PLAYER_INFO.username)
			end
			local file = Files:new("../data/quest.txt")
			local waitView = UIElement:new({
				parent = tbMenuCurrentSection,
				pos = { 5, 0 },
				size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			TBMenu:addBottomBloodSmudge(waitView, 1)
			waitView:addCustomDisplay(false, function()
					waitView:uiText(TB_MENU_LOCALIZED.QUESTSUPDATING)
					if (not file:isDownloading()) then
						file:close()
						QUESTS_DATA = Quests:getQuests()
						Quests:showQuests()
					end
				end)
		end
	end
end
