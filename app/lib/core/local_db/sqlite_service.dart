import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqliteService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'coachmint.db');
    return openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE snapshot (
          id TEXT PRIMARY KEY,
          snapshot_date TEXT,
          wallet_balance REAL,
          safe_to_spend_per_day REAL,
          survival_days REAL,
          resilience_score INTEGER,
          resilience_label TEXT,
          synced_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          type TEXT,
          amount REAL,
          category TEXT,
          merchant TEXT,
          transaction_date TEXT,
          synced_at TEXT
        )
      ''');
    });
  }

  Future<void> upsertSnapshot(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'snapshot',
      {...data, 'synced_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLatestSnapshot() async {
    final db = await database;
    final r = await db.query('snapshot',
        orderBy: 'snapshot_date DESC', limit: 1);
    return r.isEmpty ? null : r.first;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('snapshot');
    await db.delete('transactions');
    debugPrint('[SQLite] cache cleared');
  }
}

final sqliteService = SqliteService();