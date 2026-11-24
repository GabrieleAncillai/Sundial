# Sundial

A local-first planner for life, work and home.

Sundial is built for the week and month as they actually happen. One app,
three spaces: **Personal**, **Work** and **Home**.

Work shifts, house inventory and maintenance, personal admin and the dates that
matter sit in one calendar, so collisions are visible before they become
problems. Android is the daily driver. Linux desktop is where planning and the
local agent run.

No account, no cloud, no telemetry. LAN sync and a local MCP endpoint are
optional, automatic when possible, and never required for the core to work.

**Status:** v0.9 shipped, then `feat/product-polish` rebuilt the product
surface. `feat/compliance-v2` is the current branch: it preserves that surface
and fixes the audit's data-integrity and security defects (entry shape
preservation, read-only imports, one completion path, v10 repair, backup media,
private LAN binding, MCP rebinding, scoped home data, stats reconciliation and
more). The row-by-row status is in
[docs/compliance-matrix.md](docs/compliance-matrix.md). Aero 2.0 is shipped as a
first-class, brightness-aware style system; Classic remains the reference shell.
The manual and extension guide is [docs/aero-2.md](docs/aero-2.md). Reboot
rescheduling is blocked by EMUI and documented as an OEM limitation.

## Docs

- [Overview](docs/overview.md): the short version.
- [Completion plan](docs/completion-plan.md): the active v0.6 → v1.0 milestones,
  feature matrix, scenarios and acceptance criteria.
- [Compliance audit](docs/compliance-audit.md): the constraint audit and open
  findings.
- [Compliance v2 matrix](docs/compliance-matrix.md): what the current branch
  verifies and what remains open.
- [Aero 2.0 style system](docs/aero-2.md): shipped light/dark style, manual and
  extension guide for future styles.
- [Full docs](docs/full-docs.md): architecture, data model, feature areas,
  roadmap and decisions.
- [Reference map](docs/reference-map.md): the exact GymMane and Streak files to
  use for each area.
- [Contributing](CONTRIBUTING.md): setup, layout, house style and tests.
- [Release](docs/release.md): signing, split APKs and GitHub Releases.
- [Android device checklist](docs/device-checklist.md): the v1.0 real-device
  notification, reboot, battery, timezone, LAN, MCP and widget checks.
- [Device run, 2026-11-09](docs/device-run-2026-11-09.md): the Huawei pass,
  fixed defects, reboot limitation and screenshot evidence.
- [Agent brief](AGENTS.md): self-contained kickoff prompt for a coding agent.
- [Unattended kickoff](KICKSTART.md): quality-first prompt for a long,
  unattended implementation run.
- [Inspiration](inspiration/): screenshots and references for the visual
  direction.

## Working now

- Today and Plan tabs, with the Today list/timeline switch, a full-surface
  month calendar, per-space event and shift chips, a 24-hour timeline,
  previous/next navigation, jump-to-today, a desktop week grid and a phone
  week agenda.
- A responsive shell. Phones keep the floating bottom navigation; wide windows
  use a side rail that can sit on the left or right.
- Today's friendly list/timeline switch with progress, priority chips,
  context/project labels and clock-in/out for tracked tasks.
- Space overviews for Work (jobs), Home (homes) and Personal (people/groups),
  each with projects and dedicated detail screens. Work adds shifts, Home adds
  inventory, shopping and gadgets, Personal adds habits.
- A plan page that opens on a full-surface month calendar and folds into the
  desktop week grid, the phone week agenda, or the phone week strip plus
  selected-day timeline, with drag-to-move, resize and drag-to-create on the
  grid.
- A stats dashboard and Clockify-style summary/detailed PDF reports plus CSV.
- Sectioned settings with search, Classic/Aero styles, System/Light/Dark
  brightness, Aero light and dark, accent schemes, dots/grid/OLED/plain/custom
  backgrounds, text size, date format, navigation side and performance mode.
- Default categories with icons (Health, Fitness, Mindfulness, Productivity,
  Learning, Finance), editable through the category manager.
