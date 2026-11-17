local addonName, ns = ...
local UI, Storage, AutoLoot, Wrapper = ns.UI, ns.Storage, ns.AutoLoot, ns.Wrapper
local Profiles = ns.Profiles

local QUALITIES = { 0, 1, 2, 3, 4 }
local MODIFIERS = { "SHIFT", "CTRL", "ALT" }
local QUICKADDS = {
    { value = "SHIFT", label = "Shift" },
    { value = "CTRL", label = "Ctrl" },
    { value = "RIGHT", label = "Right" },
}
local ANNOUNCES = {
    { value = "CHAT", label = "Chat" },
    { value = "ERROR", label = "Top of screen" },
    { value = "NONE", label = "Off" },
}
local TABS = { "loot", "blacklist", "options" }
local GUTTER = 4
local THUMB_MIN = 18
local WHEEL_STEP = 28

local M = {
    width = 520,
    height = 444,
    pad = 14,
    headerH = 30,
    closeSize = 22,
    wordmarkWidth = 256,
    wordmarkHeight = 32,
    tabTop = -34,
    tabH = 26,
    tabGap = 8,
    toolbarTop = -64,
    toolbarH = 24,
    searchWidth = 180,
    columnH = 18,
    columnGap = 4,
    listTop = -114,
    listWidth = 492,
    optionsTop = -64,
    optionsHeight = 368,
    scrollWidth = 482,
    labelWidth = 170,
    headingGap = 8,
    actionTop = -392,
    actionH = 22,
    actionWidth = 200,
    statusTop = -420,
    swatch = 18,
    swatchGap = 4,
    indent = 16,
    rowH = 20,
    rowGap = 12,
    sectionGap = 20,
    profileField = 160,
    profileButton = 116,
    profileAction = 62,
    transferButton = 90,
    transferAccept = 80,
    announceTest = 54,
}

local frame, listPage, optionsPage, tabStrip, searchBox, bulkButton, clearButton, status
local optionsPanel, optionsScroll, optionsCanvas, optionsTrack, optionsThumb
local optionsOffset, optionsSpan = 0, 0
local tabs, swatches, conditionals, sections = {}, {}, {}, {}
local currentTab = "loot"
local qualities = {}
local profileList, profileEmpty, profileName, profileSave
local transferGroup, transferBox, transferAccept, transferExport
local profileRows = {}
local syncProfiles

local function text(key, fallback)
    return ns.L[key] or fallback
end

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function filtering()
    return searchBox:GetText() ~= "" or next(qualities) ~= nil
end

local function emptyMessage()
    if filtering() then return ns.L.EMPTY_FILTER end
    if currentTab == "blacklist" then return ns.L.EMPTY_BLACKLIST end
    return ns.L.EMPTY_LOOT
end

local function tabTotal(tab)
    local count = 0
    if tab == "blacklist" then
        for _ in pairs(Storage.Blacklist()) do count = count + 1 end
        return count
    end
    for key in pairs(Storage.History()) do
        if not Storage.IsBlacklisted(key) then count = count + 1 end
    end
    return count
end

local function tabLabel(tab)
    if tab == "options" then return text("TAB_OPTIONS", "Options") end
    local name = (tab == "blacklist") and ns.L.TAB_BLACKLIST or ns.L.TAB_LOOT
    return string.format("%s (%d)", name, tabTotal(tab))
end

local function actionLabel(count)
    local template = (currentTab == "blacklist") and ns.L.REMOVE_SELECTED or ns.L.BLACKLIST_SELECTED
    if count > 0 then return string.format(template, count) end
    return (template:gsub("%s*%(%%d%)", ""))
end

local function reflowTabs()
    local anchor
    for _, name in ipairs(TABS) do
        local tab = tabs[name]
        tab:ClearAllPoints()
        if anchor then
            tab:SetPoint("BOTTOMLEFT", anchor, "BOTTOMRIGHT", M.tabGap, 0)
        else
            tab:SetPoint("BOTTOMLEFT", tabStrip, "BOTTOMLEFT", 0, 0)
        end
        anchor = tab
    end
