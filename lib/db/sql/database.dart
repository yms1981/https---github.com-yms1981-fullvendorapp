import 'package:FullVendor/generated/assets.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

const int dbVersion = 4;
const String dbName = 'fullVendor.db';

class FullVendorSQLDB {
  static final FullVendorSQLDB _instance = FullVendorSQLDB._internal();

  static FullVendorSQLDB get instance => _instance;

  FullVendorSQLDB._internal() {
    init();
  }

  late Database db;

  factory FullVendorSQLDB() {
    return _instance;
  }

  Future<void> onDowngrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> onUpdate(Database db, int oldVersion, int newVersion) async {
    await db.rawQuery("drop table if exists Cart");
    await onCreate(db, newVersion);
  }

  Future<void> onCreate(Database db, int version) async {
    //   open database.sql file and copy paste the code
    //   open file from asserts folder
    String sql = await rootBundle.loadString(Assets.rawDatabase);
    List<String> sqls = sql.split(';');
    for (String s in sqls) {
      s = s.trim();
      if (s.isEmpty) continue;
      await db.execute(s);
    }
  }

  Future<void> init() async {
    try {
      db = await openDatabase(
        dbName,
        version: dbVersion,
        onCreate: onCreate,
        onUpgrade: onUpdate,
        onDowngrade: onDowngrade,
        singleInstance: false,
      );
    } catch (e) {
      print(e);
    }
  }

  Future<int> insert(String s, Map<String, dynamic> json) async {
    return await db.insert(
      s,
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