- Local media stickers for jobs, homes, people and projects, with crop,
  background removal and a white outline.
- Personal, Work and Home spaces, add/edit/soft-delete entries.
- Timezone-aware timed entries and shift patterns. Device travel moves the
  displayed local time; all-day dates never shift.
- Flexible shifts: cycles longer than a week, several slots per day, overnight
  slots, and free/override/extra date exceptions. A pattern editor previews the
  next 28 days and blocks overlapping shifts. The calendar's day sheet sets any
  pattern to usual, working or free for one date, which covers a weekend
  decided week by week and a monthly free Saturday without one-off entries.
- Daily, weekly, monthly and yearly recurrence with `until` and `count`,
  expanded in the entry's stored IANA timezone.
- Per-occurrence completion that survives travel and a database restart.
- Tags with a manager, entry chips and a global tag filter.
- Multiple reminders per entry, including custom times, Android notification
  permission and exact-alarm handling, a 90-day queue rebuilt on
  start/resume/timezone change, taps that open the entry, and snooze/complete
  actions.
- Work-hours visibility and quiet hours, with notification suppression and
  persistent Work deadlines.
- Settings for theme, English/Spanish, week start, hiding Work, work/quiet
  hours, default reminders, sleep buffers, data backup, automatic backup
  rotation, sync/MCP switches and About.
- Versioned JSON backup and a validated, transactional restore, older schema
  upgrades (3–15) and daily local copies with rotation.
- Home inventory with a 124-item household catalog, product groups and
  independent size variants (for example 5-gallon and 5-litre water bottles),
  user-managed categories, locations and units with icons and colours, multiple
  locations per variant, expiry dates, per-variant minimum stock, quick ±1
  adjustments and purchase history.
- A shopping list grouped by category that suggests restocking low, empty and
  expired inventory, links a line to the exact variant it restocks, and still
  handles one-off purchases. Checking a linked line updates stock; unchecking
  reverses the recorded purchase.
- Gadgets with interval-after-completion service schedules, a service log,
  manual rescheduling that does not pretend the work was done, and optional
  timed calendar blocks for the service.
- A read-only GymMane schedule import for weekly gym blocks, and CSV
  export/import for entries, shopping and inventory.
- A soft sleep window on Today, with configurable commute, wind-down and wake
  buffers.
- Shift checklists whose completions stay independent for each shift date.
- Read-only ICS import for local files, with TZID aliases, all-day and
  multi-day events, `EXDATE`, `RECURRENCE-ID`, a documented RRULE subset and
  update-on-reimport. A read-only ICS export shares the calendar without an
  account.
- Read-only companion JSON export import with a documented schema.
- Optional LAN pairing: username + PBKDF2-hashed PIN, an in-app request that
  the other device approves with its own PIN, a one-time six-digit visual code,
  pinned self-signed TLS, signed queries and replay rejection. Manual host and
  port entry is available when mDNS is blocked. The switch is off by default.
  Paired devices hold full replicas merged by field-level LWW with tombstones;
  pulls run on start, resume, discovery and a five-minute timer. First pairing
  offers an explicit source choice with a PIN-gated, backed-up replacement.
- mDNS discovery with a manual host/port fallback, automatic refresh on launch,
  resume and discovery, a five-minute timer and manual refresh.
- A Devices page with per-peer sync status, a “different plan” source choice,
  a PIN-gated replace action, and a roster of devices learned from peers but
  not directly paired.
- A schema v15 sync foundation with per-field hybrid logical clocks, tombstones,
  dependency-ordered snapshot pages, a delta feed and a transactional,
  field-level apply engine. Source replacement is staged and backed up; the
  old read-only snapshot endpoint/table are kept for one release and are no
  longer read by the UI.
- Content-addressed context/project images over the same signed LAN transport
  (protocol 4). The SHA-256 id travels in one atomic merge group; the local
  `image_path` never leaves the device. Images live in an immutable
  `media/cache/<sha256>.png`, normal pulls retry missing images without
  blocking rows, source replacement verifies every image before clearing the
  target, and backups carry the ids and bytes.
