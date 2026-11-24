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

- Full-surface month calendar on open: one stretched cell per day, event and
  shift chips, today marker and a "+N" overflow count when a day is busy.
- The bottom bar collapses the month with a clipped-height fold. Desktop lands
  on the full-week time grid; phones land on the selected-day timeline with a
  seven-day strip for the selected week above it.
- Content below the calendar must never clip through the navigation bar.
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

- **Appearance**: style (Classic, Aero), brightness (System, Light, Dark),
  colour scheme, background (dots, grid, OLED, plain, custom), text size.
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
  items and home context. Schema v10 repairs databases written by the earlier
  draft-v9 build, which used space units and task sessions and stored integer
  priorities while still reporting v9.
- Migrations v1–v10 remain supported. Backup import accepts schema 3–9.
- LAN snapshots and MCP tools expose the new entities through the shared
  repository, never through direct SQL from UI code.
- App lock stays out of the UI; its old local rows are ignored and never enter
  backups.

## 10.5 V2 request deltas (2026-11-13)

This branch keeps the shipped v1 surface. The second request refined it; these
are the only differences that still need work here. Everything not listed is
already delivered by the v1 implementation above.

### Appearance

- Aero is no longer only a palette. Selecting it also applies a glossy,
frosted component treatment and uses the Aero interaction-sound pack. Sounds
remain a separate opt-in switch (off by default).
- The standalone Colour scheme row is removed from Appearance, matching the
v2 request. The stored preference stays for compatibility but is hidden.

### Preferences

- Add a **Sound** section:
  - Interaction sounds switch, sound-pack picker and preview. Off by default.
  - Alarm sound picker with preview, used by scheduled reminders.
- Add a **Time zone** setting with a searchable IANA selector that shows the
device zone, current offset and local time. New timed entries default to the
selected planning zone; existing entries keep their stored zone.

### Entry editor

- Start and end fields can be cleared. Clearing the end makes the entry a
clock-in task; clearing the start makes it a deadline; clearing both makes it
an anytime task. A timing dropdown is no longer the primary control.
- Repeat follows Streak's sheet: never, daily, weekly weekday chips, monthly
day-of-month or nth weekday, yearly, every N, ending never / on a date / after
N occurrences. Sundial's **repeat after completion** interval stays as an
alternative mode in the same sheet.
- The space picker drives context and project pickers that only show the
selected space.

### Tasks and time

- Clocking out pauses a task. It records a session but does not write the
entry's end time or turn it into a scheduled entry. The same entry can be
resumed on another day, and each session keeps its own range.
- Completing is separate from pausing. A clock-in task stays clockable after
any number of sessions; an explicit finish can still set its end time.

### Modals and selectors

- `showAppSheet` presents a bottom sheet on compact widths and a centred
floating dialog on wide widths, with a blurred backdrop when performance mode
is off. Screens never call `showModalBottomSheet` directly.
- Selectors share one component with search, leading icon/colour, a selected
check and a summary value, instead of stock dropdowns.

### Validation for this delta

- [x] Aero component treatment and sound pack.
- [x] Sound and alarm preferences with previews.
- [x] Searchable time zone picker wired to settings, entries and shifts.
- [x] Clearable start/end with inferred timing.
- [x] Streak-style repeat sheet plus repeat after completion.
- [x] Pause/resume sessions without rewriting the entry end.
- [x] Responsive blurred modal and shared selector component.
- [x] English/Spanish ARB parity, analyze, app/core tests and both debug builds.

## 11. Implementation status

Implemented on `feat/product-polish`:

- Schema v9 and repository support for contexts, projects, habits, habit
  completions and time sessions; entry `contextId`, `projectId`, `priority`
  and `completedAt`; shift-pattern context; per-day checklist items; home and
  shopping context. Schema v10 maps the draft-v9 space-unit/task-session
  tables and integer priorities onto that model without losing rows. Schema v11
  adds habit weekday schedules and schema v12 adds the gadget icon.
- Responsive shell, side-rail side setting, Today switch, space overviews and
  context details, Plan page and desktop week grid, Stats dashboard and report
  export, sectioned/searchable settings, Aero palette/background, sticker media
  editor, discovery-first pairing UX and configurable MCP port.
