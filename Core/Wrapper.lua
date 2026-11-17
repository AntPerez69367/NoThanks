local addonName, ns = ...
local Wrapper, Filter, Storage = ns.Wrapper, ns.Filter, ns.Storage

local original = nil
local ours = nil
local disabled = false
local reentrant = false

local function wrapped(slot, ...)
    if reentrant or disabled or ns.Loot.Bypassing() then return original(slot, ...) end
    local ok, refuses = pcall(Filter.RefusesSlot, slot)
    if not ok or not refuses then return original(slot, ...) end
    local itemID, link = Filter.SlotItem(slot)
    if itemID and ns.Loot.Refuse(itemID) then
        ns.Announce(string.format(ns.L.LEFT_BEHIND, ns.ItemLink(itemID, link)))
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
    if Storage.account.wrapper and not Storage.IsEmpty() then
        Wrapper.Install()
    else
        Wrapper.Remove()
    end
end
