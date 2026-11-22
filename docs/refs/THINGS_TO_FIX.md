# Things to fix

Living list from a device walkthrough of v0.9.0.

Test context: MAR LX3A, Android 10 (API 29), 1080×2312 @ 480 dpi → 360×770 dp,
font scale 1.0, system language English, app timezone `America/Caracas`.
Debug build installed from `build/app/outputs/flutter-apk/app-debug.apk`.

Each entry lists the screen, the evidence, the code that causes it, and the
smallest fix that removes it. Add new findings below; do not delete entries
without a fix and a regression test.

---

## P1 — visible defects

### 1. Today header breaks the weekday mid-word

- **Screen:** Today
- **Evidence:** `Wednesday` renders as `Wednesda` / `y` on a 360 dp phone.
  There is no RenderFlex overflow in logcat; this is a silent line wrap.
- **Cause:** `_TodayHeader` (`lib/screens/today_screen.dart:189`) uses
  `SundialType.display(31)` inside an `Expanded` next to the List/Timeline
  `SundialSegmented` (≈166 dp wide). The header gets ≈153 dp; "Wednesday" at
  31 sp needs ≈170 dp.
- **Impact:** every 360 dp phone; worse with accessibility text scaling > 1.
- **Fix:** keep the weekday to one line (`FittedBox(fit: BoxFit.scaleDown)` or
  `maxLines: 1` + a smaller responsive size), or move the view switch to its
  own row below the header on narrow widths.
- **Test:** widget test at 360 dp width asserting a single text line / no wrap.
- **Status (2026-11-21):** Fixed. Below 420 dp the view switch moves to its
  own row under the header, so the weekday keeps its full display size and
  accessibility scaling. Covered by `test/things_to_fix_p1_test.dart`.

### 2. Search empty state overflows when the keyboard is open

- **Screen:** Search (top-bar magnifier)
- **Evidence:** debug build paints the yellow/black stripes and
  `BOTTOM OVERFLOWED BY 31 PIXELS` over the prompt text. This is the default
  state because the search field autofocuses.
- **Cause:** `SearchPage` (`lib/features/search/pages/search_page.dart:75-118`)
  puts `AppEmptyState` inside `Expanded` in a non-scrollable `Column`. The
  keyboard shrinks the viewport; `AppEmptyState`
  (`lib/core/widgets/app_empty_state.dart`) is a fixed column (96 dp halo plus
  padding) that cannot shrink or scroll.
- **Fix:** make the empty area scrollable (`SingleChildScrollView`), or use the
  `compact` empty state when the available height is small.
- **Test:** widget test with a non-zero `viewInsets.bottom` and no overflow.
- **Status (2026-11-21):** Fixed. The prompt is scrollable and switches to the
  compact empty state when the viewport is short. Covered by
  `test/things_to_fix_p1_test.dart`.

### 3. Today repeats the same empty sentence three times

- **Screen:** Today, empty plan
- **Evidence:** "Nothing planned for today." appears in the progress card, in a
  stray centered line, and in the empty-state card. The centered line is
  inconsistent with the left-aligned content around it.
- **Cause:**
  - progress card: `lib/screens/today_screen.dart:220`
  - `_TodayList` fallback: `lib/screens/today_screen.dart:307-308`
  - empty-state card: `lib/screens/today_screen.dart:151-167`
  - the standalone line is centered because `AnimatedSwitcher` centers its
    child.
- **Related:** the progress card also says "Nothing planned for today." when
  shifts exist but no tasks do, which is misleading.
- **Fix:** render the empty state once. Drop the `_TodayList` fallback and hide
  (or shorten) the progress card when `total == 0`; the empty-state card
  already carries the message and the CTA.
- **Test:** widget test asserting exactly one occurrence of the empty message.
- **Status (2026-11-21):** Fixed. The progress card is hidden when there are no
  tasks, and the list/timeline fallbacks are gone, leaving the empty-state card
  as the single message. Covered by `test/things_to_fix_p1_test.dart`.

### 4. Reminder labels never use the singular

- **Screen:** entry editor → Reminders (default chips)
- **Evidence:** default reminder chips read `10 minutes before` and
  **`1 hours before`**.
- **Cause:** `reminderOffsetLabel`
  (`lib/core/i18n/reminder_label.dart:6-12`) calls
  `reminderHoursBefore(count)` / `reminderMinutesBefore(count)` /
  `reminderDaysBefore(count)`. The ARB entries are plain
  `"{count} hours before"` with no ICU plural
  (`lib/l10n/app_en.arb:232-244`; same in `app_es.arb`).
