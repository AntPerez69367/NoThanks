local addonName, ns = ...

local columns = { enUS = 1 }
local aliases = { enGB = "enUS" }

local catalog = {
    TAB_LOOT = { "Loot" },
    TAB_BLACKLIST = { "Blacklist" },
    SEARCH = { "Search" },
    FILTER_QUALITY = { "Quality filter" },
    PRICE_NONE = { "\226\128\148" },
    PRICE_UNKNOWN = { "?" },
    COL_ITEM = { "Item" },
    COL_LOOTED = { "Looted" },
    COL_LEFT = { "Left behind" },
    COL_VENDOR = { "Vendor" },
    COL_AUCTION = { "Auction" },
    STATUS_ALL = { "%d items" },
    STATUS_FILTERED = { "Showing %d of %d" },
    BLACKLIST_SELECTED = { "Add to blacklist (%d)" },
    REMOVE_SELECTED = { "Remove from blacklist (%d)" },
    EMPTY_LOOT = { "Nothing looted yet. Loot a corpse and everything you pick up is listed here." },
    EMPTY_BLACKLIST = { "No items refused yet. Pick items on the Loot tab to add them." },
    EMPTY_FILTER = { "Nothing matches the current search and filters." },
    LEFT_BEHIND = { "Left behind: %s" },
    SETTING_WRAPPER = { "Filter loot taken by other addons" },
    SETTING_MODIFIER = { "Loot everything while holding" },
    OPEN_WINDOW = { "Open No Thanks!" },
    TAB_OPTIONS = { "Options" },
    CLEAR_SELECTION = { "Clear selection" },
    SECTION_LOOTING = { "Looting" },
    SECTION_BLACKLIST = { "Editing the blacklist" },
    SECTION_NOTIFICATIONS = { "Notifications" },
    SECTION_WINDOW = { "Window" },
    SETTING_SCALE = { "Window scale" },
    SETTING_QUICKADD = { "Blacklist an item with" },
    SETTING_QUICKADD_HELP = { "Works both ways \226\128\148 on the Blacklist tab it takes the item back off." },
    SETTING_ANNOUNCE = { "Announce skipped items in" },
    SETTING_ANNOUNCE_HELP = { "Item links are only clickable in chat." },
    SETTING_ANNOUNCE_TEST = { "Test" },
    SETTING_ANNOUNCE_SAMPLE = { "Tough Jerky, Chipped Claw, Ruined Pelt" },
    SETTING_WRAPPER_HELP = { "Some addons loot for you and skip No Thanks!. Leave this on to apply your blacklist to them too." },
    INTERFERENCE = { "Something else looted an item you skip. Enable enforcement to filter it." },
    REASSERTED = { "Auto-loot stays off while you have blacklisted items. Clear the blacklist to use auto-loot again." },
    SETTING_PROFILES = { "Profiles" },
    SETTING_PROFILES_HELP = { "A profile is a saved copy of this character's blacklist, shared by all your characters. Applying one adds its items and takes nothing off." },
    PROFILE_NAME_PLACEHOLDER = { "Profile name" },
    PROFILE_SAVE = { "Save current" },
    PROFILE_APPLY = { "Apply" },
    PROFILE_DELETE = { "Delete" },
    PROFILE_APPLIED = { "Added %d items to the blacklist." },
    PROFILE_NONE = { "No profiles saved yet." },
    EXPORT = { "Export" },
    IMPORT = { "Import" },
    IMPORT_ACCEPT = { "Accept" },
    IMPORT_RESULT = { "Added %d items, %d were already on the blacklist." },
    IMPORT_BAD_PREFIX = { "That text is not a No Thanks! blacklist string." },
    IMPORT_BAD_VERSION = { "That string comes from a newer No Thanks! than this one. Update the addon to import it." },
    IMPORT_NO_ITEMS = { "That string lists no items." },
    IMPORT_BAD_ITEM = { "That string has an item that is not a number. Check that you copied all of it." },
}

function ns.LoadLocale()
    local locale = GetLocale and GetLocale() or "enUS"
    locale = aliases[locale] or locale
    local column = columns[locale] or columns.enUS
    for key, row in pairs(catalog) do
        ns.L[key] = row[column] or row[columns.enUS]
    end
end
