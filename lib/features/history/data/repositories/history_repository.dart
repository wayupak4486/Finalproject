import '../../../../services/database/app_database.dart';
import '../models/history_record_model.dart';

class HistoryRepository {
  HistoryRepository({
    required this.database,
  });

  final AppDatabase database;

  Future<int> insertHistory(HistoryRecordModel record) async {
    final db = await database.database;

    return db.insert(
      'history',
      record.toMap(),
    );
  }

  Future<List<HistoryRecordModel>> getAllHistory() async {
    final db = await database.database;

    final maps = await db.query(
      'history',
      orderBy: 'created_at DESC',
    );

    return maps.map(HistoryRecordModel.fromMap).toList();
  }

  Future<void> deleteHistory(int id) async {
    final db = await database.database;

    await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
    Future<void> clearAllHistory() async {
    final db = await database.database;
    await db.delete('history');
  }
  
}