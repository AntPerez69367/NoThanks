# No Thanks!

A loot filter for the WoW Forever client. You decide which items are junk. Blacklisted
items stay on the corpse when you loot, or go to your bags and get destroyed.

## Install

Drop the `NoThanks` folder into `Interface/AddOns` and restart the client, or extract
a release zip there directly.

## Use

Open the window with `/nothanks`, `/noty` or `/nt`.

- **Loot** lists everything you have picked up, most recent first, with vendor and
  auction prices when Auctionator is installed. **Show items from** limits the list to
  this session, the last 7 days, or the full history. **Clear history** empties the
  list and leaves your blacklist alone.
- **Blacklist** lists what you are skipping, and how many times each item was skipped.
- **Options** holds the settings below.

Select rows and use the button at the bottom to add or remove in bulk. To change a
single item, click it with the quick-add binding — Shift, Ctrl or right-click, whichever
you set. It works both ways: on the Loot tab it blacklists, on the Blacklist tab it
takes the item back off.

Hold your **Loot all items with** modifier while looting to take everything and
ignore the filter.

## Settings

- **Loot all items with** — Shift, Ctrl or Alt. Hold it to take everything.
- **Apply the blacklist to other addons** — some addons loot for you and would
  otherwise bypass the filter. Leave this on to apply your blacklist to them too.
- **Destroy blacklisted items** — blacklisted items go to your bags and the addon
  destroys them, with no prompt. Off until you turn it on.
- **Maximum quality to destroy** — nothing above this quality is destroyed. Quest
  items are never destroyed.
- **Add to the blacklist with** — the quick-add binding.
- **Show messages in** — chat, the message area at the top of the screen, or nowhere.
  You can click item links only in chat.
- **Window scale** — 80% to 150%.
- **Show a minimap button** — on or off.

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