- **Fix:** use ICU plural forms in both ARBs
  (`=1{1 hour before} other{{count} hours before}`, etc.) and regenerate.
  Check `minutes`, `hours`, `days` and the Spanish translations.
- **Status (2026-11-21):** Fixed. English and Spanish now use ICU plurals, and
  `test/l10n_test.dart` asserts the singular and plural forms.

### 4b. Shift editor field labels are clipped and collide with their fields

- **Screen:** Shifts → Edit shift pattern
- **Evidence:** three labels look wrong on one form:
  - `Pattern name` floats half above its field and is clipped by the top of
    the scroll area (the field is focused, so the label floats).
  - `Anchor date` and the slot `Label` sit on the field's top border with no
    gap, so the rounded outline runs through the text.
  - `Context`, `Time zone`, `Start time` and `End time` use a small caption
    above the control and look correct, which makes the other three read as
    misplaced.
- **Cause:** the form mixes two label idioms.
  - `SundialSelectField` (`lib/core/widgets/sundial_select_field.dart:62-70`)
    and `SundialTimeField` render a caption above the control.
  - The name field
    (`lib/features/shifts/pages/shift_pattern_editor_page.dart:238-243`),
    `SundialDateField` (`lib/core/widgets/sundial_date_field.dart:34-46`) and
    the slot/checklist fields (`shift_pattern_editor_page.dart:540-545`,
    `:402-406`) use Material floating `labelText` under the shared
    `inputDecorationTheme` with `isDense: true`
    (`lib/theme/app_theme.dart:206-235`). Inside `_buildSlot` the field fill
    and the surrounding container are both `surfaceAlt`, so the punched-out
    notch is invisible and the label appears to sit on the border.
  - The `ListView` has no top inset
    (`shift_pattern_editor_page.dart:235-236`), so the first field's floating
    label is clipped by the viewport.
- **Impact:** the editor for recurring work schedules looks broken on a
  360 dp phone, and the same mismatch will repeat anywhere a `TextFormField`
  is dropped into this shell.
- **Fix:** pick one idiom for fields in this shell.
  - Preferred: add a shared caption-above-control text field, matching
    `SundialSelectField`, and use it for the name, anchor date, slot label and
    checklist label.
  - Or keep floating labels, set
    `floatingLabelBehavior: FloatingLabelBehavior.always`, give the field fill
    a colour distinct from `surfaceAlt` inside `_buildSlot`, and add top
    padding to the list so the first label is not clipped.
- **Test:** widget test at 360 dp that focuses the name field and asserts its
  label is fully inside the viewport and does not overlap the value text.
- **Status (2026-11-21):** Fixed. Added `SundialTextField` and
  `SundialFieldLabel`, moved `SundialDateField` to the same caption-above
  idiom, and used them for the pattern name, anchor date, slot label and
  checklist label. The list has a top inset. Covered by
  `test/shift_editor_test.dart`.

---

## P2 — polish and i18n

### 5. Stats "BY DAY" card looks empty at zero data

- **Screen:** Stats → Month
- **Evidence:** a card containing only the `BY DAY` label; the chart is
  invisible because every zero bar is 3 px tall in `c.surfaceHigh` on a
  `c.surface` card.
- **Cause:** `_BarChart` (`lib/features/stats/pages/stats_page.dart:554-593`)
  paints zero values in `c.surfaceHigh`; the 8 sp first/last labels are barely
  visible.
- **Fix:** show a small "No data in this range" line (or hide the section) when
  every value is zero; increase zero-bar contrast if the chart stays.
- **Status (2026-11-21):** Fixed. The BY DAY card shows "No data in this
  range." when every bar is zero. Covered by `test/things_to_fix_p2_test.dart`.

### 6. Tag vs category terminology is inconsistent in the UI

- **Screens/sheets:**
  - top-bar filter: `Filter by tag`, `Manage tags`
  - manager page: `Categories`
  - entry editor: `Categories`
  - ARB ids and some copy still use `tag` / `tags`
- **Cause:** mixed strings in `lib/features/tags/pages/tags_page.dart`,
  `lib/features/tags/widgets/tag_filter_sheet.dart`,
  `lib/features/tags/widgets/tag_editor_sheet.dart` and
  `lib/screens/entry_editor.dart:405`.
- **Fix:** choose one user-facing term (the project docs use **Tags**), update
  the ARB entries for English and Spanish, and reuse them everywhere.
