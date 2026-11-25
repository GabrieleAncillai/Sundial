# Android device checklist

This is the last v1.0 gate. Run it on the real Android device with a debug or
release build. Record the build version and the device model next to each item.

## Latest run

2026-11-24, HUAWEI MAR-LX3A, Android 10 / API 29, debug 0.9.0+9. The
unattended pass is in
[device-run-2026-11-24.md](device-run-2026-11-24.md). It passed the baseline,
relative reminder delivery, notification tap, clean phone-initiated pairing,
source replacement, deltas and tombstones both ways, and the context/project
image lifecycle. It failed the unpair check (a stale peer pins the Devices page
in `pulling`) and was blocked at reboot when the phone left USB. Timezone, Doze,
quiet hours, desktop-initiated pairing and payload-secrecy inspection remain
open.

2026-11-09, HUAWEI MAR-LX3A, Android 10 / API 29, debug 0.9.0+9. The full log
is in [device-run-2026-11-09.md](device-run-2026-11-09.md). Summary: install,
notifications (except the Android 13/12 paths, N/A on API 29), timezone, LAN,
MCP, backup/CSV after the fix, and app lock pass. Reboot fails because EMUI does
not deliver `BOOT_COMPLETED` to the app. The widget and OEM battery checks still
need the user. Checkboxes below reflect that run; unchecked boxes are not
passes.

## 2026-11-21 UI and replica verification

Run on the HUAWEI MAR-LX3A (Android 10) with debug 0.9.0 and the Linux debug
bundle on the same LAN. This pass covered the walkthrough fixes and the v14
replica path, not the notification, reboot or battery items.

- [x] Today, search, reminder labels, stats, tags, settings, phone Plan modes
      and space pages match the fixes recorded in `docs/progress.md` at 360 dp.
- [x] Spanish navigation, Devices, nearby pairing and device-address screens
      fit at 360 dp.
- [x] The Spanish search hint fits after the second shortening.
- [x] Manual host/port pairing UI is present; the identity is the phone name,
      not `localhost`; the paired endpoint renders as IPv4 plus port.
- [x] An entry created on the phone reached the desktop through a scheduled
      pull. Its completion and deletion propagated (soft delete plus
      tombstone) without opening the Devices page.
- [x] The phone Home inventory shows the desktop's replicated “Huevos” row.
- [ ] Clean-pair approval/rejection, source replacement, IPv6-only endpoints
      and image sync were not re-run because the devices were already paired.
- [ ] Notification, reboot, battery, widget and timezone items were not re-run
      in this pass. The 2026-11-09 results and the remaining failures above
      still stand.

Desktop screenshots are unavailable in this Wayland session; the desktop pass
was launch, logs and database verification.

## 2026-11-24 Unattended verification

Run on the HUAWEI MAR-LX3A with debug 0.9.0+9 and a headless Linux peer
(`tool/device_peer`). Full detail and evidence are in
[device-run-2026-11-24.md](device-run-2026-11-24.md).

- [x] Analyzer clean, 432 app tests and 113 core tests pass, APK installs with
      `versionName=0.9.0 versionCode=9`.
- [x] The app launches without a fatal log. API 29 correctly reports the
      Android 13 notification permission and Android 12 exact-alarm access as
      N/A.
- [x] A relative reminder scheduled for 19:47 posted at 19:47:00 on
      `sundial_reminders_chime` with `Snooze 10 minutes` and `Mark complete`.
- [x] Tapping the notification opened the matching entry editor.
- [x] A clean first-time phone-initiated pairing succeeded at protocol 4; both
      sides stored the peer and the phone reported the different-plan state.
- [x] Source replacement wrote `sundial-auto-20261124-195809.json`, kept
      identity/pairing/device-local settings, brought entries, tags, a shift,
      home inventory, a context, a project and the staged image, and matched the
      peer dataset id.
- [x] A peer edit reached the phone on startup (no Devices visit) and a phone
      edit reached the peer; a peer delete propagated as a tombstone.
- [x] Context and project images add, replace, remove and re-fetch by SHA-256;
      the card renders the image and falls back to the icon when it is missing.
