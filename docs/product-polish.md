# Product polish program

This document is the source of truth for the product-polish branch. It captures
the requested behaviour before implementation so no requirement is lost.

## 1. Responsive shell

- One Flutter codebase, two deliberately different layouts.
- Phone / narrow window: bottom navigation, floating add action, list-first
  screens, sheets for editing.
- Desktop / wide window: side navigation (left or right, user setting), dense
  multi-column content, inline week grid, dialogs or side panels where they are
  better than full-screen sheets.
- Breakpoint: 900 logical pixels wide. Layout decisions use the width available
  to the shell, not the platform name.
- Navigation: **Today, Work, Home, Personal, Plan, Stats**. Settings stays a
  separate top-level action and also appears at the bottom of the side rail.
- Desktop scroll position and selected dates survive tab changes.

## 2. Today

- A friendly task view, not only a calendar list.
- Segmented **List / Timeline** switch with an animated transition. The switch
  follows Streak's folder/list control: one control, immediate, no page reload.
- List mode: progress summary, grouped tasks, completion circles, priority
  chips, context/project chips, clock-in controls for tracked tasks, and a
  calm empty state.
- Timeline mode: the existing 24-hour day timeline, with all-day/anytime tasks
  above it.
- Shift checklists and the sleep hint remain available.

## 3. Spaces

Every space is an overview of user-created contexts:

| Space | Context | Extra capabilities |
|---|---|---|
| Work | Job | Shifts, per-day checklists, projects, tasks |
| Home | Home | Inventory, gadgets/maintenance, shopping, projects, tasks |
| Personal | Person/group | Projects, habits, tasks |

- Context form: name, icon (searchable gallery), colour, optional sticker
  image with crop + outline.
- Context detail is a dedicated screen.
- Projects exist in every space. Project form: name, description, icon,
  colour, optional sticker image.
- Tasks can be assigned to a space, then to a context and a project.
- Category/tag library is shared. Default categories and icons follow Streak:
  Health (heart), Fitness (bolt), Mindfulness (brain), Productivity (star),
  Learning (book), Finance (target).
- Work shift checklists can be ordered and configured per cycle day.
- Home gadgets are maintenance entries with an interval after completion.
- Personal habits show a weekly target, streak and per-day completion.

## 4. Plan

- Collapsible month calendar that smoothly switches between month and week.
- Content below the calendar must never clip through the navigation bar.
- Phone: selected-day list / timeline switch.
- Desktop: full-week time grid when the calendar is collapsed to week view.
- Desktop interactions: drag a block to move it, drag its bottom edge to resize,
  and drag on empty grid space to create an entry. Shifts are background blocks
  and are not dragged.
- Recurring occurrences that are dragged are changed for that occurrence only,
  using the existing recurrence override model.

## 5. Stats

- Clean dashboard with a range selector.
- Cards: completed tasks, completion rate, tracked time, overdue deadlines.
- Breakdowns: per space, per context/project, per day, habit consistency.
- Clockify-style report export:
  - summary report: range, total tracked time, project/context rows, share of
    total;
  - detailed report: date, start, end, duration, space/context/project, task.
- No billing, hourly rate or money columns.

## 6. Settings

Root settings screen is a menu with a search field. Each section opens its own
screen.

- **Appearance**: theme (System, Light, Dark, Aero), colour scheme,
  background (dots, grid, OLED, plain, custom), text size.
- **Preferences**: language, date format, week start, navigation side,
  performance mode, reminder defaults, work/quiet hours, sleep buffers.
- **Data and backup**: export/import backup, automatic backups, import/export
  calendar, companion import, CSV import/export, delete all data.
- **Online functionalities**: one master switch. Off by default. When on, two
  rows appear: **Devices & Sync** and **MCP Server**.
- **Devices & Sync**: plain-language explanation, nearby-device discovery and
  paired devices. Pairing must not require typing an IP address. A short code
  remains the security confirmation.
