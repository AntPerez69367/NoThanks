local addonName, ns = ...
local Storage = ns.Storage

local LOG_CAP = 500

local ACCOUNT_DEFAULTS = {
    announce = "CHAT",
    wrapper = true,
    bypassModifier = "SHIFT",
    destroy = false,
    destroyQuality = 1,
    quickAddBinding = "SHIFT",
    windowScale = 1.0,
    lootWindow = "WEEK",
    profiles = "table",
    minimap = "table",
    rules = "table",
    nextRuleID = 1,
}

local CHARACTER_DEFAULTS = {
    blacklist = "table",
    history = "table",
    log = "table",
    logNext = 1,
    ruleState = "table",
    ownRules = "table",
}

local function applyDefaults(store, defaults)
    for key, value in pairs(defaults) do
        if store[key] == nil then
            store[key] = (value == "table") and {} or value
        end
    end
end

local function allRules()
    return Storage.account.rules
end

local function visible(rule)
    return rule.scoped == nil or Storage.character.ownRules[rule.id]
end

function Storage.Initialise()
    NoThanksDB = NoThanksDB or {}
    NoThanksCharDB = NoThanksCharDB or {}
    if NoThanksDB.skipMessage ~= nil then
        NoThanksDB.announce = NoThanksDB.skipMessage and "CHAT" or "NONE"
        NoThanksDB.skipMessage = nil
    end
    applyDefaults(NoThanksDB, ACCOUNT_DEFAULTS)
    applyDefaults(NoThanksCharDB, CHARACTER_DEFAULTS)
    Storage.account = NoThanksDB
    Storage.character = NoThanksCharDB
    local known = {}
    for _, rule in ipairs(allRules()) do
        known[rule.id] = true
    end
    for _, store in ipairs({ NoThanksCharDB.ruleState, NoThanksCharDB.ownRules }) do
        for id in pairs(store) do
            if not known[id] then store[id] = nil end
        end
    end
end

function Storage.Key(itemID)
    local id = tonumber(itemID)
    if not id then return nil end
    return tostring(id)
end

function Storage.Blacklist()
    return Storage.character.blacklist
end

function Storage.History()
    return Storage.character.history
end

