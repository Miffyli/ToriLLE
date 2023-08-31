-- new store manager class

TB_INVENTORY_PAGE = TB_INVENTORY_PAGE or {}
TB_ITEM_DETAILS = TB_ITEM_DETAILS or nil

ITEM_SET = 1458
ITEM_FLAME = 936
ITEM_SHIAI_TOKEN = 2528

INVENTORY_SELECTED_ITEMS = INVENTORY_SELECTED_ITEMS or {}

INVENTORY_DEACTIVATED = 1
INVENTORY_ACTIVATED = 2
INVENTORY_MARKET = 3
INVENTORY_ALL = 4
TB_INVENTORY_MODE = TB_INVENTORY_MODE or INVENTORY_DEACTIVATED

INVENTORY_DEACTIVATE = 1
INVENTORY_ACTIVATE = 2
INVENTORY_ADDSET = 3
INVENTORY_REMOVESET = 4
INVENTORY_UNPACK = 5

INVENTORY_UPDATE = false
INVENTORY_MOUSE_POS = { x = 0, y = 0 }

require("system/iofiles")

do
	Torishop = {}
    Torishop.__index = Torishop
	local cln = {}
	setmetatable(cln, Torishop)

	function Torishop:getItems()
		local file = Files:new("torishop/torishop.txt")
		if (not file.data) then
			return { failed = true }
		end
		local data_types = {
			{ "catid", numeric = true },
			{ "catname" },
			{ "itemid", numeric = true },
			{ "itemname" },
			{ "on_sale", numeric = true },
			{ "now_tc_price", numeric = true },
			{ "now_usd_price", numeric = true },
			{ "price", numeric = true },
			{ "price_usd", numeric = true },
			{ "sale_time", numeric = true },
			{ "sale_promotion", numeric = true },
			{ "qi", numeric = true },
			{ "tier", numeric = true },
			{ "subscriptionid", numeric = true },
			{ "ingame", numeric = true },
			{ "colorid", numeric = true },
			{ "hidden", numeric = true },
			{ "locked", numeric = true }
		}
		local TorishopData = {}
		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^PRODUCT") then
				local _, segments = ln:gsub("\t", "")
				segments = segments
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local item = {}
				for i,v in pairs(data_types) do
					item[v[1]] = data_stream[i + 1]
					if (v.numeric) then
						item[v[1]] = tonumber(item[v[1]])
					end
				end
				item.shortname = item.itemname:gsub("Motion Trail", "Trail")
				TorishopData[item.itemid] = item
			end
		end
		file:close()
		return TorishopData
	end

	function Torishop:getItemInfo(itemid)
		if (not TB_STORE_DATA) then
			TB_STORE_DATA = Torishop:getItems()
		end
		return TB_STORE_DATA[itemid]
	end
	
	function Torishop:getItemIcon(item)
		if (type(item) == "table" and item.itemid) then
			return "../textures/store/items/" .. item.itemid .. ".tga"
		elseif (item) then
			return "../textures/store/items/" .. item .. ".tga"
		end
	end

	function Torishop:getSaleItem(temp)
		local temp = temp or nil
		local itemData = {
			id = 0,
		 	name = "",
			tcOld = 1,
			tc = 1,
			usdOld = 1,
			usd = 1
		}
		if (temp) then
			return itemData
		end
		local file = Files:new("torishop/torishop.txt")
		if (not file.data) then
			return itemData
		end
		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^PRODUCT") then
				local _, segments = ln:gsub("\t", "")
				local data_stream = { ln:match(("([^\t]*)\t?"):rep(segments)) }
				if (data_stream[6] == "1") then
					itemData.id = data_stream[4]
					itemData.name = data_stream[5]
					itemData.tcOld = tonumber(data_stream[9])
					itemData.tc = tonumber(data_stream[7])
					itemData.usdOld = tonumber(data_stream[10])
					itemData.usd = tonumber(data_stream[8])
					break
				end
			end
		end
		file:close()
		return itemData
	end

	function Torishop:getTcSales()
		local data = {}
		local file = Files:new("torishop/torishop.txt")
		if (not file.data) then
			return
		end

		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^PRODUCT") then
				local segments = 19
				local data_stream = { ln:match(("([^\t]*)\t?"):rep(segments)) }
				if (data_stream[2] == '45' and data_stream[18] == '0' and data_stream[19] == '0') then
					table.insert(data, { itemid = data_stream[4], name = data_stream[5], price = tonumber(data_stream[8]) })
				end
			end
		end
		file:close()

		return UIElement:qsort(data, "price", false)
	end

	function Torishop:getInventoryRaw(itemidOnly)
		local file = Files:new("torishop/invent.txt")
		if (not file.data) then
			return false
		end
		local data_types = {
			{ "inventid", numeric = true },
			{ "itemid", numeric = true },
			{ "description", },
			{ "flamename" },
			{ "activateable", bool = true },
			{ "flameid", numeric = true },
			{ "bodypartname" },
			{ "setname" },
			{ "active", bool = true },
			{ "tradeable", bool = true },
			{ "uploadable", bool = true },
			{ "setid", numeric = true },
			{ "sale", bool = true },
			{ "price", numeric = true },
			{ "unpackable", bool = true }
		}
		local inventory = {}
		local itemUpdated = TB_ITEM_DETAILS and 0 or 1
		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^INVITEM") then
				local segments = #data_types + 1
				local data_stream = { ln:match(("([^\t]*)\t?"):rep(segments)) }
				local item = {}

				if (itemidOnly) then
					if (tonumber(data_stream[3]) == itemidOnly) then
						for i,v in pairs(data_types) do
							item[v[1]] = data_stream[i + 1]
							if (v.numeric) then
								item[v[1]] = tonumber(item[v[1]])
							end
							if (v.bool) then
								item[v[1]] = item[v[1]] == '1' and true or false
							end
						end
						item.name = TB_STORE_DATA[item.itemid].itemname
						if (item.itemid ~= ITEM_SHIAI_TOKEN) then
							table.insert(inventory, item)
						end
					end
				else
					for i,v in pairs(data_types) do
						item[v[1]] = data_stream[i + 1]
						if (v.numeric) then
							item[v[1]] = tonumber(item[v[1]])
						end
						if (v.bool) then
							item[v[1]] = item[v[1]] == '1' and true or false
						end
					end
					item.name = TB_STORE_DATA[item.itemid].itemname
					if (itemUpdated == 0 and type(TB_ITEM_DETAILS) == "table") then
						if (item.inventid == TB_ITEM_DETAILS.inventid) then
							TB_ITEM_DETAILS = item
							itemUpdated = 1
						end
					end
					if (item.itemid ~= ITEM_SHIAI_TOKEN) then
						table.insert(inventory, item)
					end
				end
			end
		end
		if (itemUpdated == 0) then
			TB_ITEM_DETAILS = nil
		end
		file:close()
		return inventory
	end

	function Torishop:getInventory(mode)
		local inventoryRaw = Torishop:getInventoryRaw()
		local inventory = {}
		local activatedTemp = {}
		for i,v in pairs(inventoryRaw) do
			if (v.itemid == ITEM_SET) then
				v.contents = {}
			end
			if (v.setid == 0) then
				if 	(mode == INVENTORY_ACTIVATED and v.active and not v.sale) or
				 	(mode == INVENTORY_DEACTIVATED and not v.active and not v.sale) or
					(mode == INVENTORY_MARKET and v.sale) or
					(mode == INVENTORY_ALL) then
					table.insert(inventory, v)
				end
			end
			if	(mode == INVENTORY_ACTIVATED and v.active and v.setid ~= 0) then
				table.insert(activatedTemp, v)
			end
		end
		if (mode == INVENTORY_ACTIVATED) then
			for i, v in pairs(activatedTemp) do
				local isInSet = false
				for j, k in pairs(inventory) do
					if (v.setid == k.inventid) then
						isInSet = true
						break
					end
				end
				if (not isInSet) then
					v.insideset = true
					for s, n in pairs(inventoryRaw) do
						if (v.setid == n.inventid) then
							v.parentset = n
							break
						end
					end
					for s, n in pairs(inventoryRaw) do
						if (n.setid == v.parentset.inventid) then
							table.insert(v.parentset.contents, n)
						end
					end
					table.insert(inventory, v)
				end
			end
		end
		for i,v in pairs(inventoryRaw) do
			if (v.setid ~= 0) then
				for j,k in pairs(inventory) do
					if (v.setid == k.inventid) then
						table.insert(k.contents, v)
						break
					end
				end
			end
		end
		return UIElement:qsort(inventory, "name", false)
	end

	function Torishop:quit()
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end

	function Torishop:refreshInventory()
		INVENTORY_UPDATE = false
		UIElement:runCmd("download " .. TB_MENU_PLAYER_INFO.username)
		Torishop:prepareInventory(tbMenuCurrentSection)
	end

	function Torishop:getNavigationButtons(showBack)
		local navigation = {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
				action = function() TB_MENU_SPECIAL_SCREEN_ISOPEN = 0 Torishop:quit() end,
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, FONTS.BIG) * 0.65 + 30
			}
		}
		if (showBack) then
			local back = {
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function()
					TB_SET_PAGE = 1
					Torishop:showInventory(tbMenuCurrentSection)
				end,
				width = 130
			}
			table.insert(navigation, back)
		end
		return navigation
	end

	function Torishop:showStore(viewElement)
		viewElement:kill(true)
	end

	function Torishop:showSetDetailsItems(viewElement, items)
		local itemScale = viewElement.size.h / 2 > 64 and 64 or viewElement.size.h / 2
		local line = 1
		local itemsPerLine = math.floor(viewElement.size.w / itemScale)
		local horizontalShift = (viewElement.size.w - itemsPerLine * itemScale) / 2
		for i,v in pairs(items) do
			if (line * itemScale > viewElement.size.h) then
				break
			end
			local icon = UIElement:new({
				parent = viewElement,
				pos = { horizontalShift + ((i - 1) % itemsPerLine) * itemScale, (line - 1) * itemScale },
				size = { itemScale, itemScale },
				bgImage = "../textures/store/items/" .. v.itemid .. ".tga"
			})
			if (i % itemsPerLine == 0) then
				line = line + 1
			end
		end
	end

	function Torishop:showInventoryItem(item)
		inventoryItemView:kill(true)
		TB_ITEM_DETAILS = item

		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryItemView, 2)
		local itemData = TB_STORE_DATA[item.itemid]
		if (item.itemid == ITEM_SET) then
			local itemName = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, 0 },
				size = { inventoryItemView.size.w - 20, 50 }
			})

			local numItemsStr = "(" .. TB_MENU_LOCALIZED.STORESETEMPTY .. ")"
			if (#item.contents == 1) then
				numItemsStr = "(1 " .. TB_MENU_LOCALIZED.STOREITEM .. ")"
			elseif (#item.contents > 1) then
				numItemsStr = "(" .. #item.contents .. " " .. TB_MENU_LOCALIZED.STOREITEMS .. ")"
			end

			itemName:addCustomDisplay(true, function()
					itemName:uiText(item.name .. " " .. numItemsStr, nil, nil, FONTS.BIG, nil, 0.6, nil, nil, nil, nil, 0.2)
				end)
			local setName = UIElement:new({
				parent = inventoryItemView,
				pos = { 0, itemName.size.h },
				size = { inventoryItemView.size.w, 20 }
			})
			setName:addCustomDisplay(true, function()
					setName:uiText(item.setname, nil, nil, FONTS.MEDIUM, nil, 0.9, nil, nil, nil, nil, 0.05)
				end)
			local inventoryView = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, itemName.size.h + setName.size.h + 10 },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 2 - itemName.size.h - setName.size.h },
				bgColor = { 0, 0, 0, 0.1 }
			})
			local inventoryHolder = UIElement:new({
				parent = inventoryView,
				pos = { 5, 10 },
				size = { inventoryView.size.w - 10, inventoryView.size.h - 20 }
			})
			Torishop:showSetDetailsItems(inventoryHolder, item.contents)
		elseif (item.itemid == ITEM_FLAME) then
			local itemName = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, 0 },
				size = { inventoryItemView.size.w - 20, 50 }
			})
			itemName:addCustomDisplay(true, function()
					itemName:uiText(item.name, nil, nil, FONTS.BIG, nil, 0.6, nil, nil, nil, nil, 0.2)
				end)
			local flameName = UIElement:new({
				parent = inventoryItemView,
				pos = { 0, itemName.size.h },
				size = { inventoryItemView.size.w, 20 }
			})
			flameName:addCustomDisplay(true, function()
					flameName:uiText(item.flamename, nil, nil, FONTS.MEDIUM, nil, 0.9, nil, nil, nil, nil, 0.05)
				end)
			local itemInfo = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, itemName.size.h + flameName.size.h + 10 },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 2 - itemName.size.h - flameName.size.h },
				bgColor = { 0, 0, 0, 0.1 }
			})
			local itemIcon = UIElement:new({
				parent = itemInfo,
				pos = { 8, (itemInfo.size.h - 64) / 2 },
				size = { 64, 64 },
				bgImage = "../textures/store/items/" .. item.itemid .. ".tga"
			})
			local itemDescription = UIElement:new({
				parent = itemInfo,
				pos = { 80, 10 },
				size = { itemInfo.size.w - 90, itemInfo.size.h - 20 }
			})
			itemDescription:addAdaptedText(true, TB_MENU_LOCALIZED.STOREFLAMEBODYPART .. " ".. item.bodypartname:lower() .. "\n" .. TB_MENU_LOCALIZED.STOREFLAMEID .. ": " .. item.flameid, nil, nil, 4, LEFTMID, 0.6)
		else
			if (item.insideset) then
				local itemName = UIElement:new({
					parent = inventoryItemView,
					pos = { 10, 0 },
					size = { inventoryItemView.size.w - 20, 50 }
				})
				itemName:addCustomDisplay(true, function()
						itemName:uiText(item.name, nil, nil, FONTS.BIG, nil, 0.6, nil, nil, nil, nil, 0.2)
					end)
				local setCaption = UIElement:new({
					parent = inventoryItemView,
					pos = { 10, 50 },
					size = { inventoryItemView.size.w - 20, 20 }
				})
				setCaption:addCustomDisplay(true, function()
						setCaption:uiText(TB_MENU_LOCALIZED.STOREITEMINSIDESET .. ": " .. item.parentset.setname, nil, nil, FONTS.MEDIUM, nil, 0.9, nil, nil, nil, nil, 0.05)
					end)
			else
				local itemName = UIElement:new({
					parent = inventoryItemView,
					pos = { 10, 0 },
					size = { inventoryItemView.size.w - 20, 70 }
				})
				itemName:addCustomDisplay(true, function()
						itemName:uiText(item.name, nil, nil, FONTS.BIG, nil, 0.6, nil, nil, nil, nil, 0.2)
					end)
			end
			local itemInfo = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, 80 },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 2 - 70 },
				bgColor = { 0, 0, 0, 0.1 }
			})
			local itemIcon = UIElement:new({
				parent = itemInfo,
				pos = { 8, (itemInfo.size.h - 64) / 2 },
				size = { 64, 64 },
				bgImage = "../textures/store/items/" .. item.itemid .. ".tga"
			})
			local itemDescription = UIElement:new({
				parent = itemInfo,
				pos = { 80, 10 },
				size = { itemInfo.size.w - 90, itemInfo.size.h - 20 }
			})
			local modelBodypartStr = ''
			if (item.bodypartname ~= '0') then
				modelBodypartStr = TB_MENU_LOCALIZED.STOREOBJITEMBODYPART .. " " .. item.bodypartname:lower() .. "\n"
			end
			local itemDescStr = item.description == '0' and '' or item.description
			if (modelBodypartStr .. itemDescStr == '') then
				itemDescStr = TB_MENU_LOCALIZED.STOREITEMNODESCRIPTION
			end
			itemDescription:addCustomDisplay(true, function()
					itemDescription:uiText(modelBodypartStr .. itemDescStr, nil, nil, 4, LEFTMID, 0.6)
				end)
		end
		local buttonYPos = -inventoryItemView.size.h / 7
		if (item.itemid ~= ITEM_SET) then
			local addSetButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.3 }
			})
			if (item.insideset) then
				addSetButton:addCustomDisplay(false, function()
						addSetButton:uiText(TB_MENU_LOCALIZED.STOREITEMGOTOSET, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				addSetButton:addMouseHandlers(nil, function()
						Torishop:showInventoryPage(item.parentset.contents, nil, mode, TB_MENU_LOCALIZED.STORESETITEMNAME .. ": " .. item.parentset.setname, "invid" .. item.parentset.inventid, nil, true)
					end)
			elseif (item.setid == 0) then
				addSetButton:addCustomDisplay(false, function()
						addSetButton:uiText(TB_MENU_LOCALIZED.STOREITEMADDTOSET, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				addSetButton:addMouseHandlers(nil, function()
						Torishop:showSetSelection(item)
					end)
			else
				addSetButton:addCustomDisplay(false, function()
						addSetButton:uiText(TB_MENU_LOCALIZED.STOREITEMREMOVEFROMSET, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				addSetButton:addMouseHandlers(nil, function()
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						INVENTORY_SELECTION_RESET = true
						local dialogMessage = TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET2 .. "?")
						show_dialog_box(INVENTORY_REMOVESET, dialogMessage, "0 " .. item.inventid)
					end)
			end
			buttonYPos = buttonYPos - inventoryItemView.size.h / 7
		elseif (#item.contents > 0) then
			local viewSet = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.3 }
			})
			viewSet:addCustomDisplay(false, function()
					viewSet:uiText(TB_MENU_LOCALIZED.STOREVIEWSETITEMS, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
				end)
			viewSet:addMouseHandlers(nil, function()
					Torishop:showInventoryPage(item.contents, nil, mode, TB_MENU_LOCALIZED.STOREITEMSINSET .. ": " .. item.setname, "invid" .. item.inventid, nil, true)
				end, nil)
			buttonYPos = buttonYPos - inventoryItemView.size.h / 7
		end
		--[[if (item.tradeable) then
			local marketSellButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.3 }
			})
			marketSellButton:addCustomDisplay(false, function()
					marketSellButton:uiText(TB_MENU_LOCALIZED.STORESELLMARKET, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
				end)
			marketSellButton:addMouseHandlers(nil, function()
					show_dialog_box(INVENTORY_MARKETSELL, item.inventid, TB_MENU_LOCALIZED.STOREDIALOGMARKETSELL1 .. " " .. item.name .. " " .. TB_MENU_LOCALIZED.STOREDIALOGMARKETSELL2)
				end, nil)
			buttonYPos = buttonYPos - inventoryItemView.size.h / 7
		end--]]
		if (item.activateable and not item.unpackable) then
			local activateButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.3 }
			})
			if (item.active) then
				activateButton:addCustomDisplay(false, function()
						activateButton:uiText(TB_MENU_LOCALIZED.STOREITEMDEACTIVATE, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				activateButton:addMouseHandlers(nil, function(s, posX, posY)
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						show_dialog_box(INVENTORY_DEACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 .. "?"), item.inventid)
					end, nil)
			else
				activateButton:addCustomDisplay(false, function()
						activateButton:uiText(TB_MENU_LOCALIZED.STOREITEMACTIVATE, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				activateButton:addMouseHandlers(nil, function()
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						show_dialog_box(INVENTORY_ACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?"), item.inventid)
					end, nil)
			end
		elseif (item.unpackable) then
			local unpackButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.3 }
			})
			unpackButton:addCustomDisplay(false, function()
					unpackButton:uiText(TB_MENU_LOCALIZED.STOREITEMUNPACK, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
				end)
			unpackButton:addMouseHandlers(nil, function()
					INVENTORY_UPDATE = true
					INVENTORY_MOUSE_POS = { x = posX, y = posY }
					show_dialog_box(INVENTORY_UNPACK, TB_MENU_LOCALIZED.STOREDIALOGUNPACK1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKINFO, item.inventid)
				end, nil)
		end
	end

	function Torishop:showSetSelection(item)
		inventoryItemView:kill(true)

		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryItemView, 2)

		local inventory = Torishop:getInventory(INVENTORY_ALL)
		local sets = {}
		for i,v in pairs(inventory) do
			if (v.itemid == ITEM_SET) then
				table.insert(sets, v)
			end
		end
		local toReload = UIElement:new({
			parent = inventoryItemView,
			pos = { 0, 0 },
			size = { inventoryItemView.size.w, inventoryItemView.size.h }
		})
		local topBar = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { toReload.size.w, 50 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local topBarName = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w - 20, topBar.size.h }
		})
		topBarName:addCustomDisplay(true, function()
				topBarName:uiText(TB_MENU_LOCALIZED.STORESETSELECT, nil, nil, FONTS.MEDIUM, nil, nil, nil, nil, nil, nil, 0.2)
			end)
		local botBar = UIElement:new({
			parent = toReload,
			pos = { 0, -toReload.size.h / 6 },
			size = { toReload.size.w, toReload.size.h / 6 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local cancelButton = UIElement:new({
			parent = botBar,
			pos = { 10, (toReload.size.h / 6 - toReload.size.h / 8) / 2 },
			size = { botBar.size.w - 20, toReload.size.h / 8 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.3 }
		})
		cancelButton:addCustomDisplay(false, function()
				cancelButton:uiText(TB_MENU_LOCALIZED.STOREBUTTONCANCEL, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
			end)
		cancelButton:addMouseHandlers(nil, function()
				if (item) then
					Torishop:showInventoryItem(item)
				else
					Torishop:showSelectionControls()
				end
			end)

		local mainHolder = UIElement:new({
			parent = inventoryItemView,
			pos = { 0, topBar.size.h },
			size = { inventoryItemView.size.w, inventoryItemView.size.h - topBar.size.h - botBar.size.h }
		})
		local setsHolder = UIElement:new({
			parent = mainHolder,
			pos = { 0, 0 },
			size = { mainHolder.size.w - 20, mainHolder.size.h }
		})
		local listSets = {}
		for i,v in pairs(sets) do
			local setElement = UIElement:new({
				parent = setsHolder,
				pos = { 0, #listSets * 40 },
				size = { setsHolder.size.w, 40 },
				interactive = true,
				bgColor = { 0, 0, 0, 0 },
				hoverColor = { 0, 0, 0, 0.2 },
				pressedColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			setElement:addMouseHandlers(nil, function()
					INVENTORY_UPDATE = true
					INVENTORY_MOUSE_POS = { x = posX, y = posY }
					INVENTORY_SELECTION_RESET = true
					if (item) then
						show_dialog_box(INVENTORY_ADDSET, TB_MENU_LOCALIZED.STOREDIALOGADDTOSET1 .. " " .. item.name .. " " .. TB_MENU_LOCALIZED.STOREDIALOGADDTOSET2 .. "?", v.inventid .. " " .. item.inventid)
					else
						local inventidStr = ""
						for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
							inventidStr = inventidStr == "" and v.inventid or inventidStr .. ";" .. v.inventid
						end
						local itemsStr = #INVENTORY_SELECTED_ITEMS == 1 and INVENTORY_SELECTED_ITEMS[1].name or #INVENTORY_SELECTED_ITEMS .. " " .. TB_MENU_LOCALIZED.STOREITEMS
						show_dialog_box(INVENTORY_ADDSET, TB_MENU_LOCALIZED.STOREDIALOGADDTOSET1 .. " " .. itemsStr .. " " .. TB_MENU_LOCALIZED.STOREDIALOGADDTOSET2 .. "?", v.inventid .. " " .. inventidStr)
					end
				end)
			table.insert(listSets, setElement)
			local icon = UIElement:new({
				parent = setElement,
				pos = { 5, 5 },
				size = { setElement.size.h - 10, setElement.size.h - 10 },
				bgImage = "../textures/store/items/" .. ITEM_SET .. ".tga"
			})
			local setName = UIElement:new({
				parent = setElement,
				pos = { setElement.size.h, 0 },
				size = { setElement.size.w - setElement.size.h, setElement.size.h }
			})
			local itemsStr
			if (#v.contents == 0) then
				itemsStr = "(" .. TB_MENU_LOCALIZED.STORESETEMPTY .. ")"
			elseif (#v.contents == 1) then
				itemsStr = "(1 " .. TB_MENU_LOCALIZED.STOREITEM .. ")"
			else
				itemsStr = "(" .. #v.contents .. " " .. TB_MENU_LOCALIZED.STOREITEMS .. ")"
			end
			setName:addCustomDisplay(true, function()
					setName:uiText(v.setname .. " " .. itemsStr, nil, nil, 4, LEFTMID, 0.7)
				end)
		end

		for i,v in pairs(listSets) do
			v:hide()
		end

		local scrollBar = TBMenu:spawnScrollBar(setsHolder, #listSets, 40)
		scrollBar:makeScrollBar(setsHolder, listSets, toReload)
	end

	function Torishop:showSelectionControls()
		inventoryItemView:kill(true)

		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryItemView, 2)
		local controlsName = UIElement:new({
			parent = inventoryItemView,
			pos = { 10, 0 },
			size = { inventoryItemView.size.w - 20, 50 }
		})
		local itemsStr = #INVENTORY_SELECTED_ITEMS == 1 and INVENTORY_SELECTED_ITEMS[1].name or (#INVENTORY_SELECTED_ITEMS .. " " .. TB_MENU_LOCALIZED.STOREITEMS)
		controlsName:addCustomDisplay(true, function()
				controlsName:uiText(TB_MENU_LOCALIZED.STORESETSELECTIONCONTROLS .. "\n" .. itemsStr, nil, nil, FONTS.MEDIUM, nil, nil, nil, nil, nil, nil, 0.2)
			end)
		local buttonYPos = -inventoryItemView.size.h / 7

		local removeSetButton = UIElement:new({
			parent = inventoryItemView,
			pos = { 10, buttonYPos },
			size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.3 }
		})
		removeSetButton:addCustomDisplay(false, function()
				removeSetButton:uiText(TB_MENU_LOCALIZED.STOREITEMREMOVEFROMSET, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
			end)
		removeSetButton:addMouseHandlers(nil, function()
				INVENTORY_UPDATE = true
				INVENTORY_MOUSE_POS = { x = posX, y = posY }
				INVENTORY_SELECTION_RESET = true
				local inventidStr = ""
				for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
					inventidStr = inventidStr == "" and v.inventid or inventidStr .. ";" .. v.inventid
				end
				local itemsStr = #INVENTORY_SELECTED_ITEMS == 1 and INVENTORY_SELECTED_ITEMS[1].name or #INVENTORY_SELECTED_ITEMS .. " " .. TB_MENU_LOCALIZED.STOREITEMS
				show_dialog_box(INVENTORY_REMOVESET, TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET1 .. " " .. itemsStr .. " " .. TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET2 .. "?", "0 " .. inventidStr)
			end)
		buttonYPos = buttonYPos - inventoryItemView.size.h / 7

		local addSetButton = UIElement:new({
			parent = inventoryItemView,
			pos = { 10, buttonYPos },
			size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.3 }
		})
		addSetButton:addCustomDisplay(false, function()
				addSetButton:uiText(TB_MENU_LOCALIZED.STOREITEMADDTOSET, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
			end)
		addSetButton:addMouseHandlers(nil, function()
				Torishop:showSetSelection(false)
			end)
		buttonYPos = buttonYPos - inventoryItemView.size.h / 7

		local deactivateButton = UIElement:new({
			parent = inventoryItemView,
			pos = { 10, buttonYPos },
			size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.3 }
		})
		deactivateButton:addCustomDisplay(false, function()
				deactivateButton:uiText(TB_MENU_LOCALIZED.STOREITEMDEACTIVATE, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
			end)
		deactivateButton:addMouseHandlers(nil, function()
				INVENTORY_UPDATE = true
				INVENTORY_MOUSE_POS = { x = posX, y = posY }
				INVENTORY_SELECTION_RESET = true
				local inventidStr = ""
				for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
					inventidStr = inventidStr == "" and v.inventid or inventidStr .. ";" .. v.inventid
				end
				show_dialog_box(INVENTORY_DEACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE1 .. " " .. itemsStr .. (TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 .. "?"), inventidStr)
			end)
		buttonYPos = buttonYPos - inventoryItemView.size.h / 7

		local activateButton = UIElement:new({
			parent = inventoryItemView,
			pos = { 10, buttonYPos },
			size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.3 }
		})
		activateButton:addCustomDisplay(false, function()
				activateButton:uiText(TB_MENU_LOCALIZED.STOREITEMACTIVATE, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
			end)
		activateButton:addMouseHandlers(nil, function()
				INVENTORY_UPDATE = true
				INVENTORY_MOUSE_POS = { x = posX, y = posY }
				INVENTORY_SELECTION_RESET = true
				local inventidStr = ""
				for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
					inventidStr = inventidStr == "" and v.inventid or inventidStr .. ";" .. v.inventid
				end
				show_dialog_box(INVENTORY_ACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. itemsStr .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?"), inventidStr)
			end)
		buttonYPos = buttonYPos - inventoryItemView.size.h / 7
	end

	function Torishop:showInventorySingleItemData(itemView, item, itemScale)
		local icon = UIElement:new({
			parent = itemView,
			pos = { (itemScale - 64) / 2, (itemScale - 64) / 2 },
			size = { 64, 64 },
			bgImage = "../textures/store/items/" .. item.itemid .. ".tga"
		})
		local info = UIElement:new({
			parent = itemView,
			pos = { 0, itemView.size.h / 2 },
			size = { itemView.size.w, itemView.size.h / 2 - itemView.rounded }
		})
		if (item.itemid ~= ITEM_SET) then
			local itemSelected = false
			for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
				if (v.inventid == item.inventid) then
					itemSelected = true
					break
				end
			end
			local selectBox = UIElement:new({
				parent = itemView,
				pos = { -30, 10 },
				size = { 20, 20 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.2 },
				hoverColor = { 0, 0, 0, 0.4 }
			})
			local selectIcon = UIElement:new({
				parent = selectBox,
				pos = { 0, 0 },
				size = { selectBox.size.w, selectBox.size.h },
				bgImage = "../textures/menu/general/buttons/checkmark.tga"
			})
			if (not itemSelected) then
				selectIcon:hide(true)
			end

			selectBox:addMouseHandlers(nil, function()
					for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
						if (v.inventid == item.inventid) then
							table.remove(INVENTORY_SELECTED_ITEMS, i)
							selectIcon:hide()
							if (#INVENTORY_SELECTED_ITEMS == 0) then
								Torishop:showInventoryItem(TB_ITEM_DETAILS)
							else
								Torishop:showSelectionControls()
							end
							return
						end
					end
					table.insert(INVENTORY_SELECTED_ITEMS, item)
					Torishop:showSelectionControls()
					selectIcon:show(true)
				end)
		end

		local setname = ""
		local setNumItems = ""
		if (item.itemid == ITEM_SET) then
			setname = item.setname == '0' and "" or ": " .. item.setname
			setNumItems = " (" .. TB_MENU_LOCALIZED.STORESETEMPTY .. ")"
			if (#item.contents == 1) then
				setNumItems = " (1 " .. TB_MENU_LOCALIZED.STOREITEM .. ")"
			elseif (#item.contents > 1) then
				setNumItems = " (" .. #item.contents .. " " .. TB_MENU_LOCALIZED.STOREITEMS .. ")"
			end
		end
		info:addCustomDisplay(false, function()
				local color = itemView:getButtonColor()
				set_color(color[1], color[2], color[3], color[4] * 2)
				draw_quad(info.pos.x, info.pos.y, info.size.w, info.size.h)
				info:uiText(item.name .. setname .. setNumItems, nil, nil, 4, nil, 0.5, nil, nil, { 1 - color[1], 1 - color[2], 1 - color[3], color[4] * 3 })
			end)
	end

	function Torishop:showInventoryPage(inventoryItems, pageShift, mode, title, pageid, itemScale, showBack)
		local showBack = showBack or false
		local itemScale = itemScale or 100

		local inventoryOptions = {
			{ name = TB_MENU_LOCALIZED.STOREACTIVATEDINVENTORY, val = INVENTORY_ACTIVATED },
			{ name = TB_MENU_LOCALIZED.STOREDEACTIVATEDINVENTORY, val = INVENTORY_DEACTIVATED },
			{ name = TB_MENU_LOCALIZED.STOREMARKETINVENTORY, val = INVENTORY_MARKET },
			{ name = TB_MENU_LOCALIZED.STOREINVENTORYALLITEMS, val = INVENTORY_ALL },
		}

		TB_INVENTORY_PAGE[pageid] = TB_INVENTORY_PAGE[pageid] or 1

		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar(Torishop:getNavigationButtons(showBack), true)

		inventoryView:kill(true)
		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryView, 1)

		local inventoryTitle = UIElement:new({
			parent = inventoryView,
			pos = { 25, 5 },
			size = { inventoryView.size.w - 75, 50 }
		})

		if (mode) then
			local inventoryModeButton = nil
			for i,v in pairs(inventoryOptions) do
				if (v.val == mode) then
					inventoryModeButton = UIElement:new({
						parent = inventoryTitle,
						pos = { inventoryTitle.size.w / 2 + get_string_length(v.name, FONTS.BIG) * 0.7 / 2, 0 },
						size = { inventoryTitle.size.h, inventoryTitle.size.h },
						interactive = true,
						shapeType = ROUNDED,
						rounded = inventoryTitle.size.h,
						bgColor = { 0, 0, 0, 0 },
						hoverColor = { 1, 1, 1, 0.2 },
						pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
						bgImage = "../textures/menu/general/buttons/arrowbotwhite.tga"
					})
					inventoryTitle:addCustomDisplay(true, function()
							inventoryTitle:uiText(v.name, nil, nil, FONTS.BIG, nil, 0.7, nil, nil, nil, nil, 0.2)
						end)
					break
				end
			end
			local filterSelection = UIElement:new({
				parent = inventoryView,
				pos = { inventoryView.size.w / 6, 0 },
				size = { inventoryView.size.w / 3 * 2, #inventoryOptions * 40 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			for i, v in pairs(inventoryOptions) do
				local filterSelectionOption = UIElement:new({
					parent = filterSelection,
					pos = { 0, (i - 1) * 40 },
					size = { filterSelection.size.w, 40 },
					interactive = true,
					bgColor = { 0, 0, 0, 0 },
					hoverColor = { 0, 0, 0, 0.2 },
					pressedColor = { 1, 0, 0, 0.1 }
				})
				filterSelectionOption:addCustomDisplay(false, function()
						filterSelectionOption:uiText(v.name, nil, nil, 4, CENTERMID, 0.7)
					end)
				filterSelectionOption:addMouseHandlers(nil, function()
						Torishop:showInventory(tbMenuCurrentSection, v.val)
					end, nil)
			end
			inventoryModeButton:addMouseHandlers(nil, function()
					local filterBackground = UIElement:new({
						parent = tbMenuCurrentSection,
						pos = { 0, 0 },
						size = { tbMenuCurrentSection.size.w, tbMenuCurrentSection.size.h },
						interactive = true
					})
					filterBackground:addMouseHandlers(nil, function()
							filterSelection:hide()
							filterBackground:kill()
						end)
					filterSelection:show()
				end, nil)
			filterSelection:hide()
		else
			inventoryTitle:addCustomDisplay(true, function()
					inventoryTitle:uiText(title, nil, nil, FONTS.BIG, nil, 0.7, nil, nil, nil, nil, 0.2)
				end)
		end

		local inventoryPage = UIElement:new({
			parent = inventoryView,
			pos = { 50, inventoryTitle.size.h + 10 },
			size = { inventoryView.size.w - 100, inventoryView.size.h - inventoryTitle.size.h - 20 }
		})

		local lineItems = math.floor(inventoryPage.size.w / itemScale)
		local invRows = math.floor((inventoryPage.size.h - 20) / itemScale)
		local maxPages = math.ceil(#inventoryItems / lineItems / invRows)

		local page = pageShift and TB_INVENTORY_PAGE[pageid] + pageShift or TB_INVENTORY_PAGE[pageid]
		page = page < 1 and maxPages or page
		TB_INVENTORY_PAGE[pageid] = page > maxPages and 1 or page

		local invStartShift = 1 + (TB_INVENTORY_PAGE[pageid] - 1) * lineItems * invRows
		local line = 1


		if (maxPages > 1) then
			local inventoryPrevPage = UIElement:new({
				parent = inventoryView,
				pos = { 10, (inventoryView.size.h - 32) / 2 },
				size = { 32, 64 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.2 },
				bgImage = "../textures/menu/general/buttons/arrowleft.tga"
			})
			inventoryPrevPage:addMouseHandlers(nil, function()
					Torishop:showInventoryPage(inventoryItems, -1, mode, title, pageid, itemScale, showBack)
				end)
			local inventoryNextPage = UIElement:new({
				parent = inventoryView,
				pos = { -42, (inventoryView.size.h - 32) / 2 },
				size = { 32, 64 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.2 },
				bgImage = "../textures/menu/general/buttons/arrowright.tga"
			})
			inventoryNextPage:addMouseHandlers(nil, function()
					Torishop:showInventoryPage(inventoryItems, 1, mode, title, pageid, itemScale, showBack)
				end)
		end

		local inventoryHolder = UIElement:new({
			parent = inventoryPage,
			pos = { (inventoryPage.size.w - itemScale * lineItems) / 2, 0 },
			size = { itemScale * lineItems, inventoryPage.size.h }
		})

		local inventoryPagination = UIElement:new({
			parent = inventoryHolder,
			pos = { 0, -20 },
			size = { inventoryHolder.size.w, 20 }
		})
		inventoryPagination:addCustomDisplay(true, function()
				inventoryPagination:uiText(TB_MENU_LOCALIZED.PAGINATIONPAGE .. " " .. TB_INVENTORY_PAGE[pageid] .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF .. " " .. maxPages)
			end)

		if (#inventoryItemView.child == 0) then
			if (#INVENTORY_SELECTED_ITEMS == 0) then
				Torishop:showInventoryItem(TB_ITEM_DETAILS or inventoryItems[invStartShift])
			else
				Torishop:showSelectionControls()
			end
		end

		for i = invStartShift, #inventoryItems do
			if (line * itemScale > inventoryHolder.size.h) then
				break
			end
			local item = UIElement:new({
				parent = inventoryHolder,
				pos = { ((i - 1) % lineItems) * itemScale, (line - 1) * itemScale },
				size = { itemScale, itemScale },
				shapeType = ROUNDED,
				rounded = 10,
				interactive = true,
				bgColor = { 0, 0, 0, 0 },
				hoverColor = { 0, 0, 0, 0.4 },
				pressedColor = { 1, 1, 1, 0.3 }
			})
			local itemSelected = UIElement:new({
				parent = item,
				pos = { 5, 5 },
				size = { item.size.w - 10, item.size.h - 10 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = item.shapeType,
				rounded = item.rounded
			})
			if (inventoryItems[i].inventid ~= TB_ITEM_DETAILS.inventid) then
				itemSelected:hide()
			end
			itemSelected:addCustomDisplay(false, function()
					if (inventoryItems[i].inventid ~= TB_ITEM_DETAILS.inventid) then
						itemSelected:hide()
					end
				end)
			item:addMouseHandlers(nil, function()
					Torishop:showInventoryItem(inventoryItems[i])
					itemSelected:show()
					item:reload()
				end)
			Torishop:showInventorySingleItemData(item, inventoryItems[i], itemScale)
			if (i % lineItems == 0) then
				line = line + 1
			end
		end
	end

	function Torishop:prepareInventory(viewElement)
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 1
		viewElement:kill(true)

		download_inventory()
		TB_MENU_DOWNLOAD_INACTION = true
		local inventoryWait = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryWait, 1)
		local startTime = os.time()
		inventoryWait:addCustomDisplay(false, function()
				inventoryWait:uiText(TB_MENU_LOCALIZED.STOREINVENTORYLOADING .. string.rep(".", (os.time() - startTime) % 4))
				for i,v in pairs(get_downloads()) do
					if (v:match("data/script/torishop/invent.txt")) then
						return
					end
				end
				Torishop:showInventory(viewElement)
			end)
	end

	function Torishop:showInventory(viewElement, mode)
		viewElement:kill(true)
		local mode = mode or TB_INVENTORY_MODE
		TB_INVENTORY_MODE = mode
		local playerInventory = Torishop:getInventory(mode)
		inventoryView = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.7 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		inventoryItemView = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.7 + 5, 0 },
			size = { viewElement.size.w * 0.3 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Torishop:showInventoryPage(playerInventory, nil, mode, nil, "page" .. mode)
	end

	function Torishop:showTcPurchase(tcPurchaseView)
		local tcData = Torishop:getTcSales()
		for i,v in pairs(tcData) do
			local tcEntry = UIElement:new({
				parent = tcPurchaseView,
				pos = { 0, (i - 1) * tcPurchaseView.size.h / #tcData },
				size = { tcPurchaseView.size.w, tcPurchaseView.size.h / #tcData },
				interactive = true,
				bgColor = { 0, 0, 0, 0 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.1 },
				hoverSound = 31
			})
			tcEntry:addMouseHandlers(nil, function()
					if (TB_MENU_PLAYER_INFO.username == '') then
						TBMenu:showLoginError(tcPurchaseView.parent, TB_MENU_LOCALIZED.STOREPURCHASETORICREDITS)
						return
					end
					UIElement:runCmd("steam purchase " .. v.itemid)
					local waitNotification = UIElement:new({
						parent = tbMenuMain,
						pos = { WIN_W / 2 - 200, WIN_H / 2 - 50 },
						size = { 400, 100 },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR
					})
					local pressTime = os.time()
					waitNotification:addCustomDisplay(false, function()
							local waitStr = TB_MENU_LOCALIZED.STORESTEAMPURCHASELOADING .. string.rep(".", (os.time() - pressTime) % 3)
							if (os.time() - pressTime >= 30) then
								waitStr = TB_MENU_LOCALIZED.STORESTEAMPURCHASEERROR
							elseif (os.time() - pressTime >= 35) then
								waitNotification:kill()
							end
							waitNotification:uiText(waitStr)
						end)
					add_hook("console", "tbMenuConsoleIgnore", function(s,i)
							if (s:match("Transaction initiated")) then
								waitNotification:kill()
								return 1
							end
						end)
				end, nil)
			local iconScale = tcEntry.size.h - 20 < 128 and tcEntry.size.h - 20 or 128
			local tcIcon = UIElement:new({
				parent = tcEntry,
				pos = { tcEntry.size.w / 20, (tcEntry.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = "../textures/store/toricredit.tga"
			})
			local itemDetails = UIElement:new({
				parent = tcEntry,
				pos = { tcIcon.shift.x * 2 + tcIcon.size.w, 0 },
				size = { tcEntry.size.w - (tcIcon.shift.x * 3 + tcIcon.size.w), tcEntry.size.h }
			})
			local itemName = UIElement:new({
				parent = itemDetails,
				pos = { 0, itemDetails.size.h * 0.1 },
				size = { itemDetails.size.w, itemDetails.size.h * 0.5 }
			})
			local itemNameSize = 1
			while (not itemName:uiText(v.name, nil, nil, FONTS.BIG, LEFT, itemNameSize, nil, nil, nil, nil, nil, true)) do
				itemNameSize = itemNameSize - 0.05
			end
			itemName:addCustomDisplay(true, function()
					itemName:uiText(v.name, nil, nil, FONTS.BIG, LEFTBOT, itemNameSize, nil, 1)
				end)

			local itemPrice = UIElement:new({
				parent = itemDetails,
				pos = { 0, itemDetails.size.h * 0.6 },
				size = { itemDetails.size.w, itemDetails.size.h * 0.4 }
			})
			local itemPriceSize = 1
			while (not itemPrice:uiText("$" .. v.price, nil, nil, FONTS.MEDIUM, LEFT, itemPriceSize, nil, nil, nil, nil, nil, true)) do
				itemPriceSize = itemPriceSize - 0.05
			end
			itemPrice:addCustomDisplay(true, function()
					itemPrice:uiText("$" .. v.price, nil, nil, FONTS.MEDIUM, LEFT, itemPriceSize, nil, 0.6)
				end)
		end
	end

	function Torishop:showCollectorsCardsWC()
		TB_MENU_IGNORE_REWARDS = 1
		local overlay = TBMenu:spawnWindowOverlay({ 1, 1, 1, 0.5 })
		overlay:addMouseHandlers(nil, function()
				overlay:kill()
				TB_MENU_IGNORE_REWARDS = 0
			end)
		local cardsData = {
			{ player = "Gentleman", itemid = 3100 },
			{ player = "Euphoria", itemid = 3098 },
			{ player = "Code", itemid = 3096 },
			{ player = "Diamond", itemid = 3097 },
			{ player = "nervau", itemid = 3101 },
			{ player = "Fade", itemid = 3099 },
			{ player = "Nerfpls", itemid = 3093 },
			{ player = "McFarbo", itemid = 3092 },
		}
		local selectedPlayer = math.random(1, #cardsData)

		local cardsOverlay = UIElement:new({
			parent = overlay,
			pos = { 100, 100 },
			size = { overlay.size.w - 200, overlay.size.h - 200 },
			bgColor = { 0.118, 0.016, 0.043, 1 },
			interactive = true
		})
		local scale = cardsOverlay.size.h * 2 < cardsOverlay.size.w and cardsOverlay.size.h or cardsOverlay.size.w / 2
		local cardsBackgroundImage = UIElement:new({
			parent = cardsOverlay,
			pos = { cardsOverlay.size.w / 2 - scale, (cardsOverlay.size.h - scale) / 2 },
			size = { scale * 2, scale },
			bgImage = "../textures/menu/worldsbackground.tga"
		})
		local cardsBackgroundAnimation = UIElement:new({
			parent = cardsOverlay,
			pos = { 0, 0 },
			size = { cardsOverlay.size.w, cardsOverlay.size.h }
		})
		local circles = {}
		while (#circles < 100) do
			local gb = math.random(250, 620) / 1000
			local circle = {
				color = { math.random(800, 900) / 1000, gb, gb, 1},
				size = math.random(20, 60) / 10,
				x = math.random(15, cardsOverlay.size.w - 15),
			 	y = math.random(15, cardsOverlay.size.h - 15),
				speed = math.random(100, 200) / 100,
				shift = math.random(10, 40) / 100
			}
			table.insert(circles, circle)
		end
		cardsBackgroundAnimation:addCustomDisplay(true, function()
				while (#circles < 100) do
					local gb = math.random(250, 620) / 1000
					local circle = {
						color = { math.random(800, 900) / 1000, gb, gb, 1},
						size = math.random(20, 60) / 10,
						x = math.random(15, cardsOverlay.size.w - 15),
					 	y = cardsOverlay.size.h - 40,
						speed = math.random(100, 400) / 100,
						shift = math.random(10, 40) / 100
					}
					table.insert(circles, circle)
				end
				for i = #circles, 1, -1 do
					local circleTrans = circles[i].x > circles[i].y and circles[i].y or circles[i].x
					set_color(circles[i].color[1], circles[i].color[2], circles[i].color[3], (circleTrans - 6) / cardsOverlay.size.h * 2)
					draw_disk(cardsOverlay.pos.x + circles[i].x + circles[i].size / 2, cardsOverlay.pos.y + circles[i].y + circles[i].size / 2, 0, circles[i].size, 500, 1, 0, 360, 0)
					circles[i].y = circles[i].y - 1 * circles[i].speed
					circles[i].x = circles[i].x - circles[i].shift * circles[i].speed
					if (circles[i].y < 15 or circles[i].x < 15) then
						table.remove(circles, i)
					end
				end
			end)

			local backButton = UIElement:new({
				parent = cardsOverlay,
				pos = { -150, 0 },
				size = { 140, 40 },
				interactive = true,
				bgColor = UICOLORWHITE,
				hoverColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			backButton:addCustomDisplay(true, function()
					backButton:uiText(TB_MENU_LOCALIZED.NAVBUTTONBACK, nil, nil, nil, RIGHTMID, nil, nil, nil, backButton:getButtonColor())
				end)
			backButton:addMouseHandlers(nil, function()
					overlay:kill()
					TB_MENU_IGNORE_REWARDS = 0
				end)

			local cardsInfoHolder = UIElement:new({
				parent = cardsOverlay,
				pos = { 0, 0 },
				size = { cardsOverlay.size.w, cardsOverlay.size.h }
			})
			Torishop:showCollectorsCardSingle(cardsInfoHolder, cardsData, selectedPlayer)
	end

	function Torishop:showCollectorsCardSingle(cardsOverlay, cardsData, selectedPlayer)
		cardsOverlay:kill(true)
		local cardScale = cardsOverlay.size.h > 532 and 512 or cardsOverlay.size.h - 20
		local cardImage = UIElement:new({
			parent = cardsOverlay,
			pos = { (cardsOverlay.size.w * 2 / 3 - cardScale) / 2, (cardsOverlay.size.h - cardScale) / 2 },
			size = { cardScale, cardScale },
			bgImage = "../textures/menu/worlds2018/card" .. cardsData[selectedPlayer].player:lower() .. ".tga"
		})
		local cardInfoHolder = UIElement:new({
			parent = cardsOverlay,
			pos = { cardsOverlay.size.w / 3 + cardScale * 0.4, cardsOverlay.size.h / 10 },
			size = { cardScale * 0.8, cardsOverlay.size.h * 0.8 }
		})
		local cardsDisclaimer = UIElement:new({
			parent = cardInfoHolder,
			pos = { 10, 0 },
			size = { cardInfoHolder.size.w - 20, cardInfoHolder.size.h / 4 }
		})
		cardsDisclaimer:addAdaptedText(true, "World Championship 2018\nCollectors Card", nil, nil, FONTS.BIG, nil, 0.6)

		local cardName = UIElement:new({
			parent = cardInfoHolder,
			pos = { 10, cardInfoHolder.size.h / 4 },
			size = { cardInfoHolder.size.w - 20, cardInfoHolder.size.h / 4 }
		})
		cardName:addAdaptedText(true, cardsData[selectedPlayer].player, nil, nil, FONTS.BIG)

		local cardInfo = UIElement:new({
			parent = cardInfoHolder,
			pos = { 0, cardInfoHolder.size.h / 2 },
			size = { cardInfoHolder.size.w, cardInfoHolder.size.h / 4 },
			shapeType = ROUNDED,
			rounded = 5,
			bgColor = { 0.118, 0.016, 0.043, 0.7 }
		})
		local cardInfoText = UIElement:new({
			parent = cardInfo,
			pos = { 10, 5 },
			size = { cardInfo.size.w - 20, cardInfo.size.h - 10 }
		})
		cardInfoText:addAdaptedText(true, "Purchase this card now and win prize Toricredits if " .. cardsData[selectedPlayer].player .. " wins Toribash World Championship 2018 and becomes the best player of the year!", nil, nil, 4)

		local cardPurchaseButton = UIElement:new({
			parent = cardInfoHolder,
			pos = { 10, cardInfoHolder.size.h * 3 / 4 + cardInfoHolder.size.h / 16 },
			size = { cardInfoHolder.size.w - 20, cardInfoHolder.size.h / 4 - cardInfoHolder.size.h / 8 },
			shapeType = ROUNDED,
			rounded = 10,
			hoverColor = { 0.236, 0.032, 0.086, 0.8 },
			innerShadow = { 0, 5 },
			shadowColor = { 0.354, 0.048, 0.129, 0.7 },
			interactive = true,
			bgColor = { 0.354, 0.048, 0.129, 0.7 },
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		cardPurchaseButton:addAdaptedText(false, "Buy for 5,000 TC")
		cardPurchaseButton:addMouseHandlers(nil, function()
			UIElement:runCmd("bi " .. cardsData[selectedPlayer].itemid)
		end)

		local prevCardButton = UIElement:new({
			parent = cardsOverlay,
			pos = { 5, cardsOverlay.size.h / 2 - 25 },
			size = { 50, 50 },
			shapeType = ROUNDED,
			rounded = 25,
			interactive = true,
			bgColor = { 0.118, 0.016, 0.043, 0.01 },
			hoverColor = { 0.218, 0.036, 0.1, 1 },
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		local prevCardIcon = UIElement:new({
			parent = prevCardButton,
			pos = { 12.5, 0 },
			size = { 25, 50 },
			bgImage = "../textures/menu/general/buttons/arrowleft.tga"
		})
		prevCardButton:addMouseHandlers(nil, function()
				local selectedPlayer = selectedPlayer - 1 < 1 and #cardsData or selectedPlayer - 1
				Torishop:showCollectorsCardSingle(cardsOverlay, cardsData, selectedPlayer)
			end)
		local nextCardButton = UIElement:new({
			parent = cardsOverlay,
			pos = { -55, cardsOverlay.size.h / 2 - 25 },
			size = { 50, 50 },
			shapeType = ROUNDED,
			rounded = 25,
			interactive = true,
			bgColor = { 0.118, 0.016, 0.043, 0.01 },
			hoverColor = { 0.218, 0.036, 0.1, 1 },
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		local nextCardIcon = UIElement:new({
			parent = nextCardButton,
			pos = { 12.5, 0 },
			size = { 25, 50 },
			bgImage = "../textures/menu/general/buttons/arrowright.tga"
		})
		nextCardButton:addMouseHandlers(nil, function()
				local selectedPlayer = selectedPlayer + 1 > #cardsData and 1 or selectedPlayer + 1
				Torishop:showCollectorsCardSingle(cardsOverlay, cardsData, selectedPlayer)
			end)
	end

	function Torishop:showTorishopMain(viewElement)
		viewElement:kill(true)
		local tcPurchaseView = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.6 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bottomSmudge = TBMenu:addBottomBloodSmudge(tcPurchaseView, 1)
		Torishop:showTcPurchase(tcPurchaseView)


		local buttons = {
			{
				title = TB_MENU_LOCALIZED.STOREGOTOSHOP,
				subtitle = TB_MENU_LOCALIZED.STORESHOPDESC,
				size = 0.4,
				vsize = 0.5,
				action = function()
						if (TB_MENU_PLAYER_INFO.username == '') then
							TBMenu:showLoginError(viewElement, TB_MENU_LOCALIZED.STOREGOTOSHOP)
							return
						end
						close_menu()
						open_menu(12)
					end,
				noQuit = true
			},
			{
				title = TB_MENU_LOCALIZED.STOREGOTOINVENTORY,
				subtitle = TB_MENU_LOCALIZED.STOREINVENTORYDESC,
				size = 0.4,
				vsize = 0.5,
				action = function()
						if (TB_MENU_PLAYER_INFO.username == '') then
							TBMenu:showLoginError(viewElement, TB_MENU_LOCALIZED.STOREGOTOSHOP)
							return
						end
						if (#get_downloads() == 0) then
							Torishop:prepareInventory(viewElement)
						end
					end,
				noQuit = true
			},
		}
		TBMenu:showSection(buttons, tcPurchaseView.size.w)
	end

end
