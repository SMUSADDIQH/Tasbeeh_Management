enum ZikrCategory { quran, durood, istighfar, tasbeeh, wazifa, daily, custom }

enum ZikrStatus { active, completed, archived }

enum ZikrFilter { active, completed, archived }

enum HistoryPeriod { today, week, month, all }

enum ReflectionPeriod { today, week, month, year, all }

extension ZikrCategoryLabel on ZikrCategory {
  String get label => switch (this) {
    ZikrCategory.quran => 'Quran',
    ZikrCategory.durood => 'Durood',
    ZikrCategory.istighfar => 'Istighfar',
    ZikrCategory.tasbeeh => 'Tasbeeh',
    ZikrCategory.wazifa => 'Wazifa',
    ZikrCategory.daily => 'Daily',
    ZikrCategory.custom => 'Custom',
  };
}

enum CountVibrationMode { off, tasbeeh100, customInterval }

enum VibrationTrigger { none, milestone, completion }

VibrationTrigger evaluateVibrationTrigger({
  required int previousCount,
  required int newCount,
  required int liveTarget,
  required CountVibrationMode vibrationMode,
  required int? customInterval,
  int lastVibratedMilestone = 0,
}) {
  if (newCount >= liveTarget && previousCount < liveTarget) {
    return VibrationTrigger.completion;
  }

  if (vibrationMode == CountVibrationMode.off || newCount <= previousCount) {
    return VibrationTrigger.none;
  }

  if (vibrationMode == CountVibrationMode.tasbeeh100) {
    final startCycle = previousCount ~/ 100;
    final endCycle = newCount ~/ 100;
    for (var c = startCycle; c <= endCycle; c++) {
      for (final offset in const [33, 66, 100]) {
        final m = c * 100 + offset;
        if (previousCount < m && newCount >= m && m > lastVibratedMilestone) {
          return VibrationTrigger.milestone;
        }
      }
    }
    return VibrationTrigger.none;
  }

  if (vibrationMode == CountVibrationMode.customInterval &&
      customInterval != null &&
      customInterval > 0) {
    final prevQuotient = previousCount ~/ customInterval;
    final newQuotient = newCount ~/ customInterval;
    if (newQuotient > prevQuotient) {
      final milestone = newQuotient * customInterval;
      if (milestone > lastVibratedMilestone &&
          previousCount < milestone &&
          newCount >= milestone) {
        return VibrationTrigger.milestone;
      }
    }
  }

  return VibrationTrigger.none;
}

int? getCrossedMilestone({
  required int previousCount,
  required int newCount,
  required CountVibrationMode vibrationMode,
  required int? customInterval,
}) {
  if (newCount <= previousCount) return null;

  if (vibrationMode == CountVibrationMode.tasbeeh100) {
    final startCycle = previousCount ~/ 100;
    final endCycle = newCount ~/ 100;
    for (var c = endCycle; c >= startCycle; c--) {
      for (final offset in const [100, 66, 33]) {
        final m = c * 100 + offset;
        if (previousCount < m && newCount >= m) {
          return m;
        }
      }
    }
  } else if (vibrationMode == CountVibrationMode.customInterval &&
      customInterval != null &&
      customInterval > 0) {
    final prevQuotient = previousCount ~/ customInterval;
    final newQuotient = newCount ~/ customInterval;
    if (newQuotient > prevQuotient) {
      return newQuotient * customInterval;
    }
  }
  return null;
}

class Zikr {
  const Zikr({
    required this.id,
    required this.name,
    required this.target,
    required this.completed,
    required this.category,
    required this.status,
    required this.isFavorite,
    required this.colorValue,
    required this.iconCodePoint,
    required this.createdAt,
    required this.updatedAt,
    required this.startDate,
    this.arabicName,
    this.description,
    this.targetDate,
    this.completedAt,
    this.archivedAt,
    this.notes,
    this.countVibrationMode = CountVibrationMode.off,
    this.vibrationInterval,
    this.schemaVersion = 2,
  });

  factory Zikr.fromMap(Map<dynamic, dynamic> map) {
    final target = _requiredPositiveInt(map['target'], 'target');
    final completed = _requiredNonNegativeInt(map['completed'], 'completed');
    return Zikr(
      id: _requiredString(map['id'], 'id'),
      name: _requiredString(map['name'], 'name'),
      arabicName: _optionalString(map['arabicName']),
      description: _optionalString(map['description']),
      category: _enumByName(
        ZikrCategory.values,
        map['category'],
        ZikrCategory.custom,
      ),
      target: target,
      completed: completed,
      status: _enumByName(
        ZikrStatus.values,
        map['status'],
        completed >= target ? ZikrStatus.completed : ZikrStatus.active,
      ),
      isFavorite: map['isFavorite'] as bool? ?? false,
      colorValue: map['colorValue'] as int? ?? 0xFF146B55,
      iconCodePoint: map['iconCodePoint'] as int? ?? 0,
      createdAt: _requiredDate(map['createdAt'], 'createdAt'),
      updatedAt: _requiredDate(map['updatedAt'], 'updatedAt'),
      startDate: _requiredDate(map['startDate'], 'startDate'),
      targetDate: _optionalDate(map['targetDate']),
      completedAt: _optionalDate(map['completedAt']),
      archivedAt: _optionalDate(map['archivedAt']),
      notes: _optionalString(map['notes']),
      countVibrationMode: _enumByName(
        CountVibrationMode.values,
        map['countVibrationMode'],
        CountVibrationMode.off,
      ),
      vibrationInterval: _optionalPositiveInt(map['vibrationInterval']),
      schemaVersion: map['schemaVersion'] as int? ?? 2,
    );
  }

