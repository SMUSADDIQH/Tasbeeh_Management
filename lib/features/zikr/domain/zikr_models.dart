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
    bool clearTargetDate = false,
    bool clearArchivedAt = false,
    bool clearCompletedAt = false,
    bool clearArabicName = false,
    bool clearDescription = false,
    bool clearNotes = false,
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
