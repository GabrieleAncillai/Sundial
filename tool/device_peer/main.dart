// Headless LAN peer for the unattended device run.
//
// Boots the real database, identity, LAN server, sync store and engine against
// an explicit data directory, executes a JSON step script and prints one JSON
// line per step. Never touches the real app-support directory.
//
// flutter run -d linux -t tool/device_peer/main.dart \
//   --dart-define=SCRIPT=/tmp/device-run/peer-script.json
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:sundial/features/media/media_store.dart';
import 'package:sundial/features/sync/device_certificate.dart';
import 'package:sundial/features/sync/identity_service.dart';
import 'package:sundial/features/sync/lan_client.dart';
import 'package:sundial/features/sync/lan_server.dart';
import 'package:sundial/features/sync/pairing_request.dart';
import 'package:sundial/features/sync/sync_engine.dart';
import 'package:sundial/features/sync/sync_store.dart';
import 'package:sundial/models/home_item.dart';
import 'package:sundial/models/local_identity.dart';
import 'package:sundial/models/paired_device.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial/services/planner_repository.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:uuid/uuid.dart';

const _imageA =
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAHUlEQVR4nGO8Y2Pzn4ECwESJ5lEDRg0YNWAwGQAAsMMCc5Uekf8AAAAASUVORK5CYII=';
const _imageB =
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAHUlEQVR4nGO0ibrzn4ECwESJ5lEDRg0YNWAwGQAAKTYCkaAWWAUAAAAASUVORK5CYII=';

const _uuid = Uuid();

late AppDatabase db;
late PlannerRepository repository;
late SyncStore store;
late IdentityService identities;
late LocalIdentity identity;
late LanServer server;
late String dataDir;
final _contexts = <String, PlannerContext>{};
final _projects = <String, Project>{};

void emit(String step, {bool ok = true, Object? detail, String? error}) {
  stdout.writeln(jsonEncode({'step': step, 'ok': ok, 'detail': detail, 'error': error}));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));

  final scriptPath = Platform.environment['PEER_SCRIPT'] ?? const String.fromEnvironment('SCRIPT');
  if (scriptPath.isEmpty) {
    stderr.writeln('SCRIPT dart-define is required');
    exit(2);
  }
  final script = jsonDecode(await File(scriptPath).readAsString());
  final steps = script is List ? script : (script as Map)['steps'] as List;
  dataDir = Platform.environment['PEER_DATA'] ?? const String.fromEnvironment('PEER_DATA');
  if (dataDir.isEmpty) {
    stderr.writeln('PEER_DATA dart-define is required');
    exit(2);
  }
  await Directory(dataDir).create(recursive: true);
  await Directory(p.join(dataDir, 'images')).create(recursive: true);

  db = AppDatabase(
    NativeDatabase.createInBackground(File(p.join(dataDir, 'sundial.sqlite'))),
    defaultTimeZone: 'America/Caracas',
    mediaStore: MediaStore(directory: Directory(p.join(dataDir, 'media'))),
  );
  await db.seedDefaults();
  repository = PlannerRepository(db);
  store = SyncStore(db);
  identities = IdentityService(repository);

  identity =
      await identities.read() ??
      await identities.create(
        username: const String.fromEnvironment('PEER_USERNAME', defaultValue: 'muffin'),
        deviceName: const String.fromEnvironment('PEER_NAME', defaultValue: 'AgentPeer'),
        pin: await _peerPin(),
      );

  server = LanServer(repository: repository, syncStore: store, deviceTimeZone: () => 'America/Caracas');

  for (final raw in steps) {
    final step = raw as Map;
    final name = step['step'] as String? ?? '';
    try {
      final detail = await _run(name, step);
      emit(name, detail: detail);
    } catch (error) {
      emit(name, ok: false, error: '$error');
    }
  }
  await server.dispose();
  await db.close();
  exit(0);
}

Future<String> _peerPin() async {
  final path = Platform.environment['PEER_PIN_FILE'] ?? const String.fromEnvironment('PEER_PIN_FILE');
  if (path.isEmpty) return '0000';
  return (await File(path).readAsString()).trim();
}

