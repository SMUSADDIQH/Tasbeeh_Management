import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup_service.dart';
import '../domain/zikr_models.dart';
import '../domain/zikr_repository.dart';
import 'zikr_haptics.dart';

final zikrRepositoryProvider = Provider<ZikrRepository>((ref) {
  throw UnimplementedError('Override zikrRepositoryProvider at startup.');
});

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final zikrProvider = StateNotifierProvider<ZikrNotifier, ZikrState>((ref) {
  return ZikrNotifier(
    ref.watch(zikrRepositoryProvider),
    ref.watch(clockProvider),
    haptics: ref.watch(zikrHapticsProvider),
  );
});

class ZikrState {
  const ZikrState({
    this.zikr = const [],
    this.sessions = const [],
    this.liveDrafts = const {},
    this.selectedLiveZikrId,
    this.activeCounterSession,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.search = '',
    this.zikrFilter = ZikrFilter.active,
    this.historyPeriod = HistoryPeriod.all,
    this.historyZikrId,
    this.error,
    this.revision = 0,
  });

  final List<Zikr> zikr;
  final List<ZikrSession> sessions;
  final Map<String, ActiveCounterSession> liveDrafts;
  final String? selectedLiveZikrId;
  final ActiveCounterSession? activeCounterSession;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String search;
  final ZikrFilter zikrFilter;
  final HistoryPeriod historyPeriod;
  final String? historyZikrId;
  final String? error;
  final int revision;

  ActiveCounterSession? getDraftFor(String zikrId) => liveDrafts[zikrId];

  ZikrState copyWith({
    List<Zikr>? zikr,
    List<ZikrSession>? sessions,
    Map<String, ActiveCounterSession>? liveDrafts,
    String? selectedLiveZikrId,
    bool clearSelectedLiveZikrId = false,
    ActiveCounterSession? activeCounterSession,
    bool clearActiveCounterSession = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? search,
    ZikrFilter? zikrFilter,
    HistoryPeriod? historyPeriod,
    String? historyZikrId,
    bool clearHistoryZikr = false,
    String? error,
    bool clearError = false,
    int? revision,
  }) => ZikrState(
    zikr: zikr ?? this.zikr,
    sessions: sessions ?? this.sessions,
    liveDrafts: liveDrafts ?? this.liveDrafts,
    selectedLiveZikrId: clearSelectedLiveZikrId
        ? null
        : selectedLiveZikrId ?? this.selectedLiveZikrId,
    activeCounterSession: clearActiveCounterSession
        ? null
        : activeCounterSession ?? this.activeCounterSession,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    search: search ?? this.search,
    zikrFilter: zikrFilter ?? this.zikrFilter,
    historyPeriod: historyPeriod ?? this.historyPeriod,
    historyZikrId: clearHistoryZikr
        ? null
        : historyZikrId ?? this.historyZikrId,
    error: clearError ? null : error ?? this.error,
    revision: revision ?? this.revision,
  );

