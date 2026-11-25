# Unattended on-device verification run

Copy everything below the line into a new chat. Fill the configuration block
first. Do not paste it with blanks: the run must abort rather than guess.

---

# Mission

You are running the unattended on-device verification pass for Sundial v1.0.
The repository is `/home/muffin/Documents/Projects/SampleMane`. An Android device
is connected by USB and the Linux desktop is the second peer. Your job is to
execute every checklist item that is mechanically verifiable, fix only bugs that
block the run, and leave a dated report with command-backed evidence for each
result.

You are not implementing features. You are proving or disproving behaviour, and
writing down exactly what you saw.

## 0. Configuration

Read `docs/unattended-device-run.local.md` before anything else. It contains the
PINs and the permissions for this run. It is gitignored, and it must stay that
way: never commit it, never reproduce a PIN in a report, a commit message, a log
or a screenshot. If the file is missing, abort.

The effective settings for this run are:

- Source replacement, unpairing existing peers, reboot and timezone changes are
  approved. The phone holds test data only.
- The app lock is disabled.
- You have 90 minutes of wall clock. Stop starting new work at minute 80, write
  the report and finish by minute 90.

### Priority ladder

This is a time-boxed run, not a full sweep. Work top-down. When the clock forces
a cut, the items below the line are `DEFERRED`, with that word and nothing
stronger.

1. Preflight gate.
2. Phase A baseline build, analyze and tests.
3. Phase B launch and permission inventory.
4. Schedule every reminder in phase C now, so they fire while you work. Do not
   sit and wait for them.
5. Phase F sync: unpair the existing peer, clean pair, source replacement,
   delta both ways, unpair and re-pair.
6. Phase G images: add, replace, remove, offline retry, replacement with media.
7. Check the phase C reminders as they come due, and test the notification tap,
   snooze, complete and quiet-hours cases.
8. Phase D reboot.
9. Phase I report and close-out.

Defer these to the human unless you have 15 minutes spare after step 8: phase E
timezone, phase H Doze, and the three-device mesh. They are already listed as
manual items or as needing a second physical device.

At minute 70, if sync and images are not both done, abandon the weaker of the
two and finish what you have. A complete report of six passing items beats four
half-tested ones.

## 1. Read first

Read, in this order:

1. `AGENTS.md` - product constraints. Non-negotiable.
2. `KICKSTART.md` - unattended operating rules.
3. `docs/device-checklist.md` - the current checklist and its known failures.
4. `docs/manual-device-checklist.md` - what you must NOT attempt; it belongs to
   the human.
5. `docs/progress.md` - current state, especially the sync and media entries.
6. `docs/compliance-audit.md` and `docs/reference-map.md`.

Do not read `doc-personal/`. Never copy its contents anywhere.

## 2. Hard preflight gate

Run all of these. If any fails, stop and write a one-paragraph report explaining
which gate failed. Do not improvise around a failed gate.

```bash
export PATH=/home/muffin/Android/Sdk/platform-tools:/home/muffin/develop/flutter/bin:$PATH
adb devices -l
adb shell getprop ro.product.model
adb shell getprop ro.build.version.sdk
adb shell getprop persist.sys.timezone
flutter devices
```

Required:

- `adb devices -l` shows exactly one device in state `device`, not `unauthorized`
  and not `offline`.
- API level is 29. If it is not, adjust the permission items in phase C and say
  so in the report.
- `flutter devices` lists `linux` and the Android device.
- The phone and the desktop are on the same private IPv4 subnet:
  compare `adb shell ip -f inet addr show wlan0` with `ip -4 addr show` on the
  desktop. Both must be in the same /24. If not, stop: LAN sync cannot be tested.
- The phone reports a Wi-Fi address, not mobile data only.
- `adb shell dumpsys power | grep -i "mWakefulness"` reports `Awake`. If it is
  `Asleep`, wake it with `adb shell input keyevent KEYCODE_WAKEUP` and, if
  `DEVICE_UNLOCK` is set, unlock it.
