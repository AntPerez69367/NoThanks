local addonName, ns = ...
local Destroy, Filter, Storage = ns.Destroy, ns.Filter, ns.Storage

local WINDOW = 30

local pending = {}

local function plain(value)
    if type(issecretvalue) == "function" and issecretvalue(value) then return nil end
    return value
end

local function lastBag()
    return NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
end

local function bagSlots(bag)
    local getter = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    if type(getter) ~= "function" then return 0 end
    local ok, count = pcall(getter, bag)
    if not ok then return 0 end
    return tonumber(plain(count)) or 0
end

local function bagSlotItem(bag, slot)
    local getter = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo
    if type(getter) ~= "function" then return nil end
    local ok, first, _, locked, _, _, _, _, _, _, itemID = pcall(getter, bag, slot)
    if not ok then return nil end
    first = plain(first)
    if type(first) == "table" then
        return tonumber(plain(first.itemID)), plain(first.isLocked) and true or false
    end
    return tonumber(plain(itemID)), plain(locked) and true or false
end

local function cursorItem()
    local ok, kind, itemID = pcall(GetCursorInfo)
    if not ok then return nil end
    return plain(kind), tonumber(plain(itemID))
end

function Destroy.Permits(itemID)
    if not Storage.account.destroy then return false end
    if Filter.IsQuestItem(itemID) ~= false then return false end
    local _, _, quality = ns.ItemInfo(itemID)
    quality = tonumber(quality)
    if not quality then return false end
    return quality <= Storage.account.destroyQuality
end

function Destroy.Eligible(itemID)
    if not itemID or not Filter.Refuses(itemID) then return false end
    return Destroy.Permits(itemID)
end

local function prune()
    local now = GetTime()
    for itemID, entry in pairs(pending) do
        if entry.expires <= now then pending[itemID] = nil end
    end
end

local function destroySlot(bag, slot, itemID)
    local pickup = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
    if type(pickup) ~= "function" then return false end
    if not pcall(pickup, bag, slot) then return false end
    local kind, cursorID = cursorItem()
    if kind ~= "item" or cursorID ~= itemID then
        ClearCursor()
        return false
    end
    DeleteCursorItem()
    if CursorHasItem() then ClearCursor() end
    return true
end

local function flush()
    if not next(pending) then return end
    prune()
    if not next(pending) then return end
    if InCombatLockdown() then return end
    local known, dead = pcall(UnitIsDeadOrGhost, "player")
    if known and plain(dead) then return end
    if (cursorItem()) then return end
    for bag = 0, lastBag() do
        for slot = 1, bagSlots(bag) do
            local itemID, locked = bagSlotItem(bag, slot)
            local entry = itemID and pending[itemID]
            if entry and not locked then
                local action, reason = Filter.Verdict(itemID, nil, true)
                if action == "destroy" then
                    if destroySlot(bag, slot, itemID) then
                        entry.count = entry.count - 1
                        if entry.count <= 0 then pending[itemID] = nil end
                        local rule = Storage.Rule(reason)
                        Storage.LogDecision(itemID, reason, "destroy", rule and Storage.RuleLabel(rule))
                    end
                    return
                end
            end
        end
    end
end

local hooked = false

local function hook()
    if hooked then return end
    hooked = true
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)
    frame:SetScript("OnKeyDown", flush)
    frame:SetScript("OnKeyUp", flush)
    WorldFrame:HookScript("OnMouseDown", flush)
    WorldFrame:HookScript("OnMouseUp", flush)
end

function Destroy.Queue(itemID)
    if not itemID then return end
    hook()
    local entry = pending[itemID]
    if entry then
        entry.count = entry.count + 1
        entry.expires = GetTime() + WINDOW
        return
    end
    pending[itemID] = { count = 1, expires = GetTime() + WINDOW }
end
