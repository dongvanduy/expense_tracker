import 'dart:io';

import 'package:expense_tracker/models/spending.dart';
import 'package:expense_tracker/models/user.dart' as myuser;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'expense_tracker.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE spending(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            money INTEGER,
            type INTEGER,
            note TEXT,
            date INTEGER,
            image TEXT,
            typeName TEXT,
            location TEXT,
            friends TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE wallet(
            month TEXT PRIMARY KEY,
            amount INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE info(
            id INTEGER PRIMARY KEY,
            name TEXT,
            birthday TEXT,
            avatar TEXT,
            gender INTEGER,
            money INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            term TEXT
          );
        ''');

        await db.insert('info', {
          'id': 1,
          'name': 'User',
          'birthday': '01/01/2000',
          'avatar': myuser.defaultAvatar,
          'gender': 1,
          'money': 0,
        });
      },
    );
  }
}

class SpendingRepository {
  SpendingRepository._();

  static final SpendingRepository instance = SpendingRepository._();
  static final spendingNotifier = ValueNotifier<List<Spending>>([]);
  static final userNotifier = ValueNotifier<myuser.User?>(null);

  static Future<void> init() async {
    await _refreshSpending();
    await _refreshUser();
  }

  static Future<Database> get _db async => LocalDatabase.instance.database;

  static Future<void> _refreshSpending() async {
    final db = await _db;
    final data = await db.query('spending', orderBy: 'date DESC');
    spendingNotifier.value =
        data.map((e) => Spending.fromDb(e)).toList(growable: false);
  }

  static Future<void> _refreshUser() async {
    final db = await _db;
    final data = await db.query('info', where: 'id = 1');
    if (data.isNotEmpty) {
      userNotifier.value = myuser.User.fromDb(data.first);
    }
  }

  static Future<void> addSpending(Spending spending) async {
    final db = await _db;
    await db.insert('spending', spending.toMap());
    await _refreshSpending();
  }

  static Future<void> updateSpending(
    Spending spending,
    DateTime oldDay,
    File? image,
    bool check,
  ) async {
    if (image != null) {
      spending = spending.copyWith(image: image.path);
    } else if (check) {
      spending = spending.copyWith(image: null);
    }

    final db = await _db;
    await db.update(
      'spending',
      spending.toMap(),
      where: 'id = ?',
      whereArgs: [spending.id],
    );
    await _refreshSpending();
  }

  static Future<void> deleteSpending(Spending spending) async {
    final db = await _db;
    await db.delete('spending', where: 'id = ?', whereArgs: [spending.id]);
    await _refreshSpending();
  }

  static Future<List<Spending>> getSpendingList(List<String> list) async {
    if (list.isEmpty) return [];
    final db = await _db;
    final data = await db.query(
      'spending',
      where: 'id IN (${List.filled(list.length, '?').join(',')})',
      whereArgs: list,
      orderBy: 'date DESC',
    );
    return data.map((e) => Spending.fromDb(e)).toList();
  }

  static Future<List<Spending>> getSpendingByMonth(DateTime date) async {
    final db = await _db;
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 1);
    final data = await db.query(
      'spending',
      where: 'date >= ? AND date < ?',
      whereArgs: [firstDay.millisecondsSinceEpoch, lastDay.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return data.map((e) => Spending.fromDb(e)).toList();
  }

  static Future<List<Spending>> getSpendingByRange(DateTime start, DateTime end) async {
    final db = await _db;
    final data = await db.query(
      'spending',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return data.map((e) => Spending.fromDb(e)).toList();
  }

  static Future<myuser.User> getUser() async {
    final db = await _db;
    final data = await db.query('info', where: 'id = 1');
    return myuser.User.fromDb(data.first);
  }

  static Future<void> updateInfo({required myuser.User user, File? image}) async {
    if (image != null) {
      user = user.copyWith(avatar: image.path);
    }

    final db = await _db;
    await db.update('info', user.toMap(), where: 'id = 1');
    await updateWalletMoney(user.money);
    await _refreshUser();
  }

  static Future<void> updateWalletMoney(int money) async {
    final db = await _db;
    final monthKey = DateFormat('MM_yyyy').format(DateTime.now());
    final exists = await db.query('wallet', where: 'month = ?', whereArgs: [monthKey]);
    if (exists.isEmpty) {
      await db.insert('wallet', {'month': monthKey, 'amount': money});
    } else {
      await db.update('wallet', {'amount': money}, where: 'month = ?', whereArgs: [monthKey]);
    }
  }

  static Future<void> addWalletMoney(int money) async {
    final db = await _db;
    final monthKey = DateFormat('MM_yyyy').format(DateTime.now());
    final exists = await db.query('wallet', where: 'month = ?', whereArgs: [monthKey]);
    if (exists.isEmpty) {
      await db.insert('wallet', {'month': monthKey, 'amount': money});
    } else {
      await db.update('wallet', {'amount': money}, where: 'month = ?', whereArgs: [monthKey]);
    }

    await db.update('info', {'money': money}, where: 'id = 1');
  }

  static Future<int> getWallet(DateTime date) async {
    final db = await _db;
    final monthKey = DateFormat('MM_yyyy').format(date);
    final data = await db.query('wallet', where: 'month = ?', whereArgs: [monthKey]);
    if (data.isEmpty) {
      final user = await getUser();
      await db.insert('wallet', {'month': monthKey, 'amount': user.money});
      return user.money;
    }
    return data.first['amount'] as int;
  }

  static Future<List<String>> getHistory(String query) async {
    final db = await _db;
    final data = await db.query('history', orderBy: 'id DESC');
    return data
        .map((e) => e['term'] as String)
        .where((term) => term.toUpperCase().contains(query.toUpperCase()))
        .toList();
  }

  static Future<void> saveHistory(String term) async {
    final db = await _db;
    final existing = await db.query('history', where: 'term = ?', whereArgs: [term]);
    if (existing.isEmpty) {
      await db.insert('history', {'term': term});
    } else {
      await db.update('history', {'term': term}, where: 'id = ?', whereArgs: [existing.first['id']]);
    }
  }
}
