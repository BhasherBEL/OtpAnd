import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/objects/route.dart';

void main() {
  group('RouteMode.fromString', () {
    test('null → unknown', () {
      expect(RouteMode.fromString(null), RouteMode.unknown);
    });

    test('case-insensitive: "bus" → bus', () {
      expect(RouteMode.fromString('bus'), RouteMode.bus);
      expect(RouteMode.fromString('BUS'), RouteMode.bus);
    });

    test('"rail" and "train" both → rail', () {
      expect(RouteMode.fromString('rail'), RouteMode.rail);
      expect(RouteMode.fromString('train'), RouteMode.rail);
      expect(RouteMode.fromString('TRAIN'), RouteMode.rail);
    });

    test('"subway" → subway', () {
      expect(RouteMode.fromString('subway'), RouteMode.subway);
    });

    test('"tram" → tram', () {
      expect(RouteMode.fromString('tram'), RouteMode.tram);
    });

    test('"walk" → walk', () {
      expect(RouteMode.fromString('walk'), RouteMode.walk);
    });

    test('"bicycle" → bicycle', () {
      expect(RouteMode.fromString('bicycle'), RouteMode.bicycle);
    });

    test('"car" → car', () {
      expect(RouteMode.fromString('car'), RouteMode.car);
    });

    test('"ferry" → ferry', () {
      expect(RouteMode.fromString('ferry'), RouteMode.ferry);
    });

    test('unknown string → unknown', () {
      expect(RouteMode.fromString('helicopter'), RouteMode.unknown);
      expect(RouteMode.fromString(''), RouteMode.unknown);
    });
  });

  group('RouteMode properties', () {
    test('bus has correct icon and color', () {
      expect(RouteMode.bus.icon, Icons.directions_bus);
      expect(RouteMode.bus.color, Colors.amber);
    });

    test('rail has correct icon', () {
      expect(RouteMode.rail.icon, Icons.train);
      expect(RouteMode.rail.color, Colors.teal);
    });

    test('subway has correct icon', () {
      expect(RouteMode.subway.icon, Icons.subway);
    });

    test('tram has correct icon', () {
      expect(RouteMode.tram.icon, Icons.tram);
    });
  });

  group('RouteInfo', () {
    test('parse from JSON without color', () {
      final route = RouteInfo.parse({
        'gtfsId': 'agency:route1',
        'longName': 'My Long Route',
        'shortName': '42',
        'color': null,
        'textColor': null,
        'mode': 'bus',
      });
      expect(route.gtfsId, 'agency:route1');
      expect(route.longName, 'My Long Route');
      expect(route.shortName, '42');
      expect(route.color, isNull);
      expect(route.textColor, isNull);
      expect(route.mode, RouteMode.bus);
    });

    test('parse from JSON with hex string color', () {
      final route = RouteInfo.parse({
        'gtfsId': 'agency:route2',
        'longName': 'Red Route',
        'shortName': 'R',
        'color': 'FF0000',
        'textColor': 'FFFFFF',
        'mode': 'tram',
      });
      expect(route.color, isNotNull);
      expect(route.textColor, isNotNull);
      expect(route.mode, RouteMode.tram);
    });

    test('toMap contains all fields', () {
      final route = RouteInfo(
        gtfsId: 'agency:1',
        longName: 'Long Name',
        shortName: '1',
        mode: RouteMode.bus,
      );
      final map = route.toMap();
      expect(map['gtfsId'], 'agency:1');
      expect(map['longName'], 'Long Name');
      expect(map['shortName'], '1');
      expect(map['mode'], 'bus');
      expect(map.containsKey('color'), true);
      expect(map.containsKey('textColor'), true);
    });

    test('toMap stores color as int value', () {
      final route = RouteInfo(
        gtfsId: 'agency:1',
        longName: 'Red Route',
        shortName: 'R',
        color: Colors.red,
        mode: RouteMode.bus,
      );
      final map = route.toMap();
      expect(map['color'], Colors.red.value);
    });

    test('parseAll converts list', () {
      final routes = RouteInfo.parseAll([
        {'gtfsId': 'a:1', 'longName': 'Route 1', 'shortName': '1', 'color': null, 'textColor': null, 'mode': 'bus'},
        {'gtfsId': 'a:2', 'longName': 'Route 2', 'shortName': '2', 'color': null, 'textColor': null, 'mode': 'tram'},
      ]);
      expect(routes.length, 2);
      expect(routes[0].mode, RouteMode.bus);
      expect(routes[1].mode, RouteMode.tram);
    });
  });
}