  List<Zikr> get visibleZikr {
    final status = switch (zikrFilter) {
      ZikrFilter.active => ZikrStatus.active,
      ZikrFilter.completed => ZikrStatus.completed,
      ZikrFilter.archived => ZikrStatus.archived,
    };
    final query = search.trim().toLowerCase();
    return zikr.where((item) {
      if (item.status != status) return false;
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          (item.arabicName?.contains(query) ?? false) ||
          (item.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<ZikrSession> filteredSessions(DateTime now) {
    final start = switch (historyPeriod) {
      HistoryPeriod.today => DateTime(now.year, now.month, now.day),
      HistoryPeriod.week => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1)),
      HistoryPeriod.month => DateTime(now.year, now.month),
      HistoryPeriod.all => DateTime.fromMillisecondsSinceEpoch(0),
    };
    final query = search.trim().toLowerCase();
    return sessions.where((session) {
      final item = zikr.where((z) => z.id == session.zikrId).firstOrNull;
      return session.timestamp.isAfter(
            start.subtract(const Duration(seconds: 1)),
          ) &&
          (historyZikrId == null || session.zikrId == historyZikrId) &&
          (query.isEmpty ||
              item?.name.toLowerCase().contains(query) == true ||
              item?.arabicName?.contains(query) == true ||
              session.amount.toString().contains(query) ||
              session.note?.toLowerCase().contains(query) == true ||
              session.label?.toLowerCase().contains(query) == true);
    }).toList();
  }
}

class ZikrNotifier extends StateNotifier<ZikrState> {
  ZikrNotifier(this._repository, this._now, {ZikrHaptics? haptics})
    : _haptics = haptics ?? const DefaultZikrHaptics(),
      super(const ZikrState()) {
    unawaited(refresh());
  }

  static const pageSize = 40;
  final ZikrRepository _repository;
  final DateTime Function() _now;
  final ZikrHaptics _haptics;
  final Set<String> _submittingZikrs = {};
  ReflectionSummary? _reflectionCache;
  String? _reflectionKey;
  bool _saving = false;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.verifyIntegrity();
      final zikr = _repository.loadZikr();
      final sessions = await _repository.loadSessions(limit: pageSize);
      final drafts = _repository.loadAllLiveDrafts();

      final activeZikrs = zikr
          .where((z) => z.status != ZikrStatus.archived)
          .toList();
      var selectedId =
          _repository.loadSelectedLiveZikrId() ?? state.selectedLiveZikrId;
      if (selectedId == null || !activeZikrs.any((z) => z.id == selectedId)) {
        selectedId = activeZikrs.isNotEmpty ? activeZikrs.first.id : null;
      }

      final activeCounter = selectedId != null ? drafts[selectedId] : null;

      state = state.copyWith(
        zikr: zikr,
        sessions: sessions,
        liveDrafts: drafts,
        selectedLiveZikrId: selectedId,
        clearSelectedLiveZikrId: selectedId == null,
        activeCounterSession: activeCounter,
        clearActiveCounterSession: activeCounter == null,
        isLoading: false,
        hasMore: sessions.length == pageSize,
        revision: state.revision + 1,
      );
      _invalidateReflection();
    } on Object catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> selectLiveZikr(String zikrId) async {
    await _repository.saveSelectedLiveZikrId(zikrId);
    final draft = state.liveDrafts[zikrId];
    state = state.copyWith(
      selectedLiveZikrId: zikrId,
      activeCounterSession: draft,
      clearActiveCounterSession: draft == null,
    );
  }

  Future<ActiveCounterSession> startCounterSession({
    required String zikrId,
    required int target,
  }) async {
    if (target <= 0) {
      throw ArgumentError.value(
        target,
        'target',
        'Target must be greater than zero.',
      );
    }
    final now = _now();
    final session = ActiveCounterSession(
      id: '${now.microsecondsSinceEpoch}-${zikrId.hashCode.abs()}',
      zikrId: zikrId,
      target: target,
      count: 0,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveLiveDraft(session);
    await _repository.saveSelectedLiveZikrId(zikrId);

    final newDrafts = Map<String, ActiveCounterSession>.from(state.liveDrafts)
      ..[zikrId] = session;

    state = state.copyWith(
      liveDrafts: newDrafts,
      selectedLiveZikrId: zikrId,
      activeCounterSession: session,
    );
    return session;
  }

  Future<void> incrementCounter({String? forZikrId}) async {
    final targetZikrId =
        forZikrId ??
        state.activeCounterSession?.zikrId ??
        state.selectedLiveZikrId;
    if (targetZikrId == null) return;

    final active =
        state.liveDrafts[targetZikrId] ??
        (targetZikrId == state.selectedLiveZikrId
            ? state.activeCounterSession
            : null);
    if (active == null || active.isCompleted) return;

    final previousCount = active.count;
    final liveTarget = active.target;
    final newCount = (previousCount + 1).clamp(0, liveTarget);
    final isJustCompleted = newCount >= liveTarget;
    final now = _now();

    final updated = active.copyWith(
      count: newCount,
      isCompleted: isJustCompleted,
      updatedAt: now,
    );

    await _repository.saveLiveDraft(updated);

    final updatedDrafts = Map<String, ActiveCounterSession>.from(
      state.liveDrafts,
    )..[targetZikrId] = updated;

    final isSelected = targetZikrId == state.selectedLiveZikrId;
    state = state.copyWith(
      liveDrafts: updatedDrafts,
      activeCounterSession: isSelected ? updated : state.activeCounterSession,
    );

    final activeZikr = state.zikr
        .where((z) => z.id == targetZikrId)
        .firstOrNull;
    final vibrationMode =
        activeZikr?.countVibrationMode ?? CountVibrationMode.off;
    final interval = activeZikr?.vibrationInterval;

    final trigger = evaluateVibrationTrigger(
      previousCount: previousCount,
      newCount: newCount,
      liveTarget: liveTarget,
      vibrationMode: vibrationMode,
      customInterval: interval,
      lastVibratedMilestone: active.lastVibratedMilestone,
    );

    if (trigger == VibrationTrigger.completion) {
      unawaited(_haptics.completionImpact());
    } else if (trigger == VibrationTrigger.milestone) {
      unawaited(_haptics.milestoneImpact());
      final crossed = getCrossedMilestone(
        previousCount: previousCount,
        newCount: newCount,
        vibrationMode: vibrationMode,
        customInterval: interval,
      );
      if (crossed != null) {
        final draftWithMilestone = updated.copyWith(
          lastVibratedMilestone: crossed,
        );
        await _repository.saveLiveDraft(draftWithMilestone);
        final drafts = Map<String, ActiveCounterSession>.from(state.liveDrafts)
          ..[targetZikrId] = draftWithMilestone;
        state = state.copyWith(
          liveDrafts: drafts,
          activeCounterSession: isSelected
              ? draftWithMilestone
              : state.activeCounterSession,
        );
      }
    }

    if (isJustCompleted) {
      await submitLiveSession(targetZikrId, isAutoCompletion: true);
    }
  }

  Future<bool> submitLiveSession(
    String zikrId, {
    bool isAutoCompletion = false,
  }) async {
    if (_submittingZikrs.contains(zikrId)) return false;
    _submittingZikrs.add(zikrId);

    try {
      final draft =
          _repository.loadLiveDraft(zikrId) ?? state.liveDrafts[zikrId];
      if (draft == null || draft.count <= 0) {
        return false;
      }

      final item = state.zikr.where((z) => z.id == zikrId).firstOrNull;
      if (item == null) return false;

      final sessionAmount = draft.count;
      final sessionCreatedAt = draft.createdAt;

      // 1. Clear only this Zikr's draft
      await _repository.clearLiveDraft(zikrId);

      // 2. Add completed session for this exact Zikr
      await _addSessionInternal(
        item,
        sessionAmount,
        timestamp: sessionCreatedAt,
        label: isAutoCompletion
            ? 'Tasbeeh Counter (${draft.target})'
            : 'Live Session ($sessionAmount)',
      );

      // 3. Update local state
      final updatedDrafts = Map<String, ActiveCounterSession>.from(
        state.liveDrafts,
      )..remove(zikrId);

      final isSelected = zikrId == state.selectedLiveZikrId;
      state = state.copyWith(
        liveDrafts: updatedDrafts,
        activeCounterSession: isSelected ? null : state.activeCounterSession,
        clearActiveCounterSession: isSelected,
      );

      await _reloadAll();

      return true;
    } finally {
      _submittingZikrs.remove(zikrId);
    }
  }

  Future<void> abandonCounterSession({String? forZikrId}) async {
    final targetZikrId = forZikrId ?? state.selectedLiveZikrId;
    if (targetZikrId == null) return;

    await _repository.clearLiveDraft(targetZikrId);

    final updatedDrafts = Map<String, ActiveCounterSession>.from(
      state.liveDrafts,
    )..remove(targetZikrId);

    final isSelected = targetZikrId == state.selectedLiveZikrId;
    state = state.copyWith(
      liveDrafts: updatedDrafts,
      activeCounterSession: isSelected ? null : state.activeCounterSession,
      clearActiveCounterSession: isSelected,
    );
  }

  Future<void> resetCounterSession({String? forZikrId}) async {
    final targetZikrId = forZikrId ?? state.selectedLiveZikrId;
    if (targetZikrId == null) return;
    final draft =
        state.liveDrafts[targetZikrId] ??
        (targetZikrId == state.selectedLiveZikrId
            ? state.activeCounterSession
            : null);
    if (draft == null) return;

    final now = _now();
    final updated = draft.copyWith(
      count: 0,
      isCompleted: false,
      lastVibratedMilestone: 0,
      updatedAt: now,
    );
    await _repository.saveLiveDraft(updated);

    final updatedDrafts = Map<String, ActiveCounterSession>.from(
      state.liveDrafts,
    )..[targetZikrId] = updated;

    final isSelected = targetZikrId == state.selectedLiveZikrId;
    state = state.copyWith(
      liveDrafts: updatedDrafts,
      activeCounterSession: isSelected ? updated : state.activeCounterSession,
    );
  }

  Future<void> setCounterTarget(int target, {String? forZikrId}) async {
    if (target <= 0) {
      throw ArgumentError.value(
        target,
        'target',
        'Target must be greater than zero.',
      );
    }
    final targetZikrId = forZikrId ?? state.selectedLiveZikrId;
    if (targetZikrId == null) return;
    final draft =
        state.liveDrafts[targetZikrId] ??
        (targetZikrId == state.selectedLiveZikrId
            ? state.activeCounterSession
            : null);
    if (draft == null) return;

    final now = _now();
    final isCompletedNow = draft.count >= target;
    final updated = draft.copyWith(
      target: target,
      isCompleted: isCompletedNow,
      updatedAt: now,
    );
    await _repository.saveLiveDraft(updated);

    final updatedDrafts = Map<String, ActiveCounterSession>.from(
      state.liveDrafts,
    )..[targetZikrId] = updated;

    final isSelected = targetZikrId == state.selectedLiveZikrId;
    state = state.copyWith(
      liveDrafts: updatedDrafts,
      activeCounterSession: isSelected ? updated : state.activeCounterSession,
    );

    if (isCompletedNow) {
      await submitLiveSession(targetZikrId, isAutoCompletion: true);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final page = await _repository.loadSessions(
      offset: state.sessions.length,
      limit: pageSize,
    );
    state = state.copyWith(
      sessions: [...state.sessions, ...page],
      isLoadingMore: false,
      hasMore: page.length == pageSize,
    );
  }

  Future<Zikr> create(ZikrDraft draft) async {
    final now = _now();
    final id = '${now.microsecondsSinceEpoch}-${draft.name.hashCode.abs()}';
    final status = draft.startingCompleted >= draft.target
        ? ZikrStatus.completed
        : ZikrStatus.active;
    var item = Zikr(
      id: id,
      name: draft.name.trim(),
      arabicName: draft.arabicName,
      description: draft.description,
      target: draft.target,
      completed: 0,
      category: draft.category,
      status: status,
      isFavorite: draft.isFavorite,
      colorValue: draft.colorValue,
      iconCodePoint: draft.iconCodePoint,
      createdAt: now,
      updatedAt: now,
      startDate: draft.startDate,
      targetDate: draft.targetDate,
      completedAt: status == ZikrStatus.completed ? now : null,
      notes: draft.notes,
      countVibrationMode: draft.countVibrationMode,
      vibrationInterval: draft.vibrationInterval,
    );
    await _repository.saveZikr(item);
    if (draft.startingCompleted > 0) {
      await _addSessionInternal(
        item,
        draft.startingCompleted,
        timestamp: now,
        label: 'Starting amount',
      );
      item = _repository.loadZikr().firstWhere((value) => value.id == id);
    }
    await _reloadAll();
    return item;
  }

  Future<void> edit(String id, ZikrDraft draft) async {
    final item = state.zikr.firstWhere((value) => value.id == id);
    final status = item.status == ZikrStatus.archived
        ? ZikrStatus.archived
        : item.completed >= draft.target
        ? ZikrStatus.completed
        : ZikrStatus.active;
    await _repository.saveZikr(
      item.copyWith(
        name: draft.name.trim(),
        arabicName: draft.arabicName,
        description: draft.description,
        clearArabicName: draft.arabicName == null,
        clearDescription: draft.description == null,
        target: draft.target,
        category: draft.category,
        status: status,
        clearCompletedAt: status != ZikrStatus.completed,
        isFavorite: draft.isFavorite,
        colorValue: draft.colorValue,
        iconCodePoint: draft.iconCodePoint,
        updatedAt: _now(),
        startDate: draft.startDate,
        targetDate: draft.targetDate,
        clearTargetDate: draft.targetDate == null,
        notes: draft.notes,
        clearNotes: draft.notes == null,
        countVibrationMode: draft.countVibrationMode,
        vibrationInterval: draft.vibrationInterval,
        clearVibrationInterval: draft.vibrationInterval == null,
      ),
    );
    await _reloadAll();
  }

  Future<void> addSession(
    String zikrId,
    int amount, {
    DateTime? timestamp,
    String? note,
    String? label,
  }) async {
    if (_saving) return;
    _saving = true;
    try {
      final item = state.zikr.firstWhere((value) => value.id == zikrId);
      await _addSessionInternal(
        item,
        amount,
        timestamp: timestamp ?? _now(),
        note: note,
        label: label,
      );
      await _reloadAll();
    } finally {
      _saving = false;
    }
  }

  Future<void> _addSessionInternal(
    Zikr item,
    int amount, {
    required DateTime timestamp,
    String? note,
    String? label,
  }) async {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    final now = _now();
    final total = item.completed + amount;
    final session = ZikrSession(
      id: '${now.microsecondsSinceEpoch}-${item.id.hashCode.abs()}-${state.sessions.length}',
      zikrId: item.id,
      amount: amount,
      timestamp: timestamp,
      note: note?.trim(),
      label: label,
      runningTotalAfter: total,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveSession(session);
    await _repository.saveZikr(
      item.copyWith(
        completed: total,
        status: total >= item.target ? ZikrStatus.completed : ZikrStatus.active,
        completedAt: total >= item.target ? now : null,
        updatedAt: now,
      ),
    );
    await _repository.verifyIntegrity();
  }

  Future<void> editSession(
    ZikrSession session, {
    required int amount,
    required DateTime timestamp,
    String? note,
    String? label,
  }) async {
    await _repository.saveSession(
      session.copyWith(
        amount: amount,
        timestamp: timestamp,
        note: note,
        label: label,
        updatedAt: _now(),
      ),
    );
    await _repository.verifyIntegrity();
    await _reloadAll();
  }

  Future<void> deleteSession(String id) async {
    await _repository.deleteSession(id);
    await _repository.verifyIntegrity();
    await _reloadAll();
  }

  Future<void> undoLatest(String zikrId) async {
    final sessions = await _repository.loadSessions(zikrId: zikrId, limit: 1);
    if (sessions.isNotEmpty) await deleteSession(sessions.first.id);
  }

  Future<void> toggleFavorite(String id) async {
    final item = state.zikr.firstWhere((value) => value.id == id);
    await _repository.saveZikr(
      item.copyWith(isFavorite: !item.isFavorite, updatedAt: _now()),
    );
    await _reloadAll();
  }

  Future<void> setArchived(String id, bool archived) async {
    final item = state.zikr.firstWhere((value) => value.id == id);
    await _repository.saveZikr(
      item.copyWith(
        status: archived
            ? ZikrStatus.archived
            : item.completed >= item.target
            ? ZikrStatus.completed
            : ZikrStatus.active,
        archivedAt: archived ? _now() : null,
        clearArchivedAt: !archived,
        updatedAt: _now(),
      ),
    );
    await _reloadAll();
  }

  Future<void> deleteZikr(String id) async {
    if (_saving) return;
    _saving = true;
    try {
      await _repository.deleteZikr(id);
      await _reloadAll();
    } finally {
      _saving = false;
    }
  }

  void setSearch(String value) => state = state.copyWith(search: value);
  void setZikrFilter(ZikrFilter value) =>
      state = state.copyWith(zikrFilter: value);
  void setHistoryPeriod(HistoryPeriod value) =>
      state = state.copyWith(historyPeriod: value);
  void setHistoryZikr(String? id) =>
      state = state.copyWith(historyZikrId: id, clearHistoryZikr: id == null);

  Future<void> clearHistory() async {
    final zikr = state.zikr;
    await _repository.replaceAll(zikr: zikr, sessions: const []);
    await refresh();
  }

  Future<void> clearAll() async {
    await _repository.clear();
    await refresh();
  }

  Future<String> exportBackup({Map<String, Object?>? preferences}) =>
      ZikrBackupService(_repository).exportData(preferences: preferences);

  Future<ImportSummary> importBackup(String source, ImportMode mode) async {
    final result = await ZikrBackupService(
      _repository,
    ).importData(source, mode: mode);
    await refresh();
    return result;
  }

  Future<ReflectionSummary> reflection(
    ReflectionPeriod period, {
    String? zikrId,
  }) async {
    final key = '${state.revision}:${period.name}:$zikrId';
    if (_reflectionKey == key && _reflectionCache != null) {
      return _reflectionCache!;
    }
    final now = _now();
    final all = await _repository.loadAllSessions();
    final start = switch (period) {
      ReflectionPeriod.today => DateTime(now.year, now.month, now.day),
      ReflectionPeriod.week => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1)),
      ReflectionPeriod.month => DateTime(now.year, now.month),
      ReflectionPeriod.year => DateTime(now.year),
      ReflectionPeriod.all => DateTime.fromMillisecondsSinceEpoch(0),
    };
    final sessions = all
        .where(
          (item) =>
              !item.timestamp.isBefore(start) &&
              (zikrId == null || item.zikrId == zikrId),
        )
        .toList();
    final daily = <DateTime, int>{};
    final perZikr = <String, int>{};
    for (final session in sessions) {
      final day = DateTime(
        session.timestamp.year,
        session.timestamp.month,
        session.timestamp.day,
      );
      daily[day] = (daily[day] ?? 0) + session.amount;
      perZikr[session.zikrId] = (perZikr[session.zikrId] ?? 0) + session.amount;
    }
    final sortedDays = daily.keys.toList()..sort();
    var longest = 0;
    var current = 0;
    DateTime? previous;
    for (final day in sortedDays) {
      current = previous != null && day.difference(previous).inDays == 1
          ? current + 1
          : 1;
      longest = max(longest, current);
      previous = day;
    }
    final today = DateTime(now.year, now.month, now.day);
    final currentStreak =
        previous != null && today.difference(previous).inDays <= 1
        ? current
        : 0;
    final bestEntry = daily.entries.isEmpty
        ? null
        : daily.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final applicable = zikrId == null
        ? state.zikr
              .where((item) => item.status != ZikrStatus.archived)
              .toList()
        : state.zikr.where((item) => item.id == zikrId).toList();
    final target = applicable.fold<int>(0, (sum, item) => sum + item.target);
    final completed = applicable.fold<int>(
      0,
      (sum, item) => sum + min(item.completed, item.target),
    );
    final closest = applicable
        .where((item) => item.status == ZikrStatus.active)
        .fold<Zikr?>(
          null,
          (best, item) =>
              best == null || item.progress > best.progress ? item : best,
        );
    final activeEntry = perZikr.entries.isEmpty
        ? null
        : perZikr.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final mostActive = activeEntry == null
        ? null
        : state.zikr.where((item) => item.id == activeEntry.key).firstOrNull;
    DateTime? projected;
    if (closest != null && daily.isNotEmpty) {
      final average =
          sessions.fold<int>(0, (sum, s) => sum + s.amount) / daily.length;
      if (average > 0) {
        projected = now.add(
          Duration(days: (closest.remaining / average).ceil()),
        );
      }
    }
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekly = List<int>.generate(7, (index) {
      return daily[weekStart.add(Duration(days: index))] ?? 0;
    });
    final summary = ReflectionSummary(
      total: sessions.fold<int>(0, (sum, item) => sum + item.amount),
      averagePerActiveDay: daily.isEmpty
          ? 0
          : sessions.fold<int>(0, (sum, item) => sum + item.amount) /
                daily.length,
      bestDayTotal: bestEntry?.value ?? 0,
      bestDay: bestEntry?.key,
      currentStreak: currentStreak,
      longestStreak: longest,
      overallCompletion: target == 0 ? 0 : completed / target,
      weeklyTotals: weekly,
      closestZikr: closest,
      mostActiveZikr: mostActive,
      projectedCompletion: projected,
    );
    _reflectionKey = key;
    _reflectionCache = summary;
    return summary;
  }

  Future<void> _reloadAll() async {
    final zikr = _repository.loadZikr();
    final sessions = await _repository.loadSessions(
      limit: max(pageSize, state.sessions.length),
    );
    final drafts = _repository.loadAllLiveDrafts();

    final activeZikrs = zikr
        .where((z) => z.status != ZikrStatus.archived)
        .toList();
    var selectedId = state.selectedLiveZikrId;
    if (selectedId == null || !activeZikrs.any((z) => z.id == selectedId)) {
      selectedId = activeZikrs.isNotEmpty ? activeZikrs.first.id : null;
    }

    final activeCounter = selectedId != null ? drafts[selectedId] : null;

    state = state.copyWith(
      zikr: zikr,
      sessions: sessions,
      liveDrafts: drafts,
      selectedLiveZikrId: selectedId,
      clearSelectedLiveZikrId: selectedId == null,
      activeCounterSession: activeCounter,
      clearActiveCounterSession: activeCounter == null,
      revision: state.revision + 1,
      clearError: true,
    );
    _invalidateReflection();
  }

  void _invalidateReflection() {
    _reflectionCache = null;
    _reflectionKey = null;
  }
}