Future<Object?> _run(String name, Map step) async {
  switch (name) {
    case 'startServer':
      final port = step['port'] as int? ?? 0;
      await server.start(identity: identity, port: port);
      return _info();
    case 'printInfo':
      return _info();
    case 'createEntry':
      return _createEntry(step);
    case 'deleteEntry':
      return _deleteEntry(step);
    case 'createTag':
      return _createTag(step);
    case 'createHomeItem':
      return _createHomeItem(step);
    case 'createShift':
      return _createShift(step);
    case 'createContextWithImage':
      return _createContext(step);
    case 'createProjectWithImage':
      return _createProject(step);
    case 'replaceImage':
      return _replaceImage(step, useProject: false);
    case 'replaceProjectImage':
      return _replaceImage(step, useProject: true);
    case 'removeImage':
      return _removeImage(step, useProject: false);
    case 'removeProjectImage':
      return _removeImage(step, useProject: true);
    case 'waitForPairingRequest':
      return _waitForRequest(step);
    case 'approveRequest':
      return _approveRequest(step);
    case 'rejectRequest':
      return _rejectRequest(step);
    case 'waitForPeer':
      return _waitForPeer(step);
    case 'pullPeer':
      return _pullPeer(step);
    case 'requestPairing':
      return _requestPairing(step);
    case 'awaitPairApproval':
      return _awaitPairApproval(step);
    case 'dumpDebug':
      return (await store.readDebugSnapshot()).toJson();
    case 'dumpCounts':
      return _counts();
    case 'sleep':
      await Future<void>.delayed(Duration(seconds: step['seconds'] as int? ?? 1));
      return null;
    case 'quit':
      return 'quitting';
    default:
      throw StateError('Unknown step $name');
  }
}

Future<Map<String, Object?>> _info() async {
  final state = await store.deviceState();
  final fingerprint = await fingerprintOfCertificatePem(identity.certificatePem);
  return {
    'address': server.address,
    'port': server.port,
    'protocol': LanServer.protocolVersion,
    'fingerprint': fingerprint,
    'deviceId': identity.deviceId,
    'deviceName': identity.deviceName,
    'username': identity.username,
    'datasetId': state.datasetId,
    'nodeId': state.nodeId,
    'hasUserData': await repository.hasUserData(),
    'dataDir': dataDir,
  };
}

Future<Map<String, Object?>> _createEntry(Map step) async {
  final spaces = await repository.watchSpaces().first;
  final spaceName = step['space'] as String? ?? 'Personal';
  final space = spaces.firstWhere((row) => row.name == spaceName, orElse: () => spaces.first);
  final now = DateTime.now().toUtc();
  final title = step['title'] as String? ?? 'Peer entry ${now.millisecondsSinceEpoch}';
  final date = LocalDate.fromDateTime(DateTime.now());
  final entry = Entry(
    id: _uuid.v4(),
    spaceId: space.id,
    title: title,
    notes: step['notes'] as String? ?? '',
    date: date,
    allDay: true,
    createdAt: now,
    updatedAt: now,
  );
  await repository.saveEntry(entry);
  return {'id': entry.id, 'title': title, 'spaceId': space.id};
}

Future<Map<String, Object?>> _deleteEntry(Map step) async {
  final title = step['title'] as String;
  final row = await (db.select(
    db.entryRecords,
  )..where((r) => r.title.equals(title) & r.deletedAt.isNull())).getSingleOrNull();
  if (row == null) throw StateError('No live entry titled $title');
  await repository.deleteEntry(row.id);
  return {'id': row.id, 'title': title};
}

Future<Map<String, Object?>> _createTag(Map step) async {
  final spaces = await repository.watchSpaces().first;
  final space = spaces.firstWhere((row) => row.name == 'Personal', orElse: () => spaces.first);
  final tag = Tag(
    id: _uuid.v4(),
    spaceId: step['global'] == true ? null : space.id,
    name: step['name'] as String? ?? 'PeerTag',
    colorValue: 0xFF44AA88,
    position: 0,
  );
  await repository.saveTag(tag);
  return {'id': tag.id, 'name': tag.name};
}

Future<Map<String, Object?>> _createHomeItem(Map step) async {
  final item = HomeItem(
    id: _uuid.v4(),
    name: step['name'] as String? ?? 'Peer Rice',
    description: 'agent peer',
    category: 'Pantry',
    location: 'Shelf',
    quantity: 2,
    unit: 'kg',
    reorderLevel: 1,
  );
  await repository.saveHomeItem(item);
  return {'id': item.id, 'name': item.name};
}