- [ ] Unpair/re-pair. **FAIL:** with the old cross-network peer unreachable, the
      card stayed on `Syncing…` and the per-device refresh and Unpair actions
      were disabled. The stale rows were removed out-of-band; re-pair was not
      run.
- [ ] Reboot reminder. **BLOCKED:** the 20:35 alarm was queued, but after
      `adb reboot` the activity manager reported the launch activity missing and
      the device left USB; three retries over 60 s found no device.
- [ ] Absolute reminder post, snooze/complete actions, process-death survival,
      quiet hours, timezone, Doze and payload-secrecy inspection were deferred.

Known finding: the phone binds a different LAN port on each launch (33147,
35985, 39801, 35209 observed), while a paired peer stores the port from
pairing. Discovery can refresh it, but a peer without discovery cannot reach
the phone until the endpoint is updated.

Human items from `docs/manual-device-checklist.md` are unchanged.

## Appearance and Aero 2.0

- [ ] Open Settings → Appearance and confirm the separate **Style**
      (Classic/Aero) and **Brightness** (System/Light/Dark) rows.
- [ ] Switch Classic → Aero in light and dark. Confirm the sky, glass chrome,
      glossy cards, nav pill, progress and original sundial mark render.
- [ ] On a 360 dp phone, confirm the six-tab bar drops its labels, shows the
      larger icons, and keeps the selected lens inside the glass shelf at Today
      and the last tab. Long-press a tab and confirm its tooltip label appears.
- [ ] On a 430 dp phone (or resize a desktop window above the 60 dp slot
      breakpoint), confirm labels return and "Estadísticas" stays inside the
      selected lens.
- [ ] Leave the Aero background running for several minutes and confirm the
      sky and bokeh loop does not visibly jump.
- [ ] Scroll a long Today list and the month/week Plan at 360 dp. Check the
      Aero text remains readable over the environment.
- [ ] Turn Performance mode on. Confirm blur, bubbles and gloss transitions
      stop while selected states remain visible.
- [ ] Select OLED black with Aero. Confirm the app resolves to the dark Aero
      surface and stays readable.
- [ ] Rotate or reopen the app and confirm the selected style and brightness
      survive a restart.

## Launcher icon

- [ ] Settings → Appearance shows the **App icon** row with Classic and Aero
      previews. Confirm the selected card has the accent ring and check badge.
- [ ] Switch Classic → Aero and back. Confirm the launcher entry is replaced
      with the matching icon and the app still opens. If the launcher caches the
      old icon, restart the launcher and check again.
- [ ] Force-stop and reopen the app. Confirm the stored choice is re-applied
      (the alias state is restored on launch).
- [ ] On Android 13+, enable themed icons and confirm the monochrome sundial
      layer is used instead of the colour icon.
- [ ] Back up, clear app data and restore. Confirm the backup does not carry the
      launcher choice and the default Classic alias comes back.
- [ ] Place the icon at 48, 32 and 24 px on light and dark home screens under a
      circle and a rounded-square mask. Confirm the sun stays inside the mask
      and the gnomon remains readable.

## Interaction sounds

- [ ] Settings → Sound: turn interaction sounds on and confirm the switch cues.
- [ ] Switch between Soft and Aero and confirm each pack previews after the
      change.
- [ ] Open Sound library and preview every group. Confirm each cue is distinct
      and the Soft pack is noticeably quieter.
- [ ] Complete a task on Today and reopen it. Confirm the completion and undo
      cues differ from the toggle cues.
- [ ] Tick a shift checklist item, a habit, and a shopping line. Confirm the
      check cue, then the uncheck cue when each is reversed.
- [ ] Start, pause and finish a tracked task. Confirm the three timer cues
      differ.
- [ ] Switch tabs, open and close a sheet, change a segmented control and use
      a page back button. Confirm the navigation, open, back and select cues.
- [ ] Relaunch the app with sounds already on and tap immediately. Confirm the
      first cue is not delayed by loading.
- [ ] Enable silent mode / Do Not Disturb and confirm interaction cues follow
      the device's sonification policy.

## Emulator baseline (already verified)

On 2026-11-09, on a Pixel 9 emulator (Google Play image) with a debug build of
0.5.0:

- The app launched and persisted Personal/Work/Home data.
- Creating an entry requested the Android 13+ notification permission and then
  opened the exact-alarm special access screen. Enabling it made the reminders
  exact.
- Two default reminders (1 hour and 10 minutes before) were delivered as a
  grouped notification at the scheduled minute.
- Changing the device timezone from America/Bogota to Europe/Madrid moved the
  timed entry from 9:00 AM to 3:00 PM. All-day dates are covered by the widget
  and unit tests; the emulator run had no all-day entry.
- Rebooting the emulator kept the entry, and the app rebuilt the reminder queue:
  both reminders were present in `dumpsys alarm` after boot, and the 10-minute
  reminder fired after the clock was advanced.
- The release APK also builds split per ABI and the Linux release bundle builds.

The Pixel 9 baseline above is historical and still covers the Android 13/12
paths. On the physical Huawei device, notifications, timezone, real-reboot
recovery (manual launch only) and LAN with the manual host/port fallback are now
recorded in the 2026-11-09 run. Still open there: OEM battery optimization and
the home-screen widget.

## Install and first launch

- [x] Install the arm64 APK (or `flutter install` for a debug build).
- [x] The app opens offline, with Personal, Work and Home and no sample entries.
- [x] The About screen shows v0.9.0, GPL-3.0-only and the InlitX attribution.

## Notifications

- [x] N/A on the 2026-11-09 run: Android 10 does not have the Android 13 runtime
      notification permission. The emulator baseline below covers it.
- [x] N/A on the 2026-11-09 run: Android 10 does not have Android 12 exact-alarm
      special access. The emulator baseline below covers it.
- [x] Create an entry 10 minutes in the future with a 5-minute reminder.
      Lock the screen. The reminder arrives on time.
- [x] Create a second reminder on the same entry and verify both arrive.
- [x] Tap the notification while the app is closed; the entry editor opens.
- [x] Tap the notification while the app is open; no duplicate screen stack.
- [x] Edit the entry time, then verify the old notification is gone and the new
      time is scheduled.
- [x] Add an "at a time" reminder (for example 08:00) and verify it fires on the
      occurrence day at that local time.
- [x] Enable quiet hours around the reminder time and verify it is suppressed
      after the next queue rebuild.
- [x] Enable work hours and create a Work reminder outside them; verify it is
      suppressed while the task remains visible as a deadline if it is.
- [x] On Android, use the notification's Snooze action; it fires again in about
      ten minutes. Use Complete and verify the entry (or one occurrence) is
      marked done.

## Reboot

- [ ] **FAIL on EMUI 10.** With reminders queued, reboot without opening the app.
      The queued alarms remain in `scheduled_notifications.xml`, but the process
      does not start, no alarm is registered and no reminder fires. EMUI does
      not deliver `BOOT_COMPLETED` to the app. The queue only returns after a
      manual launch; this is not a pass.
- [x] Open the app after reboot and confirm the queue rebuilds without
      duplicates. Exactly the two upcoming alarms were rebuilt.

## Battery optimization

- [ ] **BLOCKED.** The app is whitelisted and in the active bucket, but the boot
      receiver still did not run. The exact EMUI App launch path and a
      restricted-bucket 30-minute reminder test still need the user.
- [ ] If it is delayed, exclude Sundial from optimization and repeat the test.
      Record the exact OEM setting path.

## Timezone change

- [x] Create a timed entry anchored in `Europe/Madrid`, and an all-day birthday
      on the same date.
- [x] Change the device timezone to `America/New_York`. Open or resume Sundial.
- [x] The timed entry moves by the expected offset; the all-day birthday stays
      on the same date.
- [x] Change the timezone back and verify the timed entry returns.
- [x] Schedule a reminder, change the timezone, resume the app, and confirm the
      reminder is still scheduled for the same absolute moment.
- [x] Enable work and quiet hours, then repeat the timezone change. The windows
      are evaluated in the new device zone after the resume rebuild.

## LAN pairing and query

Manual host/port is the supported fallback here; the phone reports "Network
discovery is unavailable" and mDNS could not be used.

Old code-display flow (2026-11-09 run, before the pairing request rework):

