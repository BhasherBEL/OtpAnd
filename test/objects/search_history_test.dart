import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/objects/profile.dart';
import 'package:otpand/objects/search_history.dart';

Profile _makeProfile({int id = 0, String name = 'Default'}) => Profile(
      id: id,
      name: name,
      color: Colors.blue,
      avoidDirectWalking: false,
      walkPreference: 1.0,
      walkSafetyPreference: 1.0,
      walkSpeed: 1.33,
      transit: true,
      transitPreference: 1.0,
      transitWaitReluctance: 1.0,
      transitTransferWorth: 1.0,
      transitMinimalTransferTime: 120,
      wheelchairAccessible: false,
      bike: false,
      bikePreference: 1.0,
      bikeFlatnessPreference: 1.0,
      bikeSafetyPreference: 1.0,
      bikeSpeed: 5.0,
      bikeFriendly: false,
      bikeParkRide: false,
      car: false,
      carPreference: 1.0,
      carParkRide: false,
      carKissRide: false,
      carPickup: false,
      agenciesEnabled: {},
      enableModeBus: true,
      preferenceModeBus: 1.0,
      enableModeMetro: true,
      preferenceModeMetro: 1.0,
      enableModeTram: true,
      preferenceModeTram: 1.0,
      enableModeTrain: true,
      preferenceModeTrain: 1.0,
      enableModeFerry: true,
      preferenceModeFerry: 1.0,
    );

