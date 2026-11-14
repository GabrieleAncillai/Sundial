# Compliance v2 matrix

Status: 2026-11-13, `feat/compliance-v2`. This matrix records what was verified
in this pass. It deliberately marks unfinished work as open instead of treating
the product-polish claims as proof.

## Gate results

| Gate | Result |
|---|---|
| `flutter analyze --no-fatal-infos` | Pass, no issues |
| `dart format --line-length 110 --output=none --set-exit-if-changed lib test packages/mane_core` | Pass |
| `flutter test` | Pass, 208 tests |
| `(cd packages/mane_core && dart test)` | Pass, 92 tests |
| `flutter build linux --debug` | Pass |
| `JAVA_HOME=/usr/lib/jvm/java-21-openjdk flutter build apk --debug` | Pass |

## Responsive shell and navigation

| Requirement | Status | Evidence |
|---|---|---|
| Phone bottom navigation; desktop side rail; rail side setting | Met (existing, revalidated) | `lib/app/app_shell.dart`, `settings_test.dart` |
| Today, Work, Home, Personal, Plan, Stats destinations | Met (existing) | `app_shell.dart` |
| Settings top-level action and bottom of rail | Met (existing) | `app_shell.dart`, `settings_page.dart` |
| Desktop persistent sidebar search field and tag filter with count | Met | `_SideRail` now owns a `TextField` and badge filter; header search/filter hidden on desktop |
| `Ctrl+F` focuses desktop search | Met | `_openSearch` focuses `_sideSearchFocus` at >= 900 px |
| Mobile keeps global search | Met | Search icon remains in the phone header |
| Selected dates, scroll positions and view modes survive tab changes | Met (existing) | `IndexedStack`, `_selected` in Plan |

## Today

| Requirement | Status | Evidence |
|---|---|---|
| Friendly list grouped by space, completion circles, priority, context/project chips, clock controls | Met (existing) | `today_screen.dart`, `task_card.dart` |
| List / Timeline switch | Met (existing) | `product_polish_widget_test.dart` |
| Four task shapes render | Met | timing expansion tests; `TaskCard` reads `Entry.timing` |
| Clock-in tasks do not disappear | Met | `timing_data_test.dart`, `task_clock_test.dart` |
| Deadline due marker | Met (existing) | `TaskCard`, `DayTimeline` |
| Shift checklists reachable from the list view | Met | `ShiftChecklistSection` is rendered under shifts in Today list and timeline |
| Sleep hint remains | Met (existing) | `SleepWindowCard` |

## Work

| Requirement | Status | Evidence |
|---|---|---|
| Jobs are DB rows with name, icon, colour, optional image | Met (existing) | contexts schema/editor |
| Searchable icon gallery with job defaults | Met (existing) | `ManeIcons`, `space_controls.dart` |
| Work overview works with 1–2 and 5–10+ jobs | Met (existing) | responsive wrap in `space_overview_page.dart` |
| Job screen: shifts, per-day checklists, projects, tasks | Met | `context_detail_page.dart` |
| Checklist items reorderable | Met (existing) | shift editor |
| Different checklist items per cycle day | Met | editor day dropdown; cycle shrink clamps stale indexes; `shift_editor_test.dart` |
| Project form and project assignment | Met (existing) | `project_editor.dart`, entry editor |
| Home/Personal must not have shifts | Met | DB rejects non-Work patterns; queries filter to Work; legacy migration moves patterns to Work; `timing_data_test.dart` |

## Home

| Requirement | Status | Evidence |
|---|---|---|
| Multiple homes with name, icon, colour, optional image | Met (existing) | contexts |
| Dedicated home screen with inventory, shopping, gadgets, projects | Met (existing) | `context_detail_page.dart` home branch |
| Inventory quantity, unit, location, reorder level | Met (existing) | `home_item.dart` |
| Low-stock creates a shopping line in the correct home | Met | `low_stock.dart` now copies `contextId` |
| “Clear bought” only clears the current home | Met | `clearCheckedShopping({contextId})`; `timing_data_test.dart` |
| Gadgets have interval days and advance from completion | Met (existing) | `Entry.repeatAfterCompletionDays`, `completeMaintenanceEntry` |
| Gadgets have name, icon, interval days, last serviced, notes and a due date | Met | dedicated gadget sheet stores an entry `icon`, `lastCompletedAt`, interval and notes; the due date is derived with `nextMaintenanceDue` (`gadget_sheet.dart`, `timing_test.dart`) |
| Global inventory/shopping create rows with a home | Met | aggregate pages resolve a home first (`home_scope.dart`) |
| No shifts for Home | Met | same shift restriction |

## Personal

