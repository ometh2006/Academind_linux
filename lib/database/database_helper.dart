import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/subject.dart';
import '../models/test_score.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('linx.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final home = Platform.environment['HOME'] ?? '.';
    final dbPath = join(home, '.local', 'share', 'linx');
    await Directory(dbPath).create(recursive: true);
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        colorHex TEXT NOT NULL DEFAULT '#6750A4',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE test_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subjectId INTEGER NOT NULL,
        testName TEXT NOT NULL,
        score REAL NOT NULL,
        maxScore REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (subjectId) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Subjects ──────────────────────────────────────────────────────────────

  Future<Subject> insertSubject(Subject subject) async {
    final db = await database;
    final id = await db.insert('subjects', subject.toMap());
    return subject.copyWith(id: id);
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final maps = await db.query('subjects', orderBy: 'createdAt DESC');
    return maps.map(Subject.fromMap).toList();
  }

  Future<Subject?> getSubject(int id) async {
    final db = await database;
    final maps = await db.query('subjects', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Subject.fromMap(maps.first);
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return db.update('subjects', subject.toMap(), where: 'id = ?', whereArgs: [subject.id]);
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    await db.delete('test_scores', where: 'subjectId = ?', whereArgs: [id]);
    return db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // ── Test Scores ────────────────────────────────────────────────────────────

  Future<TestScore> insertScore(TestScore score) async {
    final db = await database;
    final id = await db.insert('test_scores', score.toMap());
    return TestScore(
      id: id,
      subjectId: score.subjectId,
      testName: score.testName,
      score: score.score,
      maxScore: score.maxScore,
      date: score.date,
      notes: score.notes,
    );
  }

  Future<List<TestScore>> getScoresForSubject(int subjectId) async {
    final db = await database;
    final maps = await db.query(
      'test_scores',
      where: 'subjectId = ?',
      whereArgs: [subjectId],
      orderBy: 'date DESC',
    );
    return maps.map(TestScore.fromMap).toList();
  }

  Future<List<TestScore>> getAllScores() async {
    final db = await database;
    final maps = await db.query('test_scores', orderBy: 'date DESC');
    return maps.map(TestScore.fromMap).toList();
  }

  Future<int> updateScore(TestScore score) async {
    final db = await database;
    return db.update('test_scores', score.toMap(), where: 'id = ?', whereArgs: [score.id]);
  }

  Future<int> deleteScore(int id) async {
    final db = await database;
    return db.delete('test_scores', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<int, double>> getAverageScoreBySubject() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT subjectId, AVG(score * 100.0 / maxScore) as avg
      FROM test_scores
      GROUP BY subjectId
    ''');
    return {for (var r in result) r['subjectId'] as int: r['avg'] as double};
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
