import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otpand/config.dart';
import 'package:otpand/db/crud/agencies.dart';
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
      return;
    }
  }

  print('Fetching GTFS data...');
  await fetchAndStoreGtfsData();
  await prefs.setInt(_lastGtfsSyncKey, now.millisecondsSinceEpoch);
  print('GTFS data fetched and stored successfully');
}

Future<void> fetchAndStoreGtfsData() async {
  const int pageSize = 100;

  // Helper to fetch all routes for an agency with pagination
  Future<List<Map<String, dynamic>>> fetchAllRoutes(String agencyId) async {
    List<Map<String, dynamic>> allRoutes = [];
    String? after;
    bool hasNextPage = true;

    while (hasNextPage) {
      final String gql = '''
      {
        agency(id: "$agencyId") {
          routes(first: $pageSize${after != null ? ', after: "$after"' : ''}) {
            pageInfo {
              hasNextPage
              endCursor
            }
            edges {
              node {
                id
                longName
                shortName
                color
                textColor
                mode
                stops(first: $pageSize) {
                  pageInfo {
                    hasNextPage
                    endCursor
                  }
                  edges {
                    node {
                      id
                      name
                      platformCode
                      lat
                      lon
                    }
                  }
                }
              }
            }
          }
        }
      }
      ''';

      final resp = await http.post(
        Uri.parse('$OTP_API_URL/otp/gtfs/v1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': gql}),
      );

      if (resp.statusCode != 200) {
        throw Exception('Failed to fetch GTFS routes: ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body);
      final routesData = data['data']?['agency']?['routes'];
      if (routesData == null) break;

      for (final edge in routesData['edges'] ?? []) {
        final routeNode = edge['node'];
        // Fetch all stops for this route with pagination
        List<Map<String, dynamic>> allStops = [];
        var stopsData = routeNode['stops'];
        if (stopsData != null) {
          for (final stopEdge in stopsData['edges'] ?? []) {
            allStops.add(stopEdge['node']);
          }
          // If stops are paginated, fetch more
          bool stopsHasNext = stopsData['pageInfo']['hasNextPage'] ?? false;
          String? stopsAfter = stopsData['pageInfo']['endCursor'];
          while (stopsHasNext && stopsAfter != null) {
            final String stopsGql = '''
            {
              route(id: "${routeNode['id']}") {
                stops(first: $pageSize, after: "$stopsAfter") {
                  pageInfo {
                    hasNextPage
                    endCursor
                  }
                  edges {
                    node {
                      id
                      name
                      platformCode
                      lat
                      lon
                    }
                  }
                }
              }
            }
            ''';
            final stopsResp = await http.post(
              Uri.parse('$OTP_API_URL/otp/gtfs/v1'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'query': stopsGql}),
            );
            if (stopsResp.statusCode != 200) {
              throw Exception(
                'Failed to fetch GTFS stops: ${stopsResp.statusCode}',
              );
            }
            final stopsJson = jsonDecode(stopsResp.body);
            final stopsPage = stopsJson['data']?['route']?['stops'];
            if (stopsPage == null) break;
            for (final stopEdge in stopsPage['edges'] ?? []) {
              allStops.add(stopEdge['node']);
            }
            stopsHasNext = stopsPage['pageInfo']['hasNextPage'] ?? false;
            stopsAfter = stopsPage['pageInfo']['endCursor'];
          }
        }
        routeNode['stops'] = allStops;
        allRoutes.add(routeNode);
      }

      hasNextPage = routesData['pageInfo']['hasNextPage'] ?? false;
      after = routesData['pageInfo']['endCursor'];
    }
    return allRoutes;
  }

  // Fetch all agencies first
  const String agenciesGql = '''
  {
    agencies {
      id
      name
      url

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

  final data = jsonDecode(resp.body);
  if (data['data'] == null || data['data']['agencies'] == null) {
    throw Exception('No agencies found in GTFS data');
  }

  final agencies = data['data']['agencies'];
  final agencyDao = AgencyDao();
  final routeDao = RouteDao();
  final stopDao = StopDao();

  for (final agency in agencies) {
    final agencyId = await agencyDao.getOrInsert({
      'otpId': agency['id'],
      'name': agency['name'],
      'url': agency['url'],
    });

    // Fetch all routes (and their stops) for this agency
    final routes = await fetchAllRoutes(agency['id']);

    for (final route in routes) {
      final routeId = await routeDao.getOrInsert({
        'otpId': route['id'],
        'agency_id': agencyId,
        'longName': route['longName'],
        'shortName': route['shortName'],
        'color': route['color'],
        'textColor': route['textColor'],
        'mode': route['mode'],
      });

      await routeDao.insertAgency(routeId, agencyId);

      for (final stop in route['stops'] ?? []) {
        final stopId = await stopDao.getOrInsert({
          'otpId': stop['id'],
          'name': stop['name'],
          'platformCode': stop['platformCode'],
          'lat': stop['lat'],
          'lon': stop['lon'],
        });

        await stopDao.insertRoute(stopId, routeId);
      }
    }
  }
}
