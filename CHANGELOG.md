## 1.1.0

### Rules

- New **Rules** tab. A rule matches on quality, item type and subtype, required level and
  sell price, and either leaves the item or destroys it. Rules are account-wide by
  default; whether each one runs, and whether it runs live, is per character.
- A new rule starts in **Test**. It acts on nothing and records what it would have taken,
  so you can read the result before switching it to **Live**.
- Rules run top to bottom and the first match wins. **Move up** and **Move down** reorder
  them. A rule nothing can reach is marked with the reason, as is a rule that leaves
  behind items the blacklist asked to destroy.
- **This rule belongs to** gives a rule to one character instead of the account. A rule
  set to **This character** is marked `char` in the list and does not appear on your
  other characters.
- Each rule keeps its own recent catches. Click one with the quick-add binding to exempt
  that item from the rule.
- The editor previews a rule against every item this character has seen, the ones live
  rules took included, so a rule that already works still shows what it matches.
- Rules run before the blacklist. **Destroy blacklisted items** governs what a rule may
  destroy, and **Apply the blacklist to other addons** carries your live rules to them.

### Log

- New **Log** tab: the last 500 decisions on this character, with what acted and when. It
  keeps the name a rule had at the time, so the history survives editing or deleting it.

### Interface

- Rule names get the room the badges were taking. **Add a rule** is a button, a rule's
  catches say what the count counts and which click exempts an item, and a tab with no
  rules yet says so.
- In the rule editor the fields and segmented controls share one right edge, and a
  criterion you leave unset says that it matches anything.
- The Loot tab explains its `—` and `?` price marks, says why the blacklist button is
  greyed out, and gathers its footer onto one line.

### Fixes

- A quest item is recognised by the flag the loot window reports, not by its item type.
  One filed as something else — a quest key, say — now stays out of the Loot tab and out
  of rule matching. Items already in your history are recognised the next time you loot
  them.

## 1.0.0

- Fixed item lookups that could return a secret value on this client and raise an error
  in the loot pipeline or the window.

## 0.1.3-beta

- Bugfixes and improvements.

## 0.1.2-beta

- New option: **Destroy blacklisted items**. Blacklisted items go to your bags and the
  addon destroys them, with no prompt and no key press. A quality ceiling limits what it
  will destroy, and quest items are always safe. The option is off until you turn it on.
- The Loot tab now shows the last 7 days by default. Use **Show items from** to switch
  between this session, 7 days and the full history.
- New **Clear history** button on the Loot tab. It asks first, and it does not touch
  your blacklist.
- Adjusted UI spacing.

## 0.1.1-beta

- Added a minimap button. **LibDBIcon** carries it, so a broker display can hold it
  instead.
- Fixed the loot pipeline, the auto-loot handback and several defects in the window.

## 0.1.0-beta

- First release.