Future<Map<String, Object?>> _createShift(Map step) async {
  final spaces = await repository.watchSpaces().first;
  final space = spaces.firstWhere((row) => row.name == 'Work', orElse: () => spaces.first);
  final today = LocalDate.fromDateTime(DateTime.now());
  final pattern = ShiftPattern(
    id: _uuid.v4(),
    spaceId: space.id,
    name: step['name'] as String? ?? 'Peer Shift',
    timeZone: 'America/Caracas',
    cycleDays: 7,
    anchorDate: today,
    slots: [ShiftSlot(dayIndex: 0, startMinute: 9 * 60, endMinute: 17 * 60, label: 'Peer')],
  );
  await repository.saveShiftPattern(pattern);
  return {'id': pattern.id, 'name': pattern.name, 'spaceId': space.id};
}

Future<Map<String, Object?>> _createContext(Map step) async {
  final path = await _writeImage('a');
  final spaces = await repository.watchSpaces().first;
  final space = spaces.firstWhere((row) => row.name == 'Personal', orElse: () => spaces.first);
  final context = PlannerContext(
    id: _uuid.v4(),
    spaceId: space.id,
    name: step['name'] as String? ?? 'Peer Person',
    description: 'agent peer image A',
    colorValue: 0xFFAA6644,
    icon: 'person',
    imagePath: path,
  );
  await repository.saveContext(context);
  _contexts[context.id] = context;
  final row = await (db.select(db.contextRecords)..where((r) => r.id.equals(context.id))).getSingle();
  return {'id': context.id, 'imagePath': path, 'imageMediaId': row.imageMediaId};
}

Future<Map<String, Object?>> _createProject(Map step) async {
  final path = await _writeImage('a');
  final spaces = await repository.watchSpaces().first;
  final space = spaces.firstWhere((row) => row.name == 'Personal', orElse: () => spaces.first);
  final project = Project(
    id: _uuid.v4(),
    spaceId: space.id,
    name: step['name'] as String? ?? 'Peer Project',
    description: 'agent peer image A',
    colorValue: 0xFF4466AA,
    imagePath: path,
  );
  await repository.saveProject(project);
  _projects[project.id] = project;
  final row = await (db.select(db.projectRecords)..where((r) => r.id.equals(project.id))).getSingle();
  return {'id': project.id, 'imagePath': path, 'imageMediaId': row.imageMediaId};
}

Future<Map<String, Object?>> _replaceImage(Map step, {required bool useProject}) async {
  final id = step['id'] as String;
  final path = await _writeImage('b');
  if (useProject) {
    final old = _projects[id] ?? await _loadProject(id);
    final project = Project(
      id: old.id,
      spaceId: old.spaceId,
      contextId: old.contextId,
      name: old.name,
      description: old.description,
      colorValue: old.colorValue,
      icon: old.icon,
      imagePath: path,
      position: old.position,
    );
    await repository.saveProject(project);
    _projects[id] = project;
    final row = await (db.select(db.projectRecords)..where((r) => r.id.equals(id))).getSingle();
    return {'id': id, 'imagePath': path, 'imageMediaId': row.imageMediaId};
  }
  final old = _contexts[id] ?? await _loadContext(id);
  final context = PlannerContext(
    id: old.id,
    spaceId: old.spaceId,
    name: old.name,
    description: old.description,
    colorValue: old.colorValue,
    icon: old.icon,
    imagePath: path,
    position: old.position,
  );
  await repository.saveContext(context);
  _contexts[id] = context;
  final row = await (db.select(db.contextRecords)..where((r) => r.id.equals(id))).getSingle();
  return {'id': id, 'imagePath': path, 'imageMediaId': row.imageMediaId};
}