- **Status (2026-11-21):** Fixed. The manager, editor and entry chips now use
  the existing `tagsManager`, `addTag`, `editTag`, `tagName` and `noTags`
  entries. Covered by `test/things_to_fix_p2_test.dart`.

### 7. Bottom navigation labels will truncate in Spanish (verify)

- **Screen:** shell bottom nav
- **Evidence/prediction:** six destinations share a ≈276 dp pill, so each slot
  is ≈46 dp. `Estadísticas` at 10.5 sp cannot fit with
  `maxLines: 1` + `TextOverflow.ellipsis`
  (`lib/core/widgets/sundial_nav_bar.dart:152-160`). Not yet reproduced in
  Spanish; it is a layout-math finding.
- **Related:** `TextScaler.noScaling` means nav labels ignore accessibility text
  size.
- **Fix:** test Spanish at 360 dp; shorten the label (e.g. "Datos"), allow two
  lines, or revisit the six-tab split. Decide the text-scaling policy.
- **Status (2026-11-21):** Fixed. Spanish uses "Datos". Nav labels now honour
  text scaling up to 1.3× and then shrink to the slot instead of ellipsizing.
  Covered by `test/things_to_fix_p2_test.dart` at a 278 dp bar width.

### 8. Preferences "Time zone" subtitle is truncated

- **Screen:** Settings → Preferences
- **Evidence:** `Zone for new timed entries. Display follo...` because the
  `America/Caracas` value takes the right side of the row.
- **Fix:** allow the subtitle two lines, move the value below the title, or
  shorten the copy.
- **Status (2026-11-21):** Fixed. `SettingsNavRow` gained `valueBelow`; the time
  zone row puts `America/Caracas` under the title so the subtitle keeps the
  full width. Covered by `test/things_to_fix_p2_test.dart`.

### 9. Search hint is truncated

- **Screen:** Search
- **Evidence:** `Search entries, tags and home it...`.
- **Fix:** minor; use a shorter hint (`Search entries, tags, items`) or let the
  field expand. The empty state already carries the longer explanation.
- **Status (2026-11-21):** Fixed. The hint is now `Search entries, tags, items`
  in English. The first Spanish wording still ellipsized on the 360 dp phone, so
  it is now `Busca entradas, etiquetas` and was re-checked on the device.

### 9b. Pairing copy is truncated on the phone

- **Screens:** Settings → Devices & Sync (subtitle), Pair a device (code helper)
- **Evidence:** `Pair your own devices over the local n...` and
  `Enter the six-digit code shown o...`.
- **Fix:** allow the subtitle two lines, shorten `devicesSubtitle`, and give the
  code helper a second line or a shorter wording.
- **Status (2026-11-21):** Fixed. `SundialPageHeader` subtitles wrap to two
  lines. The old OTP copy (`pairCodeHint`) is no longer rendered because the
  protocol 4 pairing request flow replaced it. Covered by
  `test/things_to_fix_p2_test.dart`.

### 9c. Shift pattern editor has no save action at the top

- **Screen:** Shifts → Edit shift pattern (new and existing patterns)
- **Evidence:** the header holds only the delete icon. `Save pattern` is a
  `FilledButton` at the very bottom of the page, below every cycle day, the
  exceptions, the checklist and the preview — several screens of scrolling on
  a 7-day cycle. The request from the walkthrough is a save action in the
  header, next to delete.
- **Cause:** `shift_pattern_editor_page.dart:225-232` fills `actions` with the
  delete `GlassIconButton` only; the save button is built at
  `shift_pattern_editor_page.dart:463-475`. The shell has no editor
  save-in-header pattern to reuse yet.
- **Fix:** add a header action that calls the existing `_save`
  (`shift_pattern_editor_page.dart:734`), disabled while `_saving`, with
  `l10n.savePattern` as its label/tooltip so Spanish keeps coming from the
  ARB. Check the GymMane/Streak editor header for the exact action shape
  before picking an icon, and either keep the bottom button as the primary
  affordance or drop it — not two save paths with different validation.
- **Test:** widget test taps the header save with an empty name and asserts
  the validator error; taps it with a valid draft and asserts the pattern is
  stored and the page pops.
- **Status (2026-11-21):** Fixed. The header now has a check action with the
  `savePattern` tooltip. The bottom button stays as the primary affordance and
  both call the same `_save`. Covered by `test/shift_editor_test.dart`.

---

## P3 — product gaps / decisions

### 10. No Week view on phones