  final String id;
  final String name;
  final String? arabicName;
  final String? description;
  final ZikrCategory category;
  final int target;
  final int completed;
  final ZikrStatus status;
  final bool isFavorite;
  final int colorValue;
  final int iconCodePoint;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime startDate;
  final DateTime? targetDate;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  final String? notes;
  final CountVibrationMode countVibrationMode;
  final int? vibrationInterval;
  final int schemaVersion;

  int get remaining => (target - completed).clamp(0, target);
  double get progress => target == 0 ? 0 : (completed / target).clamp(0, 1);

  Zikr copyWith({
    String? name,
    String? arabicName,
    String? description,
    ZikrCategory? category,
    int? target,
    int? completed,
    ZikrStatus? status,
    bool? isFavorite,
    int? colorValue,
    int? iconCodePoint,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? targetDate,
    DateTime? completedAt,
    DateTime? archivedAt,
    String? notes,
    CountVibrationMode? countVibrationMode,
    int? vibrationInterval,
    bool clearTargetDate = false,
    bool clearArchivedAt = false,
    bool clearCompletedAt = false,
    bool clearArabicName = false,
    bool clearDescription = false,
    bool clearNotes = false,
    bool clearVibrationInterval = false,
  }) {
    return Zikr(
      id: id,
      name: name ?? this.name,
      arabicName: clearArabicName ? null : arabicName ?? this.arabicName,
      description: clearDescription ? null : description ?? this.description,
      category: category ?? this.category,
      target: target ?? this.target,
      completed: completed ?? this.completed,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      targetDate: clearTargetDate ? null : targetDate ?? this.targetDate,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
      notes: clearNotes ? null : notes ?? this.notes,
      countVibrationMode: countVibrationMode ?? this.countVibrationMode,
      vibrationInterval: clearVibrationInterval
          ? null
          : vibrationInterval ?? this.vibrationInterval,
      schemaVersion: schemaVersion,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'arabicName': arabicName,
    'description': description,
    'category': category.name,
    'target': target,
    'completed': completed,
    'status': status.name,
    'isFavorite': isFavorite,
    'colorValue': colorValue,
    'iconCodePoint': iconCodePoint,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'startDate': startDate.toIso8601String(),
    'targetDate': targetDate?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'archivedAt': archivedAt?.toIso8601String(),
    'notes': notes,
    'countVibrationMode': countVibrationMode.name,
    'vibrationInterval': vibrationInterval,
    'schemaVersion': schemaVersion,
  };
}

class ZikrSession {
  const ZikrSession({
    required this.id,
    required this.zikrId,
    required this.amount,
    required this.timestamp,
    required this.runningTotalAfter,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.label,
    this.schemaVersion = 2,
  });

  factory ZikrSession.fromMap(Map<dynamic, dynamic> map) => ZikrSession(
    id: _requiredString(map['id'], 'id'),
    zikrId: _requiredString(map['zikrId'], 'zikrId'),
    amount: _requiredPositiveInt(map['amount'], 'amount'),
    timestamp: _requiredDate(map['timestamp'], 'timestamp'),
    note: _optionalString(map['note']),
    label: _optionalString(map['label']),
    runningTotalAfter: _requiredNonNegativeInt(
      map['runningTotalAfter'],
      'runningTotalAfter',
    ),
    createdAt: _requiredDate(map['createdAt'], 'createdAt'),
    updatedAt: _requiredDate(map['updatedAt'], 'updatedAt'),
    schemaVersion: map['schemaVersion'] as int? ?? 2,
  );

