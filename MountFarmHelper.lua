local addonName, addon = ...

-- SavedVariables
MountFarmHelperDB = MountFarmHelperDB or {}
MountFarmHelperDB.wantToFarm = MountFarmHelperDB.wantToFarm or {}
MountFarmHelperDB.attempts = MountFarmHelperDB.attempts or {}

-- Global variables
local frame
local scrollFrame
local content
local mountRows = {}
local allMounts = {}
local filteredMounts = {}
local currentFilters = {
    instanceType = "All",
    zone = "All", 
    expansion = "All",
    lockout = "All"
}

-- Utility functions
local function GetMountSourceInfo(mountID)
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(mountID)
    local sourceText = C_MountJournal.GetMountInfoExtraByID(mountID)
    return sourceText or "Unknown"
end

local function GetMountExpansion(mountID)
    -- This is a simplified expansion detection based on mount ID ranges
    -- In a real implementation, you'd want to use a database or API
    if mountID < 1000 then
        return "Classic"
    elseif mountID < 2000 then
        return "TBC"
    elseif mountID < 3000 then
        return "WotLK"
    elseif mountID < 4000 then
        return "Cataclysm"
    elseif mountID < 5000 then
        return "MoP"
    elseif mountID < 6000 then
        return "WoD"
    elseif mountID < 7000 then
        return "Legion"
    elseif mountID < 8000 then
        return "BfA"
    elseif mountID < 9000 then
        return "Shadowlands"
    else
        return "Dragonflight"
    end
end

local function GetInstanceType(sourceText)
    if string.find(sourceText, "Dungeon") then
        return "Dungeon"
    elseif string.find(sourceText, "Raid") then
        return "Raid"
    elseif string.find(sourceText, "World Boss") then
        return "World Boss"
    elseif string.find(sourceText, "Reputation") then
        return "Reputation"
    elseif string.find(sourceText, "Achievement") then
        return "Achievement"
    elseif string.find(sourceText, "PvP") then
        return "PvP"
    else
        return "Other"
    end
end

local function GetZoneFromSource(sourceText)
    -- Extract zone name from source text (simplified)
    local zones = {"Blackrock Foundry", "Highmaul", "Hellfire Citadel", "Emerald Nightmare", "Trial of Valor", "Tomb of Sargeras", "Antorus", "Uldir", "Battle of Dazar'alor", "Crucible of Storms", "The Eternal Palace", "Ny'alotha", "Castle Nathria", "Sanctum of Domination", "Sepulcher of the First Ones", "Vault of the Incarnates", "Aberrus", "Amirdrassil"}
    for _, zone in ipairs(zones) do
        if string.find(sourceText, zone) then
            return zone
        end
    end
    return "Unknown"
end

local function GetLockoutInfo(mountID)
    local sourceText = GetMountSourceInfo(mountID)
    local instanceType = GetInstanceType(sourceText)
    
    if instanceType == "Dungeon" or instanceType == "Raid" then
        -- Check saved instances for lockout info
        local numSavedInstances = GetNumSavedInstances()
        for i = 1, numSavedInstances do
            local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
            if string.find(sourceText, name) then
                local timeLeft = reset - time()
                if timeLeft > 0 then
                    local hours = math.floor(timeLeft / 3600)
                    local minutes = math.floor((timeLeft % 3600) / 60)
                    return string.format("%dh %dm", hours, minutes)
                end
            end
        end
        return "Available"
    end
    return "N/A"
end

local function LoadUncollectedMounts()
    if not IsAddOnLoaded("Blizzard_Collections") then
        LoadAddOn("Blizzard_Collections")
    end
    
    allMounts = {}
    local numMounts = C_MountJournal.GetNumMounts()
    
    for i = 1, numMounts do
        local mountID = select(12, C_MountJournal.GetMountInfoByID(i))
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        
        if not isCollected then
            local sourceText = GetMountSourceInfo(mountID)
            local mountData = {
                id = mountID,
                name = name,
                icon = icon,
                source = sourceText,
                instanceType = GetInstanceType(sourceText),
                zone = GetZoneFromSource(sourceText),
                expansion = GetMountExpansion(mountID),
                lockout = GetLockoutInfo(mountID)
            }
            table.insert(allMounts, mountData)
        end
    end
end

local function ApplyFilters()
    filteredMounts = {}
    
    for _, mount in ipairs(allMounts) do
        local passesFilter = true
        
        if currentFilters.instanceType ~= "All" and mount.instanceType ~= currentFilters.instanceType then
            passesFilter = false
        end
        
        if currentFilters.zone ~= "All" and mount.zone ~= currentFilters.zone then
            passesFilter = false
        end
        
        if currentFilters.expansion ~= "All" and mount.expansion ~= currentFilters.expansion then
            passesFilter = false
        end
        
        if currentFilters.lockout ~= "All" then
            if currentFilters.lockout == "Available" and mount.lockout ~= "Available" then
                passesFilter = false
            elseif currentFilters.lockout == "Locked" and mount.lockout == "Available" then
                passesFilter = false
            end
        end
        
        if passesFilter then
            table.insert(filteredMounts, mount)
        end
    end
    
    UpdateMountList()
