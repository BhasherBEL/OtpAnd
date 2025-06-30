import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otpand/db/crud/agencies.dart';
import 'package:otpand/db/crud/directions.dart';
import 'package:otpand/db/crud/routes.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:otpand/objects/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _lastGtfsSyncKey = 'last_gtfs_sync';

Future<void> checkAndSyncGtfsData({bool force = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final lastSyncMillis = prefs.getInt(_lastGtfsSyncKey);

  if (!force && lastSyncMillis != null) {
    final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    final diff = now.difference(lastSync);
    if (diff.inHours < 23) {
      return;
    }
  }

  await fetchAndStoreGtfsData();
  await prefs.setInt(_lastGtfsSyncKey, now.millisecondsSinceEpoch);
}

Future<void> fetchAndStoreGtfsData() async {
  const String agenciesGql = '''
  {
    agencies {
      gtfsId
      name
      url
      routes {
        gtfsId
        longName
        shortName
        color
        textColor
        mode
				patterns {
					headsign
					stops {
						gtfsId
						name
						platformCode
						lat
						lon
						vehicleMode
						platformCode
					}
				}
      }
    }
  }
  ''';

  final resp = await http.post(
    Uri.parse('${Config().otpUrl}/otp/gtfs/v1'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'query': agenciesGql}),
  );

  if (resp.statusCode != 200) {
    throw Exception('Failed to fetch GTFS agencies: ${resp.statusCode}');
  }

  final data = jsonDecode(resp.body);
  if (data['data'] == null || data['data']['agencies'] == null) {
    throw Exception('No agencies found in GTFS data');
  }

  final agencyDao = AgencyDao();
  final routeDao = RouteDao();
  final stopDao = StopDao();

  final agencies =
      (data['data']['agencies'] as List<dynamic>).cast<Map<String, dynamic>>();

  final List<Map<String, dynamic>> agencyMaps = [];
  final List<Map<String, dynamic>> routeMaps = [];
  final Map<String, Map<String, dynamic>> stopMaps = {};
  final List<Map<String, dynamic>> directionMaps = [];
  final List<Map<String, String>> agencyRouteLinks = [];
  final List<Map<String, dynamic>> directionStopLinks = [];

  for (final agency in agencies) {
    agencyMaps.add({
      'gtfsId': agency['gtfsId'],
      'name': agency['name'],
      'url': agency['url'],
    });

    final routes =
        (agency['routes'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];

    for (final route in routes) {
      routeMaps.add({
        'gtfsId': route['gtfsId'] as String,
        'longName': route['longName'] as String,
        'shortName': route['shortName'] as String,
        'color': route['color'],
        'textColor': route['textColor'],
        'mode': route['mode'],
      });
      agencyRouteLinks.add({
        'agency_gtfsId': agency['gtfsId'] as String,
        'route_gtfsId': route['gtfsId'] as String,
      });

      final patterns =
          (route['patterns'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [];

      for (int i = 0; i < patterns.length; i++) {
        final pattern = patterns[i];
        final stops = (pattern['stops'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        directionMaps.add({
          'route_gtfsId': route['gtfsId'],
          'headsign': pattern['headsign'] ?? stops.last['name'],
        });

        for (int j = 0; j < stops.length; j++) {
          final stop = stops[j];
          stopMaps[stop['gtfsId'] as String] = {
            'gtfsId': stop['gtfsId'],
            'name': stop['name'],
            'platformCode': stop['platformCode'],
            'lat': stop['lat'],
            'lon': stop['lon'],
            'mode': stop['vehicleMode'],
          };
          directionStopLinks.add({
            'direction_origin': i,
            'stop_gtfsId': stop['gtfsId'],
            'order': j,
          });
        }
      }
    }
  }

  await agencyDao.batchInsert(agencyMaps);
  await routeDao.batchInsert(routeMaps);
  final directionsId = await DirectionDao().batchInsert(directionMaps);
  await stopDao.batchInsert(stopMaps.values.toList());
  await routeDao.batchInsertAgencies(agencyRouteLinks);
  for (final directionStopLink in directionStopLinks) {
    directionStopLink['direction_id'] =
        directionsId[directionStopLink.remove('direction_origin') as int];
  }
  await stopDao.batchInsertDirection(directionStopLinks);

  await StopDao().loadAll();
  await AgencyDao().loadAll();
}
