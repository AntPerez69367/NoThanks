local addonName, ns = ...
local Storage, AutoLoot, Loot, UI = ns.Storage, ns.AutoLoot, ns.Loot, ns.UI
local Destroy = ns.Destroy
local Button = ns.Minimap

local function devCommand(argument)
    local verb, value = argument:match("^(%S*)%s*(%S*)$")
    local itemID = tonumber(value)
    if not itemID then
        ns.Print("usage: /nothanks dev add|remove <itemID>")
        return
    end
    if verb == "add" and Storage.Add(itemID) then
        ns.Print("blacklisted " .. ns.ItemLink(itemID))
    elseif verb == "remove" and Storage.Remove(itemID) then
        ns.Print("removed " .. ns.ItemLink(itemID))
    else
        ns.Print("no change for " .. tostring(itemID))
    end
    ns.Resync()
end

SLASH_NOTHANKS1, SLASH_NOTHANKS2, SLASH_NOTHANKS3 = "/nothanks", "/noty", "/nt"

SlashCmdList.NOTHANKS = function(message)
    if not Storage.account then return end
    local command, argument = (message or ""):match("^(%S*)%s*(.-)$")
    command = (command or ""):lower()
    if command == "" then
        UI.Toggle()
    elseif command == "dev" then
        devCommand(argument)
    else
        ns.Print("/nothanks, /noty, /nt — open the window")
        ns.Print("/nothanks dev add|remove <itemID> — seed the blacklist for testing")
    end
end

local bootstrap = CreateFrame("Frame")
bootstrap:RegisterEvent("ADDON_LOADED")
bootstrap:SetScript("OnEvent", function(self, _, loaded)
    if loaded ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    Storage.Initialise()
    ns.LoadLocale()
    Button.Initialise()
    Loot.Initialise()
    Destroy.Initialise()
    AutoLoot.Initialise()
    UI.RegisterOptions()
    ns.Resync()
end)
