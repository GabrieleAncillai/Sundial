# Reference map

GymMane and Streak by InlitX are the primary references for Sundial. Before
building a feature, open the equivalent in both projects and reuse or adapt it.
This map points at the files worth reading first.

Clone the references next to this repository:

```bash
git clone https://github.com/InlitX/GymMane.git ../GymMane
git clone https://github.com/InlitX/streak.git ../Streak
```

| Area | GymMane | Streak | Notes |
|---|---|---|---|
| App shell, tabs, navigation | `lib/app/gymmane_app.dart`, `lib/app/app_shell.dart` | `lib/app/streak_app.dart`, `lib/app/home_shell.dart`, `lib/app/classic_nav_bar.dart`, `lib/core/minimal/minimal_nav.dart`, `lib/core/express/express_nav.dart` | Streak has several complete nav designs; GymMane has the simpler shell. |
| Theme, colors, typography | `lib/theme/app_colors.dart`, `lib/theme/app_theme.dart`, `assets/fonts/` | `lib/app/theme/app_palette.dart`, `lib/app/theme/app_theme.dart`, `lib/app/theme/app_tokens.dart`, `lib/app/theme/color_themes.dart` | Shipped. Sundial bundles Nunito from GymMane (`assets/fonts/`), uses `SundialColors` through `context.mc`, and `SundialType` for the scale. `SundialTheme` carries the component themes. |
| Shared UI kit | `lib/widgets/ui_kit.dart`, `lib/widgets/glass.dart`, `lib/widgets/dialogs.dart` | `lib/core/widgets/section_label.dart`, `app_empty_state.dart`, `app_text_field.dart`, `sheet_action.dart`, `glass.dart`, `page_motion.dart` | Shipped in `lib/core/widgets/ui_kit.dart` plus its parts: `SoftCard`, `AppSheet`, `SectionLabel`, `Pressable`, `TinySwitch`, `GlassSurface`, `AppEmptyState`, `SundialNotice`, `FadeThrough`, `SundialPage`, `SundialNavBar`, `SundialSegmented`, `SundialSearchField`, `SundialMenuButton`. Adapted names, same interaction language. |
| State and app architecture | `lib/state/fit_state.dart` and its `part` files | `lib/features/*/state/*_controller.dart` | GymMane is one `ChangeNotifier`; Streak is feature-first with `provider`. |
| Local storage | `lib/services/local_store.dart` | `lib/core/database/local_store.dart`, `lib/core/database/data_location.dart` | Compare with Sundial's Drift layer before adding more schema. |
| Entry / habit editing | `lib/screens/exercise_detail_screen.dart`, `lib/screens/routine_edit_screen.dart`, `lib/screens/settings_screen.dart` | `lib/features/habits/pages/habit_details_page.dart`, `lib/features/habits/widgets/habit_form_schedule.dart`, `lib/features/habits/widgets/habit_form_kind.dart` | Sheets, validation, segmented controls, date/time picking. |
| App lock and PIN pad | none | `lib/app/app_lock.dart`, `lib/app/app_lock_pin.dart`, `lib/app/pin_pad.dart`, `lib/app/pin_setup_page.dart` | Shipped in `features/app_lock` over the existing PBKDF2 primitive. Sundial keeps the PIN pad and gate, not Streak's biometrics or recovery code. |
| GymMane schedule import | `lib/state/fit_state.dart` (`weeklyPlan`, `routines`, `trainAt`), `lib/services/local_store.dart`, `lib/services/backup_zip.dart` | none | Shipped in `features/import/gymmane_import.dart`: read-only weekly blocks, dedupe, all-day fallback. Never workout logs. |
| Automatic local backup | `lib/services/auto_backup.dart`, `lib/services/backup_zip.dart` | `lib/services/backup_service.dart`, `lib/services/backup_archive.dart`, `lib/services/auto_sync.dart` | Shipped in `features/backup/auto_backup_service.dart`: daily JSON copies with rotation and a schema 3–8 import upgrade. No cloud. |
| CSV and calendar export | `lib/services/local_store.dart` (`exportCsv`), `lib/services/fit_export.dart`, `lib/services/plan_share.dart` | `lib/services/import_service.dart`, `lib/services/backup_service.dart` | Shipped: `features/export/csv_interchange.dart` for entries, shopping and inventory, plus read-only ICS export. |
| Calendar / month / week | `lib/screens/history_screen.dart`, `lib/screens/timeline_screen.dart` | `lib/features/habits/widgets/activity_calendar.dart`, `lib/core/express/express_month.dart`, `lib/features/habits/pages/day_timeline_page.dart`, `lib/features/habits/widgets/grid_habit_cards.dart` | Streak is the primary calendar reference. |
| Notifications and reminders | `lib/services/alarm_store.dart`, `lib/services/rest_alarm.dart`, `lib/services/train_reminder.dart`, `lib/services/supplement_reminder.dart` | `lib/services/notification_service.dart`, `lib/services/reminder_schedule.dart`, `lib/services/reminder_sounds.dart` | Streak is the primary reminder reference. Sundial adds absolute-time reminders, quiet/work-hour suppression and snooze/complete actions. |
| Interaction and alarm sounds | none | `lib/services/reminder_sounds.dart` (alarm choice only) | Neither reference has a semantic UI cue system. Sundial's seventeen-cue interaction set and procedural WAV generator are original; see `docs/aero-2.md` and `tool/generate_sounds.dart`. |
| Backup and import | `lib/services/auto_backup.dart`, `lib/services/backup_zip.dart`, `lib/services/fitnotes_backup.dart`, `lib/services/workout_import.dart` | `lib/services/backup_service.dart`, `lib/services/backup_archive.dart`, `lib/services/import_service.dart`, `lib/services/auto_sync.dart` | Versioned files, validation, test coverage. |
| Settings | `lib/screens/settings_screen.dart`, `lib/state/settings_state.dart` | `lib/features/settings/pages/settings_page.dart`, `lib/features/settings/state/settings_controller.dart` | Theme, locale, week start, reminders, data folder, privacy. |
| Localization | `l10n.yaml`, `lib/l10n/l10n.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb` | `l10n.yaml`, `lib/core/i18n/l10n.dart`, `lib/core/i18n/app_locale.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb` | English source, Spanish first translation. |
| Motion and polish | `lib/widgets/ui_kit.dart`, `lib/widgets/glass.dart`, `lib/widgets/dialogs.dart` | `lib/core/widgets/page_motion.dart`, `lib/core/widgets/glass.dart`, `lib/core/widgets/celebration_overlay.dart`, `lib/core/express/express_motion.dart` | Use the same motion language and timing. |
| Empty and error states | `lib/widgets/ui_kit.dart` | `lib/core/widgets/app_empty_state.dart`, `lib/core/widgets/startup_failure.dart` | Calm, useful, never an error-looking dead end. |
| Accessibility | `lib/screens/settings_screen.dart` | `lib/core/widgets/*`, `lib/core/shortcuts/*` | Semantics, text scaling, keyboard shortcuts on desktop. |
| Home widgets | `lib/services/home_widget_bridge.dart`, `lib/services/nutrition_widgets.dart` | `lib/services/home_widget_service.dart`, `lib/services/todos_widget_service.dart`, `lib/services/widget_action_service.dart` | Follow the working Android widget pattern. |
| Home inventory, shopping and maintenance | `lib/services/food_library.dart`, `assets/data/foods.tsv`, `lib/screens/nutrition/food.dart` (seeded library, search, picker and portion/measure flow) | none | Neither reference has a planner inventory. The seeded household catalog, search, art tiles and measure picker adapt the GymMane nutrition library pattern. Product variants, reference categories/locations/units, expiry/minimum stock, inventory-linked shopping suggestions and gadget service logs are Sundial-specific and live in `features/home_inventory` and schema v13. |
| ICS import | `lib/services/workout_import.dart` for local file-picking patterns | `lib/services/import_service.dart` for validation and dedupe patterns | No reference implements iCalendar. The parser is Sundial-specific and deliberately narrow. |
| Sleep window and shift checklists | none | none | New planner domain; pure calculation in `sundial_core`, UI in `features/sleep` and `features/shifts`. |
| LAN pairing, query and MCP | none | `lib/services/auto_sync.dart`, `lib/services/folder_sync.dart` (shared-folder backup exchange only) | Neither reference has LAN pairing or MCP. Sundial uses standard TLS pinning, PBKDF2, HMAC and a nonce cache in `features/sync`; pairing is an in-app request approved with the local PIN, and sync is a pull-only replica with field-level LWW and tombstones. The MCP adapter exposes the v0.9 tool set with `Mcp-Session-Id` and one-message SSE responses. |
| Device / desktop behavior | `lib/services/device_kind.dart` | `lib/services/desktop_window.dart`, `lib/core/utils/responsive.dart` | Phone-first, desktop-aware. Sundial adds `lib/core/window/window_chrome.dart` and the Linux runner frame policy; Streak only toggles fullscreen. |
| Build and release | `.github/workflows/build-apk.yml` | `.github/workflows/build-apk.yml`, `.github/workflows/linux.yml`, `fdroid/com.streak.app.yml`, `fastlane/` | Split APKs, GitHub Releases, F-Droid metadata, signing docs. |
| Tests | `test/` | `test/` | Copy the test style and coverage areas. |

