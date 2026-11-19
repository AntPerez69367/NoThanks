local addonName, ns = ...
local Loot, Filter, Storage, History, Wrapper = ns.Loot, ns.Filter, ns.Storage, ns.History, ns.Wrapper
local Destroy = ns.Destroy

local PACE = 0.1
local CLOSE_GRACE = 0.4
local STUCK_AFTER = 5

local claimed = false
local bypassing = false
local draining = false
local recorded = false
local generation = 0
local deadline = nil
local leftBehind = 0
local corpse = nil
local captured = {}
local cleared = {}
local refused = {}
local warned = false

local function bypassHeld()
    local modifier = Storage.account.bypassModifier
    if modifier == "CTRL" then return IsControlKeyDown() end
    if modifier == "ALT" then return IsAltKeyDown() end
    return IsShiftKeyDown()
end

local function lootSource()
    local ok, guid = pcall(GetLootSourceInfo, 1)
    if not ok then return nil end
    if type(issecretvalue) == "function" and issecretvalue(guid) then return nil end
    if type(guid) ~= "string" then return nil end
    return guid
end

local function release()
    claimed = false
    bypassing = false
    draining = false
    recorded = false
    generation = generation + 1
    deadline = nil
    leftBehind = 0
    captured = {}
    cleared = {}
end

function Loot.Bypassing()
    return bypassing
end

function Loot.Refuse(itemID)
    if not itemID or refused[itemID] then return false end
    refused[itemID] = true
    Storage.CountSkip(itemID)
    return true
end

local function record(count)
    for slot = count, 1, -1 do
        local itemID = (Filter.SlotItem(slot))
        if itemID then History.Record(itemID) end
    end
end

local function stillOnCorpse()
    local left = 0
    for slot = 1, Filter.SlotCount() do
        if (Filter.SlotItem(slot)) then left = left + 1 end
    end
    return left
end

local function drain(queue, token, index)
    if token ~= generation then return end
    if index > #queue then
        C_Timer.After(CLOSE_GRACE, function()
            if token ~= generation then return end
            draining = false
            if stillOnCorpse() <= leftBehind then pcall(CloseLoot) end
        end)
        return
    end
    Wrapper.Take(queue[index])
    C_Timer.After(PACE, function() drain(queue, token, index + 1) end)
end

local function announce(links, destroyed)
    if #links > 0 then
        ns.Announce(string.format(ns.L.LEFT_BEHIND, table.concat(links, ", ")))
    end
    if #destroyed > 0 then
        ns.Announce(string.format(ns.L.DESTROYED, table.concat(destroyed, ", ")))
    end
end

local function onLootWindow()
    if claimed and deadline and GetTime() > deadline then release() end
    if claimed then return end
    local count = Filter.SlotCount()
    if Storage.IsEmpty() then
        if not recorded then
            recorded = true
            record(count)
        end
        return
    end
    if count <= 0 then
        pcall(CloseLoot)
        return
    end
    claimed = true
    generation = generation + 1
    deadline = GetTime() + STUCK_AFTER
    local token = generation

    local source = lootSource()
    if source == nil or source ~= corpse then
        corpse = source
        refused = {}
        warned = false
    end

    local queue = {}
    if bypassHeld() then
        bypassing = true
        record(count)
        for slot = count, 1, -1 do queue[#queue + 1] = slot end
        leftBehind = 0
        draining = true
        drain(queue, token, 1)
        return
    end

    local links, destroyed = {}, {}
    for slot = count, 1, -1 do
        local itemID, link = Filter.SlotItem(slot)
        captured[slot] = itemID
        if itemID and not Filter.SparesSlot(slot) and Filter.Refuses(itemID) then
            if Destroy.Eligible(itemID) then
                if Loot.Refuse(itemID) then destroyed[#destroyed + 1] = ns.ItemLink(itemID, link) end
                Destroy.Queue(itemID)
                queue[#queue + 1] = slot
            elseif Loot.Refuse(itemID) then
                links[#links + 1] = ns.ItemLink(itemID, link)
            end
        else
            if itemID then History.Record(itemID) end
            queue[#queue + 1] = slot
        end
    end
    leftBehind = count - #queue
    announce(links, destroyed)
    draining = true
    drain(queue, token, 1)
end

local function onSlotCleared(slot)
    if Storage.account.wrapper or warned or not draining or cleared[slot] then return end
    cleared[slot] = true
    local itemID = captured[slot]
    if itemID and refused[itemID] and not Destroy.Eligible(itemID) then
        warned = true
        ns.Print(ns.L.INTERFERENCE)
    end
end

function Loot.Initialise()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(_, event, arg1)
        if event == "LOOT_READY" or event == "LOOT_OPENED" then
            onLootWindow()
        elseif event == "LOOT_SLOT_CLEARED" then
            onSlotCleared(arg1)
        elseif event == "LOOT_CLOSED" then
            release()
        end
    end)
    for _, event in ipairs({ "LOOT_READY", "LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_CLOSED" }) do
        pcall(frame.RegisterEvent, frame, event)
    end
end
