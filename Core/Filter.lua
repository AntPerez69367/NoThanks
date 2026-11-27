local addonName, ns = ...
local Filter, Storage, Destroy = ns.Filter, ns.Storage, ns.Destroy

local QUEST_CLASS = 12

local questClass = {}

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

function Filter.SlotQuest(slot)
    local ok, _, _, _, _, _, _, isQuestItem = pcall(GetLootSlotInfo, slot)
    if not ok then return nil end
    isQuestItem = plain(isQuestItem)
    if isQuestItem == nil then return nil end
    return isQuestItem and true or false
end

function Filter.SparesSlot(slot)
    local quest = Filter.SlotQuest(slot)
    if quest == nil then return true end
    return quest
end

function Filter.IsQuestItem(itemID)
    local entry = Storage.History()[Storage.Key(itemID)]
    if entry and entry.quest then return true end
    local known = questClass[itemID]
    if known ~= nil then return known end
    local getter = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if type(getter) ~= "function" then return nil end
    local ok, _, _, _, _, _, classID = pcall(getter, itemID)
    if not ok then return nil end
    classID = plain(classID)
    if classID == nil then return nil end
    local quest = classID == QUEST_CLASS
    questClass[itemID] = quest
    return quest
end

function Filter.Matches(rule, itemID)
    if rule.classID ~= nil or rule.subclassID ~= nil or rule.equipLoc ~= nil then
        local getter = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        if type(getter) ~= "function" then return false end
        local ok, _, _, _, equipLoc, _, classID, subclassID = pcall(getter, itemID)
        if not ok then return false end
        equipLoc, classID, subclassID = plain(equipLoc), plain(classID), plain(subclassID)
        if rule.classID ~= nil and classID ~= rule.classID then return false end
        if rule.subclassID ~= nil and subclassID ~= rule.subclassID then return false end
        if rule.equipLoc ~= nil and equipLoc ~= rule.equipLoc then return false end
    end
    if rule.quality ~= nil or rule.levelMax ~= nil or rule.priceMax ~= nil then
        local _, _, quality, _, reqLevel, _, _, _, _, _, price = ns.ItemInfo(itemID)
        if rule.quality ~= nil and (quality == nil or not rule.quality[quality]) then return false end
        if rule.levelMax ~= nil and (reqLevel == nil or reqLevel > rule.levelMax) then return false end
        if rule.priceMax ~= nil and (price == nil or price > rule.priceMax) then return false end
    end
    return true
end

local function ceilingCovers(limit, other)
    if limit == nil then return true end
    return other ~= nil and limit >= other
end

function Filter.Subsumes(a, b)
    if a.quality ~= nil then
        if b.quality == nil then return false end
        for quality in pairs(b.quality) do
            if not a.quality[quality] then return false end
        end
    end
    if a.classID ~= nil and a.classID ~= b.classID then return false end
    if a.subclassID ~= nil and a.subclassID ~= b.subclassID then return false end
    if a.equipLoc ~= nil and a.equipLoc ~= b.equipLoc then return false end
    if not ceilingCovers(a.levelMax, b.levelMax) then return false end
    if not ceilingCovers(a.priceMax, b.priceMax) then return false end
    return true
end

function Filter.Refuses(itemID)
    if not Storage.Evaluates() then return false end
    return Storage.IsBlacklisted(itemID)
end

function Filter.Verdict(itemID, slot, replay)
    if not Storage.Evaluates() then return nil end
    if slot ~= nil and Filter.SparesSlot(slot) then return nil end
    if Filter.IsQuestItem(itemID) ~= false then return nil end
    local key = Storage.Key(itemID)
    for _, rule in ipairs(Storage.Rules()) do
        if Storage.RuleEnabled(rule) and rule.whitelist[key] == nil
            and Filter.Matches(rule, itemID) then
            if Storage.RuleMode(rule) == "live" then
                if rule.intent == "destroy" and Destroy.Permits(itemID) then
                    return "destroy", rule.id
                end
                return "skip", rule.id
            end
            if not replay and ns.Loot.Flag(itemID, rule.id) then
                Storage.LogDecision(itemID, rule.id, "flag", Storage.RuleLabel(rule))
            end
        end
    end
    if not Filter.Refuses(itemID) then return nil end
    if Destroy.Eligible(itemID) then return "destroy", "blacklist" end
    return "skip", "blacklist"
end

local function shadower(rule)
    for _, candidate in ipairs(Storage.Rules()) do
        if candidate.id == rule.id then return nil end
        if Storage.RuleEnabled(candidate) and Storage.RuleMode(candidate) == "live"
            and next(candidate.whitelist) == nil and Filter.Subsumes(candidate, rule) then
            return candidate
        end
    end
end

local function preemptor(itemID, key)
    for _, rule in ipairs(Storage.Rules()) do
        if Storage.RuleEnabled(rule) and Storage.RuleMode(rule) == "live"
            and rule.whitelist[key] == nil and Filter.Matches(rule, itemID) then
            if rule.intent == "destroy" then return nil end
            return rule
        end
    end
end

function Filter.Conflicts()
    local conflicts = {}
    for key in pairs(Storage.Blacklist()) do
        local itemID = tonumber(key)
        if Destroy.Eligible(itemID) then
            local winner = preemptor(itemID, key)
            if winner then
                local entry = conflicts[winner.id] or {}
                entry.preempted = (entry.preempted or 0) + 1
                conflicts[winner.id] = entry
            end
        end
    end
    for _, rule in ipairs(Storage.Rules()) do
        local shadow = shadower(rule)
        if shadow then
            local entry = conflicts[rule.id] or {}
            entry.shadow = shadow
            conflicts[rule.id] = entry
        end
    end
    return conflicts
end