- **Screen:** Plan
- **Evidence:** on widths < 1024 dp the switch is Month/Day only
  (`lib/features/plan/pages/plan_page.dart:661-669`); Week exists only on
  desktop. The README/roadmap still describe month, week and day calendar
  modes.
- **Decision needed:** add Week to the phone switch or document the deviation
  and update the roadmap.
- **Status (2026-11-21):** Fixed. Phones now offer Month, Week and Day. Week
  uses the vertical seven-day agenda rather than the desktop grid, and the
  switch moves to its own toolbar row on narrow widths. Covered by
  `test/things_to_fix_p3_test.dart`.

### 11. Space pages require a "first job/home/person" before tasks

- **Screens:** Work / Home / Personal empty states
- **Evidence:** the primary CTA creates a job/home/people context; the pages
  report "No jobs yet" / "No homes yet" / "No people or groups yet".
- **Question:** confirm this hierarchy is intended (especially for Home, where
  inventory and shopping are independent of a home context) and update the
  docs/copy if it is.
- **Status (2026-11-21):** Fixed. The empty state leads with “Add a task” and
  keeps “Create the first one” as the secondary action. The Home hint now says
  inventory and shopping work without a home context. Covered by
  `test/things_to_fix_p3_test.dart`.

---

## LAN sync — verified working, with important gaps

