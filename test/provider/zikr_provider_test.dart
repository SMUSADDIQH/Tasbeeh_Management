import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/features/zikr/domain/zikr_models.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/zikr_provider.dart';

import '../support/fakes.dart';

void main() {
  late MemoryZikrRepository repository;
  late ZikrNotifier notifier;
  final now = DateTime(2026, 7, 30, 10);

  setUp(() async {
    repository = MemoryZikrRepository();
    notifier = ZikrNotifier(repository, () => now);
    await notifier.refresh();
  });

  ZikrDraft draft({int target = 1000, int starting = 0}) => ZikrDraft(
    name: 'Astaghfirullah',
    target: target,
    category: ZikrCategory.istighfar,
    startingCompleted: starting,
    isFavorite: false,
    colorValue: 0xFF146B55,
    iconCodePoint: 0,
    startDate: now,
  );

  test('creates and edits Zikr', () async {
    final created = await notifier.create(draft());
    expect(notifier.state.zikr.single.name, 'Astaghfirullah');
    await notifier.edit(
      created.id,
      ZikrDraft(
        name: 'Daily Istighfar',
        target: 2000,
        category: ZikrCategory.daily,
        startingCompleted: 0,
        isFavorite: true,
        colorValue: 0xFF8A6A2F,
        iconCodePoint: 1,
        startDate: now,
      ),
    );
    expect(notifier.state.zikr.single.name, 'Daily Istighfar');
    expect(notifier.state.zikr.single.target, 2000);
    expect(notifier.state.zikr.single.isFavorite, isTrue);
  });

  test('starting amount is represented by a session', () async {
    await notifier.create(draft(starting: 250));
    expect(notifier.state.zikr.single.completed, 250);
    expect(notifier.state.sessions.single.amount, 250);
    expect(notifier.state.sessions.single.label, 'Starting amount');
  });

  test('adding over-target session completes Zikr', () async {
    final item = await notifier.create(draft(target: 100));
    await notifier.addSession(item.id, 150, timestamp: now, label: 'Morning');
    expect(notifier.state.zikr.single.completed, 150);
    expect(notifier.state.zikr.single.remaining, 0);
    expect(notifier.state.zikr.single.status, ZikrStatus.completed);
  });

  test('editing and deleting sessions recalculates totals', () async {
    final item = await notifier.create(draft());
    await notifier.addSession(item.id, 100, timestamp: now);
    final session = notifier.state.sessions.single;
    await notifier.editSession(session, amount: 300, timestamp: now);
    expect(notifier.state.zikr.single.completed, 300);
    await notifier.deleteSession(session.id);
    expect(notifier.state.zikr.single.completed, 0);
    expect(notifier.state.zikr.single.status, ZikrStatus.active);
  });

  test('archive, restore, favorite, and delete update state', () async {
    final item = await notifier.create(draft());
    await notifier.toggleFavorite(item.id);
    expect(notifier.state.zikr.single.isFavorite, isTrue);
    await notifier.setArchived(item.id, true);
    expect(notifier.state.zikr.single.status, ZikrStatus.archived);
    await notifier.setArchived(item.id, false);
    expect(notifier.state.zikr.single.status, ZikrStatus.active);
    await notifier.deleteZikr(item.id);
    expect(notifier.state.zikr, isEmpty);
  });

  test('history search and date filtering use session fields', () async {
    final item = await notifier.create(draft());
    await notifier.addSession(
      item.id,
      313,
      timestamp: now,
      note: 'After prayer',
      label: 'Morning',
    );
    notifier.setSearch('prayer');
    expect(notifier.state.filteredSessions(now), hasLength(1));
    notifier.setSearch('');
    notifier.setHistoryPeriod(HistoryPeriod.today);
    expect(notifier.state.filteredSessions(now), hasLength(1));
  });

  test('history pagination appends bounded pages', () async {
    repository.zikr['z1'] = sampleZikr();
    for (var index = 0; index < 55; index++) {
      repository.sessions['s$index'] = sampleSession(
        id: 's$index',
        timestamp: now.subtract(Duration(minutes: index)),
      );
    }
    await notifier.refresh();
    expect(notifier.state.sessions, hasLength(40));
    expect(notifier.state.hasMore, isTrue);
    await notifier.loadMore();
    expect(notifier.state.sessions, hasLength(55));
    expect(notifier.state.hasMore, isFalse);
  });
}
