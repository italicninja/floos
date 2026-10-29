# Floos 3.3.0

The first public release since 3.2.0. Everything below in "Builds" shipped
as internal test builds along the way; this is the short version.

- Fatigue is counted per zone, and there is a **Global** counter that follows
  you between zones - it climbs in the zone you are working and drops one
  per hit anywhere else. On by default; `/floos global` to inspect it.
- Accuracy moved under Zone fatigue and is off by default (HELM tab of
  `/floos config` to show it).
- New themes: **Itmejammy**, **Beasty**, **Masuru** - each colours the whole
  panel.
- A faded picture can sit behind the panel (drop a PNG in
  `assets/portraits/`, pick it under Appearance).
- Rotting timber now counts toward fatigue, so the meter matches the server.
- The rate history is a real chart, the stats are tiles, and the big number
  glides instead of jumping.
- `/floos item` shows how often each item drops per zone; `/floos zones`
  ranks zones again.
- Clamming shows bucket fill and break odds.
- `/floos save`, `/floos backup`, `/floos restore` - and a damaged settings
  file is repaired before Ashita can wipe it; if it does get wiped, you are
  told.
- The journal always goes to your character's file.
- Toggles to stop the panel auto-switching tabs or popping open.
- Fixed: haul list drawn twice, `/floos clear` hiding the panel, and clearing
  not resetting the zone counters.

# Builds

## Build 3.8.0

## New

- **Global fatigue.** One counter per activity that follows you between
  zones. It climbs to the cap in the zone you are working - its *home* - and
  then every hit in ANY other zone takes one off. So 200/200 in Halvung, walk
  to Newton, ten hits there, and the Halvung figure reads 190/200. Drain it
  all the way to zero and the next hit anywhere starts a new home.

  This is the model Tyflow described - "it's still -1 from Zeruhn when you
  mine anywhere else" - and the addon is the instrument for finding out
  whether it is right. So it is built exactly as described, **on by
  default**, and can be set to any number for a test.

      /floos global off          put it away (on by default)
      /floos global              what it holds, and where its home is
      /floos global protect off  let /floos clear wipe it (protected by default)
      /floos global set <n>      put it at a number, for a test
      /floos global reset        empty it

  Or `/floos config` -> Fatigue -> Global fatigue. On Mine, Logg, Harv and
  Exca it draws as a **Global** bar directly above Zone fatigue, with the
  home zone in its label: green while you are away from it (draining), the
  usual colours while you are in it (climbing). A small `v` after the name
  means you are away. Digging, fishing, hunting and clamming are untouched.

  The Accuracy meter gave up its slot to make room and now sits under Zone
  fatigue, off by default: tick "Show Accuracy (under Zone fatigue)" in the
  HELM tab of `/floos config` to have it back. It is always in
  `/floos report`, and Dig keeps its own row.

  It is protected from `/floos clear` and Reset Session by default, because
  a counter that exists to be watched across zones is worthless if clearing
  a session takes it with it. The protection is its own toggle.

- **Masuru theme.** Green, but the airy kind: deep forest grounds under a
  cool mint trim. GreenGold is green with gold on it; Masuru is green all the
  way through. It takes the whole panel, same as Itmejammy and Beasty, and
  every text colour clears WCAG AA with room to spare. Good is a clear sky
  blue - on an all-green panel "good" cannot be green - and warn and bad stay
  warm. Appearance tab, under GreenGold.

## Fixed

- **`/floos clear` hid the panel.** After a clear the tab you are on is
  blank, so if any other tab held an old session the idle rule saw
  "activity, none recent" and hid the panel the instant you cleared it. A
  clear now counts as activity for the Display Timeout.
- **Stack overflow on the first swing** (`auto_switch_to`, tracker.lua).
  The helper that follows your activity onto its tab called itself instead
  of setting the tab, so the first mining packet after loading took the
  addon down. It now does the one thing it was for.

## Build 3.7.0 (never released - folded into this release)

## New

- **Beasty theme.** Azurite blue over deep water, whole-panel like
  Itmejammy. Named for Beasty. Picking it loads his portrait if the file is
  in `assets/portraits/`; nothing is bundled.
