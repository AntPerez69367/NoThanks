local addonName, ns = ...
local Storage = ns.Storage

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
}

local CHARACTER_DEFAULTS = {
    blacklist = "table",
    history = "table",
}

local function applyDefaults(store, defaults)
    for key, value in pairs(defaults) do
        if store[key] == nil then
            store[key] = (value == "table") and {} or value
        end
    end
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

function Storage.IsBlacklisted(itemID)
    local key = Storage.Key(itemID)
    return key ~= nil and Storage.character.blacklist[key] ~= nil
end

function Storage.IsEmpty()
    return next(Storage.character.blacklist) == nil
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

function Storage.CountSkip(itemID)
    local key = Storage.Key(itemID)
    local entry = key and Storage.character.blacklist[key]
    if not entry then return end
    entry.skipped = (entry.skipped or 0) + 1
    entry.lastSkipped = time()
end
