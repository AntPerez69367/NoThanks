local addonName, ns = ...
local UI, Storage, Wrapper = ns.UI, ns.Storage, ns.Wrapper
local Profiles, Filter = ns.Profiles, ns.Filter

local QUALITIES = { 0, 1, 2, 3, 4 }
local MODIFIERS = {
    { value = "SHIFT", label = "SHIFT" },
    { value = "CTRL", label = "CTRL" },
    { value = "ALT", label = "ALT" },
}
local DESTROY_QUALITIES = {
    { value = 0, label = ITEM_QUALITY0_DESC },
    { value = 1, label = ITEM_QUALITY1_DESC },
    { value = 2, label = ITEM_QUALITY2_DESC },
    { value = 3, label = ITEM_QUALITY3_DESC },
}
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
local TABS = { "loot", "blacklist", "rules", "log", "options" }
local CLEAR_POPUP = "NOTHANKS_CLEAR_HISTORY"
local RULE_POPUP = "NOTHANKS_DELETE_RULE"
local SEARCH_DELAY = 0.25
local PREVIEW_ROWS = 8
local CLASS_MAX = 20
local SUBCLASS_MAX = 64
local QUEST_CLASS = 12
local OBSOLETE = "OBSOLETE"
local PENCIL = "Interface\\BUTTONS\\UI-GuildButton-PublicNote-Up"
local ERASE = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
local DECISION_ROWS = 10
local WHITELIST_ROWS = 4
local LOG_ROWS = 21
local MINUTE_SPAN = 60
local HOUR_SPAN = 60 * 60
local DAY_SPAN = 24 * 60 * 60
local GUTTER = 4
local THUMB_MIN = 18
local WHEEL_STEP = 28

local M = {
    width = 520,
    height = 458,
    pad = 14,
    headerH = 30,
    closeSize = 22,
    wordmarkWidth = 256,
    wordmarkHeight = 32,
    tabTop = -34,
    tabH = 26,
    tabGap = 8,
    toolbarTop = -74,
    toolbarH = 24,
    searchWidth = 180,
    columnH = 18,
    columnGap = 4,
    listTop = -128,
    listWidth = 492,
    optionsTop = -74,
    optionsHeight = 372,
    scrollWidth = 482,
    scrollInset = 10,
    labelWidth = 170,
    headingGap = 8,
    collapsedGap = 6,
    actionTop = -406,
    actionH = 22,
    actionWidth = 200,
    statusTop = -434,
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
    ruleWidth = 400,
    ruleControl = 202,
    ruleSegment = 101,
    ruleLevel = 60,
    ruleSave = 120,
    ruleCancel = 80,
    ruleIcon = 18,
    ruleBadge = 26,
    ruleMove = 70,
    ruleEdit = 16,
    ruleDelete = 60,
    ruleAdd = 100,
    ruleColumn = 248,
    ruleDetail = 236,
    ruleGap = 8,
    ruleRow = 22,
    ruleSwitch = 130,
    ruleStrip = 28,
    ruleDivider = 60,
    ruleCountTop = 70,
    ruleHintTop = 88,
    ruleLogTop = 108,
    decisionAction = 66,
    decisionAgo = 44,
    logCause = 130,
    logAction = 72,
    logAgo = 48,
}

local frame, listPage, tabStrip, searchBox, bulkButton, clearButton, status
local searchQueued = false
local windowGroup, clearHistory
local optionsPage, rulesPage, logPage
local tabs, swatches, conditionals = {}, {}, {}
local currentTab = "loot"
local qualities = {}
local profileList, profileEmpty, profileName, profileSave
local transferGroup, transferBox, transferAccept, transferExport
local profileRows = {}
local syncProfiles
local ruleQuality, previewRows = {}, {}
local ruleRows, decisionRows, ruleConflicts = {}, {}, {}
local rulesEmpty
local ruleIntent, ruleMode, ruleScoped = "skip", "test", false
local ruleClassID, ruleSubclassID
local ruleWindow, ruleHeader, ruleEditing, deleteID
local selectedID
local detailColumn, detailBody, detailHint, detailEnable, detailMode
local detailUp, detailDown, detailDelete, detailCount, detailLog, detailWarning
local detailAction, detailExempt
local qualityRow, priceBox, intentGroup, modeGroup, scopeGroup, saveButton
local classDrop, subclassDrop, levelBox, levelRow
local previewList, previewCount
local previewQueued = false
local whitelistRows = {}
local whitelistList, whitelistCount
local logRows = {}
local logEntries = {}
local logEmpty
local syncRules, syncWhitelist, syncLog, applyRuleScale

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function filtering()
    return searchBox:GetText() ~= "" or next(qualities) ~= nil
end

local function emptyMessage()
    if filtering() then return ns.L.EMPTY_FILTER end
    if currentTab == "blacklist" then return ns.L.EMPTY_BLACKLIST end
    if Storage.account.lootWindow ~= "ALL" and next(Storage.History()) ~= nil then
        return ns.L.EMPTY_WINDOW
    end
    return ns.L.EMPTY_LOOT
end