- Developer options has "Stay awake while charging" enabled, or you will lose
  the screen mid-run. Verify with
  `adb shell settings get global stay_on_while_plugged_in` (non-zero is good).

Record every value in the report header. These facts explain later failures.

Also run `git --no-optional-locks status --short | wc -l` and record the number.
The tree is expected to be dirty with pre-existing work; that baseline tells you
which changes are yours and which are not.

## 3. Environment facts you must not rediscover

- Flutter: `/home/muffin/develop/flutter/bin/flutter`
- adb: `/home/muffin/Android/Sdk/platform-tools/adb`. `ANDROID_HOME` is unset in
  this shell, so always export the PATH line above.
- Android builds need Java 21. Prefix build commands with:
  `export JAVA_HOME=/usr/lib/jvm/java-21-openjdk; export PATH="$JAVA_HOME/bin:$PATH"`
- Package id: `io.github.sundial`. Launcher activity: `io.github.sundial/.MainActivity`
- Current schema version: 16. Backup version: 16. Do not change either in this
  run.
- The LAN server binds a private IPv4 address, or loopback if none exists.
  Endpoints: `GET /sundial/v1/info` (unauthenticated), `POST
  /sundial/v1/pair/request`, `POST /sundial/v1/pair`,
  `POST /sundial/v1/sync/snapshot`, `POST /sundial/v1/sync/changes`,
  `POST /sundial/v1/sync/media`, `GET /sundial/v1/query`.
- mDNS service type is `_sundial._tcp`. `avahi-browse` is installed; use
  `avahi-browse -rt _sundial._tcp` to observe the desktop advertisement.
- `sqlite3` CLI is NOT installed. `python3` is. Inspect pulled databases with
  `python3 -c "import sqlite3; ..."`.
- `Xvfb` and `xdotool` are NOT installed and `sudo` needs a password, so you
  cannot install them. Do not attempt desktop GUI automation. Drive the desktop
  as a headless peer (phase F) and keep all UI interaction on the phone via adb.
- Desktop screenshots are unavailable in this Wayland session. Phone screenshots
  use `adb exec-out screencap -p`.

## 4. Rules

- Offline core, no accounts, no telemetry. Do not add a network dependency.
- GPL-3.0-only. Do not touch `LICENSE`, `ADDITIONAL_TERMS.md`, `CREDITS.md`, the
  About screen attribution or the package id.
- Do not change the schema, do not bump `schemaVersion`, do not edit `.g.dart`
  files.
- Never weaken or delete a test to make something pass.
- Only commit if `COMMIT_LOCAL: yes`, and only by explicit path. The working tree
  already contains a large amount of uncommitted work (Aero 2.0, icons, sounds,
  sync debug, docs). That work is not yours. Never run `git add -A`, `git add .`,
  `git commit -a` or `git stash`. Stage only the files you personally created or
  changed in this run, naming each path, and confirm with `git diff --cached
  --stat` before every commit. One topic per commit, subject under 50 characters.
  Never push.
- Do not publish the user's plan data. Reports contain counts, ids and behaviour,
  not entry titles, notes or personal dates.
- Never commit `docs/unattended-device-run.local.md`, and never copy a PIN out of
  it. Check `git status` before every commit and confirm the local file is not
  staged. If it already was committed at any point, say so in the report; do not
  try to rewrite history.
- Screenshots go to `/tmp/device-run/`. Do not copy any into `docs/screenshots/`
  unless every visible row is test data you created. The notification shade and
  the plan screens can contain the user's real data.
- If the device disconnects, retry `adb devices` three times over 60 seconds.
  After that, stop and report.
- A phase that cannot run because of a configuration or environment limit is
  `BLOCKED` with the reason. Never mark it `PASS`.

## 5. Evidence standard

Every checklist result needs a command and its output. "It worked" is not a
result. Preferred evidence, in order:

1. Database state pulled from the phone (authoritative for sync and media).
2. `dumpsys` output (`notification`, `alarm`, `package`, `deviceidle`).
3. `logcat` filtered to the app, with the PID recorded.
4. `screencap` for rendering questions only.

