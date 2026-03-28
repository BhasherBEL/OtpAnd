import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:otpand/db/crud/agencies.dart';
import 'package:otpand/db/crud/routes.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _lastMaasGtfsSyncKey = 'last_maas_gtfs_sync';

/// Runs [fetchAndStoreMaasGtfsData] at most once every 23 hours.
///
/// Pass [force] = `true` to bypass the time check (e.g. from a settings
/// "Refresh data" button).
Future<void> checkAndSyncMaasGtfsData({bool force = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final lastSyncMillis = prefs.getInt(_lastMaasGtfsSyncKey);

  if (!force && lastSyncMillis != null) {
    final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    if (now.difference(lastSync).inHours < 23) {
      return;
    }
  }

  await fetchAndStoreMaasGtfsData();
  await prefs.setInt(_lastMaasGtfsSyncKey, now.millisecondsSinceEpoch);
}

/// Fetches stops, agencies, and routes from maas-rs and stores them in the
/// local SQLite database.
///
/// **Populated tables**: `stops`, `agencies`, `routes`, `agencies_routes`.
///
/// **Not populated** (maas-rs does not expose this data):
/// - `directions` / `direction_items` — no per-route stop sequences.
/// - Route colors / text colors — not stored in maas-rs.
/// - Stop platform codes — not stored in maas-rs.
/// - Stop vehicle mode — not stored in maas-rs.
Future<void> fetchAndStoreMaasGtfsData() async {
  const String stopsQuery = r'''
  {
    gtfsStops {
      id
      name
      lat
      lon
      mode
    }
  }
  ''';

  const String agenciesQuery = r'''
  {
    gtfsAgencies {
      id
      name
      url
      routes {
        id
        shortName
        longName
        mode
        color
        textColor
      }
    }
  }
  ''';

  final String maasUrl = Config().maasUrl;

  // ── Stops ──────────────────────────────────────────────────────────────

  final stopsResp = await http.post(
    Uri.parse('$maasUrl/graphql'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'query': stopsQuery}),
  );

  if (stopsResp.statusCode != 200) {
    throw Exception(
      'Failed to fetch GTFS stops from maas-rs: ${stopsResp.statusCode}',
    );
  }

  final stopsBody = jsonDecode(stopsResp.body) as Map<String, dynamic>;
  if (stopsBody['errors'] != null) {
    debugPrint('maas-rs gtfsStops errors: ${stopsBody['errors']}');
    throw Exception('maas-rs returned errors for gtfsStops');
  }
  if (stopsBody['data'] == null || stopsBody['data']['gtfsStops'] == null) {
    throw Exception('No stops in maas-rs response');
  }

  // ── Agencies ───────────────────────────────────────────────────────────

  final agenciesResp = await http.post(
    Uri.parse('$maasUrl/graphql'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'query': agenciesQuery}),
  );

  if (agenciesResp.statusCode != 200) {
    throw Exception(
      'Failed to fetch GTFS agencies from maas-rs: ${agenciesResp.statusCode}',
    );
  }

  final agenciesBody = jsonDecode(agenciesResp.body) as Map<String, dynamic>;
  if (agenciesBody['errors'] != null) {
    debugPrint('maas-rs gtfsAgencies errors: ${agenciesBody['errors']}');
    throw Exception('maas-rs returned errors for gtfsAgencies');
  }
  if (agenciesBody['data'] == null ||
      agenciesBody['data']['gtfsAgencies'] == null) {
    throw Exception('No agencies in maas-rs response');
  }

  // ── Persist stops ──────────────────────────────────────────────────────

  final rawStops = (stopsBody['data']['gtfsStops'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final stopMaps = rawStops
      .map(
        (s) => {
          'gtfsId': s['id'] as String,
          'name': s['name'] as String,
          'platformCode': null,
          'lat': (s['lat'] as num).toDouble(),
          'lon': (s['lon'] as num).toDouble(),
          'mode': s['mode'] as String?,
        },
      )
      .toList();

  await StopDao().batchInsert(stopMaps);

  // ── Persist agencies and routes ────────────────────────────────────────

  final rawAgencies = (agenciesBody['data']['gtfsAgencies'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final List<Map<String, dynamic>> agencyMaps = [];
  final List<Map<String, dynamic>> routeMaps = [];
  final List<Map<String, String>> agencyRouteLinks = [];

  for (final agency in rawAgencies) {
    agencyMaps.add({
      'gtfsId': agency['id'] as String,
      'name': agency['name'] as String,
      'url': (agency['url'] as String?) ?? '',
    });

    final routes =
        (agency['routes'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];

    for (final route in routes) {
      final colorHex = route['color'] as String?;
      final textColorHex = route['textColor'] as String?;
      routeMaps.add({
        'gtfsId': route['id'] as String,
        'longName': (route['longName'] as String?) ?? '',
        'shortName': (route['shortName'] as String?) ?? '',
        'color': colorHex != null ? int.tryParse(colorHex, radix: 16) : null,
        'textColor': textColorHex != null ? int.tryParse(textColorHex, radix: 16) : null,
        'mode': route['mode'] as String?,
      });
      agencyRouteLinks.add({
        'agency_gtfsId': agency['id'] as String,
        'route_gtfsId': route['id'] as String,
      });
    }
  }

  await AgencyDao().batchInsert(agencyMaps);
  await RouteDao().batchInsert(routeMaps);
  await RouteDao().batchInsertAgencies(agencyRouteLinks);

  // ── Refresh in-memory caches ──────────────────────────────────────────

  await StopDao().loadAll();
  await AgencyDao().loadAll();
}