end

function UI.Refresh()
    local List = UI.List
    for _, name in ipairs(TABS) do
        tabs[name].SetLabel(tabLabel(name), name == currentTab)
    end
    listPage:SetShown(currentTab ~= "options")
    optionsPage:SetShown(currentTab == "options")
    if currentTab == "options" then
        syncProfiles()
        reflowTabs()
        return
    end
    List.Build(currentTab, searchBox:GetText(), qualities)
    local shown, total = List.Total(), tabTotal(currentTab)
    local count = #List.Selected()
    bulkButton:SetText(actionLabel(count))
    bulkButton:SetEnabled(count > 0)
    for _, swatch in ipairs(swatches) do swatch.Apply() end
    if filtering() then
        status:SetText(string.format(ns.L.STATUS_FILTERED, shown, total))
    else
        status:SetText(string.format(ns.L.STATUS_ALL, total))
    end
    reflowTabs()
    for _, widget in ipairs(conditionals) do widget:SetShown(widget.visible()) end
    List.Render(currentTab, emptyMessage())
end

local function switchTab(name)
    currentTab = name
    UI.List.ClearSelection()
    UI.Refresh()
end

local function applyBulk()
    for _, key in ipairs(UI.List.Selected()) do
        if currentTab == "blacklist" then
            Storage.Remove(key)
        else
            Storage.Add(key)
        end
    end
    UI.List.ClearSelection()
    AutoLoot.Sync()
    Wrapper.Sync()
    UI.Refresh()
end

local function pickQuality(quality)
    if next(qualities) == nil then
        qualities = { [quality] = true }
    else
        qualities[quality] = not qualities[quality] or nil
    end
    UI.List.ClearSelection()
    UI.Refresh()
end

local function buildHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -1, -1)
    header:SetHeight(M.headerH)
    UI.Fill(header, UI.C.header)
    UI.Rule(header, "BOTTOM", UI.C.borderDim)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() parent:StartMoving() end)
    header:SetScript("OnDragStop", function() parent:StopMovingOrSizing() end)

    local wordmark = header:CreateTexture(nil, "ARTWORK")
    wordmark:SetTexture("Interface\\AddOns\\NoThanks\\Media\\wordmark.tga")
    wordmark:SetSize(M.wordmarkWidth, M.wordmarkHeight)
    wordmark:SetPoint("CENTER", header, "CENTER", 0, 0)

    local close = CreateFrame("Button", nil, header)
    close:SetSize(M.closeSize, M.closeSize)
    close:SetPoint("RIGHT", header, "RIGHT", -4, 0)
    local wash = UI.Fill(close, UI.C.buttonHover, 0)
    close.label = UI.Text(close, "GameFontNormal")
    close.label:SetPoint("CENTER")
    close.label:SetText("X")
    close.Apply = function()
        wash:SetColorTexture(UI.C.buttonHover[1], UI.C.buttonHover[2], UI.C.buttonHover[3],
            close.hover and 1 or 0)
        UI.Ink(close.label, close.hover and UI.C.white or UI.C.muted)
    end
    close:SetScript("OnEnter", function(self) self.hover = true; self.Apply() end)
    close:SetScript("OnLeave", function(self) self.hover = false; self.Apply() end)
    close:SetScript("OnClick", function() parent:Hide() end)
    close.Apply()
    return header
end

local function buildTabs(parent)
    tabStrip = CreateFrame("Frame", nil, parent)
    tabStrip:SetPoint("TOPLEFT", parent, "TOPLEFT", M.pad, M.tabTop)
    tabStrip:SetSize(M.listWidth, M.tabH)
    UI.Rule(tabStrip, "BOTTOM", UI.C.borderDim)
    for _, name in ipairs(TABS) do
        tabs[name] = UI.Tab(tabStrip, M.tabH, function() switchTab(name) end)
        tabs[name].SetLabel(tabLabel(name), name == currentTab)
    end
    reflowTabs()
end

