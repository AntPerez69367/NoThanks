local addonName, ns = ...
local Filter, Storage = ns.Filter, ns.Storage

local QUEST_CLASS = 12

local function plain(value)
    if type(issecretvalue) == "function" and issecretvalue(value) then return nil end
    return value
end

function Filter.SlotItem(slot)
    local ok, link = pcall(GetLootSlotLink, slot)
    if not ok then return nil end
    link = plain(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)")), link
end

function Filter.SlotCount()
    local ok, count = pcall(GetNumLootItems)
    if not ok then return 0 end
    count = tonumber(plain(count))
    return count or 0
end

function Filter.SparesSlot(slot)
    local ok, _, _, _, _, _, _, isQuestItem = pcall(GetLootSlotInfo, slot)
    if not ok then return true end
    isQuestItem = plain(isQuestItem)
    if isQuestItem == nil then return true end
    return isQuestItem and true or false
end

function Filter.IsQuestItem(itemID)
    local getter = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if type(getter) ~= "function" then return nil end
    local ok, _, _, _, _, _, classID = pcall(getter, itemID)
    if not ok then return nil end
    classID = plain(classID)
    if classID == nil then return nil end
    return classID == QUEST_CLASS
end

function Filter.Refuses(itemID)
    if Storage.IsEmpty() then return false end
    return Storage.IsBlacklisted(itemID)
end

function Filter.RefusesSlot(slot)
    if Storage.IsEmpty() then return false end
    if Filter.SparesSlot(slot) then return false end
    local itemID = (Filter.SlotItem(slot))
    if not itemID then return false end
    return Filter.Refuses(itemID)
end
