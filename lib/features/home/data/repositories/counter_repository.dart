import 'package:hive/hive.dart';

import '../../domain/models/tasbeeh_counter_model.dart';

abstract interface class CounterRepository {
  TasbeehCounterModel? load();

  Future<void> save(TasbeehCounterModel counter);
}

class HiveCounterRepository implements CounterRepository {
  HiveCounterRepository(this._box);

  static const _counterKey = 'counter';

  final Box<dynamic> _box;

  @override
  TasbeehCounterModel? load() {
    final value = _box.get(_counterKey);
    if (value is! Map<dynamic, dynamic>) {
      return null;
    }

    return TasbeehCounterModel.fromMap(value);
  }

  @override
  Future<void> save(TasbeehCounterModel counter) {
    return _box.put(_counterKey, counter.toMap());
  }
}
