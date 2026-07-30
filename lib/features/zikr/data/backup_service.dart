import 'dart:convert';

import '../domain/zikr_models.dart';
import '../domain/zikr_repository.dart';

enum ImportMode { replace, merge }

class ImportSummary {
  const ImportSummary({required this.zikrCount, required this.sessionCount});
  final int zikrCount;
  final int sessionCount;
}

class ZikrBackupService {
  const ZikrBackupService(this._repository);
  final ZikrRepository _repository;

  Future<String> exportData({Map<String, Object?>? preferences}) async {
    final zikr = _repository.loadZikr();
    final sessions = await _repository.loadAllSessions();
    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 2,
      'appVersion': '2.0.0',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'zikr': zikr.map((item) => item.toMap()).toList(),
      'sessions': sessions.map((item) => item.toMap()).toList(),
      'preferences': preferences ?? const <String, Object?>{},
    });
  }

  Future<ImportSummary> importData(
    String source, {
    required ImportMode mode,
  }) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 2) {
      throw const FormatException('Only Version 2 backups are supported.');
    }
    final rawZikr = decoded['zikr'];
    final rawSessions = decoded['sessions'];
    if (rawZikr is! List || rawSessions is! List) {
      throw const FormatException('Backup records are missing.');
    }
    final importedZikr = rawZikr.map((item) {
      if (item is! Map) throw const FormatException('Invalid Zikr record.');
      return Zikr.fromMap(item);
    }).toList();
    final importedSessions = rawSessions.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid session record.');
      }
      return ZikrSession.fromMap(item);
    }).toList();
    final zikrIds = importedZikr.map((item) => item.id).toSet();
    if (importedSessions.any((item) => !zikrIds.contains(item.zikrId))) {
      throw const FormatException('A session references missing Zikr.');
    }
    var resultZikr = importedZikr;
    var resultSessions = importedSessions;
    if (mode == ImportMode.merge) {
      final existingZikr = _repository.loadZikr();
      final existingSessions = await _repository.loadAllSessions();
      resultZikr = {
        for (final item in existingZikr) item.id: item,
        for (final item in importedZikr) item.id: item,
      }.values.toList();
      resultSessions = {
        for (final item in existingSessions) item.id: item,
        for (final item in importedSessions) item.id: item,
      }.values.toList();
    }
    await _repository.replaceAll(zikr: resultZikr, sessions: resultSessions);
    return ImportSummary(
      zikrCount: importedZikr.length,
      sessionCount: importedSessions.length,
    );
  }
}
