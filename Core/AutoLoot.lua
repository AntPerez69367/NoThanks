local addonName, ns = ...
local AutoLoot, Storage = ns.AutoLoot, ns.Storage

local CVAR = "autoLootDefault"

local function readCVar()
    if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(CVAR) end
    return GetCVar(CVAR)
end

local function writeCVar(value)
    if C_CVar and C_CVar.SetCVar then return C_CVar.SetCVar(CVAR, value) end
    return SetCVar(CVAR, value)
end

function AutoLoot.Owns()
    return Storage.account.heldAutoLoot ~= nil
end

function AutoLoot.Acquire()
    if not AutoLoot.Owns() then
        Storage.account.heldAutoLoot = readCVar()
    end
    writeCVar("0")
end

function AutoLoot.Release()
    local original = Storage.account.heldAutoLoot
    if original == nil then return end
    Storage.account.heldAutoLoot = nil
    writeCVar(original)
    if readCVar() ~= original then
        Storage.account.heldAutoLoot = original
    end
end

local explained = false

local function reassert()
    if not AutoLoot.Owns() then return end
    local current = readCVar()
    if current == "0" then return end
    Storage.account.heldAutoLoot = current
    writeCVar("0")
    if explained then return end
    explained = true
    ns.Print(ns.L.REASSERTED)
end

function AutoLoot.Initialise()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGOUT" then
            AutoLoot.Release()
        else
            reassert()
        end
    end)
    frame:RegisterEvent("PLAYER_LOGOUT")
    pcall(frame.RegisterEvent, frame, "CVAR_UPDATE")
end

function AutoLoot.Sync()
    if Storage.IsEmpty() then
        AutoLoot.Release()
    else
        AutoLoot.Acquire()
    end
end
