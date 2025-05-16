import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otpand/config.dart';
import 'package:otpand/db/crud/agencies.dart';
import 'package:otpand/db/crud/directions.dart';
import 'package:otpand/db/crud/routes.dart';
import 'package:otpand/db/crud/stops.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _lastGtfsSyncKey = 'last_gtfs_sync';

Future<void> checkAndSyncGtfsData() async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final lastSyncMillis = prefs.getInt(_lastGtfsSyncKey);

  if (lastSyncMillis != null) {
    final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    final diff = now.difference(lastSync);
    print('Last GTFS sync was ${diff.inHours} hours ago');
    if (diff.inHours < 23) {
      print('No need to fetch newer GTFS data');
      return;
    }
  }

  print('Fetching GTFS data...');
  await fetchAndStoreGtfsData();
  await prefs.setInt(_lastGtfsSyncKey, now.millisecondsSinceEpoch);
  print('GTFS data fetched and stored successfully');
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
					}
				}
      }
    }
  }
  ''';

  final resp = await http.post(
    Uri.parse('$OTP_API_URL/otp/gtfs/v1'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'query': agenciesGql}),
  );

  if (resp.statusCode != 200) {
    throw Exception('Failed to fetch GTFS agencies: ${resp.statusCode}');
  }

  print(resp.body.length);

  final data = jsonDecode(resp.body);
  if (data['data'] == null || data['data']['agencies'] == null) {
    throw Exception('No agencies found in GTFS data');
  }

  final agencyDao = AgencyDao();
  final routeDao = RouteDao();
  final stopDao = StopDao();

  final agencies = data['data']['agencies'];

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

    final routes = agency['routes'] ?? [];

    for (final route in routes) {
      routeMaps.add({
        'gtfsId': route['gtfsId'],
        'longName': route['longName'],
        'shortName': route['shortName'],
        'color': route['color'],
        'textColor': route['textColor'],
        'mode': route['mode'],
      });
      agencyRouteLinks.add({
        'agency_gtfsId': agency['gtfsId'],
        'route_gtfsId': route['gtfsId'],
      });

      final patterns = route['patterns'] ?? [];

      for (int i = 0; i < patterns.length; i++) {
        final pattern = patterns[i];
        final stops = pattern['stops'] ?? [];

        directionMaps.add({
          'route_gtfsId': route['gtfsId'],
          'headsign': pattern['headsign'] ?? stops.last['name'],
        });

        for (int j = 0; j < stops.length; j++) {
          final stop = stops[j];
          stopMaps[stop['gtfsId']] = {
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
  print('Agencies inserted: ${agencyMaps.length}');

  await routeDao.batchInsert(routeMaps);
  print('Routes inserted: ${routeMaps.length}');

  final directionsId = await DirectionDao().batchInsert(directionMaps);
  print('Directions inserted: ${directionMaps.length}');

  await stopDao.batchInsert(stopMaps.values.toList());
  print('Stops inserted: ${stopMaps.length}');

  await routeDao.batchInsertAgencies(agencyRouteLinks);
  print('Agency-Route links inserted: ${agencyRouteLinks.length}');

  for (final directionStopLink in directionStopLinks) {
    directionStopLink['direction_id'] =
        directionsId[directionStopLink.remove('direction_origin')];
  }

  await stopDao.batchInsertDirection(directionStopLinks);
  print('Direction-Stop links inserted: ${directionStopLinks.length}');
}
