class Direction {
  final int id;
  final String routeGtfsId;
  final String headsign;

  Direction({
    required this.id,
    required this.routeGtfsId,
    required this.headsign,
  });

  static Direction parse(Map<String, dynamic> json) {
    return Direction(
      id: json['id'] as int,
      routeGtfsId: json['route_gtfsId'] as String,
      headsign: json['headsign'] as String,
    );
  }

  static List<Direction> parseAll(List<dynamic> list) {
    return list.map((e) => Direction.parse(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'route_gtfsId': routeGtfsId, 'headsign': headsign};
  }
}