## Documented deviations

- **Timezone-aware recurrence and flexible shifts.** GymMane and Streak use
  wall-clock `DateTime` schedules and neither supports timezone-aware
  recurrence, cycles longer than a week, multiple slots per day or date
  exceptions. Sundial implements these in `packages/sundial_core/lib/src/time.dart`,
  `entry_expander.dart` and `shift_pattern.dart`. See the v0.1.5 deviation note
  in `docs/full-docs.md`.
- **Drift + Riverpod.** The reference projects use a local JSON/Hive store with
  `ChangeNotifier`/`provider`. Sundial keeps Drift and Riverpod for date-range
  queries, completion joins and transactional backup import. The audit is in
  `docs/full-docs.md`.
- **Home inventory, shopping and maintenance.** Neither reference has these
  planner-specific domains. They are implemented and tested in `sundial_core`,
  the repository and the `home_inventory`, `import`, `shifts` and `sleep`
  feature folders. The settings rows follow the GymMane/Streak patterns; the
  visual layer uses the shared kit. The seeded household catalog adapts the
  idea of GymMane's nutrition library (`FoodLibrary` plus a TSV seed) to
  household goods: the data and UI are Sundial-specific, catalog ids are stable
  and the names/descriptions are localized. The v13 rework adds one row per
  stock variant grouped by product, user-managed reference data, inventory-linked
  shopping suggestions and gadget service logs. See the v0.3 and v13 deviation
  notes in `docs/full-docs.md`.
