import 'package:flutter/widgets.dart';
import 'package:otpand/utils.dart';

enum RouteMode {
  bus('bus'),
  rail('rail'),
  subway('subway'),
  tram('tram'),
  unknown('unknown');

  const RouteMode(String title);

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
    if (json['shortName'] == '95') {
      print(json['color']);
    }
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