| Requirement | Status | Evidence |
|---|---|---|
| People/groups are contexts, projects separate them | Met (existing) | contexts + projects |
| Habits: weekly target, current-week progress, streak, history, per-day completion | Met | target, weekday schedule, per-day checks, day/week streak and a 12-week history page (`habit_history_page.dart`); `timing_test.dart`, `migration_test.dart` |
| No shifts or gadgets | Met | shift restriction; Personal branch renders habits/projects only |
| Personal detail does not show household inventory, shopping or gadgets | Met | `product_polish_widget_test.dart` |

## Plan

| Requirement | Status | Evidence |
|---|---|---|
| Collapsible month/week switch | Met (existing) | `plan_page.dart` |
| Content below calendar never clips through navigation | Met (existing) | `Expanded` layout |
| Phone selected-day list/timeline | Met (existing) | `plan_page.dart` |
| Desktop week time grid at 1024 px | Met | breakpoint is now 1024 window px, so a 1024 px window gets the rail plus the week grid |
| Drag to move, bottom-edge resize, drag empty space to create, 15-minute snap | Met (existing) | `week_time_grid.dart` |
| Shifts are background blocks and not draggable | Met (existing) | grid guards |
| Recurring occurrence drag changes only that occurrence | Met (existing) | recurrence override model |
| No title/notes corruption on overridden occurrences | Met (existing) | editor uses series title/notes plus override |
| Cross-timezone drag keeps the end date | Met (existing) | override date handling |
| All-day row aligns with day columns | Met | gutter added to the all-day row |
| Current-time line only on today | Met (existing) | `_DayColumn` |
| Wide touch screens can scroll the grid | Met (existing) | grid scroll view |

## Stats and reports

| Requirement | Status | Evidence |
|---|---|---|
| Dashboard with range selector and cards | Met (existing) | `stats_page.dart` |
| Breakdowns per space, project, day, habits | Met (existing) | stats page |
| Tracked time totals reconcile with breakdowns | Met | `trackedEntriesProvider` resolves sessions outside the occurrence range; `timing_data_test.dart` |
| Shift time included or documented | Met | a Shift hours card sums scheduled shift durations and states that it is not tracked time |
| Clockify-style summary and detailed PDF | Met (existing) | `report_writer.dart`, `report_writer_test.dart` |
| Summary and detailed CSV | Met | `ReportWriter.summaryCsv` and `ReportWriter.csv`; menu exports all four formats; `report_writer_test.dart` reconciles rows, shares and total |
| No billing/rate columns | Met | writer has no money columns |
| Compare against `docs/refs/` | Partial | structure matches; a final pixel/data comparison is still a manual review |

## Settings

| Requirement | Status | Evidence |
|---|---|---|
| Root settings menu with search field | Met (existing) | `settings_page.dart` |
| Search finds individual settings | Met | row-level index; the matching row is scrolled into view and flashed (`settings_section_test.dart`) |
| Theme System/Light/Dark/Aero | Met (existing) | `AppSettings`, theme |
| Background dots/grid/OLED/custom/plain | Met (existing) | `AppBackground` |
| OLED is readable in light mode | Met | OLED forces the dark palette, including when Aero is selected (`settings_test.dart`) |
| Text size | Met (existing) | `textScale` |
| Language English/Spanish | Met (existing) | ARB parity tests |
| Interaction sounds off by default, pack, preview, six actions | Partial | assets and settings exist; a full six-action device audit is still manual |
| Alarm sound picker used by notifications | Partial | Android channels exist; Linux uses the desktop sound; device check pending |
| Date format applied app-wide | Met (first pass) | full dates, month/year, calendar headers, shift preview and report labels use the preference |
| Searchable IANA zone with offset/local time | Met (existing) | `timezone_picker.dart` |
| Week start | Met (existing) | settings |
| Performance mode reduces blur/motion | Met (existing) | background and sheet motion |
| Reminder defaults, work/quiet hours, sleep buffers | Met (existing) | settings + reminder planner |
| Desktop time fields | Met | shared `ManeTimeField` opens a typed 15-minute-snap dialog on wide layouts and the platform sheet on phones; used by editor, shifts, reminders and hours |
| Export/import backup | Met | backup service |
| Automatic local backups with rotation | Met (existing) | auto backup service |
| Import/export calendar | Met (existing) | ICS |
| Companion import | Met (existing) | GymMane import |
| Export/import CSV | Met (existing) | CSV interchange |
| Backups include media files | Met | base64 media map; restore writes files under the media folder (`backup_test.dart`) |
| Restore over a populated database | Met | `backup_test.dart` |
| Delete all removes plan data, media and automatic backups | Met | `clearAllData` is atomic and runs first; media and automatic copies follow and a failure is reported as a partial wipe (`dataDeleteIncomplete`) |
| One online master switch, off by default | Met | master switch is authoritative over legacy rows (`settings_test.dart`) |
| Only when on show Devices & Sync and MCP | Met (existing) | settings page |
| Devices & Sync discovery-first, no IP entry as primary flow | Met (existing) | mDNS/peer discovery |
| Pairing survives IP/network changes | Met (existing) | paired device data + discovery |
| LAN binds private interfaces only | Met | private IPv4 bind + remote-address guard; loopback fallback |
| HTTP info endpoint does not leak identity | Met | `/mane/v1/info` returns app/version/protocol/fingerprint only (`lan_test.dart`) |
| Discovery does not leak username or device ID | Met | mDNS advertises only the pinned certificate fingerprint; peers match on it after an address change (`peer_discovery.dart`, `sync_service_test.dart`) |
| MCP enable/writes/port, rebind, busy-port error, token rotation | Met | `McpServer.start` stops/rebinds on identity or port change; `mcp_test.dart` |
| MCP tools expose the full model | Met | `spaces.list` (spaces/contexts/projects), `habits.list`, `time.sessions`, plus `habits.check`, `time.start` and `time.stop` behind the writes switch (`mcp_test.dart`) |
| About GPL-3.0-only and InlitX attribution | Met (existing) | About page |

