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
  Future<void> clear() async {
    await _sessionBox.clear();
    await _zikrBox.clear();
  }

  static const _activeCounterKey = 'active_counter_session_v1';
  static const _liveDraftsMapKey = 'live_counter_drafts_v1';
  static const _selectedLiveZikrKey = 'selected_live_zikr_id_v1';

  @override
  ActiveCounterSession? loadActiveCounterSession() {
    final value = _zikrBox.get(_activeCounterKey);
    if (value is Map<dynamic, dynamic>) {
      try {
        return ActiveCounterSession.fromMap(value);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveActiveCounterSession(ActiveCounterSession? session) async {
    if (session == null) {
      await _zikrBox.delete(_activeCounterKey);
    } else {
      await _zikrBox.put(_activeCounterKey, session.toMap());
      await saveLiveDraft(session);
    }
  }

  @override
  Map<String, ActiveCounterSession> loadAllLiveDrafts() {
    final drafts = <String, ActiveCounterSession>{};
    final rawMap = _zikrBox.get(_liveDraftsMapKey);
    if (rawMap is Map<dynamic, dynamic>) {
      for (final entry in rawMap.entries) {
        if (entry.key is String && entry.value is Map<dynamic, dynamic>) {
          try {
            final draft = ActiveCounterSession.fromMap(
              entry.value as Map<dynamic, dynamic>,
            );
            if (!draft.isCompleted) {
              drafts[entry.key as String] = draft;
            }
          } on FormatException {
            continue;
          }
        }
      }
    }

    // Migration logic for legacy single session
    final legacy = loadActiveCounterSession();
    if (legacy != null &&
        !legacy.isCompleted &&
        !drafts.containsKey(legacy.zikrId)) {
      drafts[legacy.zikrId] = legacy;
      saveLiveDraft(legacy);
    }

    return drafts;
  }

  @override
  ActiveCounterSession? loadLiveDraft(String zikrId) {
    return loadAllLiveDrafts()[zikrId];
  }

  @override
  Future<void> saveLiveDraft(ActiveCounterSession draft) async {
    final drafts = loadAllLiveDrafts();
    drafts[draft.zikrId] = draft;
    final mapToSave = {
      for (final entry in drafts.entries) entry.key: entry.value.toMap(),
    };
    await _zikrBox.put(_liveDraftsMapKey, mapToSave);
  }

  @override
  Future<void> clearLiveDraft(String zikrId) async {
    final drafts = loadAllLiveDrafts();
    if (drafts.containsKey(zikrId)) {
      drafts.remove(zikrId);
      final mapToSave = {
        for (final entry in drafts.entries) entry.key: entry.value.toMap(),
      };
      await _zikrBox.put(_liveDraftsMapKey, mapToSave);
    }
    final legacy = loadActiveCounterSession();
    if (legacy != null && legacy.zikrId == zikrId) {
      await _zikrBox.delete(_activeCounterKey);
    }
  }

  @override
  Future<void> clearAllLiveDrafts() async {
    await _zikrBox.delete(_liveDraftsMapKey);
    await _zikrBox.delete(_activeCounterKey);
  }

  @override
  String? loadSelectedLiveZikrId() {
    final value = _zikrBox.get(_selectedLiveZikrKey);
    return value is String ? value : null;
  }

  @override
  Future<void> saveSelectedLiveZikrId(String? zikrId) async {
    if (zikrId == null) {
      await _zikrBox.delete(_selectedLiveZikrKey);
    } else {
      await _zikrBox.put(_selectedLiveZikrKey, zikrId);
    }
  }

  @override
  Future<void> deleteZikr(String id) async {
    await clearLiveDraft(id);
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