void main() {
  final fromLocation = Location(
    name: 'Home',
    displayName: 'My Home',
    lat: 50.8,
    lon: 4.3,
  );
  final toLocation = Location(
    name: 'Work',
    displayName: 'My Office',
    lat: 50.9,
    lon: 4.4,
  );

  group('SearchHistory', () {
    test('displayText formats From → To', () {
      final history = SearchHistory(
        fromLocationName: 'Home',
        fromLocationDisplayName: 'My Home',
        fromLocationLat: 50.8,
        fromLocationLon: 4.3,
        toLocationName: 'Work',
        toLocationDisplayName: 'My Office',
        toLocationLat: 50.9,
        toLocationLon: 4.4,
        profileId: 0,
        searchedAt: DateTime(2024, 1, 1),
      );
      expect(history.displayText, 'My Home → My Office');
    });

    test('fromLocation getter returns Location', () {
      final history = SearchHistory(
        fromLocationName: 'Home',
        fromLocationDisplayName: 'My Home',
        fromLocationLat: 50.8,
        fromLocationLon: 4.3,
        toLocationName: 'Work',
        toLocationDisplayName: 'My Office',
        toLocationLat: 50.9,
        toLocationLon: 4.4,
        profileId: 0,
        searchedAt: DateTime(2024, 1, 1),
      );
      expect(history.fromLocation.name, 'Home');
      expect(history.fromLocation.lat, 50.8);
    });

    test('toLocation getter returns Location', () {
      final history = SearchHistory(
        fromLocationName: 'Home',
        fromLocationDisplayName: 'My Home',
        fromLocationLat: 50.8,
        fromLocationLon: 4.3,
        toLocationName: 'Work',
        toLocationDisplayName: 'My Office',
        toLocationLat: 50.9,
        toLocationLon: 4.4,
        profileId: 0,
        searchedAt: DateTime(2024, 1, 1),
      );
      expect(history.toLocation.name, 'Work');
      expect(history.toLocation.lon, 4.4);
    });

    test('fromSearch factory creates SearchHistory from locations and profile', () {
      final profile = _makeProfile(id: 1);
      final history = SearchHistory.fromSearch(
        fromLocation: fromLocation,
        toLocation: toLocation,
        profile: profile,
      );
      expect(history.fromLocationName, 'Home');
      expect(history.fromLocationDisplayName, 'My Home');
      expect(history.toLocationName, 'Work');
      expect(history.profileId, 1);
      expect(history.id, isNull);
    });

    group('toMap / fromMap', () {
      final history = SearchHistory(
        id: 5,
        fromLocationName: 'Home',
        fromLocationDisplayName: 'My Home',
        fromLocationLat: 50.8,
        fromLocationLon: 4.3,
        toLocationName: 'Work',
        toLocationDisplayName: 'My Office',
        toLocationLat: 50.9,
        toLocationLon: 4.4,
        profileId: 2,
        searchedAt: DateTime(2024, 6, 15, 10, 30),
      );

      test('toMap produces all expected keys', () {
        final map = history.toMap();
        expect(map['id'], 5);
        expect(map['fromLocationName'], 'Home');
        expect(map['fromLocationDisplayName'], 'My Home');
        expect(map['fromLocationLat'], 50.8);
        expect(map['fromLocationLon'], 4.3);
        expect(map['toLocationName'], 'Work');
        expect(map['toLocationDisplayName'], 'My Office');
        expect(map['toLocationLat'], 50.9);
        expect(map['toLocationLon'], 4.4);
        expect(map['profileId'], 2);
        expect(map['searchedAt'], isA<int>());
      });

      test('fromMap round-trips', () {
        final map = history.toMap();
        final restored = SearchHistory.fromMap(map);
        expect(restored.id, 5);
        expect(restored.fromLocationName, 'Home');
        expect(restored.toLocationDisplayName, 'My Office');
        expect(restored.profileId, 2);
        expect(restored.searchedAt.millisecondsSinceEpoch,
            history.searchedAt.millisecondsSinceEpoch);
      });

      test('parseAll converts list of maps', () {
        final list = [history.toMap(), history.copyWith(id: 6).toMap()];
        final parsed = SearchHistory.parseAll(list);
        expect(parsed.length, 2);
        expect(parsed[0].id, 5);
        expect(parsed[1].id, 6);
      });
    });

    group('copyWith', () {
      final base = SearchHistory(
        id: 1,
        fromLocationName: 'Home',
        fromLocationDisplayName: 'My Home',
        fromLocationLat: 50.8,
        fromLocationLon: 4.3,
        toLocationName: 'Work',
        toLocationDisplayName: 'My Office',
        toLocationLat: 50.9,
        toLocationLon: 4.4,
        profileId: 0,
        searchedAt: DateTime(2024, 1, 1),
      );

      test('copies with new id', () {
        final copy = base.copyWith(id: 99);
        expect(copy.id, 99);
        expect(copy.fromLocationName, 'Home');
      });

      test('copies with new locations', () {
        final copy = base.copyWith(
          fromLocationName: 'NewFrom',
          toLocationName: 'NewTo',
        );
        expect(copy.fromLocationName, 'NewFrom');
        expect(copy.toLocationName, 'NewTo');
        expect(copy.id, 1); // unchanged
      });

      test('no args → identical values', () {
        final copy = base.copyWith();
        expect(copy.id, base.id);
        expect(copy.profileId, base.profileId);
      });
    });

    group('equality', () {
      test('same id → equal', () {
        final h1 = SearchHistory(
          id: 1,
          fromLocationName: 'A', fromLocationDisplayName: 'A',
          fromLocationLat: 0, fromLocationLon: 0,
          toLocationName: 'B', toLocationDisplayName: 'B',
          toLocationLat: 0, toLocationLon: 0,
          profileId: 0, searchedAt: DateTime(2024),
        );
        final h2 = SearchHistory(
          id: 1,
          fromLocationName: 'X', fromLocationDisplayName: 'X',
          fromLocationLat: 9, fromLocationLon: 9,
          toLocationName: 'Y', toLocationDisplayName: 'Y',
          toLocationLat: 9, toLocationLon: 9,
          profileId: 9, searchedAt: DateTime(2025),
        );
        expect(h1, equals(h2));
      });

      test('different id → not equal', () {
        final h1 = SearchHistory(
          id: 1,
          fromLocationName: 'A', fromLocationDisplayName: 'A',
          fromLocationLat: 0, fromLocationLon: 0,
          toLocationName: 'B', toLocationDisplayName: 'B',
          toLocationLat: 0, toLocationLon: 0,
          profileId: 0, searchedAt: DateTime(2024),
        );
        final h2 = h1.copyWith(id: 2);
        expect(h1, isNot(equals(h2)));
      });
    });
  });
}
