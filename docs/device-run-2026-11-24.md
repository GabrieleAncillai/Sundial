# Sundial device run — 2026-11-24

Time-boxed unattended verification of the v1.0 device gate. The run covered the
baseline build, launch and permission inventory, reminders and notification tap,
clean phone-initiated pairing, source replacement, deltas and tombstones in both
directions, and the content-addressed image lifecycle. The phone dropped off USB
after the reboot step and never returned, so the run stopped there per the
failure policy. Timezone, Doze, quiet hours, desktop-initiated pairing and the
unpair/re-pair cycle were left for the human.

## Device and build

| Item | Value |
|---|---|
| Device | HUAWEI MAR-LX3A, EMUI 10 |
| Android | 10 / API 29 |
| Build | `0.9.0+9`, debug APK, `io.github.sundial` |
| Base commit | `e0015bf` (`docs(ui): record and cover the shared menu kit`), dirty tree with 225 pre-existing changes |
| Timezone | `America/Caracas` |
| Network | phone `172.16.20.167/24`, desktop `172.16.20.23/24` |
| Test data | Agent-created entries, tags, a shift, an inventory row and two 16×16 PNGs. The phone's previous plan was test data per the run configuration; a backup was written before replacement. |
| Run window | 19:35–20:20 local (hard stop at minute 80 of 90) |

## Results