- **Background picture.** A faded picture behind the panel: drop a PNG in
  `assets/portraits/`, press Rescan, pick it under Appearance. Picture Fade
  and Picture Width sliders sit with it. Works with every background style,
  Transparent included.
- **Follow the activity / Show the panel** toggles under Interface. Both
  were always on; both can now be switched off.

## Fixed

- **Settings file wiped on a bad shutdown.** Ashita overwrites a settings
  file it cannot parse with the defaults. Floos now checks every settings
  file before Ashita reads it, trims a damaged tail back to the last good
  line, and says so once in red. The backup is refreshed every five minutes
  while the live file is healthy.
- **Journal written to `journal-unknown.jsonl`** when the character name was
  not yet available at load. The name is resolved lazily now, and anything
  in the unknown file is folded into the named one once (the old file is
  renamed, not deleted).

## Build 3.4.0

## New

- **Itmejammy theme.** A light blue trim in place of the gold, on a cooler
  base so the blue sits on the panel rather than floating above it. Named for
  **Itmejammy**, for everything he has done for this community's addons - and
  because he is the one who asked for it: *"like a light blue trim, instead of
  gold"*.

  Appearance tab, next to DarkGold. Every trim value is a tint of one hue
  (#8FD8FF), and every text colour clears WCAG AA against the panel.

  It takes the **whole** panel. The per-activity accents - amber for mining,
  crimson for hunting and the rest - sat on top of every palette and were the
  real reason the panel stayed gold whatever you picked; Itmejammy overrides
  them and the Accent Color Per Activity toggle with them. Good / warn / bad
  are re-tuned cool rather than flattened, because a caution that looks like
  every other blue is not a caution.

## Build 3.3.6

## Fixed

- **Every haul item was listed twice**, each copy marked as the best drop.
  Nothing was double-counted - net gil and the fatigue count were always
  right - the list was simply drawn twice on top of itself.

  The haul draws into a child window and falls back to a plain list on ImGui
  builds that have no child windows. That fallback was gated on a value
  `libs/ui.lua` only started returning recently, so with an older `ui.lua`
  underneath it read as "no child window" and drew the whole list a second
  time. Mixing a new `tracker.lua` with an old `ui.lua` was enough to trigger
  it - which patch updates made easy, and that is on me.

  The fallback now tracks whether the rows actually reached the screen, so a
  double draw is impossible whichever `ui.lua` is installed. **`libs/ui.lua`
  is included in this update** so the two match.

## Build 3.3.5

## Fixed

- **`/floos zones` lost the lifetime zone ranking.** 3.3.0 added a zone
  fatigue list on the same command name and put it earlier in the handler, so
  it shadowed the report that had been there all along - the ranked
  "where have I actually earned" list never ran again.

  Both now come from the one command, ranking first:

      /floos zones      lifetime ranking, then today's fatigue counters
      /floos zf         only the fatigue counters
      /floos zones clear   wipes the lifetime ranking
      /floos zf clear      wipes only the fatigue counters

  The two clears are deliberately separate, and each says which one it kept.

## Build 3.3.4

- **A wipe now announces itself.** On load, if the settings file looks reset
  and a healthy backup exists, Floos says so in red and tells you the two
  commands to get your data back. Ashita's own revert notice scrolls past in
  the load spam; a wipe found weeks later is a wipe that cannot be undone.

  In that state Floos does **not** refresh the backup, so the good copy stays
  good however many times you log in before you notice.

## Build 3.3.3

## Important - the 3.3.0 to 3.3.2 downloads were incomplete

Those three zips were built as a whole addon folder, but the folder they were
built from was missing twelve library files. Extracting them **on top of** an
existing install was fine, because the missing files were already there. But
anyone who deleted their old `floos` folder first - a perfectly normal way to
update - ended up with a broken install.

**Releases are patch-style from now on**: only the files that changed, to be
extracted over an existing install. Nothing to delete first.

## New

- **`/floos backup` and `/floos restore`.** Ashita reverts settings to
  defaults *and overwrites the file* whenever it fails to parse one, which
  makes a single bad write the end of your lifetime totals, prices and zone
  counters. There is no undo built in.

  Floos now keeps `settings.bak.lua` beside the live file, refreshed on load -
  but only when the live file looks healthy, so a wipe cannot propagate into
  the backup on the next start. If the live file is dramatically smaller than
  the backup, the backup is kept and Floos says so.

      /floos backup       where the files are and how big
      /floos backup now   write one immediately
      /floos restore      put the backup back, then /addon reload floos

  Restoring also keeps `settings.before-restore.lua`, so restoring is itself
  undoable.

## Build 3.3.2

## New

- **`/floos save`** — flush settings, sessions and the zone fatigue counters
  to disk on demand. They are already written on a ten-second autosave and on
  unload; this is for when you want to be certain the file is current, such as
  just before replacing the addon's files.

## A note on updating

Your data is not in the addon folder. Sessions, prices, lifetime totals and
the zone fatigue counters all live in your settings file:

    Ashita\config\addons\floos\<Character>_<id>\settings.lua

Updating replaces `.lua` files under `Ashita\addons\floos\`, which is a
different folder entirely, so a normal update keeps everything. Nothing needs
exporting or re-entering.

## Build 3.3.1

## Changed

- **`/floos clear` now clears the zone fatigue counters too**, as does the
  **Reset Session** button. They were the only persistent thing the command
  left behind, which made "cleared" untrue.

  Logging in with *reset on load* set still leaves them alone. That path runs
  the same function, and wiping your zone allowances on every login would
  destroy the one thing they exist to remember — so the clearing is opt-in and
  only the explicit, user-initiated clears ask for it.

## Build 3.3.0

## New

- **Zone-specific fatigue.** Horizon's HELM allowance is per zone: 50 of 200
  in Palborough Mines stays 50 of 200 there however long you spend somewhere
  else. The session counter could never say that, because a session follows
  you across zones.

  The Fatigue meter now reads the count for the zone you are standing in, and
  remembers every zone across relogs. Mining, logging, harvesting and
  excavation only — **digging is untouched**, since its allowance is a daily
  one on a real-life clock.

  A zone clears itself when the fatigue period elapses from its first item, or
  the moment you gather there past the cap. `/floos zones` lists every zone
  with something counted and marks the one you are in; `/floos zones clear`
  wipes them. The toggle, a per-zone list and Clear buttons are in
  **Config → Data**. On by default; the meter says which counter it is showing
  by calling itself *Zone fatigue* rather than *Fatigue*.

- **The rate history is a real chart.** The old sparkline was a decoration the
  height of one row. It now holds 30 minutes instead of 8, with a gradient
  under the curve, your session average drawn as a dashed line across it so
  you can see at a glance whether the last few minutes are beating it, the
  peak marked, and the newest reading pulsing at the right edge.

- **Tiles instead of run-on lines.** The facts under the hero number — session
  clock, moon, Vana'diel day and time, weather — were joined with pipes into
  one line that clipped from the right, so the last one was the one you never
  saw. Each is now its own tile with a small caps label over its value, and
  each truncates on its own. The session tile is the pause button.

  The footer got the same treatment: Net, Gil/hr, Last 10m and Lifetime read
  side by side instead of as four stacked rows.

## Changed

- **The hero number glides** to its new value instead of snapping every time a
  sample lands, the same easing net gil already had.

- Compact and Mini modes are unchanged.

# Floos 3.2.0

All three of these come from Reisu's report on Discord.

## New

- **See what is in the bucket while you clam.** The panel used to show the
  bucket's weight and its gil value, but never its contents — you could only
  find out what you had been carrying after you turned it in. There is now an
  **In bucket** list under the weight meter: every item, its count, and what
  the stack is worth, sorted so the thing you would most regret losing to a
  burst is at the top.

  Items you have no price set for say `no price` rather than `0g`, because zero
  reads as worthless when it actually means unknown.

  Off by default — it costs a line per item type — under
  **Clamming → Show Bucket Contents**, with a sub-option to drop the prices and
  show plain counts.

## Fixed

- **The config window ignored your font settings.** You could scale the session
  panel but not this window, and there was no hidden option to find: `floos.lua`
  rendered the config *before* pushing the chosen font, so it always drew at
  ImGui's default size and family. It now follows **Font Size** like everything
  else, and there is a **Config Window** slider beside it (0.60–2.00) for
  people who want this window a different size from the panels.

- **The 24-hour reset countdown now only appears on Digging.** Chocobo digging
  is the one activity with a real daily allowance on a real-life clock. The
  others run on a rolling fatigue window with no fixed reset, so "next reset in
  6h" on the Mining tab was inviting you to sit and wait for something that was
  never going to happen.

  The schedule also only *learns* from digging now. A cap clearing on the other
  activities says nothing about when the daily clock rolls over, and feeding
  those in was dragging the prediction around.

# Floos 3.1.0

## New

- **Sound alerts.** Rank up, skill up, valuable drop, fatigue cap reached, and
  clamming point ready. A new **Sound** tab in the config gives each event its
  own dropdown, with a Play button to audition it.

  No audio ships with Floos. Drop your own `.wav` files into `floos/sounds/`
  and they appear in the list. Every event starts on **None**, so the addon is
  silent until you choose. `/floos sound` shows what is set and what is
  available; `/floos sound test <file>` plays one.

- **Clamming cooldown ding.** Plays the moment the point is ready again. It
  fires whatever tab you are on and whether or not the panel is showing,
  because a timer you only hear while staring at it is not a timer.

- **The panel hides behind the map and the main menu**, and comes straight back
  when you close them. Covers the map, widescan, inventory, equipment, the
  config screens and the rest of the full-screen windows - but deliberately not
  the chat log, which opens every time you press Enter to talk. On by default;
  turn it off in Interface, or with `/floos menu`.

- **RANK UP! banner.** A centred, addon-themed banner for ten seconds when a
  HELM rank increases - 10, 20, 30, 40, 50 and 60. `/floos rankup` previews it.

- **Skill-up rate by moon phase.** New Moon / Full Moon / Normal, replacing the
  old W/M/B row. **Off by default** - it needs hundreds of swings in each
  bucket before the three numbers mean anything, so it is opt-in from
  Interface -> Skillup Rate By Moon Phase.

- **Dig accuracy tracker**, matching the one mining already had.

## Fixed

- **Banners no longer blink.** They vanished after a single frame roughly half
  the time. The addon's millisecond clock was built from two unsynchronised
  sources and could tick backwards; anything timed read a backwards tick as
  "expired". The clock is monotonic now. This also affected the swing flash and
  every other timed effect, so those are steadier too.

- **Moon phases were misread.** A New Moon was being counted as Normal. The
  phase boundaries are not symmetric - waxing and waning have different
  windows - and only one set was being applied in both directions.

- **Estimated dig items now appears immediately.** It stayed blank until you
  had dug 25 times in the current session, which is exactly when you least
  need it. It now prices your remaining greens against your lifetime accuracy
  until the session has enough digs of its own, and says which rate it used.

- **The rank banner runs for ten seconds**, up from five. Five was easy to miss.

- **Fonts are genuinely loaded from Windows now.** The 1.0.0 notes said this
  already, but the code still only looked inside the addon folder. It now
  checks the Windows font directory first (via `%SystemRoot%`, not a hardcoded
  `C:`), falls back to a local copy if one exists, and then to Agave. No
  Microsoft fonts are bundled.

---

# Floos

## 1.0.0 - first release (formerly Olenna)

Renamed from **Olenna** to **Floos**. The addon folder, the slash command and
every internal identifier changed with it:

- `/olenna` is now `/floos` (every subcommand is unchanged otherwise)
- the folder is `Ashita4/addons/floos/`
- settings now live in `Ashita4/config/addons/floos/`

**Upgrading from Olenna:** rename your settings folder to keep lifetime gil,
zone history and your price list:

    Ashita4/config/addons/olenna    ->    Ashita4/config/addons/floos

Skip that and everything still works, it just starts from zero. Delete the old
`addons/olenna` folder either way, or you will have both loaded at once.

### Release changes

- **Fonts are no longer bundled.** Tahoma, Segoe UI, Consolas and Verdana are
  Microsoft fonts and redistributing them is not permitted. Floos now loads them
  from `C:\Windows\Fonts` at runtime instead, so the look is identical and the
  download drops from 1.9 MB to 380 KB. Falls back to Agave if they are missing.
- **LICENSE added.** GPL v3, inherited from XIUI. Replace the notice with the
  full text from gnu.org before publishing.
- **README added** covering install, commands, prices, safety and the HorizonXI
  approval situation.
- Version reset to 1.0.0 for the first public release. The history below is the
  development record under the old name.

---

# Floos 1.8.2 - excavation skill wording

Excavation skill-ups read:

    Your excavating skill has increased by 0.1 raising it to 19.3.

1.8.1 looked for "excavation skill", so it never matched and Exca sat at
Skill 0.0. Each activity now carries a list of possible words rather than one
guess - harvest accepts "harvesting" and "harvest", excavate accepts
"excavating" and "excavation" - so a wording difference cannot silently break a
tab again.

Your excavation skill will pick up its real value on the next skill-up.

---

# Floos 1.8.1 - Logging, Harvesting and Excavation audit

I went through the three neglected tabs. Six real bugs, all fixed and unit-tested.

## Drop names were being truncated

Mining and excavation captured the item with `([%w%s]+)` - letters, digits and
spaces only. Any drop with an apostrophe or a hyphen got cut short, so it was
counted under a mangled name and never matched your price list. Now all four
activities use the same `([^,!]+)` capture (which is what the addon this logic
came from actually used), plus proper trimming of trailing punctuation and the
", but your pickaxe breaks in the process." tail.

## Excavation could miss failures

Excavation reused mining's failure line only. It now accepts both
"unable to mine anything" and "unable to excavate anything", so a miss is
counted either way. This matters: a missed failure inflates your accuracy and
corrupts the skill-up attribution for that swing.

## Skill-up parsing broke on the comma

The pattern required whitespace between the amount and "raising", but the game
writes "... increases by 0.1, raising it to 23.6." Now tolerant of both forms.

## Harvesting and Excavation had no skill tracking at all

Only mining and logging were parsed. Both now have skill level, skill/hr, the
skill bar, skill-up attribution and zone credit, with settings under Config >
HELM. If Horizon has no skill for these, the patterns simply never fire and
nothing changes.

## Logging skill never fed zone tracking

Only mining did. All four gathering activities now credit their zone.

## Tool counts could be wrong

Hatchet, Sickle and Pickaxe ids were hardcoded. Pickaxe (605) and Hatchet (1021)
check out, but the Sickle id was unverified. Ids are now resolved by name from
the game's own resource table at runtime, falling back to the constants. The
Sickles counter is correct regardless of what the id actually is.

## Also

- An unresolved swing now expires after 20 seconds instead of hanging around to
  capture an unrelated chat line later.
- Excavation's fatigue cap, tool cost and break subtraction are wired properly;
  the config notes that excavation uses the Mining pickaxe cost.
- Harvesting gained a "Show Harvesting Skillups" toggle to match the others.

Note: the default price list has no excavation items in it, so Excavation will
show 0 gil until you add them under Config > HELM. I did not want to guess at
item names and give you a list that silently does not match.

---

# Floos 1.8.0 - zone tracking reworked

## The bug

The old verdict compared this zone against the average of **every zone you had
ever visited, blended together**. Standing in Oldton, "vs 0.4 avg" was your
lifetime average across Ifrit's, Palborough and everywhere else. It was never
comparing like with like, so STAY and MOVE meant nothing.

It also judged on **skill/hr**, which at 0.2 skill per half hour is one or two
events - pure noise. It only recorded a visit when you *left* a zone, so
crashing or reloading threw the sample away, and hopping Oldton to Newton and
back reset you to SAMPLING every time.

## The rework

Every zone now keeps a lifetime aggregate per activity: time actually swinging,
gil, skill, swings, items, breaks, visits. It updates on every swing instead of
on zone exit, so nothing is lost to a reload.

- **Judged on gil/hr by default.** Far less noisy than skill. Switch to skill/hr
  in Config > Appearance ("Judge zones by").
- **Compared against a real zone, and it names it.** MOVE now means "somewhere
  specific is better", and the panel line reads
  `Oldton Movalpolos  24,545/hr  vs  Ifrit's Cauldron 72,400/hr`.
- **Only trustworthy zones are used as the benchmark** - 10 minutes and 40 swings
  before a zone can be the thing you are measured against.
- **SAMPLING now counts down.** `SAMPLING 00:03:40` tells you how long until the
  verdict means something, instead of sitting there forever.
- **Quick zone hops resume.** Leaving and returning within 4 minutes continues
  the same sample rather than starting over.
- **AFK never counts.** Gaps longer than the idle limit are dropped from zone time.
- **Breaks are charged against the zone** when Subtract Tool Breaks is on, so a
  break-heavy zone shows its true rate.
- Logging skill-ups feed zone tracking now; previously only mining did.
- The verdict shows on all four gathering tabs, not just Mine and Exca.

## /floos zones

Now a ranked table for the current activity, best rate first, with time invested
and swing counts. Zones with a thin sample are marked and sorted below the solid
ones so three lucky swings never top the list. `/floos zones clear` wipes it.

---

# Floos 1.7.3 - mini mode

`/floos mini` collapses the panel to the four things you actually act on:

    MINE  Skill 23.6              50,951 gil/hr
    Fatigue   25%  49 / 200  1:36:18
    [====                    ]
    Swings 92            Breaks 14
    Pickaxes 124      Net 26,537g
    Session 00:31:15

Tabs stay (thinner), so you can still switch activity. Gone in mini: the moon and
Vana'diel line, area and verdict, accuracy meter, drop list, sparkline, lifetime
gil, skill rate and the swing strip.

## One setting instead of two toggles

Compact and mini are now levels of a single **Detail** setting:

- **Full** - everything, the default.
- **Compact** - no drop list, no footer. The old compact mode.
- **Mini** - the five-line panel above.

Set it in Config > Appearance, or:

- `/floos mini` - toggle Mini
- `/floos compact` - toggle Compact
- `/floos detail full | compact | mini` - set it directly

Your old compact setting migrates automatically. Switching level also releases a
locked panel height, so the box shrinks with the content instead of leaving a gap.

---

# Floos 1.7.2

DarkGold is now the default theme. It is first in the Appearance list, it is what
a fresh install boots with, and it is the fallback everywhere the code previously
fell back to OceanBlue.

Your saved theme is untouched - if you already picked one, you keep it. This only
changes what new installs and new characters get.

---

# Floos 1.7.1

Install: drop the `floos` folder into `Ashita4/addons/`, overwriting the old one,
then `/addon reload floos`. Settings, lifetime gil and zone history are preserved.

## Removed in 1.7.1

The node map, circuit routing and node store from 1.8.0 are gone. Deleted:
`libs/nodes.lua`, `libs/route.lua`, `modules/map.lua`, the Map config tab, the
`/floos map` and `/floos nodes` commands, and the entity scanner.

Nothing reads or records entity positions any more. The addon is back to what it
was in 1.7.0: it listens for the HELM packet, reads chat lines, and draws a panel.

If you ran 1.8.x, it may have written a node file at
`Ashita4/config/addons/floos/nodes.lua`. Nothing reads it now - delete it.

---

# Floos 1.7.0 — the expert panel

- Hero gil/hr number at 1.5x, reading `--` until a session has two minutes on it.
- Accent color per activity: Mine amber, Logg green, Harv teal, Exca orange, Hunt crimson.
- Fatigue meter with percentage, count, ETA, and a green-to-red gradient.
- Accuracy meter with a tick at your lifetime average.
- Skill bar showing progress to the next whole level.
- Swing history strip — last 30 outcomes as colored ticks, skill-ups dotted above.
- Zone STAY / MOVE verdict chip from your own per-zone skill/hr history.
- Rate sparkline, reward rows sorted by value with share bars, tab badges,
  low-tool warnings, skill-up flash, gil count-up.
- Fixed: the `?` glyph on the best drop, the panel not auto-fitting, Skill/hr
  printing twice, the width slider disagreeing with the renderer, and three
  latent nil crashes in `ui.lua`.
- `/floos compact`, `/floos auto`.