end

local function UpdateMountList()
    -- Clear existing rows
    for _, row in ipairs(mountRows) do
        row:Hide()
    end
    
    -- Create new rows for filtered mounts
    for i, mount in ipairs(filteredMounts) do
        local row = mountRows[i]
        if not row then
            row = CreateFrame("Frame", nil, content)
            row:SetSize(430, 30)
            
            -- Mount Icon
            row.icon = row:CreateTexture(nil, "BACKGROUND")
            row.icon:SetSize(28, 28)
            row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
            
            -- Mount Name
            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.name:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
            row.name:SetWidth(200)
            
            -- Lockout Info
            row.lockout = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.lockout:SetPoint("LEFT", row.name, "RIGHT", 10, 0)
            row.lockout:SetWidth(80)
            
            -- Want to Farm Checkbox
            row.checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            row.checkbox:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            
            mountRows[i] = row
        end
        
        row:Show()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((i-1)*32))
        
        row.icon:SetTexture(mount.icon)
        row.name:SetText(mount.name)
        row.lockout:SetText(mount.lockout)
        
        -- Set checkbox state
        row.checkbox:SetChecked(MountFarmHelperDB.wantToFarm[mount.id] or false)
        row.checkbox.mountID = mount.id
        row.checkbox:SetScript("OnClick", function(self)
            MountFarmHelperDB.wantToFarm[mount.id] = self:GetChecked()
        end)
    end
    
    -- Update content height
    local totalHeight = #filteredMounts * 32
    content:SetHeight(math.max(400, totalHeight))
end

local function CreateFilterDropdown(parent, label, options, filterKey)
    local dropdown = CreateFrame("Frame", "MountFarmHelperFilter"..filterKey, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetText(dropdown, label)
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, option in ipairs(options) do
            info.text = option
            info.value = option
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, option)
                currentFilters[filterKey] = option
                ApplyFilters()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    return dropdown
end

-- Main Frame
frame = CreateFrame("Frame", "MountFarmHelperFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(500, 600)
frame:SetPoint("CENTER")
frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlight")
frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
frame.title:SetText("Mount Farm Helper")
frame:Hide()

-- Close Button
frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

-- Filters Section
local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
filterLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
filterLabel:SetText("Filters:")

-- Create filter dropdowns
local instanceTypeDropdown = CreateFilterDropdown(frame, "Instance Type", {"All", "Dungeon", "Raid", "World Boss", "Reputation", "Achievement", "PvP", "Other"}, "instanceType")
instanceTypeDropdown:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", -15, -5)

local zoneDropdown = CreateFilterDropdown(frame, "Zone", {"All", "Blackrock Foundry", "Highmaul", "Hellfire Citadel", "Emerald Nightmare", "Trial of Valor", "Tomb of Sargeras", "Antorus", "Uldir", "Battle of Dazar'alor", "Crucible of Storms", "The Eternal Palace", "Ny'alotha", "Castle Nathria", "Sanctum of Domination", "Sepulcher of the First Ones", "Vault of the Incarnates", "Aberrus", "Amirdrassil"}, "zone")
zoneDropdown:SetPoint("TOPLEFT", instanceTypeDropdown, "BOTTOMLEFT", 0, -10)

local expansionDropdown = CreateFilterDropdown(frame, "Expansion", {"All", "Classic", "TBC", "WotLK", "Cataclysm", "MoP", "WoD", "Legion", "BfA", "Shadowlands", "Dragonflight"}, "expansion")
expansionDropdown:SetPoint("TOPLEFT", zoneDropdown, "BOTTOMLEFT", 0, -10)

local lockoutDropdown = CreateFilterDropdown(frame, "Lockout", {"All", "Available", "Locked"}, "lockout")
lockoutDropdown:SetPoint("TOPLEFT", expansionDropdown, "BOTTOMLEFT", 0, -10)

-- Mount List Label
local mountListLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mountListLabel:SetPoint("TOPLEFT", lockoutDropdown, "BOTTOMLEFT", 15, -20)
mountListLabel:SetText("Uncollected Mounts:")

-- Scroll Frame for Mount List
scrollFrame = CreateFrame("ScrollFrame", "MountFarmHelperScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", mountListLabel, "BOTTOMLEFT", 0, -5)
scrollFrame:SetSize(450, 400)

-- Content Frame inside Scroll Frame
content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(450, 400)
scrollFrame:SetScrollChild(content)

-- Refresh button
local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
refreshButton:SetSize(100, 25)
refreshButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15)
refreshButton:SetText("Refresh")
refreshButton:SetScript("OnClick", function()
    LoadUncollectedMounts()
    ApplyFilters()
end)

-- Initialize
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Now safe to load mounts
    LoadUncollectedMounts()
    ApplyFilters()
end)

-- Slash command to show/hide
SLASH_MOUNTFARMHELPER1 = "/mfh"
SlashCmdList["MOUNTFARMHELPER"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
