import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tasbeeh_tracker/features/zikr/data/backup_service.dart';
import 'package:tasbeeh_tracker/features/zikr/data/hive_zikr_repository.dart';

import '../support/fakes.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('zikr_v2_test_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('Hive repository persists Zikr and lazy paginated sessions', () async {
    final zikrBox = await Hive.openBox<dynamic>('zikr');
    final sessionsBox = await Hive.openLazyBox<dynamic>('sessions');
    final repository = HiveZikrRepository(zikrBox, sessionsBox);
    await repository.saveZikr(sampleZikr());
    for (var index = 0; index < 45; index++) {
      await repository.saveSession(
        sampleSession(
          id: 's$index',
          timestamp: DateTime(2026, 7, 30).add(Duration(minutes: index)),
        ),
      );
    }
    expect(repository.loadZikr(), hasLength(1));
    expect(await repository.loadSessions(limit: 40), hasLength(40));
    expect(await repository.loadSessions(offset: 40, limit: 40), hasLength(5));
  });

  test('integrity repair uses sessions as source of truth', () async {
    final zikrBox = await Hive.openBox<dynamic>('zikr');
    final sessionsBox = await Hive.openLazyBox<dynamic>('sessions');
    final repository = HiveZikrRepository(zikrBox, sessionsBox);
    await repository.saveZikr(sampleZikr(completed: 999));
    await repository.saveSession(sampleSession(amount: 100, total: 999));
    await repository.verifyIntegrity();
    expect(repository.loadZikr().single.completed, 100);
    expect((await repository.loadAllSessions()).single.runningTotalAfter, 100);
  });

  test('Version 2 backup round-trips and recalculates totals', () async {
    final source = MemoryZikrRepository()
      ..zikr['z1'] = sampleZikr(completed: 100)
      ..sessions['s1'] = sampleSession();
    final json = await ZikrBackupService(
      source,
    ).exportData(preferences: {'theme': 'dark'});
    final target = MemoryZikrRepository();
    final summary = await ZikrBackupService(
      target,
    ).importData(json, mode: ImportMode.replace);
    expect(summary.zikrCount, 1);
    expect(summary.sessionCount, 1);
    expect(target.zikr['z1']?.completed, 100);
  });

  test('merge handles duplicate IDs deterministically', () async {
    final source = MemoryZikrRepository()
      ..zikr['z1'] = sampleZikr(target: 2000);
    final json = await ZikrBackupService(source).exportData();
    final target = MemoryZikrRepository()
      ..zikr['z1'] = sampleZikr(target: 1000)
      ..zikr['z2'] = sampleZikr(id: 'z2');
    await ZikrBackupService(target).importData(json, mode: ImportMode.merge);
    expect(target.zikr, hasLength(2));
    expect(target.zikr['z1']?.target, 2000);
  });

  test('invalid and Version 1 backups are rejected without mutation', () async {
    final repository = MemoryZikrRepository()..zikr['z1'] = sampleZikr();
    final service = ZikrBackupService(repository);
    await expectLater(
      service.importData('{"schemaVersion":1}', mode: ImportMode.replace),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      service.importData('not json', mode: ImportMode.replace),
      throwsA(anything),
    );
    expect(repository.zikr, hasLength(1));
  });
}
