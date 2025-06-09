import 'package:otpand/db/crud/routes.dart';
import 'package:otpand/objects/route.dart';

class Trip {
  final String gtfsId;
  final String? headsign;
  final String? shortName;
  final RouteInfo? route;

  Trip({
    required this.gtfsId,
    required this.headsign,
    required this.shortName,
    this.route,
  });

  static Future<Trip> parse(Map<String, dynamic> json) async {
    return Trip(
      gtfsId: json['gtfsId'] as String,
      headsign: json['tripHeadsign'] as String?,
      shortName: json['tripShortName'] as String?,
      route:
          json['route'] != null
              ? await RouteDao().get(json['route']['gtfsId'] as String)
              : null,
    );
  }

  static Trip parseWithRoute(RouteInfo? route, Map<String, dynamic> json) {
    return Trip(
      gtfsId: json['gtfsId'] as String,
      headsign: json['tripHeadsign'] as String?,
      shortName: json['tripShortName'] as String?,
      route: route,
    );
  }

  Map<String, dynamic> toMap() {
    return {'gtfsId': gtfsId, 'headsign': headsign, 'shortName': shortName};
  }
}
