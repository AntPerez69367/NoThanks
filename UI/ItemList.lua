local addonName, ns = ...
local UI, Storage, Prices = ns.UI, ns.Storage, ns.Prices
local AutoLoot, Wrapper, Filter = ns.AutoLoot, ns.Wrapper, ns.Filter

local ROW_HEIGHT = 22
local VISIBLE_ROWS = 12
local ICON_X = 4
local ICON_SIZE = 18
local NAME_INSET = ICON_X + ICON_SIZE + 6
local COLUMN_GAP = 8
local COLUMN_PAD = 6
local COUNT_WIDTH_LOOT = 56
local COUNT_WIDTH_BLACKLIST = 78
local MONEY_WIDTH = 92
local GUTTER = 4
local GUTTER_SPAN = 8
local THUMB_MIN = 18

local List = {}
UI.List = List

local pool = {}
local entries = {}
local selected = {}
local offset = 0
local panel, headers, empty, track, thumb, rowWidth
local currentTab = "loot"

local function itemFacts(key)
    local itemID = tonumber(key)
    local name, link, quality, _, _, _, _, _, _, icon = ns.ItemInfo(itemID)
    return itemID, name, link, quality, icon
end

local function columnSlots(container, nameFont, valueFont)
    local slots = {
        name = UI.Text(container, nameFont),
        count = UI.Text(container, valueFont),
        vendor = UI.Text(container, valueFont),
        auction = UI.Text(container, valueFont),
    }
    slots.auction:SetPoint("RIGHT", container, "RIGHT", -COLUMN_PAD, 0)
    slots.auction:SetWidth(MONEY_WIDTH)
    slots.vendor:SetPoint("RIGHT", slots.auction, "LEFT", -COLUMN_GAP, 0)
    slots.vendor:SetWidth(MONEY_WIDTH)
    slots.count:SetPoint("RIGHT", slots.vendor, "LEFT", -COLUMN_GAP, 0)
    slots.count:SetWidth(COUNT_WIDTH_LOOT)
    slots.name:SetPoint("LEFT", container, "LEFT", NAME_INSET, 0)
    slots.name:SetPoint("RIGHT", slots.count, "LEFT", -COLUMN_GAP, 0)
    slots.name:SetJustifyH("LEFT")
    slots.count:SetJustifyH("RIGHT")
    slots.vendor:SetJustifyH("RIGHT")
    slots.auction:SetJustifyH("RIGHT")
    for _, slot in pairs(slots) do slot:SetWordWrap(false) end
    return slots
end

local function countWidth(tab)
    if tab == "blacklist" then return COUNT_WIDTH_BLACKLIST end
    return COUNT_WIDTH_LOOT
end

local function quickBinding(button)
    local binding = Storage.account.quickAddBinding
    if binding == "RIGHT" then return button == "RightButton" end
    if button ~= "LeftButton" then return false end
    if binding == "SHIFT" then return IsShiftKeyDown() end
    return IsControlKeyDown()
end

local function quickToggle(key)
    if currentTab == "blacklist" then
        Storage.Remove(key)
    else
        Storage.Add(key)
    end
    List.ClearSelection()
    AutoLoot.Sync()
    Wrapper.Sync()
    UI.Refresh()
end

local function createRow(slot)
    local row = CreateFrame("Button", nil, panel)
    row:SetSize(rowWidth, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1 - (slot - 1) * ROW_HEIGHT)

    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints(row)
    if slot % 2 == 0 then
        row.stripe:SetColorTexture(1, 1, 1, 0.035)
    else
        row.stripe:SetColorTexture(0, 0, 0, 0)
    end
    row.hover = row:CreateTexture(nil, "BORDER")
    row.hover:SetAllPoints(row)
    row.hover:SetColorTexture(1, 1, 1, 0.07)
    row.hover:Hide()
    row.fill = row:CreateTexture(nil, "BORDER")
    row.fill:SetAllPoints(row)
    row.fill:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.22)
    row.fill:Hide()
    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.accent:SetSize(3, ROW_HEIGHT)
    row.accent:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 1)
    row.accent:Hide()

    row.icon = row:CreateTexture(nil, "OVERLAY")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetPoint("LEFT", row, "LEFT", ICON_X, 0)
    row.columns = columnSlots(row, "GameFontNormalSmall", "GameFontHighlightSmall")

    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, button)
        if quickBinding(button) then
            quickToggle(self.key)
            return
        end
        selected[self.key] = not selected[self.key] or nil
        UI.Refresh()
    end)
    row:SetScript("OnEnter", function(self)
        self.hover:Show()
        if not self.link then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.hover:Hide()
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    return row
end

local function setMoney(fontString, copper)
    local text, r, g, b = UI.MoneyShort(copper)
    fontString:SetText(text)
    fontString:SetTextColor(r, g, b)
end

local function updateRow(row, entry)
    local columns = row.columns
    row.key = entry.key
    row.link = entry.link
    row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    columns.name:SetText(entry.name or ("item:" .. tostring(entry.key)))
    UI.Color(columns.name, entry.quality)
    columns.count:SetText(entry.count and tostring(entry.count) or "")
    setMoney(columns.vendor, entry.vendor)
    setMoney(columns.auction, entry.auction)
    if selected[entry.key] then
        row.fill:Show()
        row.accent:Show()
    else
        row.fill:Hide()
        row.accent:Hide()
    end
end

local function paintGutter(total, maxOffset)
    if maxOffset == 0 then
        track:Hide()
        thumb:Hide()
        return
    end
    local span = VISIBLE_ROWS * ROW_HEIGHT - 4
    local height = math.max(THUMB_MIN, math.floor(span * VISIBLE_ROWS / total))
    thumb:SetHeight(height)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -3 - math.floor((span - height) * offset / maxOffset))
    track:Show()
    thumb:Show()
