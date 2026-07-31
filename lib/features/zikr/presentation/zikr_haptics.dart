import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ZikrHaptics {
  Future<void> milestoneImpact();
  Future<void> completionImpact();
}

class DefaultZikrHaptics implements ZikrHaptics {
  const DefaultZikrHaptics();

  @override
  Future<void> milestoneImpact() async {
    await HapticFeedback.mediumImpact();
  }

  @override
  Future<void> completionImpact() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}

final zikrHapticsProvider = Provider<ZikrHaptics>((ref) {
  return const DefaultZikrHaptics();
});