Pull the phone database like this. WAL means a live copy can be stale, so always
force-stop first:

```bash
adb shell am force-stop io.github.sundial
adb shell run-as io.github.sundial find . -name 'sundial.sqlite*'
adb exec-out run-as io.github.sundial cat files/sundial.sqlite > /tmp/device-run/phone.sqlite
```

Adjust the path to what `find` printed. If `-wal` and `-shm` files exist, pull
them into the same directory with the matching names before opening.

Then inspect with python3, discovering table names rather than assuming them:

```python
import sqlite3
db = sqlite3.connect('/tmp/device-run/phone.sqlite')
print([r[0] for r in db.execute("select name from sqlite_master where type='table' order by name")])
```

Take a **baseline dump** of relevant row counts before you change anything, and
the same dump after each phase. The diff is the evidence.

## 6. Phases

Execute in the priority-ladder order from section 0, not in the alphabetical
order below. The order of the phase definitions is for reference; the ladder is
the run order. Record start and end time per phase, and write results into the
report as you go, not from memory at the end.

Before phase F, note that the phone was paired to the desktop on 2026-11-21.
Capture `paired_device_records` first, then unpair so that clean pairing is a
genuine first-time exchange rather than a re-approval.

### Phase A - Baseline (no device interaction)

```bash
cd /home/muffin/Documents/Projects/SampleMane
flutter pub get
dart run build_runner build --force-jit
flutter analyze --no-fatal-infos
flutter test
(cd packages/sundial_core && dart test)
```