end

local function renderRows()
    local total = #entries
    local maxOffset = math.max(0, total - VISIBLE_ROWS)
    if offset > maxOffset then offset = maxOffset end
    if offset < 0 then offset = 0 end
    for slot = 1, VISIBLE_ROWS do
        local entry = entries[slot + offset]
        if entry then
            updateRow(pool[slot], entry)
            pool[slot]:Show()
        else
            pool[slot]:Hide()
        end
    end
    paintGutter(total, maxOffset)
end

local function matches(entry, search, qualities)
    if search ~= "" then
        if not entry.name then return false end
        if not entry.name:lower():find(search, 1, true) then return false end
    end
    if entry.quality and next(qualities) and not qualities[entry.quality] then return false end
    return true
end

function List.Build(tab, search, qualities)
    currentTab = tab
    entries = {}
    search = (search or ""):lower()
    local blacklisted = (tab == "blacklist")
    local source = blacklisted and Storage.Blacklist() or Storage.History()
    for key, record in pairs(source) do
        local itemID, name, link, quality, icon = itemFacts(key)
        local hidden = not blacklisted and (Storage.IsBlacklisted(key) or Filter.IsQuestItem(itemID))
        if not hidden then
            local entry = {
                key = key, itemID = itemID, name = name, link = link,
                quality = quality, icon = icon, seen = record.seen or 0,
                count = blacklisted and (record.skipped or 0) or record.count,
                vendor = itemID and Prices.Vendor(itemID) or nil,
                auction = itemID and Prices.Auction(itemID) or nil,
            }
            if matches(entry, search, qualities) then entries[#entries + 1] = entry end
        end
    end
    if blacklisted then
        table.sort(entries, function(a, b) return (a.name or a.key) < (b.name or b.key) end)
    else
        table.sort(entries, function(a, b) return a.seen > b.seen end)
    end
end

function List.Selected()
    local keys = {}
    for key in pairs(selected) do keys[#keys + 1] = key end
    return keys
end

function List.ClearSelection()
    selected = {}
    offset = 0
end

function List.Total()
    return #entries
end

function List.Attach(parent, metrics)
    rowWidth = metrics.listWidth - GUTTER_SPAN - 2

    panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", metrics.pad, metrics.listTop)
    panel:SetSize(metrics.listWidth, VISIBLE_ROWS * ROW_HEIGHT + 2)
    UI.Fill(panel, UI.C.content, 0.45)
    UI.Edge(panel, UI.C.borderDim)
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        offset = offset - delta
        renderRows()
    end)

    headers = CreateFrame("Frame", nil, parent)
    headers:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", 1, metrics.columnGap)
    headers:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -(GUTTER_SPAN + 1), metrics.columnGap)
    headers:SetHeight(metrics.columnH)
    headers.columns = columnSlots(headers, "GameFontDisableSmall", "GameFontDisableSmall")
    headers.columns.name:SetText(ns.L.COL_ITEM)
    headers.columns.vendor:SetText(ns.L.COL_VENDOR)
    headers.columns.auction:SetText(ns.L.COL_AUCTION)
    local rule = headers:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", 0, 1)
    rule:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", 0, 1)
    rule:SetHeight(1)
    rule:SetColorTexture(UI.C.borderDim[1], UI.C.borderDim[2], UI.C.borderDim[3], 1)

    track = panel:CreateTexture(nil, "ARTWORK")
    track:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -3)
    track:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -3, 3)
    track:SetWidth(GUTTER)
    track:SetColorTexture(1, 1, 1, 0.05)
    track:Hide()
    thumb = panel:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(GUTTER)
    thumb:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.6)
    thumb:Hide()

    for slot = 1, VISIBLE_ROWS do pool[slot] = createRow(slot) end

    empty = UI.Text(panel, "GameFontDisableLarge")
    empty:SetPoint("CENTER", panel, "CENTER", 0, 0)
    empty:SetWidth(metrics.listWidth - 60)
    empty:SetJustifyH("CENTER")
    empty:Hide()
end

function List.Render(tab, emptyMessage)
    local width = countWidth(tab)
    headers.columns.count:SetWidth(width)
    for slot = 1, VISIBLE_ROWS do
        pool[slot].columns.count:SetWidth(width)
    end
    headers.columns.count:SetText((tab == "blacklist") and ns.L.COL_LEFT or ns.L.COL_LOOTED)
    renderRows()
    if #entries == 0 then
        empty:SetText(emptyMessage)
        empty:Show()
    else
        empty:Hide()
    end
end
