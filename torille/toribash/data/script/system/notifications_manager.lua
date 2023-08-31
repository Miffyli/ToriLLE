-- Notifications Manager Class

do
	Notifications = {}
	Notifications.__index = Notifications
	local cln = {}
	setmetatable(cln, Notifications)
	
	function Notifications:quit()
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Notifications:getNavigationButtons(showBack)
		local navigation = {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
				action = function() Notifications:quit() end,
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, FONTS.BIG) * 0.65 + 30
			},
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONLOGINREWARDS,
				action = function() Notifications:showLoginRewards() end,
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONLOGINREWARDS, FONTS.BIG) * 0.65 + 30,
				right = true,
				sectionId = 1
			},
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONQUESTS,
				action = function() Notifications:showQuests() end,
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONQUESTS, FONTS.BIG) * 0.65 + 30,
				right = true,
				sectionId = 2
			}
		}
		if (showBack) then
			local back = {
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function()
					Notifications:showMain()
				end,
				width = 130
			}
			table.insert(navigation, back)
		end
		return navigation
	end
	
	function Notifications:showLoginRewards()
		local rewards = PlayerInfo:getLoginRewards()
		if (rewards.days == 0 and rewards.available == false and rewards.timeLeft == 0) then
			return 0
		else
			TB_MENU_PLAYER_INFO.rewards = rewards
		end
		if (Rewards:getRewardData()) then
			if (TB_STORE_DATA.ready) then
				Rewards:showMain(tbMenuCurrentSection, TB_MENU_PLAYER_INFO.rewards)
			else
				TBMenu:showDataError(TB_MENU_LOCALIZED.STOREDATALOADERROR)
			end
		end
	end
	
	function Notifications:showQuests()
		Quests:showMain()
	end
	
	function Notifications:showMain()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 4
		local rewards = PlayerInfo:getLoginRewards()
		if (rewards.available) then
			Notifications:showLoginRewards()
			TBMenu:showNavigationBar(Notifications:getNavigationButtons(), true, true, 1)
		else
			Notifications:showQuests()
			TBMenu:showNavigationBar(Notifications:getNavigationButtons(), true, true, 2)
		end
	end
end