local function buildToolbar(parent)
    local toolbar = CreateFrame("Frame", nil, parent)
    toolbar:SetPoint("TOPLEFT", parent, "TOPLEFT", M.pad, M.toolbarTop)
    toolbar:SetSize(M.listWidth, M.toolbarH)

    searchBox = UI.Search(toolbar, M.searchWidth, ns.L.SEARCH, function()
        UI.List.ClearSelection()
        UI.Refresh()
    end)
    searchBox:SetPoint("LEFT", toolbar, "LEFT", 0, 0)

    local group = CreateFrame("Frame", nil, toolbar)
    group:SetHeight(M.toolbarH)
    group:SetPoint("RIGHT", toolbar, "RIGHT", 0, 0)
    UI.Fill(group, UI.C.field)
    UI.Edge(group, UI.C.borderDim)

    local caption = UI.Text(group, "GameFontNormalSmall")
    caption:SetPoint("LEFT", group, "LEFT", 8, 0)
    caption:SetText(text("FILTER_QUALITY", ns.L.QUALITY))
    caption:SetWordWrap(false)
    UI.Ink(caption, UI.C.muted)

    local anchor
    for _, quality in ipairs(QUALITIES) do
        local swatch = UI.Swatch(group, quality, M.swatch,
            function() return qualities[quality] or next(qualities) == nil end,
            pickQuality)
        if anchor then
            swatch:SetPoint("LEFT", anchor, "RIGHT", M.swatchGap, 0)
        else
            swatch:SetPoint("LEFT", caption, "RIGHT", 8, 0)
        end
        anchor = swatch
        swatches[#swatches + 1] = swatch
    end

    local captionWidth = math.ceil(caption:GetStringWidth() or 44)
    group:SetWidth(captionWidth + #QUALITIES * M.swatch
        + (#QUALITIES - 1) * M.swatchGap + 24)
    return toolbar
end

local function buildActions(parent)
    bulkButton = UI.Button(parent, actionLabel(0), M.actionWidth, applyBulk)
    bulkButton:SetPoint("TOPLEFT", parent, "TOPLEFT", M.pad, M.actionTop)

    clearButton = CreateFrame("Button", nil, parent)
    clearButton:SetHeight(M.actionH)
    clearButton:SetPoint("LEFT", bulkButton, "RIGHT", 10, 0)
    clearButton.label = UI.Text(clearButton, "GameFontNormalSmall")
    clearButton.label:SetPoint("CENTER")
    clearButton.label:SetText(text("CLEAR_SELECTION", "Clear selection"))
    clearButton:SetWidth(math.floor((clearButton.label:GetStringWidth() or 90) + 16))
    UI.Ink(clearButton.label, UI.C.muted)
    clearButton:SetScript("OnEnter", function(self) UI.Ink(self.label, UI.C.accent) end)
    clearButton:SetScript("OnLeave", function(self) UI.Ink(self.label, UI.C.muted) end)
    clearButton:SetScript("OnClick", function()
        UI.List.ClearSelection()
        UI.Refresh()
    end)
    clearButton.visible = function() return #UI.List.Selected() > 0 end
    conditionals[#conditionals + 1] = clearButton

    status = UI.Text(parent, "GameFontNormalSmall")
    status:SetPoint("TOPLEFT", parent, "TOPLEFT", M.pad, M.statusTop)
    status:SetWidth(M.listWidth)
    status:SetJustifyH("LEFT")
    status:SetWordWrap(false)
    UI.Ink(status, UI.C.dim)
end

local function paintOptionsScroll()
    local viewport = M.optionsHeight - 2
    local maxOffset = math.max(0, optionsSpan - viewport)
    if optionsOffset > maxOffset then optionsOffset = maxOffset end
    if optionsOffset < 0 then optionsOffset = 0 end
    optionsScroll:SetVerticalScroll(optionsOffset)
    if maxOffset == 0 then
        optionsTrack:Hide()
        optionsThumb:Hide()
        return
    end
    local span = viewport - 6
    local height = math.max(THUMB_MIN, math.floor(span * viewport / optionsSpan))
    optionsThumb:SetHeight(height)
    optionsThumb:ClearAllPoints()
    optionsThumb:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -3,
        -3 - math.floor((span - height) * optionsOffset / maxOffset))
    optionsTrack:Show()
    optionsThumb:Show()
end

local function relayoutOptions()
    local y = -12
    for _, section in ipairs(sections) do
        local open = section.header.expanded
        section.header:ClearAllPoints()
        section.header:SetPoint("TOPLEFT", optionsCanvas, "TOPLEFT", 12, y)
        section.header:SetPoint("TOPRIGHT", optionsCanvas, "TOPRIGHT", -12, y)
        y = y - section.header:GetHeight() - M.headingGap
        for _, widget in ipairs(section.frames) do widget:SetShown(open) end
        if open then
            for _, place in ipairs(section.rows) do y = place(y) end
        end
        y = y - M.sectionGap
    end
    optionsSpan = math.max(1, -y)
    optionsCanvas:SetHeight(optionsSpan)
    paintOptionsScroll()
end

local function addSection(label)
    local section = { frames = {}, rows = {} }
    section.header = UI.Section(optionsCanvas, label, relayoutOptions)
    sections[#sections + 1] = section
    return section
end

local function addSetting(section, control, label, body)
    local frames, note = section.frames, nil
    if label then
        local caption = UI.Text(optionsCanvas, "GameFontNormalSmall")
        caption:SetWidth(M.labelWidth - 12)
        caption:SetPoint("RIGHT", control, "LEFT", -12, 0)
        caption:SetJustifyH("LEFT")
        caption:SetWordWrap(false)
        caption:SetText(label)
        UI.Ink(caption, UI.C.text)
        frames[#frames + 1] = caption
    else
        control:SetWidth(M.scrollWidth - M.indent - 12)
    end
    if body then
        note = UI.Text(optionsCanvas, "GameFontNormalSmall")
        note:SetWidth(M.scrollWidth - M.indent - 42)
        note:SetJustifyH("LEFT")
        note:SetWordWrap(true)
        note:SetText(body)
        UI.Ink(note, UI.C.dim)
        note.span = math.ceil(note:GetStringHeight() or 12) + 4
        frames[#frames + 1] = note
    end
    frames[#frames + 1] = control
    section.rows[#section.rows + 1] = function(y)
        control:ClearAllPoints()
        control:SetPoint("TOPLEFT", optionsCanvas, "TOPLEFT",
            label and (M.indent + M.labelWidth) or M.indent, y)
        y = y - M.rowH
        if note then
            note:ClearAllPoints()
            note:SetPoint("TOPLEFT", optionsCanvas, "TOPLEFT", M.indent + 30, y)
            y = y - note.span
        end
        return y - M.rowGap
    end
end

local function addRow(section, group, x)
    section.frames[#section.frames + 1] = group
    section.rows[#section.rows + 1] = function(y)
        group:ClearAllPoints()
        group:SetPoint("TOPLEFT", optionsCanvas, "TOPLEFT", x, y)
        return y - group:GetHeight() - M.rowGap
    end
end

local function buildModifier(canvas)
    local group = CreateFrame("Frame", nil, canvas)
    group:SetSize(32 * #MODIFIERS, M.rowH)
    UI.Fill(group, UI.C.field)
    UI.Edge(group, UI.C.borderDim)
    local segments = {}
    local function paint()
        for _, segment in ipairs(segments) do
            local on = Storage.account.bypassModifier == segment.value
            segment.wash:SetShown(on)
            if on then
                UI.Ink(segment.label, UI.C.white)
            else
                UI.Ink(segment.label, segment.hover and UI.C.text or UI.C.dim)
            end
        end
    end
    for index, value in ipairs(MODIFIERS) do
        local segment = CreateFrame("Button", nil, group)
        segment:SetSize(32, M.rowH - 2)
        segment:SetPoint("TOPLEFT", group, "TOPLEFT", (index - 1) * 32, -1)
        segment.value = value
        segment.wash = segment:CreateTexture(nil, "ARTWORK")
        segment.wash:SetAllPoints(segment)
        segment.wash:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.30)
        segment.label = UI.Text(segment, "GameFontNormalSmall")
        segment.label:SetPoint("CENTER")
        segment.label:SetText(value)
        segment:SetScript("OnClick", function(self)
            Storage.account.bypassModifier = self.value
            paint()
        end)
        segment:SetScript("OnEnter", function(self)
            self.hover = true
            paint()
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(ns.L.SETTING_MODIFIER)
            GameTooltip:Show()
        end)
        segment:SetScript("OnLeave", function(self)
            self.hover = false
            paint()
            if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        end)
        segments[index] = segment
    end
    paint()
    return group
end

local function buildQuickAdd(canvas)
    local group = CreateFrame("Frame", nil, canvas)
    group:SetSize(40 * #QUICKADDS, M.rowH)
    UI.Fill(group, UI.C.field)
    UI.Edge(group, UI.C.borderDim)
    local segments = {}
    local function paint()
        for _, segment in ipairs(segments) do
            local on = Storage.account.quickAddBinding == segment.value
            segment.wash:SetShown(on)
            if on then
                UI.Ink(segment.label, UI.C.white)
            else
                UI.Ink(segment.label, segment.hover and UI.C.text or UI.C.dim)
            end
        end
    end
    for index, choice in ipairs(QUICKADDS) do
        local segment = CreateFrame("Button", nil, group)
        segment:SetSize(40, M.rowH - 2)
        segment:SetPoint("TOPLEFT", group, "TOPLEFT", (index - 1) * 40, -1)
        segment.value = choice.value
        segment.wash = segment:CreateTexture(nil, "ARTWORK")
        segment.wash:SetAllPoints(segment)
        segment.wash:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.30)
        segment.label = UI.Text(segment, "GameFontNormalSmall")
        segment.label:SetPoint("CENTER")
        segment.label:SetText(choice.label)
        segment:SetScript("OnClick", function(self)
            Storage.account.quickAddBinding = self.value
            paint()
        end)
        segment:SetScript("OnEnter", function(self)
            self.hover = true
            paint()
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(ns.L.SETTING_QUICKADD)
            GameTooltip:Show()
        end)
        segment:SetScript("OnLeave", function(self)
            self.hover = false
            paint()
            if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        end)
        segments[index] = segment
    end
    paint()
    return group
end

local function announceSample()
    local links = {}
    for key in pairs(Storage.Blacklist()) do
        links[#links + 1] = ns.ItemLink(key)
        if #links == 3 then break end
    end
    if #links == 0 then
        return text("SETTING_ANNOUNCE_SAMPLE", "Tough Jerky, Chipped Claw, Ruined Pelt")
    end
    return table.concat(links, ", ")
end

local function buildAnnounce(canvas)
    local row = CreateFrame("Frame", nil, canvas)
    row:SetHeight(M.rowH)
    local group = CreateFrame("Frame", nil, row)
    group:SetHeight(M.rowH)
    group:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    UI.Fill(group, UI.C.field)
    UI.Edge(group, UI.C.borderDim)
    local segments = {}
    local test
    local function paint()
        for _, segment in ipairs(segments) do
            local on = Storage.account.announce == segment.value
            segment.wash:SetShown(on)
            if on then
                UI.Ink(segment.label, UI.C.white)
            else
                UI.Ink(segment.label, segment.hover and UI.C.text or UI.C.dim)
            end
        end
        test:SetEnabled(Storage.account.announce ~= "NONE")
    end
    local x = 0
    for index, choice in ipairs(ANNOUNCES) do
        local segment = CreateFrame("Button", nil, group)
        segment.value = choice.value
        segment.label = UI.Text(segment, "GameFontNormalSmall")
        segment.label:SetText(choice.label)
        segment.label:SetWordWrap(false)
        local width = math.ceil((segment.label:GetStringWidth() or 32) + 18)
        segment:SetSize(width, M.rowH - 2)
        segment:SetPoint("TOPLEFT", group, "TOPLEFT", x, -1)
        segment.label:SetPoint("CENTER")
        x = x + width
        segment.wash = segment:CreateTexture(nil, "ARTWORK")
        segment.wash:SetAllPoints(segment)
        segment.wash:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.30)
        segment:SetScript("OnClick", function(self)
            Storage.account.announce = self.value
            paint()
        end)
        segment:SetScript("OnEnter", function(self)
            self.hover = true
            paint()
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(ns.L.SETTING_ANNOUNCE)
            GameTooltip:Show()
        end)
        segment:SetScript("OnLeave", function(self)
            self.hover = false
            paint()
            if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        end)
        segments[index] = segment
    end
    group:SetWidth(x)

    test = UI.Button(row, text("SETTING_ANNOUNCE_TEST", "Test"), M.announceTest, function()
        ns.Announce(string.format(ns.L.LEFT_BEHIND, announceSample()))
    end)
    test:SetHeight(M.rowH - 2)
    test:SetPoint("LEFT", group, "RIGHT", 8, 0)
    row:SetWidth(x + 8 + M.announceTest)
    paint()
    return row
end

local function paintSave()
    profileSave:SetEnabled(trim(profileName:GetText()) ~= "")
end

local function profileRow(index)
    local row = profileRows[index]
    if row then return row end
    row = CreateFrame("Frame", nil, profileList)
    row:SetHeight(M.rowH)
    row:SetPoint("TOPLEFT", profileList, "TOPLEFT", 0, -(index - 1) * M.rowH)
    row:SetPoint("TOPRIGHT", profileList, "TOPRIGHT", 0, -(index - 1) * M.rowH)

    row.delete = UI.Button(row, text("PROFILE_DELETE", "Delete"), M.profileAction, function()
        Profiles.Delete(row.name)
        syncProfiles()
    end)
    row.delete:SetHeight(M.rowH - 2)
    row.delete:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    row.apply = UI.Button(row, text("PROFILE_APPLY", "Apply"), M.profileAction, function()
        local added = Profiles.Apply(row.name)
        ns.Print(string.format(ns.L.PROFILE_APPLIED, added))
        UI.List.ClearSelection()
        AutoLoot.Sync()
        Wrapper.Sync()
        UI.Refresh()
    end)
    row.apply:SetHeight(M.rowH - 2)
    row.apply:SetPoint("RIGHT", row.delete, "LEFT", -6, 0)

    row.label = UI.Text(row, "GameFontNormalSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetPoint("RIGHT", row.apply, "LEFT", -8, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    UI.Ink(row.label, UI.C.text)

    profileRows[index] = row
    return row
end

function syncProfiles()
    local names = Profiles.List()
    for index, name in ipairs(names) do
        local row = profileRow(index)
        row.name = name
        row.label:SetText(name)
        row:Show()
    end
    for index = #names + 1, #profileRows do profileRows[index]:Hide() end
    profileEmpty:SetShown(#names == 0)
    profileList:SetHeight(math.max(M.rowH, #names * M.rowH))
    paintSave()
    transferExport:SetEnabled(not Storage.IsEmpty())
    relayoutOptions()
end

local function hideTransfer()
    transferBox:ClearFocus()
    transferBox:Hide()
    transferAccept:Hide()
    transferGroup:SetHeight(M.rowH)
    relayoutOptions()
end

local function openTransfer(editable)
    transferBox.locked = not editable
    transferBox:SetText(editable and "" or Profiles.Export())
    transferAccept:SetShown(editable)
    transferBox:Show()
    transferGroup:SetHeight(M.rowH * 2 + 6)
    relayoutOptions()
    transferBox:SetFocus()
    if not editable then transferBox:HighlightText() end
end

local function acceptImport()
    local added, result = Profiles.Import(transferBox:GetText())
    if added then
        ns.Print(string.format(ns.L.IMPORT_RESULT, added, result))
        hideTransfer()
        UI.List.ClearSelection()
        AutoLoot.Sync()
        Wrapper.Sync()
        UI.Refresh()
        return
    end
    ns.Print(ns.L["IMPORT_" .. result])
end

local function buildProfileSave(canvas)
    local group = CreateFrame("Frame", nil, canvas)
    group:SetSize(M.profileField + 8 + M.profileButton, M.rowH)

    profileName = UI.Search(group, M.profileField,
        text("PROFILE_NAME_PLACEHOLDER", "Profile name"), paintSave)
    profileName:SetHeight(M.rowH - 2)
    profileName:SetPoint("LEFT", group, "LEFT", 0, 0)

    profileSave = UI.Button(group, text("PROFILE_SAVE", "Save current"), M.profileButton, function()
        Profiles.Save(trim(profileName:GetText()))
        profileName:SetText("")
        profileName:ClearFocus()
        syncProfiles()
    end)
    profileSave:SetHeight(M.rowH - 2)
    profileSave:SetPoint("RIGHT", group, "RIGHT", 0, 0)
    return group
end

local function buildProfileList(canvas)
    profileList = CreateFrame("Frame", nil, canvas)
    profileList:SetSize(M.profileField + 8 + M.profileButton, M.rowH)
    profileEmpty = UI.Text(profileList, "GameFontNormalSmall")
    profileEmpty:SetPoint("LEFT", profileList, "TOPLEFT", 0, -M.rowH / 2)
    profileEmpty:SetJustifyH("LEFT")
    profileEmpty:SetWordWrap(false)
    profileEmpty:SetText(text("PROFILE_NONE", "No profiles saved yet."))
    UI.Ink(profileEmpty, UI.C.dim)
    return profileList
end

local function buildTransfer(canvas)
    transferGroup = CreateFrame("Frame", nil, canvas)
    transferGroup:SetSize(M.scrollWidth - M.indent - 12, M.rowH)

    transferExport = UI.Button(transferGroup, text("EXPORT", "Export"), M.transferButton,
        function() openTransfer(false) end)
    transferExport:SetHeight(M.rowH - 2)
    transferExport:SetPoint("TOPLEFT", transferGroup, "TOPLEFT", 0, -1)

    local importButton = UI.Button(transferGroup, text("IMPORT", "Import"), M.transferButton,
        function() openTransfer(true) end)
    importButton:SetHeight(M.rowH - 2)
    importButton:SetPoint("LEFT", transferExport, "RIGHT", 8, 0)

    transferAccept = UI.Button(transferGroup, text("IMPORT_ACCEPT", "Accept"),
        M.transferAccept, acceptImport)
    transferAccept:SetHeight(M.rowH - 2)
    transferAccept:SetPoint("TOPRIGHT", transferGroup, "TOPRIGHT", 0, -(M.rowH + 6))
    transferAccept:Hide()

    transferBox = CreateFrame("EditBox", nil, transferGroup)
    transferBox:SetHeight(M.rowH - 2)
    transferBox:SetPoint("TOPLEFT", transferGroup, "TOPLEFT", 0, -(M.rowH + 6))
    transferBox:SetPoint("TOPRIGHT", transferAccept, "TOPLEFT", -8, 0)
    transferBox:EnableMouse(true)
    transferBox:SetAutoFocus(false)
    transferBox:SetFontObject("GameFontHighlightSmall")
    transferBox:SetTextInsets(8, 8, 2, 2)
    UI.Fill(transferBox, UI.C.field)
    local edge = UI.Edge(transferBox, UI.C.borderDim)
    transferBox:SetScript("OnEditFocusGained", function() edge.Set(UI.C.accent) end)
    transferBox:SetScript("OnEditFocusLost", function() edge.Set(UI.C.borderDim) end)
    transferBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    transferBox:SetScript("OnEscapePressed", hideTransfer)
    transferBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and self.locked then
            self:SetText(Profiles.Export())
            self:HighlightText()
        end
    end)
    transferBox:Hide()
    return transferGroup
end

local function buildOptions(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)
    optionsPanel = CreateFrame("Frame", nil, page)
    optionsPanel:SetPoint("TOPLEFT", page, "TOPLEFT", M.pad, M.optionsTop)
    optionsPanel:SetSize(M.listWidth, M.optionsHeight)
    UI.Fill(optionsPanel, UI.C.content, 0.45)
    UI.Edge(optionsPanel, UI.C.borderDim)
    optionsPanel:EnableMouseWheel(true)
    optionsPanel:SetScript("OnMouseWheel", function(_, delta)
        optionsOffset = optionsOffset - delta * WHEEL_STEP
        paintOptionsScroll()
    end)

    optionsScroll = CreateFrame("ScrollFrame", nil, optionsPanel)
    optionsScroll:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 1, -1)
    optionsScroll:SetSize(M.scrollWidth, M.optionsHeight - 2)
    optionsCanvas = CreateFrame("Frame", nil, optionsScroll)
    optionsCanvas:SetSize(M.scrollWidth, 1)
    optionsScroll:SetScrollChild(optionsCanvas)

    optionsTrack = optionsPanel:CreateTexture(nil, "ARTWORK")
    optionsTrack:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -3, -3)
    optionsTrack:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -3, 3)
    optionsTrack:SetWidth(GUTTER)
    optionsTrack:SetColorTexture(1, 1, 1, 0.05)
    optionsTrack:Hide()
    optionsThumb = optionsPanel:CreateTexture(nil, "OVERLAY")
    optionsThumb:SetWidth(GUTTER)
    optionsThumb:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.6)
    optionsThumb:Hide()

    local looting = addSection(text("SECTION_LOOTING", "Looting"))
    addSetting(looting, buildModifier(optionsCanvas),
        text("SETTING_MODIFIER", "Loot everything while holding"))
    addSetting(looting, UI.Switch(optionsCanvas, ns.L.SETTING_WRAPPER,
        function() return Storage.account.wrapper end,
        function(on)
            Storage.account.wrapper = on
            Wrapper.Sync()
        end), nil, text("SETTING_WRAPPER_HELP",
        "Some addons loot for you and skip No Thanks!. Leave this on to apply your blacklist to them too."))

    local editing = addSection(text("SECTION_BLACKLIST", "Editing the blacklist"))
    addSetting(editing, buildQuickAdd(optionsCanvas),
        text("SETTING_QUICKADD", "Blacklist an item with"),
        ns.L.SETTING_QUICKADD_HELP)
    addSetting(editing, buildProfileSave(optionsCanvas),
        text("SETTING_PROFILES", "Profiles"),
        ns.L.SETTING_PROFILES_HELP)
    addRow(editing, buildProfileList(optionsCanvas), M.indent + M.labelWidth)
    addRow(editing, buildTransfer(optionsCanvas), M.indent)

    local notify = addSection(text("SECTION_NOTIFICATIONS", "Notifications"))
    addSetting(notify, buildAnnounce(optionsCanvas),
        text("SETTING_ANNOUNCE", "Announce skipped items in"),
        ns.L.SETTING_ANNOUNCE_HELP)

    local window = addSection(text("SECTION_WINDOW", "Window"))
    addSetting(window, UI.Slider(optionsCanvas, text("SETTING_SCALE", "Window scale"), 0.8, 1.5, 0.05,
        function() return Storage.account.windowScale end,
        function(value)
            Storage.account.windowScale = value
            local x, y = frame:GetCenter()
            local previous = frame:GetScale()
            frame:SetScale(value)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * previous / value, y * previous / value)
        end))

    syncProfiles()
    page:Hide()
    return page
end

local function build()
    frame = CreateFrame("Frame", "NoThanksWindow", UIParent)
    frame:SetSize(M.width, M.height)
    frame:SetScale(Storage.account.windowScale)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetScript("OnShow", function() UI.Refresh() end)
    frame:Hide()
    UI.Fill(frame, UI.C.frame)
    UI.Edge(frame, UI.C.border)
    tinsert(UISpecialFrames, "NoThanksWindow")

    buildHeader(frame)
    buildTabs(frame)

    listPage = CreateFrame("Frame", nil, frame)
    listPage:SetAllPoints(frame)
    buildToolbar(listPage)
    UI.List.Attach(listPage, M)
    buildActions(listPage)

    optionsPage = buildOptions(frame)
end

function UI.Toggle()
    if not frame then build() end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end
