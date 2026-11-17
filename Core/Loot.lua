local addonName, ns = ...
local Loot, Filter, Storage, History, Wrapper = ns.Loot, ns.Filter, ns.Storage, ns.History, ns.Wrapper

local PACE = 0.1
local CLOSE_GRACE = 0.4
local STUCK_AFTER = 5

local claimed = false
local deadline = nil
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

local function release()
    claimed = false
    deadline = nil
    captured = {}
    cleared = {}
    refused = {}
end

function Loot.Refuse(itemID)
    if not itemID or refused[itemID] then return false end
    refused[itemID] = true
    Storage.CountSkip(itemID)
    return true
end

local function drain(queue, index)
    if index > #queue then
        C_Timer.After(CLOSE_GRACE, function() pcall(CloseLoot) end)
        return
    end
    Wrapper.Take(queue[index])
    C_Timer.After(PACE, function() drain(queue, index + 1) end)
end

local function announce(links)
    if #links == 0 then return end
    ns.Announce(string.format(ns.L.LEFT_BEHIND, table.concat(links, ", ")))
end

local function onLootWindow()
    if claimed and deadline and GetTime() > deadline then release() end
    if claimed then return end
    local count = Filter.SlotCount()
    if count <= 0 then
        pcall(CloseLoot)
        return
    end
    claimed = true
    deadline = GetTime() + STUCK_AFTER

    local queue = {}
    if bypassHeld() then
        for slot = count, 1, -1 do queue[#queue + 1] = slot end
        drain(queue, 1)
        return
    end

    local links = {}
    for slot = count, 1, -1 do
        local itemID, link = Filter.SlotItem(slot)
        captured[slot] = itemID
        if itemID then History.Record(itemID) end
        if itemID and not Filter.SparesSlot(slot) and Filter.Refuses(itemID) then
            if Loot.Refuse(itemID) then links[#links + 1] = ns.ItemLink(itemID, link) end
        else
            queue[#queue + 1] = slot
        end
    end
    announce(links)
    drain(queue, 1)
end

local function onSlotCleared(slot)
    if Storage.account.wrapper or warned or cleared[slot] then return end
    cleared[slot] = true
    local itemID = captured[slot]
    if itemID and refused[itemID] then
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