- [x] Set a username and PIN on both devices. The PIN is at least four digits.
- [x] On device A, open Devices, show a code, and unlock with the PIN.
- [x] Device B finds A over mDNS, or connects with A's address and port.
- [x] Enter the code on B; both devices show the pairing.
- [x] A's today view and next shift appear on B's Devices page after refresh.
- [x] Kill and reopen B while A is offline; B still shows A's last read-only
      snapshot and never merges it into B's plan.
- [x] Turn on airplane mode, open B, and verify B's own plan still works. Turn
      airplane mode off and refresh; A's snapshot returns.
- [x] Unpair on one device and verify queries are rejected and the cached
      snapshot is removed.

Pairing request flow (protocol 4, started 2026-11-21):

- [x] Both devices use the same username and each has its own PIN.
- [x] On A, open Devices, send a pairing request to B (discovered, or B's
      address and port from B's Devices page).
- [ ] B shows the approval card while Sundial is open. The device name,
      fingerprint and six-digit code match on both screens.
- [ ] Reject on B; A shows that B rejected the request.
- [ ] Send again and approve on B with B's PIN. Both devices report the pairing
      and the Devices page offers the source choice for the two plans.
- [ ] Send a request with a different username on one device; it is refused with
      a "same username" message.
- [ ] Leave a request unanswered for five minutes; A reports that it expired.
- [ ] Close Sundial on B and send a request from A; A reports the expiry and the
      user must open Sundial on B. This is the documented background limit.

Notes from the 2026-11-21 pairing start:

- The first attempt used the old protocol-2 Linux build. Both devices must run
  the current build; `/sundial/v1/info` reports protocol 4.
- Avahi on Linux advertised the desktop's IPv6 link-local address first, while
  the server listens on IPv4, so the phone showed "Could not reach the device".
  The fix advertises the bound IPv4 in the `ip4` TXT attribute and prefers it on
  the client. The nearby list now shows the IPv4 address.

## Replica sync (v14, not yet run on a physical second device)

Use two physical devices or one device plus the Linux desktop. Automated tests
cover the mesh, replacement, rollback and transport; this pass validates the
real UI and LAN behavior.

- [x] Both devices run protocol 4 and the same username.
- [x] Nearby devices shows an animated search state and resolves the desktop
      over IPv4 (not the IPv6 link-local address).
- [x] A pairing request from the phone reaches the desktop's approval card.
- [ ] Approve the request on the desktop with the desktop PIN and verify the
      six-digit code matches on both screens.
- [ ] On B, choose "Use A's plan", enter B's PIN. B reports that a backup was
      written, identity/pairing/device-local settings are intact, and A's
      entries, shifts and home rows appear in B's normal screens.
- [ ] A's plan is unchanged by the replacement.
- [ ] Create an entry on B and pull on A; it appears. Edit different fields on
      both while offline, then pull both ways; both edits survive.
- [ ] Delete a row on A and pull on B; it disappears. Edit that row on B before
      pulling the delete; the newer edit restores it on both.
- [ ] Complete the same occurrence on both devices; one completion row remains
      and both show it done.
- [ ] Close B, add data on A, reopen B; B catches up on start. Turn A off; B
      still opens and edits, and its Devices card shows A's error.
- [ ] Try "Replace this device from A" with the wrong PIN; it is refused and B's
      plan is unchanged.
- [ ] With three devices, pair A–B, A–C and B–C. A change on A reaches C only
      after A–C is paired; B does not relay it. The Devices page lists the
      known-but-not-paired device with a pair action.
- [ ] Unpair one link and verify the missing-link behavior; pair again and
      verify the device catches up.

The old `/sundial/v1/query` snapshot endpoint and `remote_snapshot_records` are
kept for one release and are no longer read by the Devices page.

## Context and project images (schema v15, protocol 4)

Prerequisite: both devices run the same build. A protocol-3 peer is refused with
the "needs a Sundial update" message. Use the existing context/project editor;
there is no new picker.

- [ ] Add or change a context image on the desktop, then pull on the phone. The
      image appears in the phone's context card and detail page, sourced from
      the phone's own `media/cache/<sha256>.png`, not the desktop path.
- [ ] Do the same for a project image.
- [ ] Replace the image on the desktop and pull on the phone. The phone shows
      the new picture; while the fetch is pending the card shows the icon
      fallback, never the old picture.
- [ ] Remove the image on the desktop and pull on the phone. The phone falls
      back to icon and color; the old cache file may remain on disk.
- [ ] Turn the phone's Wi-Fi off, change or remove the image on the desktop,
      turn Wi-Fi on, and pull. The phone converges without user action.
- [ ] Stop the desktop while the phone still needs an image. The row is already
      editable and the phone shows the icon fallback; a later pull retries and
      fetches the image. The Devices card may show a media error until then.
- [ ] On the phone, open Devices and replace its plan from the desktop after
      choosing a PIN. Context and project images are present after the
      replacement, and identity/pairing still work.
- [ ] Repeat the replacement with the desktop's media cache removed (for
      example after a fresh install without its media folder). The replacement
      aborts before clearing the phone and the phone's plan is unchanged.
