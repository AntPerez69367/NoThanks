local addonName, ns = ...
local Button = ns.Minimap

local ICON = "Interface\\AddOns\\NoThanks\\Media\\icon.tga"

local function onClick(_, button)
    if button == "RightButton" then
        ns.UI.Open("options")
    else
        ns.UI.Toggle()
    end
end

local function onTooltipShow(tip)
    tip:AddLine("No Thanks!")
    tip:AddLine(ns.L.MINIMAP_LEFT_CLICK, 1, 1, 1)
    tip:AddLine(ns.L.MINIMAP_RIGHT_CLICK, 1, 1, 1)
end

function Button.Initialise()
    local broker = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
        type = "launcher",
        icon = ICON,
        OnClick = onClick,
        OnTooltipShow = onTooltipShow,
    })
    LibStub("LibDBIcon-1.0"):Register(addonName, broker, ns.Storage.account.minimap)
end

function Button.SetShown(shown)
    local icon = LibStub("LibDBIcon-1.0")
    if shown then
        icon:Show(addonName)
    else
        icon:Hide(addonName)
    end
end
