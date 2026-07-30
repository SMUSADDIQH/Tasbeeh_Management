enum AppThemePreference { system, light, dark }

enum ContinuousCountSpeed { slow, normal, fast }

extension ContinuousCountSpeedDuration on ContinuousCountSpeed {
  Duration get interval => switch (this) {
    ContinuousCountSpeed.slow => const Duration(milliseconds: 240),
    ContinuousCountSpeed.normal => const Duration(milliseconds: 140),
    ContinuousCountSpeed.fast => const Duration(milliseconds: 80),
  };
}

class AppSettings {
  const AppSettings({
    required this.theme,
    required this.defaultTarget,
    required this.hapticFeedbackEnabled,
    required this.counterAnimationEnabled,
    required this.continuousCountSpeed,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      theme: AppThemePreference.system,
      defaultTarget: 100,
      hapticFeedbackEnabled: true,
      counterAnimationEnabled: true,
      continuousCountSpeed: ContinuousCountSpeed.normal,
    );
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      theme: _themeFromName(map['theme']),
      defaultTarget: _positiveInt(map['defaultTarget'], fallback: 100),
      hapticFeedbackEnabled: map['hapticFeedbackEnabled'] as bool? ?? true,
      counterAnimationEnabled: map['counterAnimationEnabled'] as bool? ?? true,
      continuousCountSpeed: _speedFromName(map['continuousCountSpeed']),
    );
  }

  final AppThemePreference theme;
  final int defaultTarget;
  final bool hapticFeedbackEnabled;
  final bool counterAnimationEnabled;
  final ContinuousCountSpeed continuousCountSpeed;

  AppSettings copyWith({
    AppThemePreference? theme,
    int? defaultTarget,
    bool? hapticFeedbackEnabled,
    bool? counterAnimationEnabled,
    ContinuousCountSpeed? continuousCountSpeed,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      defaultTarget: defaultTarget ?? this.defaultTarget,
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      counterAnimationEnabled:
          counterAnimationEnabled ?? this.counterAnimationEnabled,
      continuousCountSpeed: continuousCountSpeed ?? this.continuousCountSpeed,
    );
  }

  Map<String, Object> toMap() {
    return {
      'theme': theme.name,
      'defaultTarget': defaultTarget,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
      'counterAnimationEnabled': counterAnimationEnabled,
      'continuousCountSpeed': continuousCountSpeed.name,
    };
  }

  static AppThemePreference _themeFromName(Object? value) {
    return AppThemePreference.values.firstWhere(
      (theme) => theme.name == value,
      orElse: () => AppThemePreference.system,
    );
  }

  static ContinuousCountSpeed _speedFromName(Object? value) {
    return ContinuousCountSpeed.values.firstWhere(
      (speed) => speed.name == value,
      orElse: () => ContinuousCountSpeed.normal,
    );
  }

  static int _positiveInt(Object? value, {required int fallback}) {
    return value is int && value > 0 ? value : fallback;
  }
}
