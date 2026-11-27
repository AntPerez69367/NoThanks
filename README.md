# No Thanks!

A loot filter for the WoW Forever client. Write a rule and it decides for every item
that matches: grey items worth less than a few silver, cloth armour your warrior will
never wear, anything below a level you set. Items a rule claims stay on the corpse when
you loot, or go to your bags and get destroyed. A per-character blacklist names the
one-off items no rule should have to describe.

## Install

Drop the `NoThanks` folder into `Interface/AddOns` and restart the client, or extract
a release zip there directly.

## Use

Open the window with `/nothanks`, `/noty` or `/nt`.

- **Loot** lists everything you have picked up, most recent first, with vendor and
  auction prices when Auctionator is installed. **Show items from** limits the list to
  this session, the last 7 days, or the full history. **Clear history** empties the
  list and leaves the rest alone.
- **Blacklist** lists the items you named by hand, and how many times each was skipped.
- **Rules** holds your rules, in the order they run.
- **Log** is the last 500 decisions on this character: what acted, what it did, when.
- **Options** holds the settings below.

## Rules

A rule is a set of criteria and one action. **Add a rule** opens the form.

- **Quality is one of** — tick any number of qualities.
- **Item type** and **Item subtype** — the client's own categories, so **Armor** with
  **Cloth**, or **Trade Goods** with **Herb**.
- **Required level at most** — the level needed to use the item, not its item level.
- **Sell price at most** — the vendor price, typed the way the game writes it: `5g 20s`.
- **Then do this** — **Leave it** or **Destroy it**.
- **Run the rule in** — **Test** or **Live**.
- **This rule belongs to** — **Account** or **This character**.

A field left blank narrows nothing, and a rule with no criteria at all cannot be saved.
As you fill the form it counts how many of your recent loot items would match, so you
can see how far a rule reaches before it runs once.

### Test first

A new rule starts in **Test**. A test rule acts on nothing: it watches, and records what
it would have taken. Read that back on the Rules tab and in the Log, and switch the rule
to **Live** when the list looks right.

Test and live are per character, as is whether a rule runs at all. A rule is account-wide
by default, so your hunter and your rogue share one set and each decides which of them to
use.

### One character only

**This rule belongs to** set to **This character** keeps the rule on the character that
saved it. It is marked `char` in the list and your other characters never see it. Set it
back to **Account** and every character has it again.

### Order

Rules run top to bottom and the first match wins. **Move up** and **Move down** reorder
them. Order matters when two rules claim the same item and want different things — put
the exception above the broad rule.

A rule that can never be reached is marked with a `!`, and the reason sits beside the
rule when you select it: something above it already claims everything it would. The same
marker appears when a live rule leaves items behind that your blacklist asked to destroy.

### Exempt items

Any rule can spare individual items. Select the rule, find the item in its list of recent
catches, and click it with the **Blacklist or exempt with** key. The rule passes over that
item from then on and the row reads **Exempt**. Click it again to undo, or use
**Let this rule apply again** in the rule's editor.

Exempt items belong to the rule, and go with it when you delete it.

## The blacklist

The blacklist names single items, per character, and needs no criteria to match.

Select rows and use the button at the bottom to add or remove in bulk. To change a single
item, click it with the **Blacklist or exempt with** key — Shift, Ctrl or right-click,
whichever you set. It works both ways: on the Loot tab it blacklists, on the Blacklist tab
it takes the item back off.

Rules run before the blacklist. If a rule claims an item, the rule's action is what
happens, so a rule set to **Leave it** will leave an item your blacklist would have
destroyed.

Hold your **Loot all items with** modifier while looting to take everything and ignore
both.

## Settings

- **Loot all items with** — Shift, Ctrl or Alt. Hold it to take everything.
- **Apply rules and the blacklist to other addons** — some addons loot for you and would
  otherwise bypass the filter. Leave this on to apply your blacklist and your live rules
  to them.
- **Allow destroying items** — nothing is destroyed until you turn this on, rules
  included: with it off, a rule set to **Destroy it** leaves the item instead. Items go
  to your bags and the next key press or mouse click destroys them, with no prompt. The
  whole stack goes, including any you were already carrying, so think twice before a rule
  destroys something you stockpile.
- **Maximum quality to destroy** — nothing above this quality is destroyed, whichever
  decided it. Quest items are never destroyed.
- **Blacklist or exempt with** — Shift, Ctrl or right-click. On the Loot tab this key
  blacklists an item, on the Blacklist tab it removes one, and in a rule's catches it
  exempts an item or lets the rule apply again.
- **Show messages in** — chat, the message area at the top of the screen, or nowhere.
  You can click item links only in chat.
- **Window scale** — 80% to 150%.
- **Show a minimap button** — on or off.

## Profiles and sharing

Your blacklist is per character. Profiles are saved account-wide, so you can snapshot one
character's list and apply it on another. Applying a profile adds its items and removes
nothing.

Export produces a string you can paste to someone else; import merges it into your current
blacklist. Exported strings carry item IDs only, not your skip counts.

Profiles and exports cover the blacklist. An account-wide rule needs none of this: every
character you play has it without being given a copy.

## Worth knowing

It does nothing until you write a rule or blacklist something. That is intended, not a
fault — one person's trash is another's reagent, so it ships empty.

Quest items are never skipped or destroyed, whatever your rules and blacklist say, and
they are hidden from the Loot tab.

A rule that tests quality, required level or sell price needs the client to have seen the
item before. Until then the rule does not match and the item is looted, which is the safe
way round.

The addon only turns off Blizzard's auto-loot setting while your blacklist has something
in it or a live rule is enabled, and hands the setting back when there is nothing to do.
Rules left in test never take it.

The Log records the name a rule had when the line was written, so your history stays
readable after you edit or delete the rule behind it.

## Licence

GPL-3.0-or-later. See `LICENSE`.
