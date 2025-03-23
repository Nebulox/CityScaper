require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self_tabList = "tabScrollArea.itemList"
  self_moduleList = "moduleScrollArea.itemList"
  self_dungeonList = "dungeonScrollArea.itemList"
  self_costList = "costScrollArea.itemList"

  self_filterList = "filterScrollArea.itemList"
  
  self_moduleConfigDirectory = config.getParameter("moduleConfig")
  self_moduleConfig = root.assetJson(self_moduleConfigDirectory)
  
  self_currentModule = 1
  self_currentTab = "rooms"
  self_selectedItem = nil
  
  populateTabsAndModules()
  widget.setButtonEnabled("btnApplyDungeon", false)
end

function update(dt)

end

function populateTabsAndModules()
  widget.clearListItems(self_moduleList)
  widget.clearListItems(self_tabList)
  widget.clearListItems(self_filterList)
  
  for x, module in pairs(self_moduleConfig.modules or {}) do
    local moduleItem = widget.addListItem(self_moduleList)
    local modulePath = string.format("%s.%s", self_moduleList, moduleItem)
  	widget.setImage(string.format("%s.moduleIcon", modulePath), self_moduleConfig.iconPath .. module.name .. ".png")
  	widget.setData(modulePath, x)
	
	  if not self_loadedTabs then
      widget.setListSelected(self_moduleList, moduleItem)
      
      local listNames = {"rooms", "prefabs", "dungeons"}
      local y = 1
      for _, list in pairs(self_moduleConfig.modules[x].config) do
	      local listName = listNames[y]
		
  	    local tabItem = widget.addListItem(self_tabList)
  	    local tabPath = string.format("%s.%s", self_tabList, tabItem)
	      widget.setText(string.format("%s.tabName", tabPath), firstToUpper(listName):sub(1, -2))
		    widget.setData(tabPath, listName)
		
		    if y == 1 then
		      widget.setListSelected(self_tabList, tabItem)
	    	end
	      y = y + 1
      end
	    self_loadedTabs = true
    end
  end
    
  -- Filter Buttons!!!
  for x, filter in ipairs(config.getParameter("filterButtons", {})) do
    local filterItem = widget.addListItem(self_filterList)
    local filterPath = string.format("%s.%s", self_filterList, filterItem)
    widget.setText(string.format("%s.filterName", filterPath), filter)
    widget.setData(filterPath, filter)
		
    if x == 1 then
      widget.setListSelected(self_filterList, filterItem)
    end
  end
end

function populateCurrentList(newTab, searchQuery, filterTab)
  widget.clearListItems(self_dungeonList)
  
  if newTab then
    widget.setImage("dungeonPreview", "/assetmissing.png")
    widget.setText("dungeonShortDescription", "No " .. self_currentTab:sub(1, -2) .. " selected.") --list current tab type
    widget.setText("dungeonSizeLabel", "")
    widget.clearListItems(self_costList)
  end
  
  local currentList = self_moduleConfig.modules[self_currentModule].config[self_currentTab]
  for x, config in ipairs(currentList) do
    local dungeonName = config.shortDescription
    local dungeonVariant = config.variant or "1"

    local dungeonFilter = config.filter or ""

    if filterTab == "A" then filterTab = nil end
    if ((not searchQuery and true) or (searchQuery and dungeonName:lower():find(searchQuery)))
      and ((not filterTab and true) or (filterTab and dungeonFilter == filterTab)) then
      
      local listItem = widget.addListItem(self_dungeonList)
      widget.setText(string.format("%s.%s.dungeonName", self_dungeonList, listItem), dungeonName)
      widget.setText(string.format("%s.%s.dungeonFilter", self_dungeonList, listItem), dungeonFilter)
      widget.setText(string.format("%s.%s.dungeonVariant", self_dungeonList, listItem), "^gray;" .. dungeonVariant)

      local image = config.previewImage or "/assetmissing.png"
      local imageSize = vec2.mul(root.imageSize(image), 0.125)
      local xS = 24 / imageSize[1]
      widget.setImage(string.format("%s.%s.dungeonIcon", self_dungeonList, listItem), image .. "?scalebicubic=" .. xS)
    
      widget.setData(string.format("%s.%s", self_dungeonList, listItem), x)
    end
  end
end

function filter(newTab, filterTab)
  local query = widget.getText("filter")
  populateCurrentList(newTab, query:lower(), filterTab or self_currentFilter)
end

function moduleSelected()
  local currentModule = widget.getListSelected(self_moduleList)
  if currentModule then
	  local x = widget.getData(string.format("%s.%s", self_moduleList, currentModule))
  	self_currentModule = x
	  if self_currentTab then	filter(true) end
  end
end

function tabSelected()
  local currentTab = widget.getListSelected(self_tabList)
  if currentTab then
  	local tabName = widget.getData(string.format("%s.%s", self_tabList, currentTab))
	  self_currentTab = tabName
  	if self_currentModule then filter(true) end
  end
