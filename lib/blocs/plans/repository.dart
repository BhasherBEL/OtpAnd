import 'package:otpand/api/plan_maas.dart' as maas_api;
import 'package:otpand/blocs/plans/helpers.dart';
import 'package:otpand/objects/config.dart';

class PlansRepository {
  /// Fetches journey plans from maas-rs.
  ///
  /// Profile preferences and mode filters in [variables] are not forwarded —
  /// maas-rs does not support them yet (see MISSING_FEATURES.md).
  ///
  /// Arrival-time routing is not supported by maas-rs; [variables.dtIso] is
  /// always treated as a departure time.
  ///
  /// Pagination cursors in [variables] are ignored; maas-rs returns all
  /// results at once and the returned pageInfo always has no next/prev page.
  Future<Map<String, dynamic>> fetchPlans(PlansQueryVariables variables) async {
    // Strip timezone suffix so DateTime.parse treats it as local time,
    // which is what was selected by the user.
    final dtStr =
        variables.dtIso.replaceFirst(RegExp(r'[+-]\d{2}:\d{2}$'), '');
    final queryDateTime = DateTime.parse(dtStr);

    return maas_api.fetchMaasPlans(
      fromLocation: variables.fromLocation,
      toLocation: variables.toLocation,
      queryDateTime: queryDateTime,
      maasUrl: Config().maasUrl,
    );
  }
}