function Storage.Rules()
    local rules = {}
    for _, rule in ipairs(allRules()) do
        if visible(rule) then rules[#rules + 1] = rule end
    end
    return rules
end

function Storage.Rule(id)
    for _, rule in ipairs(allRules()) do
        if rule.id == id and visible(rule) then return rule end
    end
end

function Storage.SetRuleScope(rule, scoped)
    rule.scoped = scoped or nil
    Storage.character.ownRules[rule.id] = scoped or nil
end

function Storage.AddRule(rule, scoped)
    rule.id = Storage.account.nextRuleID
    Storage.account.nextRuleID = rule.id + 1
    Storage.SetRuleScope(rule, scoped)
    table.insert(allRules(), 1, rule)
end

function Storage.MoveRule(id, delta)
    local rules, from = allRules()
    for index, rule in ipairs(rules) do
        if rule.id == id then from = index end
    end
    local to = from + delta
    while rules[to] and not visible(rules[to]) do to = to + delta end
    if not rules[to] then return end
    rules[from], rules[to] = rules[to], rules[from]
end

function Storage.DeleteRule(id)
    local rules = allRules()
    for index, rule in ipairs(rules) do
        if rule.id == id then
            table.remove(rules, index)
            return
        end
    end
end

function Storage.RuleEnabled(rule)
    local state = Storage.character.ruleState[rule.id]
    if state == nil then return true end
    return state.enabled
end

function Storage.RuleMode(rule)
    local state = Storage.character.ruleState[rule.id]
    if state == nil then return "test" end
    return state.mode
end

local function ruleState(rule)
    local state = Storage.character.ruleState[rule.id]
    if state == nil then
        state = { enabled = Storage.RuleEnabled(rule), mode = Storage.RuleMode(rule) }
        Storage.character.ruleState[rule.id] = state
    end
    return state
end

function Storage.SetRuleEnabled(rule, enabled)
    ruleState(rule).enabled = enabled
end

function Storage.SetRuleMode(rule, mode)
    ruleState(rule).mode = mode
end

function Storage.IsBlacklisted(itemID)
    local key = Storage.Key(itemID)
    return key ~= nil and Storage.character.blacklist[key] ~= nil
end

local function enabledRule(mode)
    for _, rule in ipairs(Storage.Rules()) do
        if Storage.RuleEnabled(rule) and (mode == nil or Storage.RuleMode(rule) == mode) then
            return true
        end
    end
    return false
end

function Storage.Evaluates()
    return next(Storage.character.blacklist) ~= nil or enabledRule()
end

function Storage.Refuses()
    return next(Storage.character.blacklist) ~= nil or enabledRule("live")
end

function Storage.Add(itemID)
    local key = Storage.Key(itemID)
    if not key or Storage.character.blacklist[key] then return false end
    Storage.character.blacklist[key] = { skipped = 0 }
    return true
end

function Storage.Remove(itemID)
    local key = Storage.Key(itemID)
    if not key or not Storage.character.blacklist[key] then return false end
    Storage.character.blacklist[key] = nil
    return true
end

function Storage.AddWhitelist(rule, itemID)
    local key = Storage.Key(itemID)
    if not key or rule.whitelist[key] then return false end
    rule.whitelist[key] = true
    return true
end

function Storage.RemoveWhitelist(rule, itemID)
    local key = Storage.Key(itemID)
    if not key or not rule.whitelist[key] then return false end
    rule.whitelist[key] = nil
    return true
end

function Storage.CountSkip(itemID)
    local key = Storage.Key(itemID)
    local entry = key and Storage.character.blacklist[key]
    if not entry then return end
    entry.skipped = (entry.skipped or 0) + 1
    entry.lastSkipped = time()
end

function Storage.LogDecision(itemID, by, action, label)
    local index = Storage.character.logNext
    Storage.character.log[index] = {
        itemID = itemID,
        at = time(),
        by = by,
        label = label,
        action = action,
    }
    Storage.character.logNext = index % LOG_CAP + 1
end

function Storage.Log()
    local log = Storage.character.log
    local index = Storage.character.logNext - 1
    local entries = {}
    for _ = 1, LOG_CAP do
        if index < 1 then index = LOG_CAP end
        local entry = log[index]
        if entry then entries[#entries + 1] = entry end
        index = index - 1
    end
    return entries
end

function Storage.RuleLog(id, limit)
    local log = Storage.character.log
    local index = Storage.character.logNext - 1
    local entries, total = {}, 0
    for _ = 1, LOG_CAP do
        if index < 1 then index = LOG_CAP end
        local entry = log[index]
        if entry and entry.by == id then
            total = total + 1
            if #entries < limit then entries[#entries + 1] = entry end
        end
        index = index - 1
    end
    return entries, total
end

local function joinNames(names)
    local count = #names
    if count == 0 then return nil end
    if count == 1 then return names[1] end
    return table.concat(names, ", ", 1, count - 1) .. " " .. ns.L.RULE_AND .. " " .. names[count]
end

local function qualityPhrase(set)
    local ids = {}
    for id in pairs(set) do ids[#ids + 1] = id end
    table.sort(ids)
    local names = {}
    for _, id in ipairs(ids) do
        local name = _G["ITEM_QUALITY" .. id .. "_DESC"]
        if type(name) == "string" then names[#names + 1] = name end
    end
    return joinNames(names)
end

local function classInfoName(getter, ...)
    if type(getter) ~= "function" then return nil end
    local ok, name = pcall(getter, ...)
    if not ok or type(name) ~= "string" or name == "" then return nil end
    return name
end

function Storage.ClassName(classID, subclassID)
    if subclassID ~= nil then
        return classInfoName((C_Item and C_Item.GetItemSubClassInfo) or GetItemSubClassInfo,
            classID, subclassID)
    end
    return classInfoName((C_Item and C_Item.GetItemClassInfo) or GetItemClassInfo, classID)
end

local function ruleNoun(rule)
    if rule.subclassID ~= nil and rule.classID ~= nil then
        local name = Storage.ClassName(rule.classID, rule.subclassID)
        if name then return name end
    end
    if rule.classID ~= nil then
        local name = Storage.ClassName(rule.classID)
        if name then return name end
    end
    return ns.L.RULE_ITEMS
end

function Storage.RuleLabel(rule)
    if rule.quality == nil and rule.classID == nil and rule.subclassID == nil
        and rule.equipLoc == nil and rule.levelMax == nil and rule.priceMax == nil then
        return nil
    end
    local parts = {}
    if rule.quality then
        local qualities = qualityPhrase(rule.quality)
        if qualities then parts[#parts + 1] = qualities end
    end
    parts[#parts + 1] = ruleNoun(rule)
    if rule.equipLoc then
        local slot = _G[rule.equipLoc]
        if type(slot) == "string" then
            parts[#parts + 1] = string.format(ns.L.RULE_EQUIP, slot)
        end
    end
    if rule.levelMax then
        parts[#parts + 1] = string.format(ns.L.RULE_BELOW, rule.levelMax)
    end
    if rule.priceMax then
        parts[#parts + 1] = string.format(ns.L.RULE_UNDER, ns.Money(rule.priceMax))
    end
    return table.concat(parts, " ")
end