- **CSV interchange and the GymMane weekly-plan adapter.** GymMane exports its
  own backup and exercise CSV shapes; it has no consumer for another planner's
  weekly plan. Sundial's CSV columns and the read-only `weeklyPlan`/`routines`
  adapter are planner-specific and documented in `docs/full-docs.md`.
- **App lock details.** Streak offers biometrics and a recovery code. Sundial ships
  only the local PIN because the planner must stay account-free and portable;
  the lock hash is excluded from backups and there is no recovery code.
- **LAN pairing, query and MCP.** Streak has a shared-folder backup exchange,
  not LAN discovery. Sundial implements pinned TLS, an in-app pairing request
  approved with the local PIN plus a short visual code, signed read-only
  queries, persisted snapshots and a loopback MCP adapter with the full tool
  set and session ids. These stay in `lib/features/sync` and
  `lib/features/mcp`. Sync is a pull-only replica with field-level LWW; see the
  v0.4 and v0.9 deviation notes in `docs/full-docs.md`.
- **Search and the Android widget.** Neither reference has a global search
  across entries, tags and household items, or a widget with this data shape.
  Search uses a Drift query in `lib/services/app_database.dart`; the widget
  follows the platform `home_widget` pattern with a Kotlin provider. See the
  v0.5 notes.