## Entry editor and task lifecycle

| Requirement | Status | Evidence |
|---|---|---|
| Editor order and inferred timing | Met | title, notes, space, context, project, categories, priority, timing fields, repeat, reminders |
| Existing task shape survives edit | Met | editor, MCP update, CSV round-trip and Plan move/resize preserve the shape; `entry_editor_v2_test.dart`, `mcp_test.dart`, `csv_interchange_test.dart` |
| Title-only task visible everywhere | Met (existing) | fallback open-entry expansion |
| Clear start/end, clear both | Met | editor clear buttons |
| Clearing end = clock-in; clearing start = deadline; both = anytime | Met | `entry_editor_v2_test.dart` |
| Pausing does not write entry end | Met (existing) | `task_clock_test.dart` |
| Explicit finish writes end | Met (existing) | `finishTracked` |
| Completion stops a running session | Met | `setEntryStatus`/`setOccurrenceCompleted` stop sessions; `timing_data_test.dart` |
| Resume on another day keeps separate sessions | Met (existing) | `task_clock_test.dart` |
| Recurring sessions keyed by occurrence | Met (existing) | occurrence key |
| Completing a recurring task affects one occurrence | Met | `repository.setCompletion`; `timing_data_test.dart` |
| Maintenance advances from completion date | Met | task cards use today for maintenance; `completeMaintenanceEntry` advances from the completion date |
| Read-only imports cannot be edited, completed or deleted | Met | editor sheet, TaskCard lock, repository/DB guards; `entry_editor_v2_test.dart`, `timing_data_test.dart` |
| Add task from a job/home defaults to that unit | Met | `initialSpaceId`/`initialUnitId`; `entry_editor_v2_test.dart` |
| Multiple reminders, offsets and absolute times | Met (existing) | reminder editor |
| Deadline reminders count from the due time | Met (existing) | reminder planner |
| Disabled reminders preserved; read failure cannot wipe them | Met | editor keeps disabled rows and skips the reminder write after a failed load |
| Categories with Streak defaults and filtering | Met (existing) | tags + icon seed + filter |
| Media crop/outline editor and backup | Met (existing) | sticker editor; backup embeds media |

## Repository, schema and recovery

| Requirement | Status | Evidence |
|---|---|---|
| v10 draft repair leaves writable tables | Met | context/time-entry tables are rebuilt, and draft `gadget_records` are converted into Home maintenance entries before the draft table is dropped (`migration_test.dart`) |
| Legacy non-Work shifts repaired | Met | migration moves them to Work |
| Deleting a project detaches tasks | Met | `softDeleteProject`; `timing_data_test.dart` |
| Deleting a context detaches tasks and hides owned rows | Met | `softDeleteContext`; `timing_data_test.dart` |
| Backup accepts schema 3–12 | Met | `backup_test.dart` |
| Backup validation is transactional | Met (existing) | rollback tests |
| Delete-all removes media and automatic backups | Met | settings action |
| Read-only import provenance preserved on re-import | Met | ICS re-import uses `saveImportedEntry` and `copyWith` |

## Known open items

These are not claimed as met:

1. Aero 2.0 is not approved or rolled out. The existing Aero remains frozen;
   see `docs/aero-2.md`.
2. Settings search opens the owning section but does not scroll to and highlight
   the exact row.
3. Habit history is a 12-week read-only view; there is no infinite archive or
   per-habit export.
4. Real-device notification, reboot, battery, LAN, MCP, sound and widget checks
   remain the user's device checklist.
5. Aero 2.0 concepts, tokens and the contrast report are ready; the direction
   still needs the user's approval before any screen is restyled.
