local addonName, ns = ...

ns.name = addonName
ns.Storage = {}
ns.Filter = {}
ns.AutoLoot = {}
ns.Wrapper = {}
ns.History = {}
ns.Profiles = {}
ns.Prices = {}
ns.Loot = {}
ns.Destroy = {}
ns.Minimap = {}
ns.UI = {}
ns.L = {}

local function plain(value)
    if type(issecretvalue) == "function" and issecretvalue(value) then return nil end
    return value
end

function ns.Print(message)
    print("|cff66ccffNo Thanks!|r " .. tostring(message))
end

function ns.Announce(message)
    local destination = ns.Storage.account.announce
    if destination == "NONE" then return end
    if destination == "ERROR" then
        UIErrorsFrame:AddMessage(message, 0.40, 0.80, 1.00)
        return
    end
    ns.Print(message)
end

function ns.Resync()
    ns.AutoLoot.Sync()
    ns.Wrapper.Sync()
end

function ns.ItemInfo(itemID)
    local getter = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if type(getter) ~= "function" then return nil end
    local ok, name, link, quality, iLevel, reqLevel, class, subclass, stack, slot, icon, price =
        pcall(getter, itemID)
    if not ok then return nil end
    return plain(name), plain(link), plain(quality), plain(iLevel), plain(reqLevel), plain(class),
        plain(subclass), plain(stack), plain(slot), plain(icon), plain(price)
end

function ns.ItemLink(itemID, known)
    if type(known) == "string" then return known end
    local _, link = ns.ItemInfo(itemID)
    if link then return link end
    return "item:" .. tostring(itemID)
end
