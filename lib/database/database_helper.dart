import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/measurement.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _webListKey = 'mediciones_web_list';
  static const String _webNextIdKey = 'mediciones_web_next_id';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path =
        join(await getDatabasesPath(), 'variables_industriales.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mediciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipo TEXT NOT NULL,
        area TEXT NOT NULL,
        variable TEXT NOT NULL,
        valor REAL NOT NULL,
        unidad TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        observaciones TEXT
      )
    ''');
  }

  // -------------------- API pública (igual que antes) --------------------

  Future<int> insertMeasurement(Measurement measurement) async {
    if (kIsWeb) {
      return _insertWeb(measurement);
    }
    final db = await database;
    return await db.insert('mediciones', measurement.toMap());
  }

  Future<List<Measurement>> getAllMeasurements() async {
    if (kIsWeb) {
      return _getAllWeb();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mediciones',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return Measurement.fromMap(maps[i]);
    });
  }

  Future<int> updateMeasurement(Measurement measurement) async {
    if (kIsWeb) {
      return _updateWeb(measurement);
    }
    final db = await database;
    return await db.update(
      'mediciones',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<int> deleteMeasurement(int id) async {
    if (kIsWeb) {
      return _deleteWeb(id);
    }
    final db = await database;
    return await db.delete(
      'mediciones',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // -------------------- Implementación Web (shared_preferences) --------------------

  Future<List<Map<String, dynamic>>> _readWebList(
      SharedPreferences prefs) async {
    final String? raw = prefs.getString(_webListKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _writeWebList(
      SharedPreferences prefs, List<Map<String, dynamic>> list) async {
    await prefs.setString(_webListKey, jsonEncode(list));
  }

  Future<int> _insertWeb(Measurement measurement) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readWebList(prefs);
    final int nextId = prefs.getInt(_webNextIdKey) ?? 1;

    final map = measurement.toMap();
    map['id'] = nextId;
    list.add(map);

    await _writeWebList(prefs, list);
    await prefs.setInt(_webNextIdKey, nextId + 1);
    return nextId;
  }

  Future<List<Measurement>> _getAllWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readWebList(prefs);
    final mediciones = list.map((m) => Measurement.fromMap(m)).toList();
    mediciones.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return mediciones;
  }

  Future<int> _updateWeb(Measurement measurement) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readWebList(prefs);
    final index = list.indexWhere((m) => m['id'] == measurement.id);
    if (index != -1) {
      list[index] = measurement.toMap();
      await _writeWebList(prefs, list);
      return 1;
    }
    return 0;
  }

  Future<int> _deleteWeb(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readWebList(prefs);
    list.removeWhere((m) => m['id'] == id);
    await _writeWebList(prefs, list);
    return 1;
  }
}
