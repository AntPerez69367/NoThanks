local addonName, ns = ...
local History, Storage = ns.History, ns.Storage

local CAP = 500

History.SessionStart = time()

local function size(store)
    local count = 0
    for _ in pairs(store) do count = count + 1 end
    return count
end

function History.Prune()
    local store = Storage.History()
    local count = size(store)
    while count > CAP do
        local oldestKey, oldestSeen
        for key, entry in pairs(store) do
            local seen = entry.seen or 0
            if oldestSeen == nil or seen < oldestSeen then
                oldestKey, oldestSeen = key, seen
            end
        end
        if not oldestKey then return end
        store[oldestKey] = nil
        count = count - 1
    end
end

function History.Record(itemID, isQuestItem)
    local key = Storage.Key(itemID)
    if not key then return end
    local store = Storage.History()
    local entry = store[key]
    if entry then
        entry.count = (entry.count or 0) + 1
        entry.seen = time()
        if isQuestItem then entry.quest = true end
        return
    end
    store[key] = { count = 1, seen = time(), quest = isQuestItem or nil }
    History.Prune()
end

function History.Clear()
    wipe(Storage.History())
end
