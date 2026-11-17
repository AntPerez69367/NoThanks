# No Thanks!

A loot filter for the WoW Forever client. You decide which items are junk; blacklisted
items stay on the corpse when you loot.

## Install

Drop the `NoThanks` folder into `Interface/AddOns` and restart the client, or extract
a release zip there directly.

## Use

Open the window with `/nothanks`, `/noty` or `/nt`.

- **Loot** lists everything you have picked up, most recent first, with vendor and
  auction prices when Auctionator is installed.
- **Blacklist** lists what you are skipping, and how many times each item has been left.
- **Options** holds the settings below.

Select rows and use the button at the bottom to add or remove in bulk. To change a
single item, click it with the quick-add binding — Shift, Ctrl or right-click, whichever
you set. It works both ways: on the Loot tab it blacklists, on the Blacklist tab it
takes the item back off.

Hold the bypass modifier while looting to take everything and ignore the filter.

## Settings

- **Loot everything while holding** — Shift, Ctrl or Alt.
- **Filter loot taken by other addons** — some addons loot for you and would otherwise
  bypass the filter. Leave this on to apply your blacklist to them too.
- **Blacklist an item with** — the quick-add binding.
- **Announce skipped items in** — chat, the message area at the top of the screen, or
  nowhere. Item links are only clickable in chat.
- **Window scale** — 80% to 150%.

## Profiles and sharing

Your blacklist is per character. Profiles are saved account-wide, so you can snapshot
one character's list and apply it on another. Applying a profile adds its items and
removes nothing.

Export produces a string you can paste to someone else; import merges it into your
current blacklist. Exported strings carry item IDs only, not your skip counts.

## Worth knowing

It does nothing until you blacklist something. That is intended, not a fault — one
person's trash is another's reagent, so it ships with no list.

Quest items are never skipped, even if one is on your blacklist, and they are hidden
from the Loot tab.

The addon only turns off Blizzard's auto-loot setting while your blacklist has
something in it, and hands the setting back when it is empty.

## Licence

GPL-3.0-or-later. See `LICENSE`.
