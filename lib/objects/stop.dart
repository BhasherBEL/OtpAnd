class Stop {
  final String gtfsId;
  final String name;
  final String? platformCode;
  final double lat;
  final double lon;
  final String? mode;

  Stop({
    required this.gtfsId,
    required this.name,
    this.platformCode,
    required this.lat,
    required this.lon,
    this.mode,
  });

  static Stop parse(Map<String, dynamic> json) {
    return Stop(
      gtfsId: json['gtfsId'] as String,
      name: json['name'] as String,
      platformCode: json['platformCode'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      mode: json['mode'] as String?,
    );
  }

  static List<Stop> parseAll(List<dynamic> list) {
    return list.map((e) => Stop.parse(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'gtfsId': gtfsId,
      'name': name,
      'lat': lat,
      'lon': lon,
      'platformCode': platformCode,
      'mode': mode,
    };
  }
}