Test method: Linux debug bundle and the Android debug APK on the same
192.168.0.0/24 LAN. Linux as pairing host, phone as guest (code 914317).
Result: pairing succeeded; both databases contain a `paired_device_records` row
with the same shared key and each other's certificate fingerprint. The phone's
`remote_snapshot_records` contains the laptop payload (`spaces` 3, `tags` 6,
`home` 1 — the laptop's **Eggs** inventory item at 4 pieces, low stock). The
laptop's snapshot of the phone persisted too. The data itself syncs. A manual refresh at `23:30:43` wrote the same timestamp
to the phone's `paired_device_records.last_seen_at` and
`remote_snapshot_records.fetched_at`; the parsed payload contained the laptop's
`Eggs` item. The gap is scope and presentation, not transport.

The gaps below are in the pairing UI and the snapshot display, not in the
transport. Pairing, refresh, restart recovery and offline handling all worked.

### 12. (P1) The Devices empty state falsely claims discovery is unavailable

- **Screens:** Settings → Devices & Sync on Android and Linux, before the first
  pairing.
- **Evidence:** both apps showed `No paired devices yet. Network discovery is
  unavailable. Use the address manually.` even though the Pair page immediately
  discovered the other device and pairing worked. No separate warning notice
  was present.
- **Cause:** `_DevicesBody` uses `l10n.discoveryUnavailable` as the empty-state
  message whenever the paired-device list is empty
  (`lib/features/sync/pages/devices_page.dart:209-218`). The real warning is a
  separate `SundialNotice` above it, shown only when
  `!state.discoveryAvailable && state.running`.
- **Impact:** users are told discovery is broken and sent to a manual address
  path that does not exist (finding 13), so a working feature looks broken at
  the exact moment a user is setting it up.
- **Fix:** use a neutral empty-state message (`noNearbyDevices` or a pairing
  hint) and reserve `discoveryUnavailable` for the real warning. Add a widget
  test for the empty state with discovery available.

### 13. (P1) Manual host/port pairing UI is missing despite the copy

- **Screen:** Pair a device → Nearby devices
- **Evidence:** the Devices page says `Network discovery is unavailable. Use the
  address manually.` and the ARB still defines `manualAddress`, `hostHint`,
  `address` and `port`, but `_GuestPairingTab`
  (`lib/features/sync/pages/devices_page.dart:740-834`) only renders discovered
  peers. There is no way to type a host or port. On a network that blocks mDNS,
  or a platform without a working daemon, pairing is impossible even though the
  copy tells the user to use an address.
- **Fix:** restore the manual address + port fields and call
  `SyncService.pairWithPeer(host, port, code)`; prefill the port when known.
  Add a widget test that pairs without a discovered peer.

### 14. (P2) Synced inventory is not visible, and contexts/projects/habits are not synced

- **Screen:** Devices → paired device card
- **Evidence:** the phone snapshot contains the laptop's `Eggs` home item, but
  the card only prints `0 entries, 0 shifts today, 0 shopping items open`
  (`lib/features/sync/pages/devices_page.dart:450-465`). The user sees no trace
  of the inventory that actually arrived.
- **Scope gap:** `SyncPayloads.snapshot`
  (`lib/features/sync/remote_payload.dart:157-166`) includes `spaces`, `tags`,
  `entries`, `shifts`, `home` and `shopping`, but no contexts, projects or
  habits. The laptop's five contexts do not sync at all.
- **Fix/decision:** render a synced-inventory summary (low stock, item count) in
  the paired card; decide whether contexts/projects/habits belong in the
  payload, then update the payload, card and docs together.
- **Superseded by the full-sync rework proposal** (`docs/refs/SYNC_REWORK.md`);
  the interim display fix is part of its Phase 0.

### 15. (P2) Android device identity defaults to "localhost"

- **Screen:** Settings → Devices & Sync → identity setup
- **Evidence:** the prefilled device name is `localhost` because
  `IdentityService.defaultDeviceName`
  (`lib/features/sync/identity_service.dart:36-39`) returns
  `Platform.localHostname`, which is `localhost` on Android.
- **Fix:** use a phone-friendly default (`This phone` or the device model) or
  leave it empty with a hint; keep the hostname on desktop.

### 16. (P3) Ephemeral server port is handled, but only while discovery works

- **Evidence:** `LanServer.start` binds port `0` by default
  (`lib/features/sync/lan_server.dart:80`), so every restart picks a new port.
  Tested: after restarting the Linux app the port changed from 46381 to 35035;
  the phone's discovery updated the paired record and the card refreshed
  automatically, and a manual refresh also succeeded.
- **Residual risk:** if mDNS is blocked and discovery is unavailable, a restarted
  peer keeps a stale `host:port`; pairing the manual fallback (finding 13) would
  also need a way to edit the address. Consider a preferred stable port with a
  dynamic fallback, or let the user edit a paired device's address.

### 17. (P3) Paired-device endpoint display is ambiguous for IPv6

- **Screen:** Devices → paired device card
- **Evidence:** after a phone restart, discovery resolved the laptop to an IPv6
  link-local address and the card rendered
  `sundial-test · fe80::dc4d:462a:dd62:f88d:35035`. The port is appended with a
  colon, which is not a valid IPv6 endpoint without brackets.
- **Cause:** `_PairedDeviceCard` builds the string as
  `${device.host}:${device.port}` (`lib/features/sync/pages/devices_page.dart:441`).
  Discovery may switch between IPv4 and IPv6 between refreshes.
- **Fix:** render `[host]:port` for IPv6 (or show the device name plus a
  separately formatted endpoint), and consider preferring IPv4 in discovery.
  Verify `LanClient` brackets IPv6 hosts (it worked in this test, but add a
  unit test for `fe80::` hosts).

### 18. (P1 UX) Pairing takes too many steps and requires typing an OTP

- **Screens:** Devices → Pair → Nearby devices; other device → Show a code →
  PIN → read code → back.
- **Evidence:** pairing a phone and laptop requires discovery on both, switching
  to “Show a code”, entering the host PIN, reading the six digits, navigating
  back on the guest and typing them. The PIN is local and never sent, but the
  flow is easy to abandon mid-way.
- **Proposal:** one pairing request from the initiator; the peer gets an in-app
  Approve/Reject card with the device name and certificate fingerprint, and asks
  for its local PIN only on approval. Both sides show the same short code for a
  final visual check; no OTP typing and no navigation.
- **Constraint:** a request can only arrive while the app is running. A killed
  app has no listener. A five-minute pairing-mode foreground service or a local
  notification while the app is alive is the realistic background option.
- **Full design:** `docs/refs/SYNC_REWORK.md`.

### 19. (Rework) Query-only snapshot cannot sync everything

- **Requirement:** the user needs every job/home/entry/inventory change on both
  devices, editable offline.
- **Why the current system cannot get there:** the snapshot payload omits
  contexts/projects/habits, only displays summary counts, and six synced tables
  (`completion`, `entry_tag`, `habit_completion`, `home_item_location`,
  `shift_pattern_tag`, `shift_checklist_completion`) have no id / `updatedAt` /
  `deletedAt` metadata to diff or tombstone.
- **Proposal:** full replica sync with a per-device change log, HLC versions,
  tombstones, pull-only deltas, LWW per row, and a v9 migration.
- **Full design, phases and open decisions:** `docs/refs/SYNC_REWORK.md`.

## Fixed in the 2026-11-21 P3 pass

- [x] Phones had no Week view.
- [x] Space pages required a job/home/person before showing a task action.

## Fixed in the 2026-11-21 P2 pass

- [x] Stats BY DAY card looked empty at zero data.
- [x] Tag vs category terminology was mixed.
- [x] Spanish bottom navigation labels could truncate.
- [x] Preferences time-zone subtitle was squeezed by its value.
- [x] Search hint was truncated.
- [x] Pairing/page subtitles were clipped to one line.
- [x] Shift editor had no save action in the header.

## Fixed in the 2026-11-21 P1 pass

- [x] Today weekday wraps mid-word at 360 dp.
- [x] Search empty state overflows above the keyboard.
- [x] Today repeats the empty sentence three times.
- [x] Reminder labels use “1 hours before”.
- [x] Shift editor mixes floating labels with captions and clips its first
      label.

## Implemented in this pass

- [x] Shift editor: **Add a slot** on an empty day now copies the nearest
      previous day's slots (label, start and end). A day that already has slots
      keeps the default times for an additional slot. The day button has a
      stable key for tests; regression coverage is in
      `test/shift_editor_test.dart`.

## Verified OK during this walkthrough

- Entry-editor autofocus lands in the title field (typing test).
- Today's date, weekday and the day-view "now" line are consistent with the
  device clock in `America/Caracas`.
- No app crashes or unhandled exceptions in logcat during the walkthrough.
- The app installs and launches on the MAR LX3A; version 0.9.0.
- LAN pairing with the Linux app succeeded: matching shared keys and certificate
  fingerprints were stored on both sides. mDNS discovery found each peer.
- The read-only snapshot persisted on the phone and contains the laptop's
  spaces, tags and inventory (`Eggs`, 4 pieces, low stock). The laptop's local
  plan was untouched.
- The phone showed the paired device's last-seen time, entry/shift/shopping
  counts and a working per-device refresh action.
- After a Linux app restart the server port changed (46381 → 35035); the phone
  picked up the new port from discovery and refreshed automatically.
- After a **phone** app restart (force-stop), the identity, paired device and
  snapshot persisted; the server got a new port (34817 → 43253), discovery
  updated the laptop endpoint and the card refreshed automatically.
- With Wi-Fi off, the phone showed `The device is offline`, kept the last
  snapshot and kept the local planner usable; after Wi-Fi returned and a
  refresh, the card recovered.

## Device verification (2026-11-21)

Phone: HUAWEI MAR-LX3A, Android 10, debug 0.9.0. Desktop: Linux debug bundle on
the same LAN. The phone runs at 360 dp.

- **P1.** Today keeps the weekday on one line in English and Spanish. The search
  empty state fits above the keyboard. Reminder chips read “1 hour before” and
  “1 hora antes”. The shift editor uses caption labels above its fields, has no
  clipped labels, and exposes the save action in the header.
- **P2.** Stats shows “No hay datos en este periodo.” at zero data. Tags are
  “Etiquetas” throughout the manager, filter and settings. The Spanish six-tab
  bar fits at 360 dp. The time-zone row puts `America/Caracas` below the title.
  The search hint fits in both languages after the second Spanish shortening.
  The Devices subtitle wraps and the auth copy is gone with the protocol 4
  flow.
- **P3.** Phone Plan switches between Month, Week and Day; the Week agenda is a
  vertical seven-day list. The job page leads with “Añadir una tarea para Pida
  Pizza”; the empty-state action is covered by the widget test.
- **Devices and pairing.** Manual host/port entry is present. The identity is
  “muffin · Huawei P30 Lite”, not `localhost`. Paired endpoints render as
  `192.168.0.110:port`. Spanish Devices, nearby pairing and device-address
  screens fit at 360 dp.
- **Replica sync.** Phone and desktop (protocol 4, same identity) converged. A
  test entry created on the phone reached the desktop through the scheduled
  pull; its completion and then its deletion propagated as a soft delete plus
  tombstone without opening Devices. The phone shows the desktop's “Huevos”
  inventory row, so replicated inventory is visible in the normal Home screen.
- **Not re-run.** Pairing approval/rejection from a clean pair, source
  replacement, IPv6-only endpoint display, image sync and the background
  listener limit. Desktop screenshots are unavailable in this Wayland session;
  the desktop pass was launch, logs and database verification.

## Still to verify

- Automatic sync after a network change without opening the Devices page
  (startup and scheduled pulls are verified; the network-change trigger was
  not observed).
- Two-device pairing approval/rejection from a clean pair, source replacement
  and image sync.
- Real-device notification, reboot and timezone checks from the v1.0 device
  checklist.