- [ ] Delete all data on the phone and confirm contexts/projects and
      `media/cache` are gone, then restore a v15 backup and confirm images and
      ids return.
- [ ] Import a v14 backup (no `imageMediaId`) and confirm ids are computed and
      images still show and sync.

## MCP

- [x] Enable the MCP endpoint and allow write tools.
- [x] From the same machine, call `initialize`, `tools/list` and
      `home.shopping` with the bearer token. Use `curl` or an MCP client.
- [x] Check that `initialize` returns an `Mcp-Session-Id`; send it on a later
      call and confirm it is accepted, then `DELETE /mcp` it and confirm the
      next explicit-session call is rejected.
- [x] Send `Accept: text/event-stream` on a `tools/call` and confirm one SSE
      message containing the JSON-RPC result.
- [x] A request without the token is rejected.
- [x] Exercise `plan.range`, `plan.search`, `work.shifts`, `home.inventory`,
      `tags.list` and `sleep.window`.
- [x] `plan.create` creates an entry visible in the app; `plan.update`,
      `plan.complete`, `plan.uncomplete` and `plan.delete` behave as expected.
- [x] `home.shopping_add` then `home.shopping_check` updates the linked
      inventory quantity.
- [x] Disable the endpoint and verify the port is closed.

## Widget

- [ ] **BLOCKED.** Long-press the home screen, add the Sundial widget, and confirm
      it shows today's plan and the next shift. This needs the user's launcher.
- [ ] Tap the widget; Sundial opens.
- [ ] Change today's plan in the app, resume, and confirm the widget updates.

## Backup

- [x] Export a backup, change or delete an entry, import the backup, and verify
      the original state returns.
- [x] Pair the devices, export a backup, and import it into a fresh install.
      The pairing is not restored and both devices still open normally.
- [x] Enable automatic local backups, background and resume Sundial, and confirm a
      `sundial-auto-*.json` file exists in the app support `backups` folder (use
      `adb shell run-as` on a debug build).
- [ ] Change the copy count, let several days pass or adjust the clock, and
      confirm older copies are removed. Not forced in this run.
- [x] Import a GymMane `gymmane.json` backup and confirm the weekly blocks are
      read-only. A backup without `trainAt` must produce all-day blocks.
- [x] Export and re-import entries CSV without duplicating rows. Shopping and
      inventory CSV are covered by the unit round-trip test; they were not
      re-run on the device.

## App lock

All items pass after the 2026-11-09 fix that moved the gate above the Navigator.

- [x] Enable the lock, set a four-digit PIN, background the app for more than
      30 seconds, and confirm the PIN pad covers the plan on resume.
- [x] Enter the wrong PIN five times; confirm the 30-second lockout, then
      unlock with the correct PIN.
- [x] Kill and relaunch the app; the lock must appear before the plan.
- [x] Disable the lock and confirm the app opens directly again.
- [x] Import a backup into a fresh install; the lock must stay off, because its
      hash is device-local.

## Report

Record for each failure:

- device model and Android version,
- build version and whether it is debug or signed release,
- exact steps,
- expected and actual behavior,
- whether the failure reproduces after a cold start.

Do not tag v1.0 until every notification, reboot, battery and timezone item has
a result, even if the result is "not reliable in this OEM's battery saver".
