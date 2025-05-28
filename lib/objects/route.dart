import 'package:flutter/material.dart';
import 'package:otpand/utils.dart';

enum RouteMode {
  bus('bus', Icons.directions_bus, Colors.blue),
  rail('rail', Icons.train, Colors.teal),
  subway('subway', Icons.subway, Colors.deepOrange),
  tram('tram', Icons.tram, Colors.purple),
  walk('walk', Icons.directions_walk, Colors.green),
  bicycle('bicycle', Icons.directions_bike, Colors.lightGreen),
  car('car', Icons.directions_car, Colors.red),
  ferry('ferry', Icons.directions_boat, Colors.grey),
  unknown('unknown', Icons.question_mark, Colors.grey);

  final String name;
  final IconData icon;
  final Color color;

  const RouteMode(this.name, this.icon, this.color);

  static RouteMode fromString(String? mode) {
    if (mode == null) return unknown;

    switch (mode.toLowerCase()) {
      case 'bus':
        return bus;
      case 'rail':
      case 'train':
        return rail;
      case 'subway':
        return subway;
      case 'tram':
        return tram;
      case 'walk':
        return walk;
      case 'bicycle':
        return bicycle;
      case 'car':
        return car;
      case 'ferry':
        return ferry;
      default:
        return unknown;
    }
  }
}

class RouteInfo {
  final String gtfsId;
  final String longName;
  final String shortName;
  final Color? color;
  final Color? textColor;
  final RouteMode mode;

  RouteInfo({
    required this.gtfsId,
    required this.longName,
    required this.shortName,
    this.color,
    required this.mode,
    this.textColor,
  });

  static RouteInfo parse(Map<String, dynamic> json) {
    return RouteInfo(
      gtfsId: json['gtfsId'] as String,
      longName: json['longName'] as String,
      shortName: json['shortName'] as String,
      color: getColorFromCode(json['color']),
      textColor: getColorFromCode(json['textColor']),
      mode: RouteMode.fromString(json['mode'] as String?),
    );
  }

  static List<RouteInfo> parseAll(List<dynamic> list) {
    return list.map((e) => RouteInfo.parse(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'gtfsId': gtfsId,
      'longName': longName,
      'shortName': shortName,
      'color': color?.value,
      'textColor': textColor?.value,
      'mode': mode.name,
    };
  }
}
