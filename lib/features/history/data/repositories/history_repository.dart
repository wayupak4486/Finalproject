import '../../../../core/constants/database_constants.dart';
import '../../../../services/database/app_database.dart';
import '../models/history_record_model.dart';

class HistoryRepository {
  HistoryRepository({required this.database});

  final AppDatabase database;

  Future<int> insertHistory(HistoryRecordModel record) async {
    final db = await database.database;

    return db.insert(DatabaseConstants.historyTable, record.toMap());
  }

  Future<void> updateHistory(HistoryRecordModel record) async {
    final db = await database.database;

    await db.update(
      DatabaseConstants.historyTable,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<List<HistoryRecordModel>> getAllHistory() async {
    final db = await database.database;

    final maps = await db.query(
      DatabaseConstants.historyTable,
      orderBy: 'created_at DESC',
    );

    return maps.map(HistoryRecordModel.fromMap).toList();
  }

  Future<void> deleteHistory(int id) async {
    final db = await database.database;

    await db.delete(
      DatabaseConstants.historyTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllHistory() async {
    final db = await database.database;
    await db.delete(DatabaseConstants.historyTable);
  }
}