- Core tests for timing modes and deadline urgency; database tests for contexts,
  projects, habits, tracking and clearing data; real v8 → v9 and draft-v9 → v10
  migration tests; backup round-trip coverage and shell/settings widget tests.

V2 deltas shipped on top of the v1 surface:

- Aero now adds glossy/frosted cards, nav bar, segmented control and icon
  buttons, and selecting it adopts the Aero interaction-sound pack. Sounds are
  still opt-in and off by default.
- Preferences gain a Sound section (interaction sounds, pack, preview, alarm
  sound with preview) and a searchable IANA time zone picker. New timed entries
  default to the selected planning zone; existing entries keep their stored
  zone and the device zone remains the display zone.
- The entry editor infers the four task shapes from the start/end fields, has
  clear buttons for each, and replaces the old repeat dropdown with a
  Streak-style repeat sheet (interval, weekday chips, monthly day or nth
  weekday, end never/on a date/after N) plus repeat-after-completion.
- Clocking out pauses a task and records a session; it no longer writes the
  entry end. `finishTracked` remains the explicit finish path. A task can be
  resumed on any later day.
- `showAppSheet` becomes a bottom sheet on compact widths and a blurred
  floating dialog on wide widths. A shared searchable selector replaces the
  stock dropdowns in the entry, shift, project and category forms.
- Screenshot evidence: `docs/screenshots/v1.2-today-aero.png` and
  `docs/screenshots/v1.2-preferences-mobile.png`.

Known follow-ups:

- The week grid interactions need a manual pass with a mouse on Linux and a
  trackpad on Android; the grid is desktop-only by design.
- The sticker editor and report save dialogs need a real-device pass. Sticker
  PNGs live in the app support `media/` folder. The compliance-v2 backup embeds
  referenced images as base64 and restores them into the new device's media
  folder, so restoring on another device no longer falls back to the built-in
  icon.
- The old app-lock implementation and its tests have been deleted. Legacy
  settings rows are ignored; the backup service keeps stripping the old
  salt/hash keys so an older database cannot leak them.
- Screenshots from the rendering harness are in `docs/screenshots/`:
  `v1.0-today-list-light.png`, `v1.0-today-timeline-light.png`,
  `v1.0-work-desktop.png`, `v1.4-plan-month-desktop.png`,
  `v1.4-plan-week-desktop.png`, `v1.4-plan-month-mobile.png`,
  `v1.4-plan-day-mobile.png`, `v1.4-plan-month-dark-desktop.png`,
  `v1.0-stats-desktop.png`, `v1.0-personal-mobile.png`,
  `v1.0-settings-mobile.png` and `v1.0-appearance-mobile.png`.
- The screenshot pass exposed and fixed three UI defects: entry blocks
  overflowing narrow 30-minute desktop slots, all-day chips clipping in the
  week grid, and scheduled tasks being displayed as deadlines outside Today.
  The day timeline now scrolls itself and opens near the current hour instead of
  midnight, and deadline-only items get a due marker instead of an all-day chip.
- Desktop layouts for Today/Stats are intentionally the spacious single-column
  versions; a denser dashboard can follow once the real window sizes are known.
- Sound needs a real-device pass: Android plays bundled raw resources through a
  SoundPool bridge and Linux shells out to `aplay`; both fall back to system
  sounds. The alarm-sound setting maps to per-sound Android notification
  channels; Linux notifications keep the desktop default.
- Time zone selection sets the planning zone for new timed entries. Changing
  the display zone still follows the device, as the time model requires.
- Compact sheets keep the standard dimmed barrier so drag-to-dismiss, keyboard
  insets and safe areas stay intact; the blurred barrier is used on wide
  layouts.
- Clock-out is now a pause rather than a finish, which deliberately differs
  from the v1 wording. Users finish a clock-in task with the completion control
  or the explicit `finishTracked` path.

## 10. Validation

- Core tests for timing modes, deadline urgency, habits and context rules.
- Migration test from v8 with real rows.
- Backup round-trip includes the new tables.
- Widget tests for the responsive shell, Today view switch and entry timing
  modes.
- `flutter analyze`, app tests, core tests and both debug builds.