Future<Map<String, Object?>> _removeImage(Map step, {required bool useProject}) async {
  final id = step['id'] as String;
  if (useProject) {
    final old = _projects[id] ?? await _loadProject(id);
    final project = Project(
      id: old.id,
      spaceId: old.spaceId,
      contextId: old.contextId,
      name: old.name,
      description: old.description,
      colorValue: old.colorValue,
      icon: old.icon,
      position: old.position,
    );
    await repository.saveProject(project);
    _projects[id] = project;
    final row = await (db.select(db.projectRecords)..where((r) => r.id.equals(id))).getSingle();
    return {'id': id, 'imageMediaId': row.imageMediaId};
  }
  final old = _contexts[id] ?? await _loadContext(id);
  final context = PlannerContext(
    id: old.id,
    spaceId: old.spaceId,
    name: old.name,
    description: old.description,
    colorValue: old.colorValue,
    icon: old.icon,
    position: old.position,
  );
  await repository.saveContext(context);
  _contexts[id] = context;
  final row = await (db.select(db.contextRecords)..where((r) => r.id.equals(id))).getSingle();
  return {'id': id, 'imageMediaId': row.imageMediaId};
}

Future<String> _writeImage(String which) async {
  final file = File(p.join(dataDir, 'images', 'image-$which-${DateTime.now().microsecondsSinceEpoch}.png'));
  await file.writeAsBytes(base64Decode(which == 'a' ? _imageA : _imageB), flush: true);
  return file.path;
}

Future<PlannerContext> _loadContext(String id) async {
  final row = await (db.select(db.contextRecords)..where((r) => r.id.equals(id))).getSingleOrNull();
  if (row == null) throw StateError('Unknown context id $id');
  return PlannerContext(
    id: row.id,
    spaceId: row.spaceId,
    name: row.name,
    description: row.description,
    colorValue: row.color,
    icon: row.icon,
    imagePath: row.imagePath,
    position: row.position,
    deletedAt: row.deletedAt,
  );
}

Future<Project> _loadProject(String id) async {
  final row = await (db.select(db.projectRecords)..where((r) => r.id.equals(id))).getSingleOrNull();
  if (row == null) throw StateError('Unknown project id $id');
  return Project(
    id: row.id,
    spaceId: row.spaceId,
    contextId: row.contextId,
    name: row.name,
    description: row.description,
    colorValue: row.color,
    icon: row.icon,
    imagePath: row.imagePath,
    position: row.position,
    deletedAt: row.deletedAt,
  );
}

