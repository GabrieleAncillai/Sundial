# Progress log

Keep this file current. A fresh context window should be able to resume from it.

## Current milestone

The sync rework is underway. Phase 0 through Phase 5 of the sync rework
shipped on 2026-11-21, including content-addressed media sync. The remaining work is the real-device multi-device and image pass,
removing the transitional read-only snapshot path, and the optional Phase 4
background listener.

Aero 2.0 shipped on 2026-11-23 as a first-class, brightness-aware style system;
see the new entry below and `docs/aero-2.md`. The earlier “stop gate” notes are
historical.

## 2026-11-23 Aero 2.0 style system shipped

- **Architecture.** Added `SundialStyle` / `SundialStyleTheme` and the
  `SundialVisualStyle { classic, aero }` enum. Brightness is now `themeMode`;
  the legacy `themeVariant = aero` row migrates to `visualStyle = aero` with
  light brightness. Components branch on feature getters such as
  `hasSurfaceGradient`, not on a style name, so a future Cyberpunk pack is a
  data change plus one environment painter.
- **Palette and type.** Aero light/dark palettes derived from the checked
  tokens; Open Sans (OFL) for Aero, Nunito for Classic. All component text
  styles carry the resolved family.
- **Environment and components.** Procedural sky, horizon, water bands and
  drifting bokeh; glass rail/nav/sheets/fields; glossy cards, task rows,
  calendar blocks, month/week date cells, switches, segmented controls,
  progress and add button; original sundial orb mark and glossy glyphs.
- **Settings.** Separate Style and Brightness rows, Aero light and dark, legacy
  migration, updated English/Spanish ARB strings and search keywords.
- **Evidence.** `test/style_system_test.dart`, expanded
  `test/aero_contrast_test.dart`, updated `test/aero_widgets_test.dart`, and
  five real-app screenshots (`v1.2-today-aero.png`, `v2-aero-today-dark.png`,
  `v2-aero-plan-desktop.png`, `v2-aero-settings-mobile.png`,
  `v2-aero-appearance-mobile.png`).
- **Verification.** `flutter analyze` clean; 388 app tests and 107 core tests
  pass; Linux debug and Android debug APKs build.
- **Follow-up (2026-11-23).** The ambient loop now completes whole motion cycles
  over a 256 s loop (`AeroMotion`), removing the visible cut at the repeat seam.
  The bottom tab row is inset so the selected lens stays inside the shelf's
  rounded corners; the lens uses the 24 dp card radius, spans its slot and fits
  the longest Spanish label. Below a 60 dp slot the six-tab bar drops labels and
  grows the icons from 22 to 26 dp, keeping the name in semantics and a tooltip.
  The docs screenshot harness now captures with production shadow blur
  (`debugDisableShadows = false`), because Flutter's test binding otherwise
  removes the blur and makes shadows look harder than the running app.
  `test/aero_background_test.dart`, the nav-lens geometry test and the compact
  nav test cover the fixes; 392 app tests pass.
- **Open.** The user's real-device visual and blur-performance pass is in
  `docs/device-checklist.md`. The Aero sound pack is unchanged.

## 2026-11-21 Device verification and tree cleanup

- **Phone pass.** HUAWEI MAR-LX3A, Android 10, debug 0.9.0 at 360 dp. Verified
  the P1 and P2 layouts, the Spanish six-tab bar, the phone Month/Week/Day
  switch, the job-page task action, the Devices copy, manual host/port entry,
  the non-localhost identity and Spanish Devices/pairing screens at 360 dp.
- **One regression found and fixed.** The first Spanish search hint still
  ellipsized on the device. It is now `Busca entradas, etiquetas` and was
  re-checked on the phone. `test/l10n_test.dart` follows the new string.
- **Replica sync.** Phone and desktop (protocol 4) converged. A probe entry
  created on the phone arrived on the desktop through the scheduled pull; the
  status change and then the soft delete plus tombstone also arrived without
  opening Devices. The phone shows the desktop's “Huevos” inventory row.
- **Desktop pass.** The Linux debug bundle starts and syncs on the same LAN.
  Wayland blocks the available screenshot tools, so the desktop check is
  launch, logs and database verification, not a visual pass.
- **Not run.** Clean-pair approval/rejection, source replacement, IPv6-only
  endpoint display, image sync and the notification/reboot/battery/widget
  checklist remain open.
- **Validation.** `flutter analyze --no-fatal-infos` clean; 379 app tests and
  107 core tests pass; format check clean; Linux debug and Android debug builds
  pass.

## 2026-11-21 Walkthrough P3 product decisions

- **Phone Week view.** Plan now offers Month, Week and Day on phones. Week uses
  the new `WeekAgenda`, a vertical seven-day list extracted from the old Week
  screen, instead of squeezing the desktop grid into 360 dp. Below 520 dp the
  view switch moves to its own toolbar row so all three segments fit.
- **Space pages.** The empty state leads with “Add a task” (prefilled to that
  space) and keeps “Create the first one” as the secondary action. The Home hint
  now says inventory and shopping work without a home context.
- **Docs.** `README.md` describes the phone week agenda. The P3 entries are
  marked fixed in this log.
- **Validation.** `flutter analyze --no-fatal-infos` clean; 379 app tests and
  107 core tests pass; format check clean; Linux debug and Android debug
  builds pass. New coverage in `test/things_to_fix_p3_test.dart`.

## 2026-11-21 Walkthrough P2 fixes

- **Stats.** The BY DAY card shows “No data in this range.” when every bar is
  zero instead of painting three-pixel bars that disappear into the card.
- **Terminology.** The tag manager, tag editor and entry chips now use the
  existing Tags strings (`tagsManager`, `addTag`, `editTag`, `tagName`,
  `noTags`) instead of the inventory category strings.
- **Bottom navigation.** Spanish uses “Datos”; labels honor text scaling up to
  1.3× and then shrink to the slot, so a six-tab bar no longer ellipsizes.
- **Settings rows.** `SettingsNavRow` gained `valueBelow`; the time-zone row
  puts the zone id under the title, leaving the subtitle its full two lines.
- **Page subtitles and search.** `SundialPageHeader` subtitles wrap to two
  lines, and the search hint is shortened in both languages.
- **Shift editor header.** Added a check action with the `savePattern`
  tooltip; it shares `_save` with the bottom button.
- **Validation.** `flutter analyze --no-fatal-infos` clean; 377 app tests and
  107 core tests pass; format check clean; Linux debug and Android debug
  builds pass. New coverage in `test/things_to_fix_p2_test.dart`, plus the
  header-save case in `test/shift_editor_test.dart`.

## 2026-11-21 Walkthrough P1 fixes

- **Today header.** Below 420 dp the List/Timeline switch moves to its own row,
  so the weekday keeps its display size instead of wrapping mid-word.
- **Today empty state.** The progress card is hidden when there are no tasks and
  the list/timeline fallbacks were removed, leaving one empty-state card.
- **Search.** The prompt is scrollable and goes compact when the keyboard
  shrinks the viewport, so it no longer overflows above the keyboard.
- **Reminders.** English and Spanish ARBs use ICU plurals for minutes, hours
  and days; “1 hour before” is now singular.
- **Shift editor fields.** Added `SundialFieldLabel` and `SundialTextField`, moved
  `SundialDateField` to the caption-above-control idiom, and applied it to the
  pattern name, anchor date, slot label and checklist label. The form has a top
  inset so the first label is not clipped.
