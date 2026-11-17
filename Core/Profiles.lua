local addonName, ns = ...
local Profiles, Storage = ns.Profiles, ns.Storage

local VERSION = "NT1"
local PREFIX = VERSION .. ":"

local function trim(text)
    return text:match("^%s*(.-)%s*$")
end

local function currentIDs()
    local ids = {}
    for key in pairs(Storage.Blacklist()) do
        ids[#ids + 1] = tonumber(key)
    end
    table.sort(ids)
    return ids
end

local function merge(ids)
    local added, present = 0, 0
    for _, id in ipairs(ids) do
        if Storage.Add(id) then
            added = added + 1
        else
            present = present + 1
        end
    end
    return added, present
end

function Profiles.List()
    local names = {}
    for name in pairs(Storage.account.profiles) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function Profiles.Save(name)
    Storage.account.profiles[name] = currentIDs()
end

function Profiles.Delete(name)
    Storage.account.profiles[name] = nil
end

function Profiles.Apply(name)
    local added = merge(Storage.account.profiles[name])
    return added
end

function Profiles.Export()
    return PREFIX .. table.concat(currentIDs(), ",")
end

function Profiles.Import(text)
    local version, body = trim(text):match("^([^:]+):(.*)$")
    if not version then return nil, "BAD_PREFIX" end
    if version ~= VERSION then
        if version:match("^NT%d+$") then return nil, "BAD_VERSION" end
        return nil, "BAD_PREFIX"
    end
    body = trim(body)
    if body == "" then return nil, "NO_ITEMS" end
    local ids = {}
    for field in (body .. ","):gmatch("([^,]*),") do
        local id = tonumber(trim(field))
        if not id or id < 1 or id >= math.huge or math.floor(id) ~= id then return nil, "BAD_ITEM" end
        ids[#ids + 1] = id
    end
    return merge(ids)
end
