import 'package:otpand/db/crud/plans.dart';
import 'package:otpand/objects/leg.dart';
import 'package:otpand/api/plan.dart' as plan_api;
import 'package:otpand/objects/plan.dart';

final _planDao = PlanDao();

class PlanRepository {
  Future<Leg?> fetchLegById(String legId) async {
    return await plan_api.fetchLegById(legId);
  }

  Future<List<Leg>> updateLegs(List<Leg> legs) async {
    return await Future.wait(
      legs.map((leg) async {
        if (leg.id != null) {
          final updated = await plan_api.fetchLegById(leg.id!);
          return updated ?? leg;
        }
        return leg;
      }),
    );
  }

  Future<int> savePlannedPlan(Plan plan) async {
    return await _planDao.insertPlan(plan);
  }

  Future<void> deletePlannedPlan(Plan plan) async {
    if (plan.id == null) return;
    await _planDao.deletePlan(plan.id!);
  }
}