- **Validation.** `flutter analyze --no-fatal-infos` clean; 370 app tests and
  107 core tests pass; format check clean; Linux debug and Android debug
  builds pass. New coverage in `test/things_to_fix_p1_test.dart`,
  `test/l10n_test.dart` and `test/shift_editor_test.dart`.

## 2026-11-21 Content-addressed media sync (Design B)

- **Identity and cache.** Context/project images are identified by the lowercase
  SHA-256 of their PNG bytes. Schema v15 adds `image_media_id` to both tables and
  a device-local `media_cache_records` index. `MediaStore` keeps immutable files
  at `.../media/cache/<sha256>.png`; editor deletion refuses cache paths so a
  shared file survives.
- **Merge and payloads.** `image` is an atomic merge group on contexts and
  projects. `image_path` remains device-local and is stripped from snapshots,
  changes, media requests and media responses. Local display paths follow the
  merged id: a cache path when the bytes arrived, null while pending.
- **Protocol 4.** Added signed, paired-only `POST /sundial/v1/sync/media`.
  Requests carry 1–32 hashes (`^[0-9a-f]{64}$`); responses carry base64 PNG data
  or `missing`. The server serves only registered cache files, verifies the hash,
  caps items at 4 MiB and responses at 8 MiB, and never accepts a path. Pairing
  now refuses protocol-3 peers.
- **Pull and replacement.** After a normal pull the engine fetches missing ids,
  verifies and installs them, and links rows to a local path. A fetch failure is
  a per-peer media error; the ids stay pending and are retried on the next pull.
  Source replacement stages and verifies every image before the target is
  cleared, and aborts untouched if any image cannot be verified. Replacement
  keeps the local media cache.
- **Backups.** Schema 15. Context/project JSON carries `imageMediaId`; the media
  map carries display bytes or cache bytes when the display copy is gone. Import
  rebuilds `media_cache_records`; v14 backups compute ids from restored bytes.
- **Migration.** The real v14→v15 test rewinds a file, keeps real display files
  and verifies backfill, cache files and image field versions. Missing and
  corrupt files leave ids null without failing the upgrade.
- **Validation.** `flutter analyze --no-fatal-infos` clean; 365 app tests and 107
  core tests pass; Linux debug bundle and Android debug APK build. New coverage:
  `test/media_store_test.dart`, image add/replace/remove/retry in
  `test/sync_engine_test.dart`, replacement with images and abort in
  `test/sync_replacement_test.dart`, mesh convergence/no-relay in
  `test/sync_mesh_test.dart`, endpoint security in `test/lan_test.dart`, backup
  v15/v14 in `test/backup_test.dart`, and v14→v15 in `test/migration_test.dart`.
- **Remaining.** The physical-device image checklist in
  `docs/device-checklist.md` still needs the user's run.

## 2026-11-21 Sync rework Phase 3: replacement, scheduling and status UI

- **Scheduled replica pulls.** `SyncService` now pulls each paired peer on
  start, resume, discovery, the five-minute timer and manual refresh. Pulls are
  serialized per device, one peer never blocks another, and a failed peer keeps
  its own error and cursor.
- **Source replacement.** A paired peer can replace this device after the local
  PIN is entered. The source snapshot is staged page by page in memory and
  validated; a backup is written first when this device has user data and its
  failure aborts the replacement. The clear-and-apply runs in one transaction,
  adopts the source dataset and `weekStart`, generates a new node id and epoch,
  moves the HLC past the source and records the source cursor. Identity,
  pairing records, MCP token and device-local settings survive. A malformed
  stage leaves the target untouched.
- **Devices page.** The read-only snapshot card is replaced by per-peer sync
  status: last pull, syncing, error, a “different plan” source choice with the
  PIN-gated replace action, and a “replace this device from …” action. Devices
  learned from peers but not directly paired appear in a roster section with a
  pair action.
- **Side effects.** The app shell listens to `SyncService.applyEvents` and
  rebuilds the reminder queue, reloads `weekStart` and refreshes the Android
  home widget after a remote apply.