- **Work-hours rules, quiet hours and full MCP tool coverage.** Neither
  reference has these surfaces. They are implemented against the planner model
  in v0.9; see `docs/full-docs.md`.
- **Work jobs, Home homes, Personal people/groups, projects and habits.** The
  reference projects use folders/projects for habits and to-dos but do not have
  a first-class job/home/person context inside three spaces. Sundial adds
  `PlannerContext`, `Project` and `Habit` to `sundial_core` and schema v9. The
  folder cards, category icons and habit controls adapt Streak's patterns.
  Monthly habit quotas and per-day check-in counts are a Sundial extension:
  Streak's habit form is weekly-target only. Schema v16 stores the period on
  the habit and the count on each completion.
- **Responsive shell and week grid.** GymMane and Streak are phone-first. Sundial's
  side rail follows Streak's `responsive.dart` idea, and the desktop week grid
  is a planner-specific widget with move/resize/create gestures. Overlapping
  shifts keep the full column and blend their translucent fills where they
  share time, so a collision stays visible without a seam or a stepped outline.
  The full-surface Plan month and its fold into the week/day timeline are also
  planner-specific; Streak's month grid is a compact activity picker.
- **Desktop window chrome.** GymMane and Streak are mobile-first; Streak's
  `lib/services/desktop_window.dart` only toggles fullscreen. Sundial's Linux
  runner selects the frame in `linux/runner/my_application.cc` and
  `lib/core/window/window_chrome.dart` pushes the app palette to GTK. This is a
  platform-layer adaptation, not a new visual pattern. See the window-chrome
  note in `docs/full-docs.md`.
- **Selectable launcher icons.** Neither reference ships alternate launcher
  icons or an in-app icon switch. Sundial's original sundial mark is designed in
  Penpot; Android uses activity aliases (`.ClassicIcon`/`.AeroIcon`) and a
  `sundial/app_icon` `MethodChannel`, with a device-local setting. The design
  record is `branding/README.md` and the reproducible generator is
  `tool/generate_icons.py`.
- **Stats and report export.** Streak has habit statistics; neither reference
  has a Clockify-style tracked-time report. The dashboard uses Sundial data and the
  PDF/CSV writer lives in `lib/features/stats/report_writer.dart`.
- **Sticker media editor.** GymMane's nutrition cutout editor was the reference
  for crop/background removal/outline. Sundial reimplements it in
  `lib/features/media/` for job, home, person and project images.
- **Visual layer.** v0.6 adapts GymMane's shell, Nunito, warm palette and
  settings rows, plus Streak's floating nav, sheet shape and page motion. Sundial
  does not ship GymMane's photo/pattern background picker or Streak's three
  selectable navigation styles; the palette, spacing and component names are
  planner-specific. Reference screenshots are in `docs/screenshots/`.

## How to use this map

1. Read the GymMane file first when the task is about the small-app shell,
   settings, theme, l10n, backup or a simple screen.
2. Read the Streak file first when the task is about calendar, notifications,
   sync, motion, feature modules or a larger state tree.
3. If both have an implementation, choose the one closest to the task and keep
   the difference small.
4. If neither has an equivalent, it is a new domain problem. Design it, test it,
   and document the deviation in `docs/full-docs.md`.
5. If code is copied or closely adapted, keep GPL-3.0-only and update
   `CREDITS.md` plus the About screen attribution.