  final String id;
  final String zikrId;
  final int amount;
  final DateTime timestamp;
  final String? note;
  final String? label;
  final int runningTotalAfter;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  ZikrSession copyWith({
    int? amount,
    DateTime? timestamp,
    String? note,
    String? label,
    int? runningTotalAfter,
    DateTime? updatedAt,
  }) => ZikrSession(
    id: id,
    zikrId: zikrId,
    amount: amount ?? this.amount,
    timestamp: timestamp ?? this.timestamp,
    note: note ?? this.note,
    label: label ?? this.label,
    runningTotalAfter: runningTotalAfter ?? this.runningTotalAfter,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    schemaVersion: schemaVersion,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'zikrId': zikrId,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
    'label': label,
    'runningTotalAfter': runningTotalAfter,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'schemaVersion': schemaVersion,
  };
}

class ZikrDraft {
  const ZikrDraft({
    required this.name,
    required this.target,
    required this.category,
    required this.startingCompleted,
    required this.isFavorite,
    required this.colorValue,
    required this.iconCodePoint,
    required this.startDate,
    this.arabicName,
    this.description,
    this.targetDate,
    this.notes,
    this.countVibrationMode = CountVibrationMode.off,
    this.vibrationInterval,
  });

  final String name;
  final String? arabicName;
  final String? description;
  final int target;
  final int startingCompleted;
  final ZikrCategory category;
  final bool isFavorite;
  final int colorValue;
  final int iconCodePoint;
  final DateTime startDate;
  final DateTime? targetDate;
  final String? notes;
  final CountVibrationMode countVibrationMode;
  final int? vibrationInterval;
}

class ReflectionSummary {
  const ReflectionSummary({
    required this.total,
    required this.averagePerActiveDay,
    required this.bestDayTotal,
    required this.bestDay,
    required this.currentStreak,
    required this.longestStreak,
    required this.overallCompletion,
    required this.weeklyTotals,
    this.closestZikr,
    this.mostActiveZikr,
    this.projectedCompletion,
  });

  final int total;
  final double averagePerActiveDay;
  final int bestDayTotal;
  final DateTime? bestDay;
  final int currentStreak;
  final int longestStreak;
  final double overallCompletion;
  final List<int> weeklyTotals;
  final Zikr? closestZikr;
  final Zikr? mostActiveZikr;
  final DateTime? projectedCompletion;

  Map<String, Object?> toMap() => {
    'total': total,
    'averagePerActiveDay': averagePerActiveDay,
    'bestDayTotal': bestDayTotal,
    'bestDay': bestDay?.toIso8601String(),
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'overallCompletion': overallCompletion,
    'weeklyTotals': weeklyTotals,
    'closestZikr': closestZikr?.toMap(),
    'mostActiveZikr': mostActiveZikr?.toMap(),
    'projectedCompletion': projectedCompletion?.toIso8601String(),
  };
}

class ActiveCounterSession {
  const ActiveCounterSession({
    required this.id,
    required this.zikrId,
    required this.target,
    required this.count,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.lastVibratedMilestone = 0,
  });

  factory ActiveCounterSession.fromMap(Map<dynamic, dynamic> map) {
    final target = _requiredPositiveInt(map['target'], 'target');
    final count = _requiredNonNegativeInt(map['count'], 'count');
    return ActiveCounterSession(
      id: _requiredString(map['id'], 'id'),
      zikrId: _requiredString(map['zikrId'], 'zikrId'),
      target: target,
      count: count,
      createdAt: _requiredDate(map['createdAt'], 'createdAt'),
      updatedAt: _requiredDate(map['updatedAt'], 'updatedAt'),
      isCompleted: map['isCompleted'] as bool? ?? false,
      lastVibratedMilestone: map['lastVibratedMilestone'] as int? ?? 0,
    );
  }

  final String id;
  final String zikrId;
  final int target;
  final int count;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final int lastVibratedMilestone;

  int get remaining => (target - count).clamp(0, target);
  double get progress => target == 0 ? 0 : (count / target).clamp(0, 1.0);

  ActiveCounterSession copyWith({
    int? count,
    int? target,
    DateTime? updatedAt,
    bool? isCompleted,
    int? lastVibratedMilestone,
  }) {
    return ActiveCounterSession(
      id: id,
      zikrId: zikrId,
      target: target ?? this.target,
      count: count ?? this.count,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      lastVibratedMilestone:
          lastVibratedMilestone ?? this.lastVibratedMilestone,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'zikrId': zikrId,
    'target': target,
    'count': count,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isCompleted': isCompleted,
    'lastVibratedMilestone': lastVibratedMilestone,
  };
}

String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('$field is invalid.');
}

String? _optionalString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

int _requiredPositiveInt(Object? value, String field) {
  if (value is int && value > 0) return value;
  throw FormatException('$field is invalid.');
}

int? _optionalPositiveInt(Object? value) =>
    value is int && value > 0 ? value : null;

int _requiredNonNegativeInt(Object? value, String field) {
  if (value is int && value >= 0) return value;
  throw FormatException('$field is invalid.');
}

DateTime _requiredDate(Object? value, String field) {
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed != null) return parsed;
  throw FormatException('$field is invalid.');
}

DateTime? _optionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

T _enumByName<T extends Enum>(List<T> values, Object? value, T fallback) =>
    values.where((item) => item.name == value).firstOrNull ?? fallback;
