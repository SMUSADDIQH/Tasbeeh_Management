import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/counter_history_entry.dart';
import '../../domain/models/history_filter.dart';
import '../../domain/repositories/history_repository.dart';
import 'history_repository_provider.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((
  ref,
) {
  return HistoryNotifier(ref.watch(historyRepositoryProvider))..load();
});

sealed class HistoryTimelineItem {
  const HistoryTimelineItem();
}

class HistoryDateHeaderItem extends HistoryTimelineItem {
  const HistoryDateHeaderItem(this.date);

  final DateTime date;
}

class HistoryEventItem extends HistoryTimelineItem {
  const HistoryEventItem(this.entry);

  final CounterHistoryEntry entry;
}

class HistoryState {
  const HistoryState({
    this.items = const [],
    this.filter = HistoryFilter.allTime,
    this.searchTerm = '',
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.cursor,
    this.errorMessage,
  });

  final List<HistoryTimelineItem> items;
  final HistoryFilter filter;
  final String searchTerm;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? cursor;
  final String? errorMessage;

  HistoryState copyWith({
    List<HistoryTimelineItem>? items,
    HistoryFilter? filter,
    String? searchTerm,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? cursor,
    String? errorMessage,
    bool clearCursor = false,
    bool clearError = false,
  }) {
    return HistoryState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      searchTerm: searchTerm ?? this.searchTerm,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      cursor: clearCursor ? null : cursor ?? this.cursor,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier(this._repository) : super(const HistoryState());

  static const _pageSize = 30;
  static const _searchDebounce = Duration(milliseconds: 300);

  final HistoryRepository _repository;
  Timer? _searchTimer;
  int _requestId = 0;

  Future<void> load() => _loadFirstPage();

  Future<void> refresh() => _loadFirstPage();

  void setFilter(HistoryFilter filter) {
    if (filter == state.filter) {
      return;
    }

    state = state.copyWith(filter: filter);
    unawaited(_loadFirstPage());
  }

  void search(String searchTerm) {
    state = state.copyWith(searchTerm: searchTerm);
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      unawaited(_loadFirstPage());
    });
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final requestId = _requestId;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final page = await _fetchPage(cursor: state.cursor);
      if (requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        items: _appendEntries(state.items, page.entries),
        cursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } on Object {
      if (requestId == _requestId) {
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: 'Could not load more history.',
        );
      }
    }
  }

  Future<void> _loadFirstPage() async {
    final requestId = ++_requestId;
    state = state.copyWith(
      items: const [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: false,
      clearCursor: true,
      clearError: true,
    );

    try {
      final page = await _fetchPage();
      if (requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        items: _appendEntries(const [], page.entries),
        cursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } on Object {
      if (requestId == _requestId) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load history.',
        );
      }
    }
  }

  Future<HistoryPage> _fetchPage({String? cursor}) {
    return _repository.fetchPage(
      range: state.filter.rangeAt(DateTime.now()),
      searchTerm: state.searchTerm,
      limit: _pageSize,
      cursor: cursor,
    );
  }

  List<HistoryTimelineItem> _appendEntries(
    List<HistoryTimelineItem> existing,
    List<CounterHistoryEntry> entries,
  ) {
    final items = [...existing];
    DateTime? previousDate;

    for (final item in items.reversed) {
      if (item case HistoryEventItem(:final entry)) {
        previousDate = _day(entry.timestamp);
        break;
      }
    }

    for (final entry in entries) {
      final entryDate = _day(entry.timestamp);
      if (previousDate != entryDate) {
        items.add(HistoryDateHeaderItem(entryDate));
        previousDate = entryDate;
      }
      items.add(HistoryEventItem(entry));
    }

    return List.unmodifiable(items);
  }

  DateTime _day(DateTime timestamp) {
    final local = timestamp.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
