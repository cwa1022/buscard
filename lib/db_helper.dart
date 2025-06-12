import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

import 'card_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'cards.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cards(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            company TEXT,
            phone TEXT,
            email TEXT,
            orientation TEXT,
            image_path TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertCard(CardModel card) async {
    final db = await database;
    return db.insert('cards', card.toMap());
  }

  Future<List<CardModel>> getCards() async {
    final db = await database;
    final maps = await db.query('cards');
    return maps.map((e) => CardModel.fromMap(e)).toList();
  }
}