- **Mesh coverage.** Tests cover three- and four-device convergence, the
  missing-link rule (a peer never relays another device's changes), replacement
  cursor continuation, backup abort, rollback, PIN rejection and
  identity/pairing preservation.
- **Discovery hardening.** mDNS now advertises the server's bound IPv4 in a
  TXT `ip4` attribute and clients prefer it over the resolved host. Avahi on
  Linux was returning an IPv6 link-local address that the IPv4-only listener
  could not answer, which surfaced as “Could not reach the device”. The Linux
  broadcast no longer sets an Avahi host override.
- **Discovery feedback.** The Nearby devices screen now shows an animated
  search state while mDNS is looking, a bounded four-second search card with a
  manual-address hint, a spinner on the refresh action, and a clear
  no-results/fallback card. Verified on the Android device with the desktop
  stopped and running.
- **Validation.** `flutter analyze --no-fatal-infos` clean; 332 app tests and
  107 core tests pass; the Linux debug bundle and Android debug APK build. The
  updated debug APK was installed on the MAR-LX3A, the new Devices page and
  identity setup were exercised, and the on-device DB is schema v14. Nearby
  discovery now resolves the desktop over IPv4 and a pairing request reaches
  the desktop's approval card. A two-physical-device sync pass is still
  required.
- **Transitional.** The old `/sundial/v1/query` snapshot endpoint and
  `remote_snapshot_records` are kept for one release because the MCP adapter
  still shares `remote_payload.dart`. The Devices UI no longer reads them; the
  service only refreshes the preview when a peer serves a different dataset.
  Removing them is a follow-up once the MCP payload helpers move.

## 2026-11-21 Sync rework Phase 2: v14 replica foundation

- **Schema v14.** Added `sync_device_state_records` (node id, dataset id,
  epoch, persisted HLC), `sync_change_records` (local edit feed),
  `sync_field_version_records`, `sync_tombstone_records` and
  `sync_peer_state_records`. Shift slots and exceptions gained stable `sync_id`
  UUIDs, backfilled during the migration. Existing soft-deleted rows get
  tombstones; existing rows get one base field version.
- **Merge mapping.** `sync_field_groups.dart` splits every synced table into
  atomic merge groups (for example `entry.timing` and `homeItem.stock`),
  serializes Drift values to JSON-safe primitives and produces canonical row
  keys. Only `weekStart` is included from settings; context/project image paths
  are stripped from payloads.
- **Write capture.** `AppDatabase` records one HLC version per changed group
  and appends a local change row inside the same transaction. It covers the
  mutating paths added so far, including home side effects and time entries.
  Remote applies, migrations, seeds and imports do not record.
- **Per-row child writes.** Entry tags, reminders, shift slots/exceptions/
  pattern tags and checklist items are added, updated or removed individually.
  The `removedIds`/`previousIds` path stops a stale editor from deleting a
  concurrent addition; a caller that predates sync ids falls back to the old
  replace-all behavior instead of leaving stale rows.
- **Store and engine.** `SyncStore` produces dependency-ordered snapshot pages
  and delta pages, then applies a page in one transaction with per-field HLC
  comparison, tombstones, resurrection, `createdAt` preservation and
  `updatedAt` max. `SyncEngine` pulls a snapshot when needed, follows deltas,
  and falls back to a fresh snapshot when a peer epoch changes.
- **Transport.** Protocol 3 adds signed `POST /sundial/v1/sync/snapshot` and
  `POST /sundial/v1/sync/changes`. Requests sign the body as well as the path;
  the existing pinning, private-address bind, nonce cache and pair-only access
  still apply. `LanClient` implements the transport.
- **Validation.** `flutter analyze --no-fatal-infos` clean; 319 app tests and
  107 core tests pass. New coverage is in `test/sync_clock_test.dart`,
  `test/sync_store_test.dart`, `test/sync_engine_test.dart`, the v13→v14 case
  in `test/migration_test.dart`, and the signed snapshot/changes case in
  `test/lan_test.dart`. Linux and Android builds have not been rerun since the
  Phase 2 edits.
- **Not in this increment.** Source replacement and source selection, wiring
  the engine into the five-minute scheduler, the Devices status UI,
  notification/widget refresh after apply, and the 3/4-device mesh. The
  read-only snapshot card is unchanged until Phase 3.

## 2026-11-21 Sync rework: pairing requests and snapshot enrichment

- **Pairing request flow (protocol 3).** The initiator picks a discovered
  device or enters a manual host/port and sends a request carrying a one-time
  code; the peer shows an in-app approval card with the device name, username,
  fingerprint, code and plan status. Approval requires the peer's own PIN and
  must match the local PIN hash; the PIN never leaves the device. Requests
  expire after five minutes, only one is active at a time and the endpoint is
  rate-limited. The old code-display/code-entry tabs are gone.
- **Plan handshake.** A device-local `syncDatasetId` setting and `hasUserData`
  detection travel in the request and the final pairing response. The approval
  card warns when two devices hold different plans; full sync will ask for a
  source before replacing one. `syncDatasetId` is excluded from backups so a
  restore starts a new dataset. `hasUserData` ignores the seeded spaces,
  default tags and home reference rows.
- **Snapshot card.** The read-only LAN payload now also carries contexts,
  projects and habits, and the Devices card shows context and inventory
  counts. The misleading “discovery unavailable” empty state was replaced.
- **Transport hardening.** `/sundial/v1/pair/request` and
  `/sundial/v1/pair/request/{id}` are new; the final `/sundial/v1/pair` is
  bound to the approved request and a one-time token. The server still binds to
  a private address, the client still pins the certificate, and the query
  replay cache and five-minute clock window are unchanged.
- **Validation.** `flutter analyze --no-fatal-infos` clean; `flutter test`
  (292 tests) and `(cd packages/sundial_core && dart test)` (107 tests) pass;
  the Linux debug bundle and Android debug APK build; the ARB parity and
  widget-literal scanners pass. New coverage is in `test/lan_test.dart`
  (approval, rejection, expiry, one-at-a-time, rate limit, dataset handshake,
  username mismatch), `test/sync_service_test.dart` (polling and completion),
  `test/app_database_test.dart` (dataset id and user-data detection),
  `test/backup_test.dart` (dataset exclusion) and `test/l10n_test.dart`.
- **Next.** Phase 2: schema v14 (`sync_device_state`, change feed, field
  versions, tombstones, peer cursors), HLC and merge-field mapping, write
  capture in `AppDatabase`, per-row child writes, and the snapshot/delta
  endpoints with transactional apply.

## 2026-11-17 Home inventory, shopping and gadgets rework

- **Inventory is product + stock variants.** `home_item_records` gained
  `groupId`; one card groups every size of the same product. Three 5-gallon
  water bottles and four 5-litre bottles are one product with two variants,
  each with its own unit, pack size, quantity, minimum, expiry and locations.
  The editor adds another size without re-entering the product and accepts
  multiple locations per variant.
- **Reference data replaces free text.** New `home_category_records`,
  `home_location_records`, `home_unit_records` and
  `home_item_location_records` tables, seeded through
  `homeReferenceSeeded`. Categories and locations carry an icon and colour;
  units carry a symbol and kind. `HomeReferencePage` creates, renames,
  recolours and deletes them with duplicate-name and delete guards. Existing
  rows are backfilled by name, and deleted rows are not resurrected by text.
- **Household catalog.** `lib/data/household_catalog.dart` ships 124 common
  household goods across 12 categories with EN/ES names and descriptions,
  icons, colours and default category/unit/pack/minimum/shelf life.
  `HouseholdCatalogPage` searches by localized text, shows what is already in
  inventory, reuses an existing product group for another size and still
  accepts a custom item. The catalog pattern adapts GymMane's nutrition
  library; the data and UI are original (see `CREDITS.md`).
- **Shopping is inventory-aware.** Low, empty and expired stock produces a
  suggestion card with per-item and add-all actions. Shopping lines can link to
  an exact variant; checking one restocks that variant, stamps the purchase and
  writes history. Unchecking reverses the quantity recorded at check time,
  even if the line was edited or relinked. Removing a variant unlinks its
  lines. One-off purchases remain a first-class path.
- **Gadgets support the real maintenance loop.** Interval presets, a next due
  date that starts after the actual service, manual rescheduling, a service log
  with note and duration, and an optional completed calendar event with a
  start/end block. Service dates are read in the entry zone (UTC for all-day
  rows), so timezone travel cannot shift an all-day service by a day. Delete
  actions confirm first.
- **Fixes from the quality review.** Quantity labels read `3 Bottle · 5 gal`
  instead of multiplying the pack. Clearing a category or unit persists the
  clear. Linked shopping lines lock the fields the inventory owns. The
  inventory, shopping and gadget pages show a load-error notice instead of
  looking empty. Checkboxes and switches carry semantic labels and 48 dp
  targets. Shopping unit names are localized. Inventory search matches
  localized catalog names, descriptions, units and categories. Removal dialogs
  say “Remove” rather than “Delete”.
- **Schema and data path.** Schema v13 (from v12), with a real v12 fixture
  migration test. Backup, auto-backup, CSV, LAN payload, MCP shopping add and
  global search understand the new fields and reference rows. `clearAllData`
  deletes maintenance logs before entries and reseeds reference data.
- **Docs and captures.** `docs/full-docs.md` section 4.2 and the data model are
  updated; `docs/reference-map.md`, `README.md` and `CREDITS.md` describe the
  rework and the GymMane catalog inspiration. New screenshots:
  `v1.6-home-inventory-mobile.png`, `v1.6-home-catalog-mobile.png`,
  `v1.6-home-shopping-mobile.png` and `v1.6-home-gadgets-mobile.png`.
- **Validation.** `flutter analyze --no-fatal-infos` clean; 271 app tests pass;
  95 core tests pass; the CI format check is clean; Linux debug and Android
  debug APK builds pass; the screenshot suite renders 26 captures. New and
  updated coverage is in `test/home_inventory_v2_test.dart` (19 tests),
  `test/migration_test.dart`, `test/backup_test.dart`,
  `test/csv_interchange_test.dart` and `test/home_tracking_test.dart`.

Open follow-ups: expose manual section ordering (positions are stored), use the
unit kind for purchase rounding, include maintenance logs in the read-only LAN
snapshot, and add widget tests for the reference manager and the log/reschedule
sheets.

## Product-polish baseline

The `feat/product-polish` branch reworks the product surface after v0.9. These
parts are in place and green:

- Responsive shell: bottom navigation on phones, a configurable left/right side
  rail on desktop.
- Today list/timeline switch with progress and friendly task cards.
- Work/Home/Personal space overviews with jobs, homes, people, projects and
  habits. Context detail screens expose shifts, per-day checklists, inventory,
  gadgets, projects and habits.
- Plan page with a full-surface month calendar that folds into the desktop
  week grid or the phone selected-day timeline; the week grid keeps
  drag-to-move, resize and drag-to-create.
- Stats dashboard with PDF summary/detailed reports and CSV export.
- Sectioned settings with search, Aero/light/dark/system themes, background
  styles, text size, date format, navigation side and a performance mode. App
  lock is removed from the product surface.
- V2 delta: Aero now treats shared surfaces as glossy frosted glass and selects
  the Aero interaction-sound pack. Preferences add an opt-in Sound section
  (interaction pack, preview, alarm sound) and a searchable IANA time zone
  picker for new timed entries.
- V2 delta: the entry editor infers scheduled / clock-in / deadline / anytime
  from clearable start and end fields, and uses a Streak-style repeat sheet plus
  repeat-after-completion. Clocking out pauses; the same entry resumes on a
  later day with a second session.
- V2 delta: `showAppSheet` is a bottom sheet on phones and a blurred floating
  dialog on desktop; a shared searchable selector replaces the stock dropdowns
  in the main forms.
- Online master switch gates Devices & Sync and MCP; the MCP port is
  configurable and pairing is discovery-first.
- Schema v9 adds contexts, projects, habits, habit completions, time sessions,
  entry context/project/priority/completedAt and per-day shift checklists,
  with a v8 migration test and a backup round-trip. Schema v10 repairs
  databases written by the earlier draft-v9 build (space units, task sessions
  and integer priorities) and keeps their rows.

Still open: real-device visual pass, Android tablet/desktop layout review,
weekly-grid interaction polish, manual testing of the sticker editor and
report save dialogs on both platforms, and a real-device audio check for the
SoundPool bridge, `aplay` fallback and per-sound notification channels. The old app-lock feature and its tests
are deleted; legacy settings rows are ignored and still excluded from backups.

## 2026-11-16 shared reading pane

- Wide windows now give page bodies the same centred 760 px column that the
  Settings master-detail pane already used. Lists, forms and dashboards keep
  equal gutters instead of stretching cards to the window edge.
- `SundialContentPane` in `lib/core/widgets/sundial_content_pane.dart` wraps the
  shell tabs and every `SundialPage`, so pushed screens inherit the treatment
  without per-page layout code. The settings pane now uses the same widget.
- The Plan page opts out because the month and week grids are canvases that
  need the full width. The shared width lives in `kContentMaxWidth`.
- Updated screenshots: `v1.0-stats-desktop.png` and
  `v1.5-radii-work-desktop.png`.
- Validation: analyze clean, 249 app tests, 95 core tests.

## 2026-11-16 plan month surface and fold

- The Plan page opens on a full-surface month calendar: one stretched cell per
  day, event and shift chips in their space/job colour, a today marker and a
  "+N" overflow count. The fixed-width month sidebar is gone.
- The month folds upward with a clipped-height animation into the full-width
  week time grid on desktop and the selected-day timeline on phones. Phones
  keep a seven-day strip for the selected week above the day lane, so tapping a
  day or stepping across a week boundary keeps the week in view. The bottom bar
  carries the expand/collapse chevrons (a single toggle on phones), Today, and
  a Month/Week or Month/Day switch. Reduced motion snaps without the animation.
- `month_calendar.dart` is the full month widget, `week_day_strip.dart` keeps
  the selected week above the phone day lane, `day_timeline.dart` gains a fill
  mode for that lane, and `plan_page.dart` owns the fold controller and the
  separate month/timeline data ranges.
- The week grid keeps its drag-to-move, resize and drag-to-create gestures and
  gives the all-day row room for three chips. The phone chips drop the clock
  label on narrow cells so the title keeps the space.
- `plan_page_test.dart` covers the month-to-week and month-to-day folds,
  including a mid-animation height assertion.
- Screenshots: `v1.4-plan-month-desktop.png`, `v1.4-plan-week-desktop.png`,
  `v1.4-plan-month-mobile.png`, `v1.4-plan-day-mobile.png` and
  `v1.4-plan-month-dark-desktop.png`.
- Validation: analyze clean, 248 app tests, 95 core tests, Linux debug and
  Android debug APK pass.

## 2026-11-16 appearance palettes and picker

- Space and tag palettes now offer 30+ colours while the original defaults keep
  their order. The context avatar opens the icon picker directly, so the editor
  no longer needs a separate icon row.
- The paper dot pattern is denser and stronger so the background reads on both
  light and dark surfaces.
- The desktop rail search uses the shared full-height pill with a short hint,
  so it no longer clips on the narrow rail.
- `space_editor_test.dart` covers the palette size and the avatar picker.
- Validation: analyze clean, 247 app tests, 95 core tests, Linux debug and
  Android debug APK pass.

## 2026-11-15 overlapping shifts blend

- The desktop week grid and the day timeline no longer split colliding shifts
  into side-by-side lanes. Each shift keeps the full column width, and a shift
  that starts later paints its translucent fill over the one beneath it. The
  shared minutes read as a deeper blended tint with no vertical seam, no step
  and no danger outline.
- Labels that would land on the same pixels stack downward instead of being
  clipped into narrow lanes, so two shifts starting together both stay
  readable.
- `shift_block_layout.dart` orders the blocks for painting and places the
  labels; `shift_block_painter.dart` draws the blend. Unit tests cover the
  ordering, dropped spans and label stacking, and the week-grid and day-timeline
  widget tests assert full-width blocks.
- Entries with a start time and no end render as open-ended blocks in the day
  timeline and week grid instead of zero-height events.
- Week-grid drag and resize previews are pointer-device aware: mouse drags move
  immediately, touch and pen hold first, and trackpad pans scroll without
  creating or moving an entry.
- Cross-pattern overlaps stay allowed and intentional; the editor still blocks
  overlaps inside one pattern.
- Validation: analyze clean, 245 app tests, 95 core tests, Linux debug and
  Android debug APK pass. Updated screenshot:
  `docs/screenshots/v1.0-plan-overlap-desktop.png`.

## 2026-11-13 compliance v2

`feat/compliance-v2` was built from the preserved v1.2 snapshot. The first
compliance wave fixed the data-integrity defects found by the audit:

- Entry edits preserve the four timing shapes and imported provenance; the
  editor no longer invents 09:00/10:00 times. Add-from-unit passes space/unit.
- Read-only imports are guarded in the editor, task cards, repository and
  database. Re-import uses a separate importer write path.
- Schema v10 repairs the draft context/time-entry tables in place and moves
  legacy non-Work shift patterns to Work.
- The online master switch is authoritative; MCP token rotation and port changes
  rebind the running endpoint and reject the old token.
- Completion has one repository path, stops running sessions, scopes recurring
  occurrences and advances maintenance dates.
- Backups accept schema 3–12, embed media as base64 and restore over a populated
  database. Delete-all removes media and automatic backups in a foreign-key-safe
  order.
- LAN binds a private IPv4 interface and the unauthenticated info endpoint no
  longer leaks username/device ID.
- Per-day checklists refresh on date changes; cycle changes clamp stale day
  indexes. Plan uses the 1024 px week-grid breakpoint and aligns the all-day
  gutter. Today's list renders the shift checklist, not only the timeline.
- Stats resolves tracked sessions outside the selected occurrence range, so
  totals and breakdowns reconcile.
- Context/project deletion detaches tasks and hides owned rows; shifts outside
  Work are rejected. Multi-home shopping keeps its home and clear-bought is
  scoped. Low-stock lines keep their home.
- Weekly habit streaks count the current week and consecutive qualifying weeks.
  Habits now carry a weekday schedule (schema v11) and a 12-week history page;
  weekly targets are clamped to the scheduled days and off-days never break a
  day streak.
- Desktop sidebar search is a persistent field with a filter badge; settings
  search indexes individual rows and now scrolls to the matching row with a
  short highlight.
- Desktop time fields share one typed picker with 15-minute snaps, exact minutes
  and keyboard submit; phones keep the platform sheet.
- Reports export a summary CSV as well as the detailed one, both reconciling
  with the tracked total.
- Delete-all reports a partial wipe instead of claiming success; backup media is
  written before the database commit and only media the replaced plan referenced
  is pruned. Import validates enum names, timezones and recurrence JSON before
  writing.
- Draft-v9 gadgets migrate to Home maintenance entries, the v10 repair also runs
  for files a broken v1.2 build already stamped as v10, and mDNS advertises the
  certificate fingerprint plus the device name, never the username or device ID.
- Editing a recurring occurrence writes an override instead of the series, and
  Plan drag/resize keeps an existing override's text.

Validation: analyze clean, 215 app tests, 95 core tests, Linux debug and Android
debug APK all pass. `docs/compliance-matrix.md` records the row-by-row status,
including what is still open.

Aero 2.0 is a stop gate. `docs/aero-2.md` now carries the token candidate in
`lib/theme/aero_colors.dart`, three rendered concept screens
(`docs/screenshots/aero2-*.png`, `tool/screenshots/aero_concept_test.dart`) and
a WCAG contrast table enforced by `test/aero_contrast_test.dart`. The shipped
Aero surface is frozen until the user approves the direction; nothing in the app
imports the new tokens yet.

Screenshot evidence is rendered by `tool/screenshots/screenshot_test.dart` into
`docs/screenshots/v1.0-*.png` plus the v2 captures
`docs/screenshots/v1.2-today-aero.png` and
`docs/screenshots/v1.2-preferences-mobile.png`. That pass fixed narrow desktop entry blocks,
clipped all-day chips, scheduled tasks shown as deadlines, and the day timeline
opening at midnight; it now self-scrolls near the current hour and draws a
separate due marker for deadlines.

The v1.0 device/accessibility/release items from the earlier program remain in
`docs/completion-plan.md`.

## 2026-11-14 shift editor and job colours

- Shift surfaces (Today list, Today/Plan timelines, the desktop week grid and
  the month/week markers) now use the job context colour of each shift pattern
  instead of the generic Work blue. Patterns without a context keep the Work
  colour.
- The desktop time dialog focuses its text field on open and selects the
  prefilled value, so typing replaces the time immediately.
- Leaving the shift editor with unsaved edits asks before discarding them. The
  prompt is skipped when nothing changed, and saving or deleting still closes
  the page without a second confirmation.
- Validation: analyze clean, 219 app tests, 95 core tests, Linux debug and
  Android debug APK pass. Updated screenshots: `v1.0-today-list-light.png`,
  `v1.0-today-timeline-light.png` and `v1.0-plan-desktop.png`.

## 2026-11-14 overlapping shift lanes

- The desktop week grid and the day timeline now split overlapping shifts into
  side-by-side lanes only for the shared slice. The rest of each shift stays
  full width, so a partially overlapping block steps back to full width when
  the collision ends.
- Direct collisions get a single danger outline around the union of their
  slices, so neither shift can disappear.
- The slicing helper lives in `shift_lane_layout.dart` and the stepped painter
  in `shift_lane_painter.dart`, with unit tests and widget coverage for both
  layouts.
- Cross-pattern overlaps stay allowed (they can be temporary or intentional),
  but the calendar now shows the collision rather than silently stacking it.
- Validation: analyze clean, 231 app tests, 95 core tests. Screenshot:
  `docs/screenshots/v1.0-plan-overlap-desktop.png`.

## 2026-11-14 desktop settings master-detail

- On windows at the 900 px shell breakpoint and wider, Settings now keeps the
  section menu and search in a left card and renders the selected panel on the
  right. Phones keep the existing list-to-subpage flow unchanged.
- The desktop menu covers Appearance, Preferences, Data and backup, Online
  functionalities and About. Settings search still indexes individual rows and
  opens the matching section with the row highlighted.
- Appearance, Preferences, Data and About reuse the existing page bodies through
  an embedded mode, so there is one implementation of every setting.
- Validation: analyze clean, 230 app tests, 95 core tests. Screenshot:
  `docs/screenshots/v1.3-settings-desktop.png`.

## Reference notes

- Timezone resolution: Streak `lib/services/notification_service.dart`.
- Notifications, channels, exact alarms, boot receiver: Streak
  `lib/services/notification_service.dart`, `lib/services/reminder_schedule.dart`
  and `android/app/src/main/AndroidManifest.xml`.
- Backup shape and validation: Streak `lib/services/backup_service.dart`,
  GymMane `lib/services/backup_zip.dart` and `lib/state/fit_state.dart` for the
  validate-then-rollback idea.
- Settings shell and row kit: Streak
  `features/settings/pages/settings_page.dart`,
  `features/settings/widgets/settings_rows.dart`, `features/settings/pages/about_page.dart`.
- Localization: both projects use the same `l10n.yaml`; Sundial follows Streak's
  `context.l10n` extension and explicit `en`/`es` supported locales.
- Calendar: Streak `timeline_week_strip.dart`, `activity_calendar.dart`,
  `express_month.dart`. Sundial keeps the month maths and selection model, but
  replaces habit cells with per-space markers and shift bars, and taps navigate
  to a day detail instead of toggling completion.
- Home inventory, shopping, ICS import, interval maintenance, sleep window and
  shift checklists have no equivalent in GymMane or Streak. They are
  planner-specific, implemented in `sundial_core` and the `home_inventory`,
  `import`, `shifts` and `sleep` feature folders. The settings rows, theme and
  localization still follow the reference patterns.
- LAN pairing, query and MCP have no equivalent. Streak's `auto_sync.dart` and
  `folder_sync.dart` exchange backup files through a shared folder; they do not
  discover peers, pin TLS certificates or expose tools. Sundial implements the
  v0.4 transport in `lib/features/sync` and `lib/features/mcp` with standard
  PBKDF2, HMAC, AES-GCM and TLS pinning.

## Decisions

- Keep Drift + Riverpod. The reason is in `docs/full-docs.md`.
- Settings live in the existing `setting_records` table. Keys:
  `themeMode`, `locale`, `weekStart`, `hideWorkSpace`,
  `defaultReminderOffsets`, `syncEnabled`, `mcpEnabled`, `mcpWritesEnabled`,
  `sleepEnabled`, `sleepCommuteMinutes`, `sleepWindDownMinutes`,
  `sleepWakeBufferMinutes`.
- Default week start is Monday. Default reminder offsets are 10 and 60 minutes.
  All-day reminders count from 09:00 in the device timezone.
- Default sleep buffers are 30 minutes commute, 60 minutes wind-down and
  30 minutes wake buffer. The sleep window follows the visible plan and is off
  only when the user turns it off.
- Calendar month grid is six weeks from the week containing the 1st. Week start
  comes from settings. Tapping a day selects it; a second tap is not needed.
- Tags are rows with an optional space. Deleting a tag removes its entry links
  in one transaction. Entry tag links are saved with the entry in a transaction.
- Reminders are offsets stored per entry, with deterministic ids
  (`entryId:offsetMinutes`). The notification queue is rebuilt on start,
  resume, timezone change, and after entry/reminder edits. The horizon is 90
  days with a 500-notification cap.
- Backup is a versioned JSON document (`app: sundial`, `schemaVersion: 5`) with
  every user table, timestamps, IANA zones, recurrence JSON and soft deletes.
  Import validates the envelope before the transaction and rolls back on any bad
  row. `identity_records` and `paired_device_records` are deliberately excluded.
- Localization uses `lib/l10n/app_en.arb` and `app_es.arb`, generated into
  `lib/l10n/app_localizations*.dart`.
- ICS import stores read-only entries with `source = 'ics'`. The external id is
  `uid:<UID>` when present, otherwise a stable
  `fallback:<date>:<startMinute>:<summary>` string. Re-import deduplicates but
  does not update changed events.
- Companion import stores read-only entries with `source = 'companion'` and a
  documented JSON export shape. It also deduplicates but does not update.
- Shift checklist items belong to a pattern and keep their ids across edits.
  Completions are keyed by item id and the shift date in the pattern's timezone.
  Removing an item deletes its completions; renaming it preserves them.
- Pairing identity is one local row: device id/name, username, PBKDF2-SHA256
  PIN hash (210k iterations, 16-byte salt), self-signed RSA-2048 certificate and
  private key, and the MCP token. It is device-local security material.
- Pairing uses a six-digit code valid for five minutes with at most five
  attempts. The code plus both certificate fingerprints derive a PBKDF2 key
  (150k iterations). A random 32-byte shared key is wrapped in AES-256-GCM and
  acknowledged with an HMAC. Queries are signed over method, path, timestamp,
  nonce and body hash; the server keeps a five-minute nonce cache.
- MCP is loopback-only (`127.0.0.1:8765/mcp`), off by default, and requires the
  device bearer token. `initialize`, `ping`, `tools/list` and `tools/call` are
  implemented. Write tools appear only when `mcpWritesEnabled` is on.
- Snapshots from paired devices are display-only and stay in memory. Sundial never
  merges a remote plan into the local one.
- Search reads only non-deleted entries and home items. It matches titles,
  notes, tag names, and home name/category/location/notes; results are grouped
  in the UI.
- The Android home widget uses `home_widget` plus a Kotlin provider. It is
  updated when the app starts or resumes; Android's own minimum refresh period
  is 30 minutes, and the widget is Android-only.
- Accessibility is a first pass: semantics, text scaling in the calendar,
  tooltips and desktop shortcuts. It is not a certified screen-reader audit.
- Release signing is user-provided. The workflow refuses to publish without
  keystore secrets; a local release build without them uses the debug key.

## Work completed

### v0.1.5

- Timezone-aware entries and shifts, Personal/Work/Home, flexible slots and
  exceptions, v1→v2 migration, DST/travel tests.

### v0.2

- Month/week calendar with markers, shift bars, month/week navigation, jump to
  today, selected-day detail and a selected date that survives edits.
- Week navigation and the week-start setting.
- Tags: schema v3, entry links, manager, editor chips and an app-wide tag
  filter.
- Shift-pattern editor: cycles, multiple slots per day, overnight slots,
  free/override/extra exceptions, conflict validation and a 28-day preview.
- Settings: theme, language (system/en/es), week start, hide Work, default
  reminders, tags, shift patterns, backup, sync/MCP switches and About.
- Reminders: multiple per entry, editor chips, Android notification permission
  and exact-alarm handling, stable IDs, a pure schedule planner, rescheduling on
  start/resume/timezone change, and notification taps that open the entry.
- Backup: versioned JSON export, validated transactional import, file picker,
  round-trip test and rejection tests.
- Localization foundation and English/Spanish strings for all shipped screens.

### v0.3

- Schema v4: home items, shopping items, shift checklist items and completions,
  plus entry source/read-only/maintenance columns.
- Home inventory, shopping list, low-stock flow and linked quantity updates.
- Interval maintenance that advances from the actual completion date.
- Sleep window on Today with configurable buffers.
- Per-shift checklists in the editor and day detail, independent per date.
- Local-only ICS import with a documented RRULE subset and dedupe.
- Backup schema v4 and real v3 migration test.

### v0.4

- Schema v5: `identity_records` and `paired_device_records`, with a real v4
  fixture and migration test. Both tables are excluded from backups.
- Local identity setup: username, device name, PIN with PBKDF2 hashing,
  self-signed certificate, MCP token, profile edit and PIN change.
- Pairing: host code sheet with PIN unlock and five-minute expiry; guest sheet
  with discovered peers and manual host/port; fingerprint-bound HMAC, AES-GCM
  key wrapping and an HMAC acknowledgement.
- LAN server: pinned HTTPS; `info`, `pair` and `query` endpoints; signed
  requests with timestamp window and nonce replay cache; read-only resources for
  summary, entries, shifts, spaces, tags, home and shopping.
- LAN client: certificate capture and pinning, pairing, signed queries and
  friendly errors for stale pairing, offline peers and wrong certificates.
- Bonsoir mDNS advertisement and browsing with manual fallback.
- Sync service: start/stop, discovery updates, presence, snapshots, automatic
  refresh on launch, resume, discovery and a five-minute timer, manual refresh
  and per-device errors. Local plan untouched when a peer is offline.
- Devices page: identity setup, identity card, paired devices with snapshots,
  refresh, unpair and pair flows. MCP page: endpoint, token, copy, rotate and
  write-tool switch.
- MCP server: loopback HTTP, bearer token, JSON-RPC initialize/ping/tools,
  `personal.today`, `work.next_shifts`, `home.shopping`, and gated `plan.create`
  and `plan.complete`.
- Companion JSON export import with fixtures, dedupe, read-only rows and a space
  choice.
- Android permissions for LAN and multicast; MCP remains loopback-only.

### v0.5

- Global search over entry titles/notes, tag names and home name, category,
  location and notes, with grouped results and a debounced screen.
- Android home-screen widget: `home_widget` bridge, Kotlin provider, layout,
  widget info and manifest receiver. It shows today's plan, the next shift and
  the update time.
- Error banners on Calendar and Week; the search screen has prompt, loading,
  error and no-results states.
- Semantics for shift tiles and week days, scaled calendar cell heights,
  Ctrl+F search and Ctrl+1..3 tab shortcuts.
- English/Spanish ARB parity and a scanner that rejects new user-facing string
  literals in widgets.
- Recurrence count ordinals are constant-time; a year of a long-running daily
  rule expands under a regression threshold.
- Release workflow and `docs/release.md`: keystore secrets, split-per-ABI APKs,
  Linux bundle, checksums and GitHub release.
- Tests: 85 app/database/widget tests and 71 core tests.

### v0.6

- Completion program and compliance audit added: `docs/completion-plan.md`,
  `docs/compliance-audit.md`.
- Android cloud backup and device transfer disabled for the app's data, with a
  data-extraction rule. User-exported JSON remains the only backup path.
- CI now checks formatting and builds a Linux debug bundle; Zed has a
  `verify: all` task and a format-check task.
- Documentation truth pass: v1.0 scope, known gaps and reference-map claims now
  match the code.
- Bundled Nunito (the GymMane face) with a display/headline/title/body/label
  scale in `lib/theme/app_typography.dart`.
- Rewrote `SundialColors` as the single palette (space, state, glass, nav and
  shadow tokens) and rebuilt `SundialTheme` with app bar, card, sheet, dialog,
  snack bar, navigation bar, button, input, chip, switch, date and time picker
  themes. Screens read `context.mc`, not generated Material roles.
- Added the shared UI kit under `lib/core/widgets`: `SoftCard`, `AppSheet`,
  `SectionLabel`, `Pressable`, `GlassIconButton`, `GlassPill`, `TinySwitch`,
  `GlassSurface`, `AppEmptyState`, `SundialNotice`, `FadeThrough`, `SundialPage`,
  `SundialAddButton`, `SundialNavBar`, `SundialSegmented`, `SundialSearchField` and the
  dotted `AppBackground`.
- Replaced the stock shell with a transparent scaffold, paper background, custom
  header, floating nav and companion add button. Ctrl+1..3 and the tag filter
  still work.
- Swept Today, Week, Calendar, Settings, Tags, Shift patterns, Home inventory,
  Shopping, Devices, pairing, MCP, Search and About onto the kit. Entry, shift,
  tag, reminder and household sheets use `showAppSheet`.
- Added `test/visual_kit_test.dart` (theme tokens, kit behaviour, nav selection,
  custom page header, sheet handle) and rendered reference screenshots to
  `docs/screenshots/`.
- Validation: format clean, analyze clean, 90 app tests and 71 core tests pass,
  Linux debug and Android debug APK build.

### v0.7

- Day timeline: 24-hour view in Calendar's Day mode, shifts drawn behind
  entries, all-day chips above it, a now line and per-shift checklists. The
  screenshot is `docs/screenshots/v0.7-calendar-day-light.png`.
- Multi-day timed entries: `endDate` is now valid for timed rows, end instants
  resolve on the end date, and the expander emits each displayed day (including
  overnight tails).
- Recurrence: `skipDates`, `RecurrenceOverride` (moved or time-changed
  occurrences), ordinal weekdays (`1MO`, `-1FR`), negative `BYMONTHDAY` and
  `BYSETPOS`, with JSON round-trip and DST-safe expansion.
- Entry editor: optional end date, skip-this-occurrence toggle and an
  only-this-occurrence mode that writes a recurrence override.
- Shift patterns carry tags and optional commute/wind-down minutes. The global
  tag filter now filters shifts as well as entries. The editor exposes both.
- Per-slot checklists: schema v6 adds `slot_key` to completions, the real v5
  fixture is migrated by assigning legacy ticks to the first slot, and two slots
  on one date keep independent ticks.
- ICS export in `features/export`: read-only VCALENDAR for entries (with RRULE,
  EXDATE and RECURRENCE-ID), multi-day dates and concrete shift blocks.
- ICS import hardening: `EXDATE`, `RECURRENCE-ID` cancellations and moves,
  Windows TZID aliases, vendor-prefixed TZIDs, multi-day timed events and
  update-on-reimport.
- Schema v6 adds `shift_pattern_tag_records`, `commute_minutes`,
  `wind_down_minutes` and the per-slot key. Backup schema 6 exports the new
  fields and table.
- Tests: 98 app/database/widget tests and 82 core tests.
- Validation: format clean, analyze clean, both suites pass, Linux debug and
  Android debug APK build.

### v0.8

- Schema v7 adds `shopping_item_records.position` and `home_purchase_records`,
  with a real v6 fixture (`test/fixtures/schema_v6.sql`) migrated to the current
  schema. Purchase history is written by linked shopping check-offs and manual
  stock increases; unchecking reverses the quantity and removes that history
  row.
- GymMane import in `features/import/gymmane_import.dart`: reads `weeklyPlan`,
  `routines` and `trainAt`, writes read-only weekly Personal blocks, skips
  archived and unknown routines, deduplicates by routine/weekday, and falls back
  to all-day blocks when `trainAt` is missing. The documented input is the JSON
  payload (`gymmane.json`).
- Automatic backups in `features/backup/auto_backup_service.dart`: one JSON copy
  per local day under the app support `backups` folder, rotation to the
  configured count, and manual export unchanged as the canonical path. Wired to
  app start and resume.
- Backup import accepts schema versions 3–8. Missing tables and fields in older
  payloads become empty defaults. App-lock settings (salt, hash, misses,
  blocked-until) are excluded from export, so a restored install starts
  unlocked.
- CSV in `features/export/csv_interchange.dart`: entry export/import with space,
  kind, all-day or timed values, end date, timezone, status, recurrence JSON,
  tags and notes; shopping and inventory export/import with dedupe. Shopping
  groups by the linked home item's category/location, clears bought lines and
  supports move up/down.
- Home tracking: inventory quick ±1 adjustment and a purchase-history sheet;
  a dedicated maintenance page with due/upcoming groups and one-tap completion;
  the low-stock card now states the count as well as the names.
- App lock in `features/app_lock`: PBKDF2 salt/hash in device settings, a PIN pad
  adapted from Streak's `pin_pad.dart`, a two-step setup page, a 30-second
  resume grace and a 30-second lockout after five misses. The About/data
  section documents that the lock is optional and has no recovery code.
- Screenshots: `docs/screenshots/v0.8-shopping-light.png`,
  `v0.8-maintenance-light.png` and `v0.8-pin-setup-light.png`.
- Tests: 121 app/database/widget tests and 82 core tests.
- Validation: format check clean, analyze clean, both suites pass, Linux debug
  and Android debug APK build.

### v0.9

- Schema v8 adds `reminder_records.time_minute` and `remote_snapshot_records`,
  with a real v7 fixture (`test/fixtures/schema_v7.sql`) migrated to the current
  schema. LAN snapshots store the raw read-only payload, are restored on start
  and are pruned for unpaired devices.
- MCP adapter: `plan.range`, `plan.search`, `plan.get`, `work.shifts`,
  `home.inventory`, `tags.list`, `sleep.window`, plus gated `plan.update`,
  `plan.uncomplete`, `plan.delete`, `home.shopping_add` and
  `home.shopping_check`. `initialize` returns `Mcp-Session-Id`; sessions expire
  after an hour, `DELETE /mcp` closes one, and `text/event-stream` clients get
  one SSE message per call. The MCP page lists the surface.
- LAN: the `snapshot` resource returns the compact summary plus spaces, tags,
  the next week of entries and shifts, inventory and shopping. The Devices page
  keeps the last snapshot after a restart and while the peer is offline.
- Work hours and quiet hours: settings, time pickers, aggregate-screen Work
  filtering (deadlines stay visible), and reminder-planner suppression at each
  notification's local fire time. Custom reminder times are stored as
  `time_minute`; the editor and reminder sheet support offsets and times.
- Android notification actions: snooze (10 minutes) and complete. The payload
  carries the occurrence date, so completing one recurring occurrence is
  correct; cold-start actions are handled at bootstrap.
- Screenshots: `docs/screenshots/v0.9-settings-hours-light.png` and
  `v0.9-reminders-light.png`.
- Tests: 131 app/database/widget tests and 85 core tests.
- Validation: format check clean, analyze clean, both suites pass, Linux debug
  and Android debug APK build.

### v1.0 device verification (in progress)

- 2026-11-09: HUAWEI MAR-LX3A, Android 10 / API 29, debug 0.9.0+9. Full log in
  `docs/device-run-2026-11-09.md`.
- Fixed: the app-lock gate moved into `MaterialApp.builder`, above the Navigator,
  so Settings and other pushed routes cannot cover the PIN pad. A regression
  test locks, pushes a route, resumes and asserts the gate still covers it.
- Fixed: notification actions use the foreground path (`showsUserInterface`),
  and a resume rebuild cancels only planner-owned IDs so a one-off snooze
  survives. Timezone lookup uses `timeZoneLocation()` and scheduling errors are
  logged.
- Fixed: CSV entry import now uses `hasEntryLike(...)`, matching any live entry
  by title, space, date, all-day flag and minutes, not only earlier CSV rows.
  The same CSV re-imported on the phone reported 0 imported, 7 duplicates and
  left 7 entries.
- Passed on the device: first launch/About, notifications on API 29 (delivery,
  grouping, taps, edit time, custom time, quiet/work suppression, snooze,
  complete), timezone travel, LAN pairing with manual host/port, MCP including
  session `DELETE` and linked inventory, JSON backup/import, and app lock.
- Blocked or failed: the widget needs the user's launcher; OEM battery needs the
  EMUI path; reboot fails because EMUI does not deliver `BOOT_COMPLETED` even
  with the app whitelisted and auto-launch enabled. Opening Sundial rebuilt the
  queue without duplicates.
- Tests: 135 app/database/widget tests and 85 core tests.
- Validation: format check clean (144 files), analyze clean, both suites pass,
  Linux debug and Android debug APK build.

## Known limitations

- The 2026-11-09 real-device run passed install, notifications on API 29,
  timezone, LAN, MCP, backup/CSV and app lock. The Android 13 permission and
  Android 12 exact-alarm paths are N/A on that API 29 phone and are covered by
  the Pixel 9 emulator baseline. The widget and OEM battery checks still need
  the user.
- Reboot rescheduling fails on EMUI 10: the queued alarms are persisted in
  `scheduled_notifications.xml`, but `BOOT_COMPLETED` does not reach the plugin
  receiver after a reboot. A manual launch rebuilds the queue without
  duplicates. This is documented as an OEM limitation, not a pass.
- Automatic backup rotation is implemented and unit-tested; pruning older copies
  was not forced on the device by changing the clock.
- The Android manifest has the plugin boot receiver. A separate
  `TIMEZONE_CHANGED` receiver is not implemented; the app rebuilds the queue on
  resume and after the device zone is re-read.
- The notification channel name is English at the OS level; in-app strings are
  localized.
- Backup import accepts schema versions 3 through 8. Versions 1–2 are rejected
  because they predate timezone-aware entries. Import still replaces the local
  plan rather than merging it.
- Automatic backups run on app start/resume, once per local day. A long-running
  foreground session without a resume does not trigger a new copy.
- GymMane import reads the JSON payload, not the zip container; `planMoves`
  per-date overrides are ignored, and a timed block is one hour because GymMane
  stores no duration.
- Linux file export depends on zenity/kdialog through `file_picker`.
- ICS import still does not support `BYHOUR`/`BYMINUTE`, multiple
  `BYMONTHDAY` values, `EXRULE`, floating time without a TZID default that the
  user can control, or non-IANA zones outside the built-in Windows alias table.
  Unsupported events are reported as skipped.
- Multi-day recurring timed entries have a single end offset; moving one
  occurrence with `RECURRENCE-ID` carries the moved date but not a changed end
  date.
- Shift checklist completions are now keyed by pattern, date and slot. Legacy
  pre-v6 ticks are assigned to the first slot of that date.
- The visual layer follows the references: Nunito, tokens, component themes,
  the shared kit and the floating shell.
- ICS export is shipped. GymMane schedule import is shipped as a read-only
  JSON adapter in v0.8.
- MCP is loopback-only and exposes the full v0.9 tool set behind the write
  switch. Streamable HTTP is one SSE message per call; sessions are in memory
  and `GET /mcp` is rejected.
- LAN snapshots are persisted read-only and restored after a restart; they are
  never merged into the local plan. A companion app's ContentProvider is not
  integrated because no app and authority were specified; the documented JSON
  export is the v0.4 path and the GymMane JSON import is the v0.8 path.
- mDNS depends on the platform daemon (Avahi on Linux, NSD on Android). The
  phone reports "Network discovery is unavailable", so manual host/port is the
  verified fallback. Pairing sessions live in memory and are cancelled by an app
  restart.
- The Android home-screen widget refreshes when the app starts or resumes; it
  is Android-only and has no configuration screen.
- Accessibility is a first pass, not a certified screen-reader or contrast
  audit.
- The app lock has no recovery code; clearing app data is the only reset. The
  lock hash is deliberately absent from backups.
- Work-hours hiding applies to Today, Week and Calendar outside the window.
  Work deadlines stay visible; search and opened entries are never filtered.
- Quiet hours and work hours suppress notifications when the queue is rebuilt;
  Settings rebuilds it immediately. A reminder scheduled before an external
  change can still fire until the next launch/resume rebuild.
- MCP sessions live in memory and expire after one hour. Streamable HTTP is one
  SSE message per call, not a long-lived bidirectional stream; `GET /mcp` is
  rejected.
- Android notification action labels are English at the OS level; buttons are
  Android-only.
- Remote snapshots are display data only and are never merged into the local
  plan. They are pruned when a device is unpaired.
- Release signing is a user-provided keystore step; local release builds fall
  back to the debug key and are not production releases.

## Next three steps

1. Add the Sundial widget on the phone and finish the OEM battery path, then record
   both in `docs/device-run-2026-11-09.md`.
2. Run the accessibility/contrast pass and fix what is fixable.
3. Tag v1.0 only when every scenario in `docs/completion-plan.md` passes and a
   signed release succeeds.

## Commands and results

- `flutter pub get` — ok.
- `dart run build_runner build --force-jit` — ok.
- `flutter gen-l10n` — ok.
- `dart format --line-length 110 --output=none --set-exit-if-changed` — clean
  (143 hand-written Dart files; generated `.g.dart` and ARB outputs excluded,
  matching CI).
- `flutter analyze --no-fatal-infos` — no issues.
- `flutter test` — 135 passed (database, migrations v1→v8, timezone, calendar,
  tags, reminders and custom times, backup and pairing-secret exclusion, shift
  editor and checklists, home inventory and purchase history, shopping grouping,
  app lock and the pushed-route regression, ICS, CSV including same-plan
  dedupe, GymMane import, companion import, pairing crypto, certificates, TLS
  pinning, replay rejection, MCP tools/sessions/SSE, sync orchestration and
  snapshot persistence, search, widget data, notification actions, l10n
  enforcement and widget flows).
- `(cd packages/sundial_core && dart test)` — 85 passed (recurrence including
  constant-time ordinals, expansion, shifts, timezones, local windows, sleep).
- `flutter build linux --debug` — ok, including the Bonsoir plugin.
- `flutter build linux --release` — ok.
- `flutter build apk --debug` — ok with Java 21 and core library desugaring.
- `flutter build apk --release --split-per-abi` — ok for armeabi-v7a, arm64-v8a
  and x86_64 with the local debug-key fallback; CI requires the real keystore.
- Linux launch with isolated `XDG_DATA_HOME` — starts and stays up.
- Pixel 9 emulator (debug 0.5.0): app launch, entry creation, notification
  permission, exact-alarm access, two grouped reminders delivered, timezone
  travel moved 9:00 AM Bogota to 3:00 PM Madrid, reboot kept the entry and
  rescheduled both reminders; the 10-minute reminder fired after advancing the
  clock. `dumpsys alarm` showed exact alarms after reboot.
- Huawei MAR-LX3A (debug 0.9.0+9, Android 10): the full result table, fixed
  defects, reboot limitation and screenshot list are in
  `docs/device-run-2026-11-09.md`. The final APK was rebuilt and reinstalled; the
  preserved plan launched normally.
