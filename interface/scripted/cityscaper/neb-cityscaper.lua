require "/scripts/util.lua"

function init()
  self_tabList = "tabScrollArea.itemList"
  self_moduleList = "moduleScrollArea.itemList"
  self_dungeonList = "dungeonScrollArea.itemList"
  
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
  widget.setSliderEnabled("tabScrollArea.hScrollBar", false)
  widget.setSliderEnabled("moduleScrollArea.hScrollBar", false)
  
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
	    widget.setText(string.format("%s.tabName", tabPath), firstToUpper(listName))
		widget.setData(tabPath, listName)
		
		if y == 1 then
		  widget.setListSelected(self_tabList, tabItem)
		end
		y = y + 1
      end
	  self_loadedTabs = true
    end
  end
end

function populateCurrentList()
  widget.clearListItems(self_dungeonList)
  
  local currentList = self_moduleConfig.modules[self_currentModule].config[self_currentTab]
  for x, config in ipairs(currentList) do
	local listItem = widget.addListItem(self_dungeonList)
	widget.setText(string.format("%s.%s.dungeonName", self_dungeonList, listItem), config.shortDescription)
	widget.setImage(string.format("%s.%s.dungeonIcon", self_dungeonList, listItem), config.previewImage or "/assetmissing.png")
	
	widget.setData(string.format("%s.%s", self_dungeonList, listItem), x)
  end
end

function moduleSelected()
  local currentModule = widget.getListSelected(self_moduleList)
  if currentModule then
	local x = widget.getData(string.format("%s.%s", self_moduleList, currentModule))
	self_currentModule = x
	if self_currentTab then	populateCurrentList() end
  end
end

function tabSelected()
  local currentTab = widget.getListSelected(self_tabList)
  if currentTab then
	local tabName = widget.getData(string.format("%s.%s", self_tabList, currentTab))
	self_currentTab = tabName
	if self_currentModule then populateCurrentList() end
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
    widget.setText("dungeonShortDescription", config.shortDescription or "NAME MISSING")
	local dungeonSize = config.dungeonSize or {"x", "x"}
    widget.setText("dungeonSizeLabel", tostring(dungeonSize[1]) .. "/" .. tostring(dungeonSize[2]))
	
	setMaterialsText(config.cost)
    widget.setButtonEnabled("btnApplyDungeon", sufficientCosts(config.cost))
  end
end

function generateBlueprint()
  local config = self_moduleConfig.modules[self_currentModule].config[self_currentTab][self_currentDungeon]
  local itemParameters = {dungeon = config.dungeon, dungeonPreview = config.previewImage, shortdescription = config.shortDescription, inventoryIcon = config.previewImage}
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
  return isSufficient
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
  return sufficient
end

function setMaterialsText(cost)
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
end

function playerAmount(mat)
  local returnVal = ""
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