| Item | Result | Evidence | Notes |
|---|---|---|---|
| Preflight gate | PASS | `adb devices -l` showed one `device`; API 29; `flutter devices` listed linux and android; both hosts in `172.16.20.0/24`; `mWakefulness=Awake`; `stay_on_while_plugged_in=7` | All required gates met. |
| Phase A: analyze | PASS | `flutter analyze --no-fatal-infos` → `No issues found! (ran in 6.3s)` | After `pub get` and `build_runner build --force-jit`. |
| Phase A: app tests | PASS | `flutter test` → `All tests passed!` (432) | Exit 0. |
| Phase A: core tests | PASS | `(cd packages/sundial_core && dart test)` → `All tests passed!` (113) | Exit 0. |
| Phase A: build and install | PASS | `flutter build apk --debug`; `adb install -r`; `versionName=0.9.0 versionCode=9 lastUpdateTime=2026-11-24 19:37:37` | Installed build matched the build output. |
| Phase B: launch | PASS | `am start` then `logcat -d | grep -iE "FATAL|AndroidRuntime"` empty | No crash. |
| Phase B: permissions | N/A by API level | Manifest lists `POST_NOTIFICATIONS` and `SCHEDULE_EXACT_ALARM`; `appops get … SCHEDULE_EXACT_ALARM` → `Unknown operation string` | API 29 predates both runtime permissions. |
| Phase B: boot/alarm permissions | PASS | `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `FOREGROUND_SERVICE` granted | Inventory only. Device-idle whitelist was empty. |
| Phase C: relative reminder | PASS | Alarm for `19:47:00.000`; `NotificationService: enqueue … id=467366085` at `19:47:00.076`; channel `sundial_reminders_chime`; `android.title=AgentTest Reminder A`; actions `Snooze 10 minutes`, `Mark complete` | Fired at the scheduled second while the app was open. |
| Phase C: notification tap | PASS | `dumpsys activity activities` stayed on `MainActivity`; UI dumped `Edit entry` with title `AgentTest Reminder A` | Opened the correct editor. |
| Phase C: absolute reminder | DEFERRED | Alarm `when=2026-11-24 19:50:00.000` was queued and exact | The post was not observed; the run was mid-pairing and then the device rebooted. |
| Phase C: snooze/complete actions | DEFERRED | Actions were present in `dumpsys notification` | Not exercised before reboot. |
| Phase C: process-death alarm | DEFERRED | — | Not tested. |
| Phase C: quiet-hours suppression | DEFERRED | — | Not tested in this run. |
| Phase F1: phone-initiated pairing | PASS | Peer request `690595`, phone fingerprint `26ac…2da0`; harness `waitForPeer` returned `Huawei P30 Lite`; phone showed “Paired with AgentPeer” | Clean first-time exchange at `172.16.20.23:43564`. |
| Phase F2: desktop-initiated pairing | DEFERRED | — | Not attempted; phone server port changed between launches (see finding 2). |
| Phase F3: source replacement | PASS | Backup `files/backups/sundial-auto-20261124-195809.json`; phone rows after: 1 entry, 1 context, 1 project, 7 tags, 1 home item, 1 shift pattern, 1 slot; `datasetId=b7b22d87…` matched the peer; identity and pairing rows survived | Phone showed “The plan was replaced.” |
| Phase F4: peer→phone delta | PASS | After app start, `entry_records` gained `Peer Delta 2`; `sync_peer_state.last_pulled_seq=8`, `last_error=null` | Arrived within 45 s without opening Devices. |
| Phase F4: phone→peer delta | PASS | Peer `pullPeer` → `applied:3, skipped:73, pages:2`; peer entries 3 including `Phone Delta 1` | Peer cursor advanced. |
| Phase F4: tombstone | PASS | Delete on peer; phone `deleted_at` set for `Peer Delta 2`; `sync_tombstone_records` row for the entry id; `last_pulled_seq=9` | Delete stayed deleted. |
| Phase F5: unpair/re-pair | FAIL | `Unpair` and per-device `Refresh` were rendered disabled (`clickable` absent) while the stale peer stayed `Syncing…`; row removal was done out-of-band from the stopped database | See finding 1. Re-pair catch-up not tested. |
| Phase F6: payload secrecy | DEFERRED | — | Export not pulled before the device disappeared. Existing automated tests cover payload secrecy. |
| Phase G: context image | PASS | `context_records.image_media_id=c48490…7585b`; `media_cache_records` has the same id; `files/media/cache/c48490….png` exists; `image_path` is the phone cache path, not the desktop path | Image arrived with source replacement. |
| Phase G: project image | PASS | `project_records.image_media_id=c48490…7585b`; rendered in `Peer Project` | Same content address as the context image. |
| Phase G: replace image | PASS | Peer set image B; phone rows moved to `3e29cdb7…cee1a`; new cache file written; old cache file retained | Both context and project. |
| Phase G: remove image | PASS | Peer cleared images; phone rows `image_media_id=null`; Personal page showed the folder fallback; no crash | Both context and project. |
| Phase G: offline retry | PASS with caveat | With the peer stopped, the app opened, showed `The device is offline`, and remained editable; after the peer returned and the app restarted, the missing cache file was fetched and both rows pointed at `3e29…` again | The exact row-applied-before-media-fetch window was not isolated. |
| Phase G: fallback while missing media | PASS | Cache file deleted; Personal page showed the icon fallback; later pull restored the file | No stale picture shown. |
| Phase G: image render | PASS | Screenshot `/tmp/device-run/personal-image2.png`: blue `Peer Person` and `Peer Project` tiles | Test images only. |
| Phase G: replacement with media | PASS | Replacement above staged and verified `c48490…` before clearing the phone; image present after replacement | — |
| Phase D: reboot | BLOCKED | Alarm `when=2026-11-24 20:35:00.000` queued; `adb reboot`; `sys.boot_completed=1`; then `am start` → `Error type 3: Activity class … does not exist`; `adb devices -l` empty on three retries over 60 s | Reminder due at 20:35 could not be observed. |
| Phase H: peer offline | PASS | App opened with the peer stopped; Devices showed the offline error; plan remained editable | No blocking dialog. |
| Phase H: airplane mode | DEFERRED | — | Not tested. |
| Phase H: Doze | DEFERRED | — | Not tested. |
| Phase E: timezone | DEFERRED | — | Not tested. |

## Findings

### 1. A stale peer can pin the Devices page in `pulling` and disable Unpair

The phone was still paired to the previous desktop address `192.168.0.110:43563`
from a different network. On launch the peer card showed `Syncing…`, and the
per-device refresh and Unpair controls were disabled because
`peer.pulling` stayed true. It never cleared; the only way to remove the peer
was to stop the app and delete the `paired_device_records` and
`sync_peer_state_records` rows out-of-band. The old address is unreachable, so
this is reproducible with any peer that moved networks while remaining paired.

Suspected cause: the pull future is not completed when the peer is unreachable,
so the busy flag never resets. A regression test should pull from an address
that drops SYN packets and assert the pull finishes and the buttons re-enable.
Not fixed in this run.

### 2. The phone's LAN server port changes on every launch

Observed server ports: `33147` at pairing, `35985` after source replacement,
`39801` on the next launch, `35209` after the reboot. Paired peers store
`host:port` at pairing and do not learn the new port without discovery. The
headless peer had to update its stored port before it could pull the phone.

This is the Android side of the documented `GET /sundial/v1/info` and mDNS
design: a peer with working discovery can refresh the endpoint, but a peer
without discovery (or a desktop whose avahi cache is cold) cannot reach the
phone after a restart. A stable port, or an advertised endpoint the peer
persists, would remove the gap.

### 3. Reboot lost the USB connection before the app could be opened

The reboot itself completed (`sys.boot_completed=1`), but `am start` reported
`Error type 3: Activity class {io.github.sundial/io.github.sundial.MainActivity}
does not exist` and then `adb devices -l` was empty for all three retries. The
known EMUI `BOOT_COMPLETED` limitation still stands; this run could not add new
evidence either way because the device never re-appeared. The 20:35 reminder
result is unknown.

## Deliberately not tested

- Timezone change and restore (phase E).
- Doze/force-idle, airplane mode, and the OEM battery-killer window.
- Quiet-hours and work-hours suppression.
- Snooze and Mark complete notification actions, and alarm survival after
  `force-stop`.
- Desktop-initiated pairing, unpair/re-pair, and the three-device mesh.
- Backup export and payload-secrecy inspection on the device.
- TalkBack, widget, lock screen, release-signed build and the post-run data
  review. These stay in `docs/manual-device-checklist.md`.

## Artifacts

- Harness: `tool/device_peer/main.dart`.
- Raw evidence: `/tmp/device-run/` (`peer.log`, `peer2.log`,
  `phone-*.sqlite`, notification and Personal-page screenshots).
- No screenshot or report contains a PIN, shared key, certificate private key or
  a personal entry title. Only agent-created test rows are named.