local function tabLabel(tab, total)
    if tab == "options" then return ns.L.TAB_OPTIONS end
    if tab == "rules" then
        return string.format("%s (%d)", ns.L.TAB_RULES, #Storage.Rules())
    end
    if tab == "log" then
        return string.format("%s (%d)", ns.L.TAB_LOG, #Storage.Log())
    end
    local name = (tab == "blacklist") and ns.L.TAB_BLACKLIST or ns.L.TAB_LOOT
    return string.format("%s (%d)", name, total or UI.List.TabTotal(tab))
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

function UI.SyncBulkAction()
    local count = #UI.List.Selected()
    bulkButton:SetText(actionLabel(count))
    bulkButton:SetEnabled(count > 0)
    if count == 0 then
        bulkButton.reason = (currentTab == "blacklist") and ns.L.REMOVE_HINT or ns.L.BLACKLIST_HINT
    else
        bulkButton.reason = nil
    end
    for _, widget in ipairs(conditionals) do widget:SetShown(widget.visible()) end
end

function UI.Refresh()
    local List = UI.List
    local listed = currentTab ~= "options" and currentTab ~= "rules" and currentTab ~= "log"
    listPage:SetShown(listed)
    optionsPage.frame:SetShown(currentTab == "options")
    rulesPage.frame:SetShown(currentTab == "rules")
    logPage.frame:SetShown(currentTab == "log")
    local shown, total
    if listed then
        List.Build(currentTab, searchBox:GetText(), qualities)
        shown, total = List.Counts()
    end
    for _, name in ipairs(TABS) do
        tabs[name].SetLabel(tabLabel(name, name == currentTab and total or nil), name == currentTab)
    end
    if currentTab == "options" then
        syncProfiles()
        reflowTabs()
        return
    end
    if currentTab == "rules" then
        syncRules()
        reflowTabs()
        return
    end
    if currentTab == "log" then
        syncLog()
        reflowTabs()
        return
    end
    UI.SyncBulkAction()
    for _, swatch in ipairs(swatches) do swatch.Apply() end
    if filtering() then
        status:SetText(string.format(ns.L.STATUS_FILTERED, shown, total))
    else
        status:SetText(string.format(ns.L.STATUS_ALL, total))
    end
    reflowTabs()
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
    ns.Resync()
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

local function buildHeader(parent, title)
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
    UI.Unhover(close, function(self) self.hover = false; self.Apply() end)
    close:SetScript("OnClick", function() parent:Hide() end)
    close.Apply()

    if title then
        header.title = UI.Text(header, "GameFontNormal")
        header.title:SetPoint("LEFT", header, "LEFT", 12, 0)
        header.title:SetPoint("RIGHT", close, "LEFT", -8, 0)
        header.title:SetJustifyH("LEFT")
        header.title:SetWordWrap(false)
        header.title:SetText(title)
        UI.Ink(header.title, UI.C.gold)
        return header
    end
    local wordmark = header:CreateTexture(nil, "ARTWORK")
    wordmark:SetTexture("Interface\\AddOns\\NoThanks\\Media\\wordmark.tga")
    wordmark:SetSize(M.wordmarkWidth, M.wordmarkHeight)
    wordmark:SetPoint("CENTER", header, "CENTER", 0, 0)
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
        if searchQueued then return end
        searchQueued = true
        C_Timer.After(SEARCH_DELAY, function()
            searchQueued = false
            UI.List.ClearSelection()
            UI.Refresh()
        end)
    end)
    searchBox:SetPoint("LEFT", toolbar, "LEFT", 0, 0)

    local group = CreateFrame("Frame", nil, toolbar)
    group:SetHeight(M.toolbarH)
    group:SetPoint("RIGHT", toolbar, "RIGHT", 0, 0)
    UI.Fill(group, UI.C.field)
    UI.Edge(group, UI.C.borderDim)

    local caption = UI.Text(group, "GameFontNormalSmall")
    caption:SetPoint("LEFT", group, "LEFT", 8, 0)
    caption:SetText(ns.L.FILTER_QUALITY)
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

    local captionWidth = math.ceil(caption:GetStringWidth())
    group:SetWidth(captionWidth + #QUALITIES * M.swatch
        + (#QUALITIES - 1) * M.swatchGap + 24)
    return toolbar
end

local function buildActions(parent)
    bulkButton = UI.Button(parent, actionLabel(0), M.actionWidth, applyBulk)
    bulkButton:SetPoint("TOPLEFT", parent, "TOPLEFT", M.pad, M.actionTop)
    bulkButton:SetMotionScriptsWhileDisabled(true)
    bulkButton:SetScript("OnEnter", function(self)
        self.hover = true
        self.Apply()
        if not self.reason then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.reason, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    UI.Unhover(bulkButton, function(self)
        self.hover = false
        self.Apply()
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)

    clearButton = CreateFrame("Button", nil, parent)
    clearButton:SetHeight(M.actionH)
    clearButton:SetPoint("LEFT", bulkButton, "RIGHT", 10, 0)
    clearButton.label = UI.Text(clearButton, "GameFontNormalSmall")
    clearButton.label:SetPoint("CENTER")
    clearButton.label:SetText(ns.L.CLEAR_SELECTION)
    clearButton:SetWidth(math.ceil(clearButton.label:GetStringWidth() + 16))
    UI.Ink(clearButton.label, UI.C.muted)
    clearButton:SetScript("OnEnter", function(self) UI.Ink(self.label, UI.C.accent) end)
    UI.Unhover(clearButton, function(self) UI.Ink(self.label, UI.C.muted) end)
    clearButton:SetScript("OnClick", function()
        UI.List.ClearSelection()
        UI.Refresh()
    end)
    clearButton.visible = function() return #UI.List.Selected() > 0 end
    conditionals[#conditionals + 1] = clearButton

    local windows = {
        { value = "SESSION", label = ns.L.WINDOW_SESSION },
        { value = "WEEK", label = ns.L.WINDOW_WEEK },
        { value = "ALL", label = ns.L.WINDOW_ALL },
    }
    windowGroup = UI.Segmented(parent, windows, nil,
        function() return Storage.account.lootWindow end,
        function(value)
            Storage.account.lootWindow = value
            UI.List.ClearSelection()
            UI.Refresh()
        end,
        ns.L.FILTER_WINDOW)
    windowGroup.visible = function() return currentTab == "loot" end
    conditionals[#conditionals + 1] = windowGroup

    status = UI.Text(parent, "GameFontNormalSmall")
    status:SetPoint("TOPLEFT", parent, "TOPLEFT", M.pad, M.statusTop)
    status:SetWidth(M.listWidth)
    status:SetJustifyH("LEFT")
    status:SetWordWrap(false)
    UI.Ink(status, UI.C.dim)

    StaticPopupDialogs[CLEAR_POPUP] = {
        text = ns.L.CLEAR_HISTORY_CONFIRM,
        button1 = ACCEPT,
        button2 = CANCEL,
        whileDead = 1,
        hideOnEscape = 1,
        timeout = 0,
        OnAccept = function()
            ns.History.Clear()
            UI.List.ClearSelection()
            UI.Refresh()
        end,
    }

    clearHistory = CreateFrame("Button", nil, parent)
    clearHistory:SetHeight(M.actionH)
    clearHistory:SetPoint("RIGHT", status, "RIGHT", 0, 0)
    clearHistory.label = UI.Text(clearHistory, "GameFontNormalSmall")
    clearHistory.label:SetPoint("CENTER")
    clearHistory.label:SetText(ns.L.CLEAR_HISTORY)
    clearHistory:SetWidth(math.ceil(clearHistory.label:GetStringWidth() + 16))
    UI.Ink(clearHistory.label, UI.C.muted)
    clearHistory:SetScript("OnEnter", function(self) UI.Ink(self.label, UI.C.accent) end)
    UI.Unhover(clearHistory, function(self) UI.Ink(self.label, UI.C.muted) end)
    clearHistory:SetScript("OnClick", function() StaticPopup_Show(CLEAR_POPUP) end)
    clearHistory.visible = function()
        return currentTab == "loot" and next(Storage.History()) ~= nil
    end
    conditionals[#conditionals + 1] = clearHistory

    windowGroup:SetPoint("RIGHT", status, "RIGHT", -(clearHistory:GetWidth() + 10), 0)
end

local function paintScroll(page)
    local viewport = page.scroll:GetHeight()
    local maxOffset = math.max(0, page.span - viewport)
    if page.offset > maxOffset then page.offset = maxOffset end
    if page.offset < 0 then page.offset = 0 end
    page.scroll:SetVerticalScroll(page.offset)
    if maxOffset == 0 then
        page.track:Hide()
        page.thumb:Hide()
        return
    end
    local span = viewport - 6
    local height = math.max(THUMB_MIN, math.floor(span * viewport / page.span))
    page.thumb:SetHeight(height)
    page.thumb:ClearAllPoints()
    page.thumb:SetPoint("TOPRIGHT", page.panel, "TOPRIGHT", -3,
        -3 - math.floor((span - height) * page.offset / maxOffset))
    page.track:Show()
    page.thumb:Show()
end

local function relayout(page)
    local y = -12
    for _, section in ipairs(page.sections) do
        local open = section.header.expanded
        section.header:ClearAllPoints()
        section.header:SetPoint("TOPLEFT", page.canvas, "TOPLEFT", 12, y)
        section.header:SetPoint("TOPRIGHT", page.canvas, "TOPRIGHT", -12, y)
        for _, widget in ipairs(section.frames) do widget:SetShown(open) end
        if open then
            y = y - section.header:GetHeight() - M.headingGap
            for _, place in ipairs(section.rows) do y = place(y) end
            y = y - M.sectionGap
        else
            y = y - section.header:GetHeight() - M.collapsedGap
        end
    end
    page.span = math.max(1, -y)
    page.canvas:SetHeight(page.span)
    paintScroll(page)
end

local function addSection(page, label)
    local section = { frames = {}, rows = {} }
    section.header = UI.Section(page.canvas, label, function() relayout(page) end)
    page.sections[#page.sections + 1] = section
    return section
end

local function addSetting(page, section, control, label, body)
    local canvas, frames, note = page.canvas, section.frames, nil
    if label then
        local caption = UI.Text(canvas, "GameFontNormalSmall")
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
        note = UI.Text(canvas, "GameFontNormalSmall")
        note:SetWidth(M.scrollWidth - M.indent - 42)
        note:SetJustifyH("LEFT")
        note:SetWordWrap(true)
        note:SetText(body)
        UI.Ink(note, UI.C.dim)
        note.span = math.ceil(note:GetStringHeight()) + 4
        frames[#frames + 1] = note
    end
    frames[#frames + 1] = control
    section.rows[#section.rows + 1] = function(y)
        control:ClearAllPoints()
        control:SetPoint("TOPLEFT", canvas, "TOPLEFT",
            label and (M.indent + M.labelWidth) or M.indent, y)
        y = y - math.max(M.rowH, control:GetHeight())
        if note then
            note:ClearAllPoints()
            note:SetPoint("TOPLEFT", canvas, "TOPLEFT", M.indent + 30, y)
            y = y - note.span
        end
        return y - M.rowGap
    end
end

local function addRow(page, section, group, x)
    section.frames[#section.frames + 1] = group
    section.rows[#section.rows + 1] = function(y)
        group:ClearAllPoints()
        group:SetPoint("TOPLEFT", page.canvas, "TOPLEFT", x, y)
        return y - group:GetHeight() - M.rowGap
    end
end

local function buildScroller(parent, width, top, height)
    local page = { sections = {}, offset = 0, span = 0 }
    page.frame = CreateFrame("Frame", nil, parent)
    page.frame:SetAllPoints(parent)
    page.panel = CreateFrame("Frame", nil, page.frame)
    page.panel:SetPoint("TOPLEFT", page.frame, "TOPLEFT", M.pad, top)
    page.panel:SetSize(width, height)
    UI.Fill(page.panel, UI.C.content, 0.45)
    UI.Edge(page.panel, UI.C.borderDim)
    page.panel:EnableMouseWheel(true)
    page.panel:SetScript("OnMouseWheel", function(_, delta)
        page.offset = page.offset - delta * WHEEL_STEP
        paintScroll(page)
    end)

    page.scroll = CreateFrame("ScrollFrame", nil, page.panel)
    page.scroll:SetPoint("TOPLEFT", page.panel, "TOPLEFT", 1, -1)
    page.scroll:SetSize(width - M.scrollInset, height - 2)
    page.canvas = CreateFrame("Frame", nil, page.scroll)
    page.canvas:SetSize(width - M.scrollInset, 1)
    page.scroll:SetScrollChild(page.canvas)

    page.track = page.panel:CreateTexture(nil, "ARTWORK")
    page.track:SetPoint("TOPRIGHT", page.panel, "TOPRIGHT", -3, -3)
    page.track:SetPoint("BOTTOMRIGHT", page.panel, "BOTTOMRIGHT", -3, 3)
    page.track:SetWidth(GUTTER)
    page.track:SetColorTexture(1, 1, 1, 0.05)
    page.track:Hide()
    page.thumb = page.panel:CreateTexture(nil, "OVERLAY")
    page.thumb:SetWidth(GUTTER)
    page.thumb:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.6)
    page.thumb:Hide()
    return page
end

local function announceSample()
    local links = {}
    for key in pairs(Storage.Blacklist()) do
        links[#links + 1] = ns.ItemLink(key)
        if #links == 3 then break end
    end
    if #links == 0 then
        return ns.L.SETTING_ANNOUNCE_SAMPLE
    end
    return table.concat(links, ", ")
end

local function buildAnnounce(canvas)
    local row = CreateFrame("Frame", nil, canvas)
    row:SetHeight(M.rowH)
    local test
    local group = UI.Segmented(row, ANNOUNCES, nil,
        function() return Storage.account.announce end,
        function(value)
            Storage.account.announce = value
            test:SetEnabled(value ~= "NONE")
        end,
        ns.L.SETTING_ANNOUNCE)
    group:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)

    test = UI.Button(row, ns.L.SETTING_ANNOUNCE_TEST, M.announceTest, function()
        ns.Announce(string.format(ns.L.LEFT_BEHIND, announceSample()))
    end)
    test:SetHeight(M.rowH - 2)
    test:SetPoint("LEFT", group, "RIGHT", 8, 0)
    test:SetEnabled(Storage.account.announce ~= "NONE")
    row:SetWidth(group:GetWidth() + 8 + M.announceTest)
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

    row.delete = UI.Button(row, ns.L.PROFILE_DELETE, M.profileAction, function()
        Profiles.Delete(row.name)
        syncProfiles()
    end)
    row.delete:SetHeight(M.rowH - 2)
    row.delete:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    row.apply = UI.Button(row, ns.L.PROFILE_APPLY, M.profileAction, function()
        local added = Profiles.Apply(row.name)
        ns.Print(string.format(ns.L.PROFILE_APPLIED, added))
        UI.List.ClearSelection()
        ns.Resync()
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
    transferExport:SetEnabled(next(Storage.Blacklist()) ~= nil)
    relayout(optionsPage)
end

local function hideTransfer()
    transferBox:ClearFocus()
    transferBox:Hide()
    transferAccept:Hide()
    transferGroup:SetHeight(M.rowH)
    relayout(optionsPage)
end

local function openTransfer(editable)
    transferBox.exported = not editable and Profiles.Export() or nil
    transferBox:SetText(transferBox.exported or "")
    transferAccept:SetShown(editable)
    transferBox:Show()
    transferGroup:SetHeight(M.rowH * 2 + 6)
    relayout(optionsPage)
    transferBox:SetFocus()
    if not editable then transferBox:HighlightText() end
end

local function acceptImport()
    local added, result = Profiles.Import(transferBox:GetText())
    if added then
        ns.Print(string.format(ns.L.IMPORT_RESULT, added, result))
        hideTransfer()
        UI.List.ClearSelection()
        ns.Resync()
        UI.Refresh()
        return
    end
    ns.Print(ns.L["IMPORT_" .. result])
end

local function buildProfileSave(canvas)
    local group = CreateFrame("Frame", nil, canvas)
    group:SetSize(M.profileField + 8 + M.profileButton, M.rowH)

    profileName = UI.Search(group, M.profileField,
        ns.L.PROFILE_NAME_PLACEHOLDER, paintSave)
    profileName:SetHeight(M.rowH - 2)
    profileName:SetPoint("LEFT", group, "LEFT", 0, 0)

    profileSave = UI.Button(group, ns.L.PROFILE_SAVE, M.profileButton, function()
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
    profileEmpty:SetText(ns.L.PROFILE_NONE)
    UI.Ink(profileEmpty, UI.C.dim)
    return profileList
end

local function buildTransfer(canvas)
    transferGroup = CreateFrame("Frame", nil, canvas)
    transferGroup:SetSize(M.scrollWidth - M.indent - 12, M.rowH)

    transferExport = UI.Button(transferGroup, ns.L.EXPORT, M.transferButton,
        function() openTransfer(false) end)
    transferExport:SetHeight(M.rowH - 2)
    transferExport:SetPoint("TOPLEFT", transferGroup, "TOPLEFT", 0, -1)

    local importButton = UI.Button(transferGroup, ns.L.IMPORT, M.transferButton,
        function() openTransfer(true) end)
    importButton:SetHeight(M.rowH - 2)
    importButton:SetPoint("LEFT", transferExport, "RIGHT", 8, 0)

    transferAccept = UI.Button(transferGroup, ns.L.IMPORT_ACCEPT,
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
        if userInput and self.exported then
            self:SetText(self.exported)
            self:HighlightText()
        end
    end)
    transferBox:Hide()
    return transferGroup
end

local function buildOptions(parent)
    optionsPage = buildScroller(parent, M.listWidth, M.optionsTop, M.optionsHeight)
    local canvas = optionsPage.canvas

    local looting = addSection(optionsPage, ns.L.SECTION_LOOTING)
    addSetting(optionsPage, looting, UI.Segmented(canvas, MODIFIERS, 32,
        function() return Storage.account.bypassModifier end,
        function(value) Storage.account.bypassModifier = value end,
        ns.L.SETTING_MODIFIER), ns.L.SETTING_MODIFIER)
    addSetting(optionsPage, looting, UI.Switch(canvas, ns.L.SETTING_WRAPPER,
        function() return Storage.account.wrapper end,
        function(on)
            Storage.account.wrapper = on
            Wrapper.Sync()
        end), nil, ns.L.SETTING_WRAPPER_HELP)
    addSetting(optionsPage, looting, UI.Switch(canvas, ns.L.SETTING_DESTROY,
        function() return Storage.account.destroy end,
        function(on) Storage.account.destroy = on end), nil, ns.L.SETTING_DESTROY_HELP)
    addSetting(optionsPage, looting, UI.Segmented(canvas, DESTROY_QUALITIES, nil,
        function() return Storage.account.destroyQuality end,
        function(value) Storage.account.destroyQuality = value end,
        ns.L.SETTING_DESTROY_QUALITY), ns.L.SETTING_DESTROY_QUALITY)

    local editing = addSection(optionsPage, ns.L.SECTION_BLACKLIST)
    addSetting(optionsPage, editing, UI.Segmented(canvas, QUICKADDS, 40,
        function() return Storage.account.quickAddBinding end,
        function(value) Storage.account.quickAddBinding = value end,
        ns.L.SETTING_QUICKADD), ns.L.SETTING_QUICKADD,
        ns.L.SETTING_QUICKADD_HELP)
    addSetting(optionsPage, editing, buildProfileSave(canvas),
        ns.L.SETTING_PROFILES,
        ns.L.SETTING_PROFILES_HELP)
    addRow(optionsPage, editing, buildProfileList(canvas), M.indent + M.labelWidth)
    addRow(optionsPage, editing, buildTransfer(canvas), M.indent)

    local notify = addSection(optionsPage, ns.L.SECTION_NOTIFICATIONS)
    addSetting(optionsPage, notify, buildAnnounce(canvas),
        ns.L.SETTING_ANNOUNCE,
        ns.L.SETTING_ANNOUNCE_HELP)

    local window = addSection(optionsPage, ns.L.SECTION_WINDOW)
    addSetting(optionsPage, window, UI.Slider(canvas, ns.L.SETTING_SCALE, 0.8, 1.5, 0.05,
        function() return Storage.account.windowScale end,
        function(value)
            Storage.account.windowScale = value
            local x, y = frame:GetCenter()
            local previous = frame:GetScale()
            frame:SetScale(value)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * previous / value, y * previous / value)
            if ruleWindow then applyRuleScale() end
        end))
    addSetting(optionsPage, window, UI.Switch(canvas, ns.L.SETTING_MINIMAP,
        function() return not Storage.account.minimap.hide end,
        function(on)
            Storage.account.minimap.hide = not on
            ns.Minimap.SetShown(on)
        end))

    syncProfiles()
    optionsPage.frame:Hide()
end

local function modeChoices()
    return {
        { value = "test", label = ns.L.RULE_MODE_TEST },
        { value = "live", label = ns.L.RULE_MODE_LIVE },
    }
end

local function classChoices()
    local list = { { label = ns.L.RULE_ANY_CLASS } }
    for classID = 0, CLASS_MAX do
        local name = Storage.ClassName(classID)
        if name and classID ~= QUEST_CLASS and not name:find(OBSOLETE, 1, true) then
            list[#list + 1] = { value = classID, label = name }
        end
    end
    return list
end

local function subclassChoices()
    local list = { { label = ns.L.RULE_ANY_SUBCLASS } }
    if ruleClassID == nil then return list end
    for subclassID = 0, SUBCLASS_MAX do
        local name = Storage.ClassName(ruleClassID, subclassID)
        if name then list[#list + 1] = { value = subclassID, label = name } end
    end
    return list
end

local function draft()
    local rule = {
        intent = ruleIntent,
        classID = ruleClassID,
        subclassID = ruleSubclassID,
        levelMax = tonumber(levelBox:GetText()),
        priceMax = ns.Copper(priceBox:GetText()),
        whitelist = {},
    }
    if ruleEditing then rule.equipLoc = ruleEditing.equipLoc end
    for quality in pairs(ruleQuality) do
        rule.quality = rule.quality or {}
        rule.quality[quality] = true
    end
    return rule
end

local function constrained(rule)
    return rule.quality ~= nil or rule.classID ~= nil or rule.subclassID ~= nil
        or rule.equipLoc ~= nil or rule.levelMax ~= nil or rule.priceMax ~= nil
end

local function previewRow(index)
    local row = previewRows[index]
    if row then return row end
    row = CreateFrame("Frame", nil, previewList)
    row:SetHeight(M.rowH)
    row:SetPoint("TOPLEFT", previewList, "TOPLEFT", 0, -(index - 1) * M.rowH)
    row:SetPoint("TOPRIGHT", previewList, "TOPRIGHT", 0, -(index - 1) * M.rowH)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(M.ruleIcon, M.ruleIcon)
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label = UI.Text(row, "GameFontNormalSmall")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    previewRows[index] = row
    return row
end

local function whitelistRow(index)
    local row = whitelistRows[index]
    if row then return row end
    row = CreateFrame("Frame", nil, whitelistList)
    row:SetHeight(M.rowH)
    row:SetPoint("TOPLEFT", whitelistList, "TOPLEFT", 0, -(index - 1) * M.rowH)
    row:SetPoint("TOPRIGHT", whitelistList, "TOPRIGHT", 0, -(index - 1) * M.rowH)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(M.ruleIcon, M.ruleIcon)
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.remove = CreateFrame("Button", nil, row)
    row.remove:SetSize(M.ruleEdit, M.ruleEdit)
    row.remove:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.remove:SetNormalTexture(ERASE)
    row.remove:SetHighlightTexture(ERASE)
    row.remove:SetScript("OnClick", function()
        Storage.RemoveWhitelist(ruleEditing, row.itemID)
        ns.Resync()
        syncWhitelist()
        UI.Refresh()
    end)
    row.remove:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.L.RULE_WHITELIST_REMOVE)
        GameTooltip:Show()
    end)
    UI.Unhover(row.remove, function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    row.label = UI.Text(row, "GameFontNormalSmall")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.label:SetPoint("RIGHT", row.remove, "LEFT", -8, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    whitelistRows[index] = row
    return row
end

function applyRuleScale()
    local fit = UIParent:GetHeight() / ruleWindow:GetHeight()
    ruleWindow:SetScale(math.min(Storage.account.windowScale, fit))
end

local function layoutRuleWindow()
    local y = -(M.headerH + 12)
    local function place(control)
        control:ClearAllPoints()
        control:SetPoint("TOPLEFT", ruleWindow, "TOPLEFT", M.pad + M.labelWidth, y)
        y = y - math.max(M.rowH, control:GetHeight()) - M.rowGap
    end
    place(qualityRow)
    place(classDrop)
    place(subclassDrop)
    place(levelRow)
    place(priceBox)
    place(intentGroup)
    place(modeGroup)
    place(scopeGroup)
    previewCount:ClearAllPoints()
    previewCount:SetPoint("TOPLEFT", ruleWindow, "TOPLEFT", M.pad, y)
    y = y - M.rowH - 4
    previewList:ClearAllPoints()
    previewList:SetPoint("TOPLEFT", ruleWindow, "TOPLEFT", M.pad, y)
    y = y - previewList:GetHeight() - M.rowGap
    if whitelistCount:IsShown() then
        whitelistCount:ClearAllPoints()
        whitelistCount:SetPoint("TOPLEFT", ruleWindow, "TOPLEFT", M.pad, y)
        y = y - M.rowH - 4
        whitelistList:ClearAllPoints()
        whitelistList:SetPoint("TOPLEFT", ruleWindow, "TOPLEFT", M.pad, y)
        y = y - whitelistList:GetHeight() - M.rowGap
    end
    saveButton:ClearAllPoints()
    saveButton:SetPoint("TOPRIGHT", ruleWindow, "TOPRIGHT", -M.pad, y)
    ruleWindow:SetHeight(-y + M.actionH + M.pad)
    applyRuleScale()
end

local function priceFault()
    local text = priceBox:GetText():gsub("%s+", "")
    return text ~= "" and ns.Copper(text) == nil
end

local function previewPool()
    local seen, pool = {}, {}
    for key in pairs(Storage.History()) do seen[tonumber(key)] = true end
    for _, entry in ipairs(Storage.Log()) do seen[entry.itemID] = true end
    for itemID in pairs(seen) do
        if Filter.IsQuestItem(itemID) == false then pool[#pool + 1] = itemID end
    end
    return pool
end

local function syncPreview()
    if priceBox.fault then
        for index = 1, #previewRows do previewRows[index]:Hide() end
        previewCount:SetText(ns.L.RULE_PRICE_INVALID)
        UI.Ink(previewCount, UI.C.bad)
        previewList:SetHeight(M.rowH)
        layoutRuleWindow()
        return
    end
    local rule = draft()
    local criteria = constrained(rule)
    local pool, matched = previewPool(), {}
    if criteria then
        for _, itemID in ipairs(pool) do
            if Filter.Matches(rule, itemID) then
                local name, _, quality = ns.ItemInfo(itemID)
                matched[#matched + 1] = { itemID = itemID, name = name, quality = quality }
            end
        end
    end
    table.sort(matched, function(a, b)
        return (a.name or tostring(a.itemID)) < (b.name or tostring(b.itemID))
    end)
    local shown = math.min(#matched, PREVIEW_ROWS)
    for index = 1, shown do
        local entry = matched[index]
        local row = previewRow(index)
        row.icon:SetTexture(ns.ItemIcon(entry.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.label:SetText(entry.name or ("item:" .. entry.itemID))
        UI.Color(row.label, entry.quality)
        row:Show()
    end
    for index = shown + 1, #previewRows do previewRows[index]:Hide() end
    if not criteria then
        previewCount:SetText(ns.L.RULE_PREVIEW_NONE)
    elseif #matched == 0 then
        previewCount:SetText(string.format(ns.L.RULE_PREVIEW_EMPTY, #pool))
    else
        previewCount:SetText(string.format(ns.L.RULE_PREVIEW_COUNT, #matched, #pool))
    end
    UI.Ink(previewCount, UI.C.muted)
    previewList:SetHeight(math.max(M.rowH, shown * M.rowH))
    layoutRuleWindow()
end

function syncWhitelist()
    local entries = {}
    if ruleEditing then
        for key in pairs(ruleEditing.whitelist) do
            local itemID = tonumber(key)
            local name, _, quality = ns.ItemInfo(itemID)
            entries[#entries + 1] = {
                key = key, itemID = itemID, name = name, quality = quality,
            }
        end
        table.sort(entries, function(a, b) return (a.name or a.key) < (b.name or b.key) end)
    end
    local shown = math.min(#entries, WHITELIST_ROWS)
    for index = 1, shown do
        local entry = entries[index]
        local row = whitelistRow(index)
        row.itemID = entry.itemID
        row.icon:SetTexture(ns.ItemIcon(entry.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.label:SetText(entry.name or ("item:" .. entry.key))
        UI.Color(row.label, entry.quality)
        row:Show()
    end
    for index = shown + 1, #whitelistRows do whitelistRows[index]:Hide() end
    if shown < #entries then
        whitelistCount:SetText(string.format(ns.L.RULE_WHITELIST_MORE, shown, #entries))
    else
        whitelistCount:SetText(string.format(ns.L.RULE_WHITELIST, #entries))
    end
    whitelistCount:SetShown(#entries > 0)
    whitelistList:SetShown(#entries > 0)
    whitelistList:SetHeight(math.max(M.rowH, shown * M.rowH))
    layoutRuleWindow()
end

local function paintRuleForm()
    qualityRow.Apply()
    classDrop.Apply()
    subclassDrop:SetEnabled(ruleClassID ~= nil)
    priceBox.fault = priceFault()
    priceBox.Apply()
    saveButton:SetEnabled(constrained(draft()) and not priceBox.fault)
end

local function ruleChanged()
    paintRuleForm()
    if previewQueued then return end
    previewQueued = true
    C_Timer.After(SEARCH_DELAY, function()
        previewQueued = false
        if ruleWindow:IsShown() then syncPreview() end
    end)
end

local function pickRuleQuality(quality)
    ruleQuality[quality] = not ruleQuality[quality] or nil
    ruleChanged()
end

local function saveRule()
    local rule = draft()
    if ruleEditing then
        ruleEditing.quality = rule.quality
        ruleEditing.classID = rule.classID
        ruleEditing.subclassID = rule.subclassID
        ruleEditing.levelMax = rule.levelMax
        ruleEditing.priceMax = rule.priceMax
        ruleEditing.intent = rule.intent
        Storage.SetRuleScope(ruleEditing, ruleScoped)
        Storage.SetRuleMode(ruleEditing, ruleMode)
    else
        Storage.AddRule(rule, ruleScoped)
        Storage.SetRuleMode(rule, ruleMode)
    end
    ns.Resync()
    UI.Refresh()
    ruleWindow:Hide()
end

local function buildRuleQuality(parent)
    local group = CreateFrame("Frame", nil, parent)
    group:SetSize(M.ruleControl, M.rowH)
    local swatchList, anchor = {}, nil
    for _, quality in ipairs(QUALITIES) do
        local swatch = UI.Swatch(group, quality, M.swatch,
            function() return ruleQuality[quality] end, pickRuleQuality)
        if anchor then
            swatch:SetPoint("LEFT", anchor, "RIGHT", M.swatchGap, 0)
        else
            swatch:SetPoint("LEFT", group, "LEFT", 0, 0)
        end
        anchor = swatch
        swatchList[#swatchList + 1] = swatch
    end
    group.any = UI.Text(group, "GameFontNormalSmall")
    group.any:SetPoint("LEFT", anchor, "RIGHT", 8, 0)
    group.any:SetWidth(M.ruleControl - #QUALITIES * M.swatch
        - (#QUALITIES - 1) * M.swatchGap - 8)
    group.any:SetJustifyH("LEFT")
    group.any:SetWordWrap(false)
    group.any:SetText(ns.L.RULE_ANY_QUALITY)
    UI.Ink(group.any, UI.C.dim)
    group.Apply = function()
        for _, swatch in ipairs(swatchList) do swatch.Apply() end
        group.any:SetShown(next(ruleQuality) == nil)
    end
    group.Apply()
    return group
end

local function ruleCaption(parent, control, label)
    local caption = UI.Text(parent, "GameFontNormalSmall")
    caption:SetWidth(M.labelWidth - 12)
    caption:SetPoint("RIGHT", control, "LEFT", -12, 0)
    caption:SetJustifyH("LEFT")
    caption:SetWordWrap(false)
    caption:SetText(label)
    UI.Ink(caption, UI.C.text)
end

local function buildRuleWindow()
    ruleWindow = CreateFrame("Frame", "NoThanksRuleWindow", UIParent)
    ruleWindow:SetSize(M.ruleWidth, M.headerH)
    ruleWindow:SetScale(Storage.account.windowScale)
    ruleWindow:SetPoint("CENTER")
    ruleWindow:SetFrameStrata("HIGH")
    ruleWindow:SetToplevel(true)
    ruleWindow:SetMovable(true)
    ruleWindow:SetClampedToScreen(true)
    ruleWindow:EnableMouse(true)
    ruleWindow:SetScript("OnShow", applyRuleScale)
    ruleWindow:Hide()
    UI.Fill(ruleWindow, UI.C.frame)
    UI.Edge(ruleWindow, UI.C.border)
    tinsert(UISpecialFrames, "NoThanksRuleWindow")
    ruleHeader = buildHeader(ruleWindow, ns.L.RULE_WINDOW_NEW)

    qualityRow = buildRuleQuality(ruleWindow)
    ruleCaption(ruleWindow, qualityRow, ns.L.RULE_QUALITY)
    classDrop = UI.Dropdown(ruleWindow, M.ruleControl, classChoices,
        function() return ruleClassID end,
        function(value)
            if value ~= ruleClassID then ruleSubclassID = nil end
            ruleClassID = value
            ruleChanged()
        end)
    classDrop:SetHeight(M.rowH)
    ruleCaption(ruleWindow, classDrop, ns.L.RULE_CLASS)
    subclassDrop = UI.Dropdown(ruleWindow, M.ruleControl, subclassChoices,
        function() return ruleSubclassID end,
        function(value)
            ruleSubclassID = value
            ruleChanged()
        end)
    subclassDrop:SetHeight(M.rowH)
    ruleCaption(ruleWindow, subclassDrop, ns.L.RULE_SUBCLASS)
    levelRow = CreateFrame("Frame", nil, ruleWindow)
    levelRow:SetSize(M.ruleControl, M.rowH)
    levelBox = UI.Search(levelRow, M.ruleLevel, ns.L.RULE_LEVEL_PLACEHOLDER, ruleChanged)
    levelBox:SetHeight(M.rowH)
    levelBox:SetPoint("RIGHT", levelRow, "RIGHT", 0, 0)
    levelBox:SetNumeric(true)
    levelBox:SetMaxLetters(3)
    ruleCaption(ruleWindow, levelRow, ns.L.RULE_LEVEL)
    priceBox = UI.Search(ruleWindow, M.ruleControl, ns.L.RULE_PRICE_PLACEHOLDER, ruleChanged,
        "[^%d%.gscGSC ]")
    priceBox:SetHeight(M.rowH)
    priceBox:SetMaxLetters(20)
    ruleCaption(ruleWindow, priceBox, ns.L.RULE_PRICE)
    intentGroup = UI.Segmented(ruleWindow, {
        { value = "skip", label = ns.L.RULE_INTENT_SKIP },
        { value = "destroy", label = ns.L.RULE_INTENT_DESTROY },
    }, M.ruleSegment, function() return ruleIntent end,
        function(value) ruleIntent = value end, ns.L.RULE_INTENT)
    ruleCaption(ruleWindow, intentGroup, ns.L.RULE_INTENT)
    modeGroup = UI.Segmented(ruleWindow, modeChoices(), M.ruleSegment,
        function() return ruleMode end,
        function(value) ruleMode = value end, ns.L.RULE_MODE)
    ruleCaption(ruleWindow, modeGroup, ns.L.RULE_MODE)
    scopeGroup = UI.Segmented(ruleWindow, {
        { value = false, label = ns.L.RULE_SCOPE_ACCOUNT },
        { value = true, label = ns.L.RULE_SCOPE_CHARACTER },
    }, M.ruleSegment, function() return ruleScoped end,
        function(value) ruleScoped = value end, ns.L.RULE_SCOPE)
    ruleCaption(ruleWindow, scopeGroup, ns.L.RULE_SCOPE)

    previewCount = UI.Text(ruleWindow, "GameFontNormalSmall")
    previewCount:SetSize(M.ruleWidth - M.pad * 2, M.rowH)
    previewCount:SetJustifyH("LEFT")
    previewCount:SetWordWrap(false)
    UI.Ink(previewCount, UI.C.muted)

    previewList = CreateFrame("Frame", nil, ruleWindow)
    previewList:SetSize(M.ruleWidth - M.pad * 2, M.rowH)

    whitelistCount = UI.Text(ruleWindow, "GameFontNormalSmall")
    whitelistCount:SetSize(M.ruleWidth - M.pad * 2, M.rowH)
    whitelistCount:SetJustifyH("LEFT")
    whitelistCount:SetWordWrap(false)
    UI.Ink(whitelistCount, UI.C.muted)

    whitelistList = CreateFrame("Frame", nil, ruleWindow)
    whitelistList:SetSize(M.ruleWidth - M.pad * 2, M.rowH)

    saveButton = UI.Button(ruleWindow, ns.L.RULE_SAVE, M.ruleSave, saveRule)
    local cancel = UI.Button(ruleWindow, ns.L.RULE_CANCEL, M.ruleCancel,
        function() ruleWindow:Hide() end)
    cancel:SetPoint("RIGHT", saveButton, "LEFT", -8, 0)
end

local function openRuleWindow(rule)
    if not ruleWindow then buildRuleWindow() end
    ruleEditing = rule
    wipe(ruleQuality)
    if rule and rule.quality then
        for quality in pairs(rule.quality) do ruleQuality[quality] = true end
    end
    ruleIntent = (rule and rule.intent) or "skip"
    ruleMode = (rule and Storage.RuleMode(rule)) or "test"
    ruleScoped = (rule and rule.scoped) or false
    ruleClassID = rule and rule.classID
    ruleSubclassID = rule and rule.subclassID
    levelBox:SetText((rule and rule.levelMax) and tostring(rule.levelMax) or "")
    levelBox:ClearFocus()
    priceBox:SetText((rule and rule.priceMax) and ns.MoneyExact(rule.priceMax) or "")
    priceBox:ClearFocus()
    ruleHeader.title:SetText(rule and ns.L.RULE_WINDOW_EDIT or ns.L.RULE_WINDOW_NEW)
    intentGroup.Apply()
    modeGroup.Apply()
    scopeGroup.Apply()
    ruleWindow:Show()
    ruleWindow:Raise()
    paintRuleForm()
    syncWhitelist()
    syncPreview()
end

local function moveRule(id, delta)
    Storage.MoveRule(id, delta)
    ns.Resync()
    UI.Refresh()
end

local function selectedRule()
    return selectedID and Storage.Rule(selectedID)
end

local function badgeFor(rule)
    local enabled = Storage.RuleEnabled(rule)
    if enabled and Storage.RuleMode(rule) == "live" then
        return ns.L.RULE_BADGE_LIVE, UI.C.accent
    end
    if enabled then return ns.L.RULE_BADGE_TEST, UI.C.muted end
    return ns.L.RULE_BADGE_OFF, UI.C.dim
end

local function warningText(conflict)
    local parts = {}
    if conflict.shadow then
        parts[#parts + 1] = string.format(ns.L.RULE_WARN_UNREACHABLE,
            Storage.RuleLabel(conflict.shadow))
    end
    if conflict.preempted then
        parts[#parts + 1] = string.format(ns.L.RULE_WARN_PREEMPT, conflict.preempted)
    end
    return table.concat(parts, " ")
end

local function actionText(action)
    if action == "destroy" then return ns.L.RULE_ACTION_DESTROY, UI.C.bad end
    if action == "flag" then return ns.L.RULE_ACTION_FLAG, UI.C.muted end
    return ns.L.RULE_ACTION_SKIP, UI.C.text
end

local function bindingClick()
    return ns.L["QUICKADD_" .. Storage.account.quickAddBinding]
end

local function catchAction(rule, entry)
    if rule.whitelist[Storage.Key(entry.itemID)] then
        return ns.L.RULE_ACTION_EXEMPT, UI.C.dim
    end
    return actionText(entry.action)
end

local function ago(at)
    local span = time() - at
    if span < MINUTE_SPAN then return ns.L.AGO_NOW end
    if span < HOUR_SPAN then
        return string.format(ns.L.AGO_MINUTES, math.floor(span / MINUTE_SPAN))
    end
    if span < DAY_SPAN then
        return string.format(ns.L.AGO_HOURS, math.floor(span / HOUR_SPAN))
    end
    return string.format(ns.L.AGO_DAYS, math.floor(span / DAY_SPAN))
end

local function otherClaims(rule, itemID)
    local key, names = Storage.Key(itemID), {}
    for _, candidate in ipairs(Storage.Rules()) do
        if candidate.id ~= rule.id and Storage.RuleEnabled(candidate)
            and candidate.whitelist[key] == nil and Filter.Matches(candidate, itemID) then
            names[#names + 1] = Storage.RuleLabel(candidate)
        end
    end
    if #names == 0 then return nil end
    return table.concat(names, ", ")
end

local function ruleRow(index)
    local row = ruleRows[index]
    if row then return row end
    local canvas = rulesPage.canvas
    row = CreateFrame("Button", nil, canvas)
    row:SetHeight(M.ruleRow)
    row:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -(index - 1) * M.ruleRow)
    row:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", 0, -(index - 1) * M.ruleRow)
    row.fill = row:CreateTexture(nil, "BACKGROUND")
    row.fill:SetAllPoints(row)
    row.fill:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.22)
    row.fill:Hide()
    row.wash = row:CreateTexture(nil, "BORDER")
    row.wash:SetAllPoints(row)
    row.wash:SetColorTexture(1, 1, 1, 0.07)
    row.wash:Hide()
    row.label = UI.Text(row, "GameFontNormalSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    UI.Unhover(row, function(self)
        self.wash:Hide()
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    row.badge = UI.Text(row, "GameFontNormalSmall")
    row.badge:SetPoint("RIGHT", row, "RIGHT", -(M.ruleEdit + 8), 0)
    row.badge:SetWidth(M.ruleBadge)
    row.badge:SetJustifyH("RIGHT")
    row.badge:SetWordWrap(false)
    row.warn = UI.Text(row, "GameFontNormalSmall")
    row.warn:SetPoint("RIGHT", row.badge, "LEFT", -4, 0)
    UI.Ink(row.warn, UI.C.bad)
    row.scope = UI.Text(row, "GameFontNormalSmall")
    row.scope:SetPoint("RIGHT", row.warn, "LEFT", -4, 0)
    row.scope:SetWordWrap(false)
    UI.Ink(row.scope, UI.C.dim)
    row.label:SetPoint("RIGHT", row.scope, "LEFT", -4, 0)
    row.edit = CreateFrame("Button", nil, row)
    row.edit:SetSize(M.ruleEdit, M.ruleEdit)
    row.edit:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.edit:SetNormalTexture(PENCIL)
    row.edit:SetHighlightTexture(PENCIL)
    row.edit:SetScript("OnClick", function() openRuleWindow(row.rule) end)
    row.edit:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.L.RULE_EDIT)
        GameTooltip:Show()
    end)
    UI.Unhover(row.edit, function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    row:SetScript("OnClick", function(self)
        selectedID = self.rule.id
        syncRules()
    end)
    row:SetScript("OnEnter", function(self)
        self.wash:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Storage.RuleLabel(self.rule), 1, 1, 1, 1, true)
        if self.rule.scoped then
            GameTooltip:AddLine(ns.L.RULE_SCOPE_ONLY,
                UI.C.muted[1], UI.C.muted[2], UI.C.muted[3], true)
        end
        GameTooltip:Show()
    end)
    ruleRows[index] = row
    return row
end

local function decisionRow(index)
    local row = decisionRows[index]
    if row then return row end
    row = CreateFrame("Button", nil, detailLog)
    row:SetHeight(M.rowH)
    row:SetPoint("TOPLEFT", detailLog, "TOPLEFT", 0, -(index - 1) * M.rowH)
    row:SetPoint("TOPRIGHT", detailLog, "TOPRIGHT", 0, -(index - 1) * M.rowH)
    row.wash = row:CreateTexture(nil, "BACKGROUND")
    row.wash:SetAllPoints(row)
    row.wash:SetColorTexture(1, 1, 1, 0.07)
    row.wash:Hide()
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(M.ruleIcon, M.ruleIcon)
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.when = UI.Text(row, "GameFontNormalSmall")
    row.when:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.when:SetWidth(M.decisionAgo)
    row.when:SetJustifyH("RIGHT")
    row.when:SetWordWrap(false)
    UI.Ink(row.when, UI.C.dim)
    row.action = UI.Text(row, "GameFontNormalSmall")
    row.action:SetPoint("RIGHT", row.when, "LEFT", -8, 0)
    row.action:SetWidth(M.decisionAction)
    row.action:SetJustifyH("RIGHT")
    row.action:SetWordWrap(false)
    row.label = UI.Text(row, "GameFontNormalSmall")
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, button)
        if not UI.List.QuickBinding(button) then return end
        local rule = selectedRule()
        if rule.whitelist[Storage.Key(self.itemID)] then
            Storage.RemoveWhitelist(rule, self.itemID)
        else
            Storage.AddWhitelist(rule, self.itemID)
        end
        ns.Resync()
        UI.Refresh()
        if ruleEditing == rule and ruleWindow:IsShown() then syncWhitelist() end
    end)
    row:SetScript("OnEnter", function(self)
        self.wash:Show()
        local rule = selectedRule()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        local claims = otherClaims(rule, self.itemID)
        if claims then
            GameTooltip:AddLine(string.format(ns.L.RULE_WHITELIST_OTHER, claims),
                UI.C.muted[1], UI.C.muted[2], UI.C.muted[3], true)
        end
        local exempt = rule.whitelist[Storage.Key(self.itemID)] ~= nil
        GameTooltip:AddLine(string.format(
            exempt and ns.L.RULE_EXEMPT_UNDO or ns.L.RULE_EXEMPT_ADD, bindingClick()),
            UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], true)
        GameTooltip:Show()
    end)
    UI.Unhover(row, function(self)
        self.wash:Hide()
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    decisionRows[index] = row
    return row
end

local function syncDetail()
    local rule = selectedRule()
    detailHint:SetShown(rule == nil)
    detailBody:SetShown(rule ~= nil)
    if not rule then return end
    detailEnable.Apply()
    detailMode.Apply()
    local rules, position = Storage.Rules(), 0
    for index, candidate in ipairs(rules) do
        if candidate.id == rule.id then position = index end
    end
    detailUp:SetEnabled(position > 1)
    detailDown:SetEnabled(position < #rules)
    local conflict = ruleConflicts[rule.id]
    detailWarning:SetText(conflict and warningText(conflict) or "")
    local entries, total = Storage.RuleLog(rule.id, DECISION_ROWS)
    local shared, sharedInk
    for index, entry in ipairs(entries) do
        local text, ink = catchAction(rule, entry)
        if index == 1 then
            shared, sharedInk = text, ink
        elseif shared ~= text then
            shared = nil
        end
    end
    for index, entry in ipairs(entries) do
        local row = decisionRow(index)
        local name, link, quality = ns.ItemInfo(entry.itemID)
        local text, ink = catchAction(rule, entry)
        row.itemID = entry.itemID
        row.link = ns.ItemLink(entry.itemID, link)
        row.icon:SetTexture(ns.ItemIcon(entry.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.label:SetText(name or ("item:" .. tostring(entry.itemID)))
        UI.Color(row.label, quality)
        row.action:SetText(text)
        UI.Ink(row.action, ink)
        row.action:SetShown(shared == nil)
        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.label:SetPoint("RIGHT", shared and row.when or row.action, "LEFT", -8, 0)
        row.when:SetText(ago(entry.at))
        row:Show()
    end
    for index = #entries + 1, #decisionRows do decisionRows[index]:Hide() end
    detailAction:SetText(shared or "")
    if shared then UI.Ink(detailAction, sharedInk) end
    detailExempt:SetText(string.format(ns.L.RULE_LOG_HINT, bindingClick()))
    detailExempt:SetShown(#entries > 0)
    if total == 0 then
        detailCount:SetText(ns.L.RULE_LOG_EMPTY)
    else
        detailCount:SetText(string.format(ns.L.RULE_LOG_COUNT, #entries, total))
    end
end

function syncRules()
    local rules = Storage.Rules()
    ruleConflicts = Filter.Conflicts()
    for index, rule in ipairs(rules) do
        local row = ruleRow(index)
        local badge, ink = badgeFor(rule)
        local chosen = rule.id == selectedID
        row.rule = rule
        row.label:SetText(Storage.RuleLabel(rule))
        UI.Ink(row.label, chosen and UI.C.white or UI.C.text)
        row.badge:SetText(badge)
        UI.Ink(row.badge, ink)
        row.scope:SetText(rule.scoped and ns.L.RULE_BADGE_SCOPED or "")
        row.warn:SetText(ruleConflicts[rule.id] and "!" or "")
        row.fill:SetShown(chosen)
        row.edit:SetShown(chosen)
        row:Show()
    end
    for index = #rules + 1, #ruleRows do ruleRows[index]:Hide() end
    rulesEmpty:SetShown(#rules == 0)
    rulesPage.span = #rules * M.ruleRow + 4
    rulesPage.canvas:SetHeight(rulesPage.span)
    paintScroll(rulesPage)
    syncDetail()
end

local function buildRuleDetail(parent)
    detailColumn = CreateFrame("Frame", nil, parent)
    detailColumn:SetPoint("TOPLEFT", parent, "TOPLEFT",
        M.pad + M.ruleColumn + M.ruleGap, M.optionsTop)
    detailColumn:SetSize(M.ruleDetail, M.optionsHeight)

    detailHint = UI.Text(detailColumn, "GameFontNormalSmall")
    detailHint:SetPoint("TOPLEFT", detailColumn, "TOPLEFT", 0, -2)
    detailHint:SetWidth(M.ruleDetail)
    detailHint:SetJustifyH("LEFT")
    detailHint:SetWordWrap(true)
    detailHint:SetText(ns.L.RULE_SELECT_HINT)
    UI.Ink(detailHint, UI.C.dim)

    detailBody = CreateFrame("Frame", nil, detailColumn)
    detailBody:SetAllPoints(detailColumn)

    detailEnable = UI.Switch(detailBody, ns.L.RULE_ENABLED,
        function()
            local rule = selectedRule()
            return rule and Storage.RuleEnabled(rule)
        end,
        function(on)
            Storage.SetRuleEnabled(selectedRule(), on)
            ns.Resync()
            UI.Refresh()
        end)
    detailEnable:SetWidth(M.ruleSwitch)
    detailEnable:SetPoint("TOPLEFT", detailBody, "TOPLEFT", 0, 0)
    detailMode = UI.Segmented(detailBody, modeChoices(), nil,
        function()
            local rule = selectedRule()
            return rule and Storage.RuleMode(rule)
        end,
        function(value)
            Storage.SetRuleMode(selectedRule(), value)
            ns.Resync()
            UI.Refresh()
        end, ns.L.RULE_MODE)
    detailMode:SetPoint("LEFT", detailEnable, "RIGHT", M.ruleGap, 0)

    detailUp = UI.Button(detailBody, ns.L.RULE_MOVE_UP, M.ruleMove,
        function() moveRule(selectedID, -1) end)
    detailUp:SetPoint("TOPLEFT", detailBody, "TOPLEFT", 0, -M.ruleStrip)
    detailDown = UI.Button(detailBody, ns.L.RULE_MOVE_DOWN, M.ruleMove,
        function() moveRule(selectedID, 1) end)
    detailDown:SetPoint("LEFT", detailUp, "RIGHT", 6, 0)
    detailDelete = UI.Button(detailBody, ns.L.RULE_DELETE, M.ruleDelete, function()
        deleteID = selectedID
        StaticPopup_Show(RULE_POPUP, Storage.RuleLabel(selectedRule()))
    end)
    detailDelete:SetPoint("TOPRIGHT", detailBody, "TOPRIGHT", 0, -M.ruleStrip)

    local divider = detailBody:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", detailBody, "TOPLEFT", 0, -M.ruleDivider)
    divider:SetPoint("TOPRIGHT", detailBody, "TOPRIGHT", 0, -M.ruleDivider)
    divider:SetHeight(1)
    divider:SetColorTexture(UI.C.borderDim[1], UI.C.borderDim[2], UI.C.borderDim[3], 1)

    detailCount = UI.Text(detailBody, "GameFontNormalSmall")
    detailCount:SetPoint("TOPLEFT", detailBody, "TOPLEFT", 0, -M.ruleCountTop)
    detailCount:SetWidth(M.ruleDetail)
    detailCount:SetJustifyH("LEFT")
    detailCount:SetWordWrap(false)
    UI.Ink(detailCount, UI.C.muted)

    detailAction = UI.Text(detailBody, "GameFontNormalSmall")
    detailAction:SetPoint("TOPRIGHT", detailBody, "TOPRIGHT",
        -(M.decisionAgo + 8), -M.ruleCountTop)
    detailAction:SetWidth(M.decisionAction)
    detailAction:SetJustifyH("RIGHT")
    detailAction:SetWordWrap(false)

    detailExempt = UI.Text(detailBody, "GameFontNormalSmall")
    detailExempt:SetPoint("TOPLEFT", detailBody, "TOPLEFT", 0, -M.ruleHintTop)
    detailExempt:SetWidth(M.ruleDetail)
    detailExempt:SetJustifyH("LEFT")
    detailExempt:SetWordWrap(false)
    UI.Ink(detailExempt, UI.C.dim)

    detailLog = CreateFrame("Frame", nil, detailBody)
    detailLog:SetPoint("TOPLEFT", detailBody, "TOPLEFT", 0, -M.ruleLogTop)
    detailLog:SetSize(M.ruleDetail, DECISION_ROWS * M.rowH)

    detailWarning = UI.Text(detailBody, "GameFontNormalSmall")
    detailWarning:SetPoint("TOPLEFT", detailLog, "BOTTOMLEFT", 0, -M.rowGap)
    detailWarning:SetWidth(M.ruleDetail)
    detailWarning:SetJustifyH("LEFT")
    detailWarning:SetWordWrap(true)
    UI.Ink(detailWarning, UI.C.bad)
end

local function buildRules(parent)
    rulesPage = buildScroller(parent, M.ruleColumn,
        M.optionsTop - M.ruleStrip, M.optionsHeight - M.ruleStrip)
    StaticPopupDialogs[RULE_POPUP] = {
        text = ns.L.RULE_DELETE_CONFIRM,
        button1 = ACCEPT,
        button2 = CANCEL,
        whileDead = 1,
        hideOnEscape = 1,
        timeout = 0,
        OnAccept = function()
            if ruleEditing and ruleEditing.id == deleteID then ruleWindow:Hide() end
            if selectedID == deleteID then selectedID = nil end
            Storage.DeleteRule(deleteID)
            ns.Resync()
            UI.Refresh()
        end,
    }

    local add = UI.Button(rulesPage.frame, ns.L.RULE_NEW, M.ruleAdd,
        function() openRuleWindow(nil) end)
    add:SetPoint("TOPLEFT", rulesPage.frame, "TOPLEFT", M.pad, M.optionsTop)

    rulesEmpty = UI.Text(rulesPage.canvas, "GameFontNormalSmall")
    rulesEmpty:SetPoint("TOPLEFT", rulesPage.canvas, "TOPLEFT", 6, -6)
    rulesEmpty:SetWidth(M.ruleColumn - M.scrollInset - 12)
    rulesEmpty:SetJustifyH("LEFT")
    rulesEmpty:SetWordWrap(true)
    rulesEmpty:SetText(ns.L.RULE_NONE)
    UI.Ink(rulesEmpty, UI.C.dim)

    buildRuleDetail(rulesPage.frame)
    syncRules()
    rulesPage.frame:Hide()
end

local function logRow(index)
    local row = logRows[index]
    if row then return row end
    local canvas = logPage.canvas
    row = CreateFrame("Frame", nil, canvas)
    row:SetHeight(M.rowH)
    row:EnableMouse(true)
    row.wash = row:CreateTexture(nil, "BACKGROUND")
    row.wash:SetAllPoints(row)
    row.wash:SetColorTexture(1, 1, 1, 0.07)
    row.wash:Hide()
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(M.ruleIcon, M.ruleIcon)
    row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.when = UI.Text(row, "GameFontNormalSmall")
    row.when:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.when:SetWidth(M.logAgo)
    row.when:SetJustifyH("RIGHT")
    row.when:SetWordWrap(false)
    UI.Ink(row.when, UI.C.dim)
    row.action = UI.Text(row, "GameFontNormalSmall")
    row.action:SetPoint("RIGHT", row.when, "LEFT", -8, 0)
    row.action:SetWidth(M.logAction)
    row.action:SetJustifyH("RIGHT")
    row.action:SetWordWrap(false)
    row.cause = UI.Text(row, "GameFontNormalSmall")
    row.cause:SetPoint("RIGHT", row.action, "LEFT", -8, 0)
    row.cause:SetWidth(M.logCause)
    row.cause:SetJustifyH("LEFT")
    row.cause:SetWordWrap(false)
    UI.Ink(row.cause, UI.C.muted)
    row.label = UI.Text(row, "GameFontNormalSmall")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.label:SetPoint("RIGHT", row.cause, "LEFT", -8, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row:SetScript("OnEnter", function(self)
        self.wash:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end)
    UI.Unhover(row, function(self)
        self.wash:Hide()
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    logRows[index] = row
    return row
end

local function paintLog()
    local first = math.floor(logPage.offset / M.rowH)
    for slot = 1, LOG_ROWS do
        local entry = logEntries[first + slot - 1]
        local row = logRow(slot)
        if entry then
            local y = -(first + slot - 2) * M.rowH - 2
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", logPage.canvas, "TOPLEFT", 0, y)
            row:SetPoint("TOPRIGHT", logPage.canvas, "TOPRIGHT", 0, y)
            local name, link, quality = ns.ItemInfo(entry.itemID)
            row.link = ns.ItemLink(entry.itemID, link)
            row.icon:SetTexture(ns.ItemIcon(entry.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.label:SetText(name or ("item:" .. tostring(entry.itemID)))
            UI.Color(row.label, quality)
            row.cause:SetText((entry.by == "blacklist") and ns.L.LOG_BLACKLIST or entry.label)
            local text, ink = actionText(entry.action)
            row.action:SetText(text)
            UI.Ink(row.action, ink)
            row.when:SetText(ago(entry.at))
            row:Show()
        else
            row:Hide()
        end
    end
end

function syncLog()
    logEntries = Storage.Log()
    logEmpty:SetShown(#logEntries == 0)
    logPage.span = #logEntries * M.rowH + 4
    logPage.canvas:SetHeight(logPage.span)
    paintScroll(logPage)
    paintLog()
end

local function buildLog(parent)
    logPage = buildScroller(parent, M.listWidth, M.optionsTop, M.optionsHeight)
    logPage.panel:SetScript("OnMouseWheel", function(_, delta)
        logPage.offset = logPage.offset - delta * WHEEL_STEP
        paintScroll(logPage)
        paintLog()
    end)
    logEmpty = UI.Text(logPage.canvas, "GameFontNormalSmall")
    logEmpty:SetPoint("TOPLEFT", logPage.canvas, "TOPLEFT", 6, -6)
    logEmpty:SetWidth(M.scrollWidth - 12)
    logEmpty:SetJustifyH("LEFT")
    logEmpty:SetWordWrap(true)
    logEmpty:SetText(ns.L.LOG_EMPTY)
    UI.Ink(logEmpty, UI.C.dim)
    syncLog()
    logPage.frame:Hide()
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

    buildOptions(frame)
    buildRules(frame)
    buildLog(frame)
end

function UI.Toggle()
    if not frame then build() end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function UI.Open(tab)
    if not frame then build() end
    frame:Show()
    switchTab(tab)
end
