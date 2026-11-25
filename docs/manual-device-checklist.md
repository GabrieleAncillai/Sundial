# Manual device checklist

The residual v1.0 device gate: only the items an agent cannot complete on its
own. Everything else on `docs/device-checklist.md` is covered by the unattended
run in `docs/unattended-device-run.md`.

Target: HUAWEI MAR-LX3A, Android 10 / API 29 (EMUI). Because API 29 predates the
Android 12 exact-alarm and Android 13 notification permissions, those two matrix
items are closed as **N/A**, not as passes.

Run the unattended pass first. It leaves a dated `docs/device-run-<date>.md` with
pass/fail/blocked per item; this file is what remains after that report.

The 2026-11-24 run is time-boxed to 90 minutes. Expect it to defer the timezone
and Doze items back here, and to leave the three-device mesh untested. The
unattended report is authoritative about what it actually covered; do not assume
an item passed because it is absent from this list.

Record for each item: date, build version, result, and one line of evidence.

---

## 1. OEM battery killer over a real idle window

**Why only you.** `dumpsys deviceidle force-idle` simulates Doze, but EMUI's own
task killer is a vendor layer above AOSP. It only reveals itself over hours, on
battery, unplugged, with the screen off. No adb command reproduces it.

**Setup.** Settings > Battery > App launch > Sundial > Manage manually, with all
three toggles (auto-launch, secondary launch, run in background) ON. Note which
state you started in.

**Steps.**
1. Create a reminder 90 minutes out.
2. Unplug, lock the screen, leave the phone untouched for 2 hours.
3. Unlock and check whether the notification is present and roughly on time.
4. Repeat once with the three toggles OFF, if you want to know whether the
   protection is actually required.

**Pass.** Notification arrives within 60 seconds of its scheduled time with the
toggles ON. Record the OFF result as information, not a failure.

**Budget.** 2 x 2 hours, can run overnight in parallel with everything else.

---

## 2. Reboot: accept the limitation or fund a fix

**Why only you.** The agent can run `adb reboot` and will confirm the current
behaviour. The decision that follows is a product call, not a test.

**Known state.** On this device EMUI does not deliver `BOOT_COMPLETED` to the
app, so the reminder queue is not rebuilt after a reboot until the app is opened.
Documented in `docs/device-checklist.md` and listed in `AGENTS.md`.

**Steps.**
1. After the agent's reboot phase, read its result.
2. Accept one of: (a) the limitation stays, documented as "open the app once
   after a reboot"; (b) a fix is scheduled (WorkManager job, or a
   manufacturer-agnostic bootstrap on first launch after boot).

**Pass.** The chosen option is written into `docs/full-docs.md` and the roadmap.
No code change is required to close this item if you choose (a).

---

## 3. Real network transitions

**Why only you.** The agent can turn Wi-Fi off and on from adb. It cannot leave
the LAN, join a different access point, or reproduce a router that filters
multicast.

**Steps.**
1. While paired and synced, walk out of range for five minutes, return.
2. Sync a change made in the meantime on the desktop; confirm it arrives without
   opening the Devices page.
3. On a foreign network (hotel, office guest Wi-Fi with client isolation),
   confirm the app still opens and edits locally, and that Devices reports the
   peer as unreachable rather than crashing or retrying forever.

**Pass.** Convergence on return; the app never blocks on a missing peer.

---

## 4. Lock screen and heads-up presentation

**Why only you.** `screencap` captures pixels, not judgement. Whether a reminder
is legible, correctly grouped and appropriately loud is a taste and UX call, and
EMUI groups and truncates differently from AOSP.

**Steps.**
1. With the screen locked, trigger a task reminder and a shift reminder.
2. Observe: presence on the lock screen, title/body truncation, grouping when
   two are pending, sound and vibration, and whether tapping opens the right
   entry.
3. Trigger one during quiet hours to confirm silence, and one outside them.

**Pass.** Legible and correctly routed; the quiet-hours case is silent; nothing
is so aggressive that you would mute the app.

---

## 5. TalkBack usability pass

**Why only you.** Widget semantics tests prove labels exist. They do not prove
the app is usable with a screen reader.

**Steps.**
1. Settings > Accessibility > TalkBack on.
2. Navigate: Today, Week, Calendar month, open and save an entry, complete a
   task, open a shift checklist.
3. Note anywhere focus order, labels or custom actions are wrong.

**Pass.** Every control is reachable and announces something meaningful. File
each defect as a follow-up; a first-pass audit does not need to be perfect.

---

## 6. Home-screen widget on the real launcher

**Why only you.** Adding, resizing and placing a widget happens in the launcher.
No adb path exists that a reasonable agent should take.

**Steps.**
1. Add the Sundial widget, resize it small and large.
2. Confirm it shows today's plan and the next shift.
3. Change an entry in the app, background the app, confirm the widget refreshes.
4. Reboot and confirm what the widget shows before the app is opened (expect
   stale or blank, consistent with item 2).

**Pass.** Renders correctly at both sizes; refresh works on open/resume.

---

## 7. Release-signed build sanity

**Why only you.** It needs your keystore, and installing a differently signed
APK forces an uninstall, which wipes the phone's local plan.

**Steps.**
1. Export a backup from the debug build and copy it off the phone.
2. Uninstall, install the release-signed APK, restore the backup.
3. Confirm Android does not carry over state from the debug build (expected) and
   that the restore is complete.
4. Spot-check reminders and LAN pairing still work in the release build.

**Pass.** Release build restores a debug backup and schedules reminders. Until
this passes, do not call the APK a production release.

---

## 8. Post-run data review

**Why only you.** The unattended run replaces the phone's plan as part of the
source-replacement test, after writing a backup. Deciding that the result is
acceptable is yours.

**Steps.**
1. Compare the phone's plan to the backup the run wrote.
2. Restore your own backup if you would rather not keep the test plan.
3. Confirm identity, pairing records and the app lock still behave as expected.

**Pass.** You are back on the data you want, with no orphaned paired devices.

---

## Residual gap: second physical Android device

Not achievable with one phone. Phone-to-desktop covers the full transport, TLS,
pairing, media and replacement path across two physical machines and two OS
stacks. Pure Android-to-Android remains unobserved on hardware; the same code
path is covered by the mesh tests and by the emulator pass, so this is a
low-risk residual, not a blocker.

---

## Close-out

When items 1-8 have a recorded result, update `docs/device-checklist.md` with a
dated section that points here, and state explicitly which items are passes,
which are accepted limitations, and which are deferred with a reason.
