local addonName, ns = ...
local Destroy, Filter, Storage = ns.Destroy, ns.Filter, ns.Storage

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

function Destroy.Eligible(itemID)
    if not Storage.account.destroy then return false end
    if not itemID or not Filter.Refuses(itemID) then return false end
    if Filter.IsQuestItem(itemID) then return false end
    local _, _, quality = ns.ItemInfo(itemID)
    quality = tonumber(quality)
    if not quality then return false end
    return quality <= Storage.account.destroyQuality
end

function Destroy.Queue(itemID)
    if not itemID then return end
    pending[itemID] = true
end

local function destroySlot(bag, slot, itemID)
    local pickup = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
    if type(pickup) ~= "function" then return end
    if not pcall(pickup, bag, slot) then return end
    local kind, cursorID = cursorItem()
    if kind ~= "item" or cursorID ~= itemID then
        ClearCursor()
        return
    end
    DeleteCursorItem()
    if CursorHasItem() then ClearCursor() end
end

local function flush()
    if not next(pending) then return end
    if InCombatLockdown() then return end
    local known, dead = pcall(UnitIsDeadOrGhost, "player")
    if known and plain(dead) then return end
    if (cursorItem()) then return end
    for bag = 0, lastBag() do
        for slot = 1, bagSlots(bag) do
            local itemID, locked = bagSlotItem(bag, slot)
            if itemID and pending[itemID] and not locked and Destroy.Eligible(itemID) then
                pending[itemID] = nil
                destroySlot(bag, slot, itemID)
                return
            end
        end
    end
end

function Destroy.Initialise()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)
    frame:SetScript("OnKeyDown", flush)
    frame:SetScript("OnKeyUp", flush)
    WorldFrame:HookScript("OnMouseDown", flush)
    WorldFrame:HookScript("OnMouseUp", flush)
end
