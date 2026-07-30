import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  throw UnimplementedError(
    'historyRepositoryProvider must be overridden at application startup.',
  );
});