- Optional local MCP endpoint on loopback with a bearer token, the full tool
  set, streamable HTTP sessions and write tools behind a second setting.
- Global search across entry titles and notes, tag names and household items.
- An Android home-screen widget with today's plan and the next shift.
- A reference-style visual foundation: Nunito, `SundialColors`/`SundialType`, component
  themes, a shared UI kit, a floating shell and a dotted paper background.
- Accessibility basics: semantics on calendar days and shifts, text scaling in
  the calendar, keyboard shortcuts for search and tab switching.
- A schema v1 through v15 migration path tested against real prior rows.
- A pure Dart domain package with the timezone, recurrence, shift and sleep
  rules.
- Android debug APK, Linux debug build and a tagged release workflow for split
  APKs and a Linux bundle.

## Completion program

- v0.6: reference visual foundation, UI kit and shell. Done.
- v0.7: day timeline, multi-day entries, recurrence exceptions, tagged shifts,
  per-slot checklists, ICS export and real-file ICS hardening. Done.
- v0.8: GymMane schedule import, automatic local backups with rotation, older
  backup schemas, CSV interchange, home-tracking views. Done.
- v0.9: full MCP tool set and sessions, persistent LAN snapshots, work-hours and
  quiet-hours rules, custom reminder times and actions. Done.
- Post-v0.9: schema v13 Home rework with product variants, the household
  catalog, reference categories/locations/units, expiry and minimum stock,
  inventory-linked shopping suggestions and gadget service logs. Done.
- v1.0: device verification, accessibility/contrast audit, final docs and a
  signed release.

## Planned after v1.0

- A ContentProvider client for a specific companion app.
- MCP over LAN with the same pinned transport.
- Home-screen widget variants for other platforms.

## Stack

- Flutter 3.38 / Dart 3.10
- Drift + SQLite
- Riverpod
- Material 3
- `cryptography` for PBKDF2/AES-GCM, `basic_utils` for the self-signed
  certificate, `bonsoir` for mDNS
- Android and Linux desktop from one codebase

The stack audit is done: Sundial keeps Drift + Riverpod. The planner needs
date-range queries, entry/completion joins and a transactional backup import,
which the reference projects' local JSON stores do not provide directly.
Riverpod's overrides keep the clock, timezone and database injectable in tests.
There is no second state-management system. See
[docs/full-docs.md](docs/full-docs.md).

## Layout

```
lib/
  app/         MaterialApp and the shell
  features/    calendar, shifts, home inventory, settings, backup, sync, mcp
  models/      plain data classes that are not in sundial_core
  screens/     one file per screen
  services/    database, repository, platform side effects
  state/       providers and app state
  theme/       colors and text styles
  widgets/     shared UI pieces
packages/
  sundial_core/  pure Dart domain model, recurrence and shift rules
docs/
inspiration/
```

The core package has no Flutter imports on purpose. The UI, a future LAN server
and the MCP adapter share the same rules. The target is Streak's feature-first
layout as Sundial grows; see [docs/full-docs.md](docs/full-docs.md).

## Run

```bash
flutter pub get
dart run build_runner build --force-jit
flutter run -d linux
```

`--force-jit` is needed on this Flutter version: build_runner 2.15 tries to
AOT-compile the build script, and one transitive dependency ships a native build
hook. JIT mode avoids that.

## Test

```bash
flutter test
(cd packages/sundial_core && dart test)
```

## License

GPL-3.0-only, the same license as the primary references. See [LICENSE](LICENSE)
and [ADDITIONAL_TERMS.md](ADDITIONAL_TERMS.md).

## Credits

[GymMane](https://github.com/InlitX/GymMane) and
[Streak](https://github.com/InlitX/streak) by [InlitX](https://github.com/InlitX)
are the primary references for this project's structure, components, styles,
navigation, notifications, motion and architecture. See [CREDITS.md](CREDITS.md).