Record test counts and the analyzer result. Then build and install:

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk; export PATH="$JAVA_HOME/bin:$PATH"
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell dumpsys package io.github.sundial | grep -E "versionName|versionCode|firstInstallTime|lastUpdateTime"
```

**Pass:** analyzer clean, both suites green, install succeeds, and the installed
version matches the build. A red suite is a stop condition: report it and do not
continue into UI testing with a broken baseline.

### Phase B - Launch, persistence and permission inventory

```bash
adb shell am start -n io.github.sundial/.MainActivity
adb logcat -c
adb shell dumpsys package io.github.sundial | grep -E "POST_NOTIFICATIONS|SCHEDULE_EXACT_ALARM|RECEIVE_BOOT_COMPLETED|WAKE_LOCK|FOREGROUND_SERVICE"
adb shell appops get io.github.sundial SCHEDULE_EXACT_ALARM
adb shell dumpsys deviceidle whitelist | grep -i sundial
adb shell dumpsys alarm | grep -i sundial | head -n 40
```

On API 29 the notification runtime permission and the exact-alarm permission do
not exist. Verify that and record them as **N/A by API level**, with the `grep`
output showing the absent permission names. Do not invent a pass.

Confirm the app opened without a crash: `adb logcat -d | grep -iE
"FATAL|AndroidRuntime"` must be empty. Take a baseline database dump.

### Phase C - Reminders and notifications

Create three reminders inside the app using adb input. Text entry is ASCII only;
use `%s` for spaces.

```bash
adb shell input text "AgentTest%sReminder"
```

Cover: a relative reminder about 2 minutes out, an absolute time about 5 minutes
out, and one on a task with a tag. After each save, verify scheduling:

```bash
adb shell dumpsys alarm | grep -i sundial | head -n 40
```

Wait for the due time, then:

```bash
adb shell dumpsys notification --noredact | grep -iA6 sundial
adb shell input keyevent KEYCODE_WAKEUP
adb shell cmd statusbar expand-notifications
adb exec-out screencap -p > /tmp/device-run/notification-shade.png
```

Verify, in order: the notification is posted within 60 seconds of the expected
time; the channel id and title match the entry; tapping it opens the right entry
(capture `dumpsys activity activities` before and after, or logcat);
snooze and complete actions work and the underlying entry/reminder row changes
accordingly in the database; quiet-hours suppression silences a Work reminder
while a Personal one still fires.

Repeat after `adb shell am force-stop io.github.sundial` to prove the alarm
survives process death.

**Pass criteria are per-case.** Report each reminder separately. A posted
notification seen only after reopening the app is a **FAIL**, not a pass.

### Phase D - Reboot behaviour

Only if `ALLOW_REBOOT: yes`.

1. Schedule a reminder 15 minutes out.
2. Capture `dumpsys alarm | grep -i sundial` before the reboot.
3. `adb reboot`, then `adb wait-for-device`, then wait for
   `sys.boot_completed` to read `1`.
4. Before opening the app: capture `dumpsys alarm | grep -i sundial` and
   `dumpsys notification --noredact | grep -i sundial`.
5. Open the app, wait 60 seconds, capture both again.
6. Let the reminder time pass and confirm whether it fires.

**Expected known state on this device:** EMUI does not deliver `BOOT_COMPLETED`,
so the queue is empty before the app is opened and rebuilt afterwards. Confirm
that precisely. If the reminder fires after reboot without opening the app, that
is a change in behaviour and must be reported as such - do not silently mark the
known issue resolved.

The product decision that follows is listed in
`docs/manual-device-checklist.md` item 2. Do not make that decision; record the
behaviour.

### Phase E - Timezone

Only if `ALLOW_TIMEZONE_CHANGE: yes`. Record the original value first and
restore it at the end of the phase, even on failure.

Try, in order, verifying after each with `adb shell getprop
persist.sys.timezone`:

```bash
adb shell cmd alarm set-timezone America/New_York
adb shell service call alarm 3 s16 America/New_York
```

If neither changes the property, open Settings and set it by hand-equivalent
navigation:

```bash
adb shell am start -a android.settings.DATE_SETTINGS
```

If that still fails, mark the phase `BLOCKED` and say so. Do not fake it.

With the zone changed: confirm an all-day entry keeps its date, a timed entry
shifts its displayed time, and reminders reschedule against the new zone
(`dumpsys alarm` deltas). Restore the original zone and confirm the app's
displayed times and alarms return to the original state.

### Phase F - LAN sync, phone and desktop peer

The desktop cannot be driven through a GUI here. Build a headless peer instead:
a second Flutter entrypoint under `tool/device_peer/` that boots the real
`AppDatabase`, identity, `LanServer`, `SyncEngine` and `MediaStore` against its
own explicit data directory, executes a JSON step script, and prints one JSON
line per step. It must never touch the real desktop app-support directory.

Requirements for the harness:

- `flutter run -d linux -t tool/device_peer/main.dart --dart-define=SCRIPT=/path/script.json`
- Explicit directories for the database, media and backups. Do not rely on
  `getApplicationSupportDirectory()`.
- Call `initializeTimeZones()` and `open.overrideFor(OperatingSystem.linux, () =>
  DynamicLibrary.open('libsqlite3.so.0'))`.
- Steps: `startServer`, `printInfo`, `createEntry`, `createContextWithImage`,
  `replaceImage`, `removeImage`, `waitForPairingRequest`, `approveRequest`,
  `rejectRequest`, `pullPeer`, `dumpDebug`, `sleep`, `quit`.
- One JSON line per step: `{"step": "...", "ok": true, "detail": {...}}`.
- `dumpDebug` calls `SyncStore.readDebugSnapshot` and prints changes, field
  versions, tombstones and peer cursors. Cap the arrays as the existing debug
  code does.
- The harness lives in `tool/` and is never shipped. Commit it if
  `COMMIT_LOCAL: yes`.

Then run these scenarios, asserting from the phone database and the peer JSON log
rather than from screenshots:

1. **Pairing request, phone initiates.** Desktop peer waits; phone sends from
   Devices using the peer's address and port, entering `DESKTOP_PIN` on the
   desktop side via `approveRequest`. Assert both
   `paired_device_records` rows exist with matching fingerprints, and that the
   phone shows the peer.
2. **Clean pairing, desktop initiates.** The peer sends a request; approve it on
   the phone through the real UI with `DEVICE_PIN`. This is the flow the previous
   pass skipped because the devices were already paired. If the peer cannot
   initiate, say so and mark the direction `BLOCKED`.
3. **Snapshot and source replacement.** Only if `ALLOW_SOURCE_REPLACEMENT: yes`.
   Confirm the phone writes a backup before replacing, that entries, shifts, home
   items and tags arrive, and that identity, pairing records and device-local
   settings survive. Assert row counts and `sync_dataset_id` / `hasUserData`
   consistency.
4. **Delta both ways.** Create on the phone, pull on the peer; create on the
   peer, pull on the phone. Assert arrival within the scheduled interval without
   opening the Devices page. Then delete on one side and assert the tombstone
   propagates and the row stays deleted.
5. **Unpair and re-pair.** Assert queries are rejected after unpair, and that
   re-pairing catches up from the peer cursor.
6. **Secrecy.** Assert no shared key, PIN hash, certificate private key or MCP
   token appears in any peer payload or in the phone's exported backup.

**Note:** a three-device mesh needs three endpoints. You have one phone and one
desktop. Two headless peers plus the phone would test relay behaviour but not a
second Android stack. Run it only if the harness supports it cheaply; otherwise
mark the three-device item `BLOCKED - needs a second physical device` rather than
claiming it.

### Phase G - Content-addressed images

Using the peer: create a context with image A, pull on the phone, and assert:

- the phone has a `media/cache/<sha256>.png` file whose hash matches the id;
- the context card renders the image, not the icon fallback;
- the phone never receives or stores the desktop `image_path`.

Then replace with image B and assert the new hash appears and the old picture is
never shown while the fetch is pending. Then remove the image and assert the
fallback with no crash. Then stop the peer, change the image, restart it and pull:
assert the row is still editable with the fallback while media is missing, and
that a later pull fetches it.

Repeat once for a project image.

Finally, repeat source replacement with images present and assert the staged
images verify and appear.

Record `media_cache_records` contents and the on-device file list as evidence.

### Phase H - Offline, Doze and quiet hours

1. Airplane mode on (`adb shell svc wifi disable`), create an entry, confirm it
   is editable and saved locally, turn Wi-Fi back on, confirm convergence with
   the peer.
2. Confirm the app does not block, spin or show an error banner that requires
   dismissal while the peer is unreachable.
3. Force Doze and confirm the reminder still fires within tolerance, or record
   the delay:

```bash
adb shell dumpsys deviceidle force-idle
adb shell dumpsys deviceidle unforce
```

4. Quiet hours: confirm a Work reminder is suppressed inside the window and a
   Personal reminder is not.

### Phase I - Report

Write `docs/device-run-<YYYY-MM-DD>.md`, following the shape of
`docs/device-run-2026-11-09.md`. Include:

- header: date, model, API level, build version, timezone, IP/subnet, build hash
  if available;
- a results table: item, result (`PASS` / `FAIL` / `BLOCKED` / `N/A`), evidence
  (one line, the command that proves it), notes;
- a section per failure with reproduction steps, relevant logcat excerpt and the
  suspected cause;
- anything you fixed, with the test proving it;
- anything you deliberately did not test and why.

Then update:

- `docs/device-checklist.md` - add the dated section, tick what passed, leave the
  human items unchecked and pointing at `docs/manual-device-checklist.md`;
- `docs/progress.md` - a dated entry, in the existing style;
- `docs/full-docs.md` - only if behaviour changed.

## 7. Failure policy

- One focused fix attempt per bug, with a regression test. If it is not a
  test-blocking bug, record it and move on.
- Stop immediately, without further changes, if: the phone's data would be lost
  outside the agreed replacement; a secret would be written to disk or logs; the
  device is unreachable after three retries; the preflight gate fails; or a
  decision is needed that is listed in `docs/manual-device-checklist.md`.
- Never edit `docs/manual-device-checklist.md` to tick your own items.

## 8. Final message

End with:

1. The results table, copied from the report.
2. Every `FAIL` and `BLOCKED` item, with the one-line reason.
3. Files added or changed.
4. Commands you ran that the human should rerun to confirm.
5. The human-only items you deliberately left, with a pointer to
   `docs/manual-device-checklist.md`.

Keep it under 400 words. The report file holds the detail.
