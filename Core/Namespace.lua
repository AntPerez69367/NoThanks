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

local UNITS = { g = 10000, s = 100, c = 1 }

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

function ns.ItemIcon(itemID)
    local getter = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if type(getter) ~= "function" then return nil end
    local ok, _, _, _, _, icon = pcall(getter, itemID)
    if not ok then return nil end
    return plain(icon)
end

function ns.Money(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local bronze = copper % 100
    if gold > 0 then
        if silver > 0 then return string.format("%dg %ds", gold, silver) end
        return string.format("%dg", gold)
    end
    if silver > 0 then
        if bronze > 0 then return string.format("%ds %dc", silver, bronze) end
        return string.format("%ds", silver)
    end
    return string.format("%dc", bronze)
end

function ns.MoneyExact(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local bronze = copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = string.format("%dg", gold) end
    if silver > 0 then parts[#parts + 1] = string.format("%ds", silver) end
    if bronze > 0 or #parts == 0 then parts[#parts + 1] = string.format("%dc", bronze) end
    return table.concat(parts, " ")
end

function ns.Copper(text)
    text = text:lower():gsub("%s+", "")
    if text == "" then return nil end
    local gold = text:match("^%d+%.?%d*$")
    if gold then return math.floor(tonumber(gold) * 10000 + 0.5) end
    local total, span = 0, 0
    for amount, unit in text:gmatch("(%d+%.?%d*)([gsc])") do
        total = total + tonumber(amount) * UNITS[unit]
        span = span + #amount + 1
    end
    if span ~= #text then return nil end
    return math.floor(total + 0.5)
end

function ns.ItemLink(itemID, known)
    if type(known) == "string" then return known end
    local _, link = ns.ItemInfo(itemID)
    if link then return link end
    return "item:" .. tostring(itemID)
end
