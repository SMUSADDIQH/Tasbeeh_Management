import 'package:tasbeeh_tracker/features/settings/domain/models/app_settings.dart';
import 'package:tasbeeh_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:tasbeeh_tracker/features/zikr/data/arabic_name_translation_service.dart';
import 'package:tasbeeh_tracker/features/zikr/data/islamic_phrase_resolver.dart';
import 'package:tasbeeh_tracker/features/zikr/domain/zikr_models.dart';
import 'package:tasbeeh_tracker/features/zikr/domain/zikr_repository.dart';

class FakeArabicNameTranslationService implements ArabicNameTranslationService {
  bool isModelPrepared = true;
  bool shouldFail = false;

  @override
  bool get isSupportedPlatform => true;

  @override
  Future<TranslationResult> translate(
    String text, {
    void Function(String message)? onProgress,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const TranslationResult.error('Empty text');

    final localMatch = IslamicPhraseResolver.resolve(trimmed);
    if (localMatch != null) {
      return TranslationResult.success(localMatch, isLocalMatch: true);
    }

    if (shouldFail) {
      return const TranslationResult.error(
        'Translation unavailable. Enter Arabic manually or retry.',
      );
    }

    return TranslationResult.success('ترجمة $trimmed');
  }

  @override
  void dispose() {}
}

class MemoryZikrRepository implements ZikrRepository {
  final Map<String, Zikr> zikr = {};
  final Map<String, ZikrSession> sessions = {};
  final Map<String, ActiveCounterSession> liveDrafts = {};
  ActiveCounterSession? activeCounterSession;
  String? selectedLiveZikrId;

  @override
  Map<String, ActiveCounterSession> loadAllLiveDrafts() {
    final drafts = Map<String, ActiveCounterSession>.from(liveDrafts);
    if (drafts.isEmpty &&
        activeCounterSession != null &&
        !activeCounterSession!.isCompleted) {
      drafts[activeCounterSession!.zikrId] = activeCounterSession!;
    }
    return drafts;
  }

  @override
  ActiveCounterSession? loadLiveDraft(String zikrId) {
    return loadAllLiveDrafts()[zikrId];
  }

  @override
  Future<void> saveLiveDraft(ActiveCounterSession draft) async {
    liveDrafts[draft.zikrId] = draft;
    if (selectedLiveZikrId == draft.zikrId || selectedLiveZikrId == null) {
      activeCounterSession = draft;
    }
  }

  @override
  Future<void> clearLiveDraft(String zikrId) async {
    liveDrafts.remove(zikrId);
    if (activeCounterSession?.zikrId == zikrId) {
      activeCounterSession = null;
    }
  }

  @override
  Future<void> clearAllLiveDrafts() async {
    liveDrafts.clear();
    activeCounterSession = null;
  }

  @override
  String? loadSelectedLiveZikrId() => selectedLiveZikrId;

  @override
  Future<void> saveSelectedLiveZikrId(String? zikrId) async {
    selectedLiveZikrId = zikrId;
  }

  @override
  ActiveCounterSession? loadActiveCounterSession() {
    if (selectedLiveZikrId != null &&
        liveDrafts.containsKey(selectedLiveZikrId)) {
      return liveDrafts[selectedLiveZikrId];
    }
    return activeCounterSession;
  }

  @override
  Future<void> saveActiveCounterSession(ActiveCounterSession? session) async {
    if (session == null) {
      if (selectedLiveZikrId != null) {
        liveDrafts.remove(selectedLiveZikrId);
      }
      activeCounterSession = null;
    } else {
      liveDrafts[session.zikrId] = session;
      activeCounterSession = session;
      selectedLiveZikrId = session.zikrId;
    }
  }

  @override
  List<Zikr> loadZikr() =>
      zikr.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<List<ZikrSession>> loadAllSessions() async =>
      sessions.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  @override
  Future<List<ZikrSession>> loadSessions({
    int offset = 0,
    int limit = 40,
    String? zikrId,
  }) async {
    final all = await loadAllSessions();
    final filtered = zikrId == null
        ? all
        : all.where((item) => item.zikrId == zikrId).toList();
    if (offset >= filtered.length) return [];
    return filtered.sublist(offset, (offset + limit).clamp(0, filtered.length));
  }

  @override
  Future<void> saveZikr(Zikr value) async => zikr[value.id] = value;

  @override
  Future<void> deleteZikr(String id) async {
    await clearLiveDraft(id);
    zikr.remove(id);
    sessions.removeWhere((_, value) => value.zikrId == id);
  }

  @override
  Future<void> saveSession(ZikrSession value) async =>
      sessions[value.id] = value;

  @override
  Future<void> deleteSession(String id) async => sessions.remove(id);

  @override
  Future<void> replaceAll({
    required List<Zikr> zikr,
    required List<ZikrSession> sessions,
  }) async {
    this.zikr
      ..clear()
      ..addEntries(zikr.map((item) => MapEntry(item.id, item)));
    this.sessions
      ..clear()
      ..addEntries(sessions.map((item) => MapEntry(item.id, item)));
    await verifyIntegrity();
  }

  @override
  Future<void> clear() async {
    zikr.clear();
    sessions.clear();
  }

  @override
  Future<void> verifyIntegrity() async {
    for (final item in zikr.values.toList()) {
      final own =
          sessions.values.where((session) => session.zikrId == item.id).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      var total = 0;
      for (final session in own) {
        total += session.amount;
        sessions[session.id] = session.copyWith(runningTotalAfter: total);
      }
      zikr[item.id] = item.copyWith(
        completed: total,
        status: item.status == ZikrStatus.archived
            ? ZikrStatus.archived
            : total >= item.target
            ? ZikrStatus.completed
            : ZikrStatus.active,
        clearCompletedAt: total < item.target,
      );
    }
  }
}

class MemorySettingsRepository implements SettingsRepository {
  AppSettings value = AppSettings.defaults();
  @override
  AppSettings load() => value;
  @override
  Future<void> save(AppSettings settings) async => value = settings;
}

Zikr sampleZikr({
  String id = 'z1',
  int target = 1000,
  int completed = 0,
  ZikrStatus status = ZikrStatus.active,
  CountVibrationMode countVibrationMode = CountVibrationMode.off,
  int? vibrationInterval,
}) {
  final date = DateTime(2026, 7, 30, 8);
  return Zikr(
    id: id,
    name: 'Ayat-e-Kareema',
    arabicName: 'لَا إِلَٰهَ إِلَّا أَنتَ',
    target: target,
    completed: completed,
    category: ZikrCategory.quran,
    status: status,
    isFavorite: true,
    colorValue: 0xFF146B55,
    iconCodePoint: 0,
    createdAt: date,
    updatedAt: date,
    startDate: date,
    countVibrationMode: countVibrationMode,
    vibrationInterval: vibrationInterval,
  );
}

ZikrSession sampleSession({
  String id = 's1',
  String zikrId = 'z1',
  int amount = 100,
  int total = 100,
  DateTime? timestamp,
}) {
  final date = timestamp ?? DateTime(2026, 7, 30, 9);
  return ZikrSession(
    id: id,
    zikrId: zikrId,
    amount: amount,
    timestamp: date,
    label: 'After Fajr',
    note: 'Quiet morning',
    runningTotalAfter: total,
    createdAt: date,
    updatedAt: date,
  );
}