end

function filterSelected()
  local currentFilter = widget.getListSelected(self_filterList)
  if currentFilter then
  	local filterName = widget.getData(string.format("%s.%s", self_filterList, currentFilter))
	  self_currentFilter = filterName
  	if self_currentFilter then filter(true, self_currentFilter) end
  end
end

function dungeonSelected()
  local currentDungeon = widget.getListSelected(self_dungeonList)
  widget.setButtonEnabled("btnApplyDungeon", false)
  if currentDungeon then
  	local dungeonName = widget.getData(string.format("%s.%s", self_dungeonList, currentDungeon))
	  self_currentDungeon = dungeonName
	
    local config = self_moduleConfig.modules[self_currentModule].config[self_currentTab][self_currentDungeon]
    widget.setImage("dungeonPreview", config.previewImage or "/assetmissing.png")
    widget.setText("dungeonShortDescription", config.shortDescription or "No name provided.")
	  local dungeonSize = vec2.mul(root.imageSize(config.previewImage), 0.125)
    widget.setText("dungeonSizeLabel", tostring(dungeonSize[1]):gsub("%.?0+$", "") .. " x " .. tostring(dungeonSize[2]):gsub("%.?0+$", ""))
	
	  populateCostList(config.cost)
    widget.setButtonEnabled("btnApplyDungeon", sufficientCosts(config.cost))
  end
end

function populateCostList(costConfig)
  widget.clearListItems(self_costList)
  
  local keys = {}
  for key, _ in pairs(costConfig) do
    table.insert(keys, key)
  end
  table.sort(keys, function(keyLhs, keyRhs) return costConfig[keyLhs] > costConfig[keyRhs] end)


  for _, item in ipairs(keys) do
    local cost = costConfig[item]

    local costItem = widget.addListItem(self_costList)
    local itemName = root.itemConfig(item).config.shortdescription

    local itemPath = string.format("%s.%s", self_costList, costItem)
  	widget.setItemSlotItem(string.format("%s.icon", itemPath), item)
	
    local playerMatCount = playerAmount(item)
    local isSufficient = playerMatCount >= cost
    local directive = isSufficient and "^green;" or "^red;"
    local costText = directive .. playerMatCount .. "^white;/" .. cost .. "\n"

    widget.setText(string.format("%s.cost", itemPath), costText)
    widget.setText(string.format("%s.name", itemPath), itemName)
  end
end




--[[function setMaterialsText(cost)
  local matText = ""
  local xText = ""
  
  local lim = 1
  for mat, x in pairs(cost) do
    if lim <= 5 then
	  lim = lim + 1
	  
      matText = matText .. firstToUpper(checkMoney(mat)) .. ":\n"
	
	    local playerMatCount = playerAmount(mat)
      local isSufficient = playerMatCount >= x
      local directive = isSufficient and "^green;" or "^red;"
	    xText = xText .. directive .. playerMatCount .. "^white;/" .. x .. "\n"
    end
  end
  
  widget.setText("materialLabel", matText)
  widget.setText("costLabel", xText)
end]]

function generateBlueprint()
  local config = self_moduleConfig.modules[self_currentModule].config[self_currentTab][self_currentDungeon]
  local itemParameters = {
    dungeon = config.dungeon,
    dungeonPreview = config.previewImage,
    shortdescription = config.shortDescription,
    inventoryIcon = {
      { image = config.previewImage } 
    } 
  }
  local newCityScaper = root.createItem({ name = "neb-cityscaper", count = 1, parameters = itemParameters})
  local consumeCosts = consumeMaterials(config.cost)
  if consumeCosts then
	  player.giveItem(newCityScaper)
  end
end

function consumeMaterials(cost)
  local isSufficient = sufficientCosts(cost)
  if isSufficient then
    local lim = 1
    for mat, x in pairs(cost) do
      if lim <= 5 then
        lim = lim + 1
        local playerMatCount = playerAmount(mat)
        if checkMoney(mat) then
          player.consumeCurrency(mat, x)
        else
          player.consumeItem(mat, x)
        end
      end
    end
  end
  return player.isAdmin() or isSufficient
end

function sufficientCosts(cost)
  local sufficient = true
  local lim = 1
  for mat, x in pairs(cost) do
    if lim <= 5 then
	    lim = lim + 1
	    local playerMatCount = playerAmount(mat)
      local isInsufficient = playerMatCount < x
	    if isInsufficient then
	      sufficient = false
	    end
    end
  end
  return player.isAdmin() or sufficient
end

function playerAmount(mat)
  local returnVal = 0
  if mat == "money" or mat == "essence" then
    returnVal = player.currency(mat)
  else
    returnVal = player.hasCountOfItem(mat)
  end
  return returnVal
end

function checkMoney(mat)
  return (mat == "money") and "pixels" or mat
end

function firstToUpper(str)
  return (str:gsub("^%l", string.upper))
end