- **MCP Server**: enable, allow writes, configurable loopback port.
- **About**.
- App lock is removed from the product surface.

## 7. Entry editor

Order follows the user's mental model:

1. What is it? (title)
2. Notes (optional)
3. Space
4. Context/job/home/person (when the space has contexts)
5. Project (optional)
6. Categories and priority
7. Timing mode
8. Recurrence, reminders and other advanced options

Timing modes:

- **Scheduled**: start + end. Complete when done.
- **Clock in**: start only. Clock in at the start; clocking out records the end.
- **Deadline**: end only. The task can happen any time until the deadline.
  Priority is derived from the remaining time (overdue, <6h, <24h, <72h).
- **Anytime**: no start or end. Can be completed directly or tracked with a
  clock-in/out session.

## 8. Media

- Jobs, homes, people and projects can use a built-in icon or an image.
- Image flow: choose a file, crop/zoom, optionally remove a plain background
  and add a white sticker outline, preview, save.
- Images are copied into the app's local media folder. Backups preserve the
  relative media filename; no cloud upload.

## 9. Data and compatibility

- Schema v9 adds contexts, projects, habits, habit completions, time entries,
  entry context/project/priority/completedAt, shift context, per-day checklist
  items and home context.
- Migrations v1–v9 remain supported. Backup import accepts schema 3–9.
- LAN snapshots and MCP tools expose the new entities through the shared
  repository, never through direct SQL from UI code.
- App lock stays out of the UI; its old local rows are ignored and never enter
  backups.

## 11. Implementation status

Implemented on `feat/product-polish`:

- Schema v9 and repository support for contexts, projects, habits, habit
  completions and time sessions; entry `contextId`, `projectId`, `priority`
  and `completedAt`; shift-pattern context; per-day checklist items; home and
  shopping context.
- Responsive shell, side-rail side setting, Today switch, space overviews and
  context details, Plan page and desktop week grid, Stats dashboard and report
  export, sectioned/searchable settings, Aero palette/background, sticker media
  editor, discovery-first pairing UX and configurable MCP port.
- Core tests for timing modes and deadline urgency; database tests for contexts,
  projects, habits, tracking and clearing data; a real v8 → v9 migration test;
  backup round-trip coverage and shell/settings widget tests.

Known follow-ups:

- The week grid interactions need a manual pass with a mouse on Linux and a
  trackpad on Android; the grid is desktop-only by design.
- The sticker editor and report save dialogs need a real-device pass. Sticker
  PNGs live in the app support `media/` folder; the JSON backup currently stores
  their local paths but does not embed the image bytes, so restoring on another
  device falls back to the built-in icon until media export is added.
- The old app-lock implementation and its tests have been deleted. Legacy
  settings rows are ignored; the backup service keeps stripping the old
  salt/hash keys so an older database cannot leak them.
- Screenshots from the rendering harness are in `docs/screenshots/`:
  `v1.0-today-list-light.png`, `v1.0-today-timeline-light.png`,
  `v1.0-work-desktop.png`, `v1.0-plan-desktop.png`,
  `v1.0-stats-desktop.png`, `v1.0-personal-mobile.png`,
  `v1.0-settings-mobile.png` and `v1.0-appearance-mobile.png`.
- The screenshot pass exposed and fixed three UI defects: entry blocks
  overflowing narrow 30-minute desktop slots, all-day chips clipping in the
  week grid, and scheduled tasks being displayed as deadlines outside Today.
  The day timeline now scrolls itself and opens near the current hour instead of
  midnight, and deadline-only items get a due marker instead of an all-day chip.
- Desktop layouts for Today/Stats are intentionally the spacious single-column
  versions; a denser dashboard can follow once the real window sizes are known.

## 10. Validation

- Core tests for timing modes, deadline urgency, habits and context rules.
- Migration test from v8 with real rows.
- Backup round-trip includes the new tables.
- Widget tests for the responsive shell, Today view switch and entry timing
  modes.
- `flutter analyze`, app tests, core tests and both debug builds.
