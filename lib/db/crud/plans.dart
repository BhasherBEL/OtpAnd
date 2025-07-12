import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:otpand/db/helper.dart';
import 'package:otpand/objects/plan.dart';

class PlanDao {
  final dbHelper = DatabaseHelper();

  Future<int> insertPlan(Plan plan) async {
    final db = await dbHelper.database;
    return await db.insert(
      'planned_plans',
      {'raw': jsonEncode(plan.raw)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Plan>> getPlans() async {
    final db = await dbHelper.database;
    final data = await db.query('planned_plans');
    return await Future.wait(
      data.map(
        (e) => Plan.parse(
          jsonDecode(e['raw'] as String) as Map<String, dynamic>,
          id: e['id'] as int,
        ),
      ),
    );
  }

  Future<int> deletePlan(int planId) async {
    final db = await dbHelper.database;
    await db.delete('planned_legs', where: 'plan_id = ?', whereArgs: [planId]);
    return await db
        .delete('planned_plans', where: 'id = ?', whereArgs: [planId]);
  }

  Future<void> loadAll() async {
    Plan.currentPlanneds.value = await getPlans();
  }
}
