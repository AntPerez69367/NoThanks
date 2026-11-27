local addonName, ns = ...
local Wrapper, Filter, Storage, Destroy = ns.Wrapper, ns.Filter, ns.Storage, ns.Destroy

local original = nil
local ours = nil
local disabled = false
local reentrant = false

local function wrapped(slot, ...)
    if reentrant or disabled or ns.Loot.Bypassing() then return original(slot, ...) end
    local itemID, link = Filter.SlotItem(slot)
    local ok, action, reason = pcall(Filter.Verdict, itemID, slot)
    if not ok or not action then return original(slot, ...) end
    if action == "destroy" then
        if ns.Loot.Refuse(itemID) then
            ns.Announce(string.format(ns.L.DESTROYED, ns.ItemLink(itemID, link)))
        end
        Destroy.Queue(itemID)
        return original(slot, ...)
    end
    if ns.Loot.Refuse(itemID) then
        ns.Announce(string.format(ns.L.LEFT_BEHIND, ns.ItemLink(itemID, link)))
        local rule = Storage.Rule(reason)
        Storage.LogDecision(itemID, reason, "skip", rule and Storage.RuleLabel(rule))
    end
end

function Wrapper.Take(slot)
    reentrant = true
    pcall(LootSlot, slot)
    reentrant = false
end

function Wrapper.Install()
    if ours then
        disabled = false
        return
    end
    original = LootSlot
    ours = wrapped
    LootSlot = wrapped
    disabled = false
end

function Wrapper.Remove()
    if not ours then return end
    if LootSlot == ours then
        LootSlot = original
        original, ours, disabled = nil, nil, false
    else
        disabled = true
    end
end

function Wrapper.Sync()
    if Storage.account.wrapper and Storage.Refuses() then
        Wrapper.Install()
    else
        Wrapper.Remove()
    end
end
