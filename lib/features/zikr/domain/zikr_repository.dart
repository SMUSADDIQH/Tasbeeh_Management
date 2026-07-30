import 'zikr_models.dart';

abstract interface class ZikrRepository {
  List<Zikr> loadZikr();
  Future<List<ZikrSession>> loadSessions({
    int offset = 0,
    int limit = 40,
    String? zikrId,
  });
  Future<List<ZikrSession>> loadAllSessions();
  Future<void> saveZikr(Zikr zikr);
  Future<void> deleteZikr(String id);
  Future<void> saveSession(ZikrSession session);
  Future<void> deleteSession(String id);
  Future<void> replaceAll({
    required List<Zikr> zikr,
    required List<ZikrSession> sessions,
  });
  Future<void> clear();
  Future<void> verifyIntegrity();
}
