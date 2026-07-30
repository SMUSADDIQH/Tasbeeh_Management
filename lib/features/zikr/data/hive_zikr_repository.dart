import 'package:hive/hive.dart';

import '../domain/zikr_models.dart';
import '../domain/zikr_repository.dart';

class HiveZikrRepository implements ZikrRepository {
  HiveZikrRepository(this._zikrBox, this._sessionBox);

  final Box<dynamic> _zikrBox;
  final LazyBox<dynamic> _sessionBox;

  @override
  List<Zikr> loadZikr() {
    final values = <Zikr>[];
    for (final value in _zikrBox.values) {
      if (value is Map<dynamic, dynamic>) {
        try {
          values.add(Zikr.fromMap(value));
        } on FormatException {
          continue;
        }
      }
    }
    values.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return values;
  }

  @override
  Future<List<ZikrSession>> loadSessions({
    int offset = 0,
    int limit = 40,
    String? zikrId,
  }) async {
    final sessions = await loadAllSessions();
    final filtered = zikrId == null
        ? sessions
        : sessions.where((session) => session.zikrId == zikrId).toList();
    if (offset >= filtered.length) return const [];
    return filtered.sublist(offset, (offset + limit).clamp(0, filtered.length));
  }

  @override
  Future<List<ZikrSession>> loadAllSessions() async {
    final sessions = <ZikrSession>[];
    for (final key in _sessionBox.keys) {
      final value = await _sessionBox.get(key);
      if (value is Map<dynamic, dynamic>) {
        try {
          sessions.add(ZikrSession.fromMap(value));
        } on FormatException {
          continue;
        }
      }
    }
    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sessions;
  }

  @override
  Future<void> saveZikr(Zikr zikr) => _zikrBox.put(zikr.id, zikr.toMap());

  @override
  Future<void> deleteZikr(String id) async {
    final sessions = await loadAllSessions();
    final batch = <dynamic, dynamic>{
      for (final session in sessions.where((item) => item.zikrId == id))
        session.id: null,
    };
    for (final key in batch.keys) {
      await _sessionBox.delete(key);
    }
    await _zikrBox.delete(id);
  }

  @override
  Future<void> saveSession(ZikrSession session) =>
      _sessionBox.put(session.id, session.toMap());

  @override
  Future<void> deleteSession(String id) => _sessionBox.delete(id);

  @override
  Future<void> replaceAll({
    required List<Zikr> zikr,
    required List<ZikrSession> sessions,
  }) async {
    await _zikrBox.clear();
    await _sessionBox.clear();
    await _zikrBox.putAll({for (final item in zikr) item.id: item.toMap()});
    for (final session in sessions) {
      await _sessionBox.put(session.id, session.toMap());
    }
    await verifyIntegrity();
  }

  @override
  Future<void> clear() async {
    await _sessionBox.clear();
    await _zikrBox.clear();
  }

  @override
  Future<void> verifyIntegrity() async {
    final zikr = loadZikr();
    final sessions = await loadAllSessions();
    for (final item in zikr) {
      final own =
          sessions.where((session) => session.zikrId == item.id).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      var total = 0;
      for (final session in own) {
        total += session.amount;
        if (session.runningTotalAfter != total) {
          await saveSession(session.copyWith(runningTotalAfter: total));
        }
      }
      final status = item.status == ZikrStatus.archived
          ? ZikrStatus.archived
          : total >= item.target
          ? ZikrStatus.completed
          : ZikrStatus.active;
      if (item.completed != total || item.status != status) {
        await saveZikr(
          item.copyWith(
            completed: total,
            status: status,
            updatedAt: DateTime.now(),
            completedAt: status == ZikrStatus.completed
                ? item.completedAt ?? DateTime.now()
                : null,
            clearCompletedAt: status != ZikrStatus.completed,
          ),
        );
      }
    }
  }
}
