local addonName, ns = ...

local columns = { enUS = 1 }
local aliases = { enGB = "enUS" }

local catalog = {
    TAB_LOOT = { "Loot" },
    TAB_BLACKLIST = { "Blacklist" },
    TAB_OPTIONS = { "Options" },
    SEARCH = { "Search" },
    FILTER_QUALITY = { "Quality filter" },
    FILTER_WINDOW = { "Show items from" },
    WINDOW_SESSION = { "Session" },
    WINDOW_WEEK = { "7 days" },
    WINDOW_ALL = { "All" },
    CLEAR_HISTORY = { "Clear history" },
    CLEAR_HISTORY_CONFIRM = { "Clear the loot history for this character? This does not change the blacklist." },
    PRICE_NONE = { "\226\128\148" },
    PRICE_UNKNOWN = { "?" },
    COL_ITEM = { "Item" },
    COL_LOOTED = { "Looted" },
    COL_LEFT = { "Skipped" },
    COL_VENDOR = { "Vendor" },
    COL_AUCTION = { "Auction" },
    STATUS_ALL = { "%d items" },
    STATUS_FILTERED = { "Showing %d of %d" },
    BLACKLIST_SELECTED = { "Add to the blacklist (%d)" },
    REMOVE_SELECTED = { "Remove from the blacklist (%d)" },
    EMPTY_LOOT = { "No loot yet. Loot a corpse and every item you take appears here." },
    EMPTY_BLACKLIST = { "The blacklist is empty. Select items on the Loot tab to add them." },
    EMPTY_FILTER = { "No items match the search and the filters." },
    EMPTY_WINDOW = { "No loot in this period. Select All to see the full history." },
    LEFT_BEHIND = { "Left on the corpse: %s" },
    DESTROYED = { "Destroying: %s" },
    OPEN_WINDOW = { "Open the window" },
    CLEAR_SELECTION = { "Clear selection" },
    SECTION_LOOTING = { "Looting" },
    SECTION_BLACKLIST = { "Blacklist" },
    SECTION_NOTIFICATIONS = { "Messages" },
    SECTION_WINDOW = { "Window" },
    SETTING_MODIFIER = { "Loot all items with" },
    SETTING_WRAPPER = { "Apply the blacklist to other addons" },
    SETTING_WRAPPER_HELP = { "Some addons loot items for you. Turn this on and the blacklist also applies to them." },
    SETTING_DESTROY = { "Destroy blacklisted items" },
    SETTING_DESTROY_HELP = { "Blacklisted items go to your bags. The next key press or mouse move destroys them, with no prompt. The full stack goes, including any you carried before." },
    SETTING_DESTROY_QUALITY = { "Maximum quality to destroy" },
    SETTING_QUICKADD = { "Add to the blacklist with" },
    SETTING_QUICKADD_HELP = { "Use the same key on the Blacklist tab to remove an item." },
    SETTING_ANNOUNCE = { "Show messages in" },
    SETTING_ANNOUNCE_HELP = { "You can click item links only in the chat window." },
    SETTING_ANNOUNCE_TEST = { "Test" },
    SETTING_ANNOUNCE_SAMPLE = { "Tough Jerky, Chipped Claw, Ruined Pelt" },
    SETTING_SCALE = { "Window scale" },
    SETTING_MINIMAP = { "Show a minimap button" },
    MINIMAP_LEFT_CLICK = { "Left-click to open the window" },
    MINIMAP_RIGHT_CLICK = { "Right-click to open the options" },
    INTERFERENCE = { "Another addon looted a blacklisted item. Turn on \"Apply the blacklist to other addons\" to stop this." },
    REASSERTED = { "Auto-loot stays off while the blacklist has items. Clear the blacklist to use auto-loot again." },
    SETTING_PROFILES = { "Profiles" },
    SETTING_PROFILES_HELP = { "A profile is a copy of this character's blacklist. All your characters can use it. A profile adds items and removes none." },
    PROFILE_NAME_PLACEHOLDER = { "Profile name" },
    PROFILE_SAVE = { "Save current" },
    PROFILE_APPLY = { "Apply" },
    PROFILE_DELETE = { "Delete" },
    PROFILE_APPLIED = { "Added %d items to the blacklist." },
    PROFILE_NONE = { "No profiles yet." },
    EXPORT = { "Export" },
    IMPORT = { "Import" },
    IMPORT_ACCEPT = { "Accept" },
    IMPORT_RESULT = { "Added %d items. %d items were already on the blacklist." },
    IMPORT_BAD_PREFIX = { "That text is not a blacklist string." },
    IMPORT_BAD_VERSION = { "That string comes from a newer version. Update the addon to import it." },
    IMPORT_NO_ITEMS = { "That string lists no items." },
    IMPORT_BAD_ITEM = { "That string contains an item that is not a number. Make sure you copied all of it." },
}

function ns.LoadLocale()
    local locale = GetLocale and GetLocale() or "enUS"
    locale = aliases[locale] or locale
    local column = columns[locale] or columns.enUS
    for key, row in pairs(catalog) do
        ns.L[key] = row[column] or row[columns.enUS]
    end
end