Future<Map<String, Object?>> _waitForRequest(Map step) async {
  final deadline = DateTime.now().add(Duration(seconds: step['timeoutSeconds'] as int? ?? 300));
  while (DateTime.now().isBefore(deadline)) {
    final request = server.pendingPairingRequest;
    if (request != null) {
      return {
        'id': request.id,
        'code': request.code,
        'displayCode': request.displayCode,
        'deviceName': request.deviceName,
        'deviceId': request.deviceId,
        'fingerprint': request.certificateFingerprint,
        'host': request.host,
        'port': request.port,
        'datasetId': request.datasetId,
      };
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw StateError('No pairing request arrived');
}

Future<Map<String, Object?>> _approveRequest(Map step) async {
  final request = server.pendingPairingRequest;
  if (request == null) throw StateError('No pending pairing request');
  if (!await identities.verifyPin(identity, await _peerPin())) {
    throw StateError('Peer PIN file does not match the identity');
  }
  final approved = server.approvePairingRequest(request.id);
  if (approved == null) throw StateError('Request was no longer pending');
  return {'id': approved.id, 'code': approved.displayCode, 'status': approved.status.name};
}

Future<Map<String, Object?>> _rejectRequest(Map step) async {
  final request = server.pendingPairingRequest;
  if (request == null) throw StateError('No pending pairing request');
  final rejected = server.rejectPairingRequest(request.id);
  if (rejected == null) throw StateError('Request was no longer pending');
  return {'id': rejected.id, 'status': rejected.status.name};
}

Future<Map<String, Object?>> _waitForPeer(Map step) async {
  final deadline = DateTime.now().add(Duration(seconds: step['timeoutSeconds'] as int? ?? 120));
  while (DateTime.now().isBefore(deadline)) {
    final peers = await repository.readPairedDevices();
    if (peers.isNotEmpty) {
      return {
        'peers': [for (final peer in peers) _peerJson(peer)],
      };
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw StateError('Pairing did not complete');
}

Map<String, Object?> _peerJson(PairedDevice peer) => {
  'id': peer.id,
  'name': peer.name,
  'username': peer.username,
  'fingerprint': peer.certificateFingerprint,
  'host': peer.host,
  'port': peer.port,
};

Future<Map<String, Object?>> _pullPeer(Map step) async {
  final peers = await repository.readPairedDevices();
  final target = step['deviceName'] as String?;
  final results = <Map<String, Object?>>[];
  for (final peer in peers) {
    if (target != null && peer.name != target) continue;
    final engine = SyncEngine(store: store, transport: LanClient(repository));
    final pulled = await engine.pull(peer, localDeviceId: identity.deviceId);
    results.add({
      'peer': peer.name,
      'applied': pulled.result.applied,
      'skipped': pulled.result.skipped,
      'deleted': pulled.result.deleted,
      'pages': pulled.pages,
      'didSnapshot': pulled.didSnapshot,
      'mediaError': pulled.mediaError,
      'missingMediaIds': pulled.result.missingMediaIds.toList(),
    });
  }
  return {'pulls': results};
}

Future<Map<String, Object?>> _requestPairing(Map step) async {
  final client = LanClient(repository);
  final state = await store.deviceState();
  final fingerprint = await fingerprintOfCertificatePem(identity.certificatePem);
  final request = await client.requestPairing(
    identity: identity,
    myFingerprint: fingerprint,
    host: step['host'] as String,
    port: step['port'] as int,
    myServerPort: server.port,
    datasetId: state.datasetId,
    hasUserData: await repository.hasUserData(),
    displayName: identity.deviceName,
  );
  return {
    'id': request.id,
    'code': request.code,
    'displayCode': request.code.length == 6
        ? '${request.code.substring(0, 3)} ${request.code.substring(3)}'
        : request.code,
    'host': request.host,
    'port': request.port,
    'fingerprint': request.certificateFingerprint,
    'expiresAt': request.expiresAt.toIso8601String(),
  };
}

Future<Map<String, Object?>> _awaitPairApproval(Map step) async {
  final pending = step['pending'] as Map;
  final client = LanClient(repository);
  final deadline = DateTime.now().add(Duration(seconds: step['timeoutSeconds'] as int? ?? 300));
  while (DateTime.now().isBefore(deadline)) {
    final status = await client.readPairRequest(
      requestId: pending['id'] as String,
      host: pending['host'] as String,
      port: pending['port'] as int,
      pinnedFingerprint: pending['fingerprint'] as String,
    );
    if (status.status == PairingRequestStatus.rejected) {
      throw StateError('The phone rejected the request');
    }
    if (status.status == PairingRequestStatus.expired) {
      throw StateError('The phone let the request expire');
    }
    if (status.status == PairingRequestStatus.approved && status.approvalToken != null) {
      final fingerprint = await fingerprintOfCertificatePem(identity.certificatePem);
      final result = await client.completePairing(
        identity: identity,
        myFingerprint: fingerprint,
        host: pending['host'] as String,
        port: pending['port'] as int,
        code: pending['code'] as String,
        requestId: pending['id'] as String,
        approvalToken: status.approvalToken!,
        expectedFingerprint: pending['fingerprint'] as String,
        myServerPort: server.port,
      );
      return {'peer': _peerJson(result.device), 'datasetId': result.datasetId};
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw StateError('The phone did not approve the request');
}

Future<Map<String, Object?>> _counts() async {
  final entries = await db.select(db.entryRecords).get();
  final contexts = await db.select(db.contextRecords).get();
  final projects = await db.select(db.projectRecords).get();
  final tags = await db.select(db.tagRecords).get();
  final home = await db.select(db.homeItemRecords).get();
  final shopping = await db.select(db.shoppingItemRecords).get();
  final patterns = await db.select(db.shiftPatternRecords).get();
  final peers = await repository.readPairedDevices();
  return {
    'entries': entries.where((row) => row.deletedAt == null).length,
    'contexts': contexts.where((row) => row.deletedAt == null).length,
    'projects': projects.where((row) => row.deletedAt == null).length,
    'tags': tags.where((row) => row.deletedAt == null).length,
    'homeItems': home.where((row) => row.deletedAt == null).length,
    'shoppingItems': shopping.where((row) => row.deletedAt == null).length,
    'shiftPatterns': patterns.where((row) => row.deletedAt == null).length,
    'peers': peers.map((row) => row.name).toList(),
  };
}
