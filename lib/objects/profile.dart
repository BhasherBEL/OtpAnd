import 'package:flutter/material.dart';
import 'package:otpand/db/crud/agencies.dart';
import 'package:otpand/objects/agency.dart';
import 'package:otpand/utils.dart';

class Profile {
  int id;
  String name;
  Color color;
  bool hasTemporaryEdits = false;
  Map<String, dynamic>? originalValues; // Stores original values when temporarily editing

  bool avoidDirectWalking;
  double walkPreference;
  double walkSafetyPreference;
  double walkSpeed;

  bool transit;
  double transitPreference;
  double transitWaitReluctance;
  double transitTransferWorth;
  int transitMinimalTransferTime;
  bool wheelchairAccessible;

  bool bike;
  double bikePreference;
  double bikeFlatnessPreference;
  double bikeSafetyPreference;
  double bikeSpeed;
  bool bikeFriendly;
  bool bikeParkRide;

  bool car;
  double carPreference;
  bool carParkRide;
  bool carKissRide;
  bool carPickup;

  Map<Agency, bool> agenciesEnabled = {};

  bool enableModeBus;
  double preferenceModeBus;
  bool enableModeMetro;
  double preferenceModeMetro;
  bool enableModeTram;
  double preferenceModeTram;
  bool enableModeTrain;
  double preferenceModeTrain;
  bool enableModeFerry;
  double preferenceModeFerry;

  Profile({
    required this.id,
    required this.name,
    required this.color,
    this.hasTemporaryEdits = false,
    this.originalValues,
    required this.avoidDirectWalking,
    required this.walkPreference,
    required this.walkSafetyPreference,
    required this.walkSpeed,
    required this.transit,
    required this.transitPreference,
    required this.transitWaitReluctance,
    required this.transitTransferWorth,
    required this.transitMinimalTransferTime,
    required this.wheelchairAccessible,
    required this.bike,
    required this.bikePreference,
    required this.bikeFlatnessPreference,
    required this.bikeSafetyPreference,
    required this.bikeSpeed,
    required this.bikeFriendly,
    required this.bikeParkRide,
    required this.car,
    required this.carPreference,
    required this.carParkRide,
    required this.carKissRide,
    required this.carPickup,
    required this.agenciesEnabled,
    required this.enableModeBus,
    required this.preferenceModeBus,
    required this.enableModeMetro,
    required this.preferenceModeMetro,
    required this.enableModeTram,
    required this.preferenceModeTram,
    required this.enableModeTrain,
    required this.preferenceModeTrain,
    required this.enableModeFerry,
    required this.preferenceModeFerry,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Store original values and mark as having temporary edits
  void startTemporaryEditing() {
    if (!hasTemporaryEdits) {
      originalValues = _getCurrentValues();
      hasTemporaryEdits = true;
    }
  }

  /// Revert to original values and clear temporary edit flag
  void revertToOriginal() {
    if (hasTemporaryEdits && originalValues != null) {
      _restoreFromMap(originalValues!);
      hasTemporaryEdits = false;
      originalValues = null;
    }
  }

  /// Clear temporary edit flag and original values (when saving permanently)
  void commitTemporaryEdits() {
    hasTemporaryEdits = false;
    originalValues = null;
  }

  /// Gets the display name for this profile
  String get displayName {
    if (name.isNotEmpty) {
      return hasTemporaryEdits ? '$name*' : name;
    }
    return hasTemporaryEdits ? 'Profile $id*' : 'Profile $id';
  }

  Map<String, dynamic> _getCurrentValues() {
    return {
      'name': name,
      'color': color.value,
      'avoidDirectWalking': avoidDirectWalking,
      'walkPreference': walkPreference,
      'walkSafetyPreference': walkSafetyPreference,
      'walkSpeed': walkSpeed,
      'transit': transit,
      'transitPreference': transitPreference,
      'transitWaitReluctance': transitWaitReluctance,
      'transitTransferWorth': transitTransferWorth,
      'transitMinimalTransferTime': transitMinimalTransferTime,
      'wheelchairAccessible': wheelchairAccessible,
      'bike': bike,
      'bikePreference': bikePreference,
      'bikeFlatnessPreference': bikeFlatnessPreference,
      'bikeSafetyPreference': bikeSafetyPreference,
      'bikeSpeed': bikeSpeed,
      'bikeFriendly': bikeFriendly,
      'bikeParkRide': bikeParkRide,
      'car': car,
      'carPreference': carPreference,
      'carParkRide': carParkRide,
      'carKissRide': carKissRide,
      'carPickup': carPickup,
      'agenciesEnabled': Map<Agency, bool>.from(agenciesEnabled),
      'enableModeBus': enableModeBus,
      'preferenceModeBus': preferenceModeBus,
      'enableModeMetro': enableModeMetro,
      'preferenceModeMetro': preferenceModeMetro,
      'enableModeTram': enableModeTram,
      'preferenceModeTram': preferenceModeTram,
      'enableModeTrain': enableModeTrain,
      'preferenceModeTrain': preferenceModeTrain,
      'enableModeFerry': enableModeFerry,
      'preferenceModeFerry': preferenceModeFerry,
    };
  }

  void _restoreFromMap(Map<String, dynamic> values) {
    name = values['name'] as String;
    color = Color(values['color'] as int);
    avoidDirectWalking = values['avoidDirectWalking'] as bool;
    walkPreference = values['walkPreference'] as double;
    walkSafetyPreference = values['walkSafetyPreference'] as double;
    walkSpeed = values['walkSpeed'] as double;
    transit = values['transit'] as bool;
    transitPreference = values['transitPreference'] as double;
    transitWaitReluctance = values['transitWaitReluctance'] as double;
    transitTransferWorth = values['transitTransferWorth'] as double;
    transitMinimalTransferTime = values['transitMinimalTransferTime'] as int;
    wheelchairAccessible = values['wheelchairAccessible'] as bool;
    bike = values['bike'] as bool;
    bikePreference = values['bikePreference'] as double;
    bikeFlatnessPreference = values['bikeFlatnessPreference'] as double;
    bikeSafetyPreference = values['bikeSafetyPreference'] as double;
    bikeSpeed = values['bikeSpeed'] as double;
    bikeFriendly = values['bikeFriendly'] as bool;
    bikeParkRide = values['bikeParkRide'] as bool;
    car = values['car'] as bool;
    carPreference = values['carPreference'] as double;
    carParkRide = values['carParkRide'] as bool;
    carKissRide = values['carKissRide'] as bool;
    carPickup = values['carPickup'] as bool;
    agenciesEnabled = Map<Agency, bool>.from(values['agenciesEnabled'] as Map);
    enableModeBus = values['enableModeBus'] as bool;
    preferenceModeBus = values['preferenceModeBus'] as double;
    enableModeMetro = values['enableModeMetro'] as bool;
    preferenceModeMetro = values['preferenceModeMetro'] as double;
    enableModeTram = values['enableModeTram'] as bool;
    preferenceModeTram = values['preferenceModeTram'] as double;
    enableModeTrain = values['enableModeTrain'] as bool;
    preferenceModeTrain = values['preferenceModeTrain'] as double;
    enableModeFerry = values['enableModeFerry'] as bool;
    preferenceModeFerry = values['preferenceModeFerry'] as double;
  }

  Map<String, dynamic> getPlanPreferences() {
    num bikeFlatnessRatio = round(
      bikeFlatnessPreference * (1 - bikeSafetyPreference / 2),
      5,
    );
    num bikeSafetyRatio =
        bikeSafetyPreference * (1 - bikeFlatnessPreference / 2);
    num bikeTimeRatio = 1 - bikeFlatnessRatio - bikeSafetyRatio;

    return {
      'accessibility': {
        'wheelchair': {'enabled': wheelchairAccessible},
      },
      'street': {
        'bicycle': {
          'optimization': {
            'triangle': {
              'flatness': round(bikeFlatnessRatio, 5),
              'safety': round(bikeSafetyRatio, 5),
              'time': round(bikeTimeRatio, 5),
            },
          },
          'reluctance': round(transitPreference / bikePreference, 5),
          'speed': round(bikeSpeed / 3.6, 5),
        },
        'car': {'reluctance': round(transitPreference / carPreference, 5)},
        'walk': {
          'reluctance': round(transitPreference / walkPreference, 5),
          'safetyFactor': round(walkSafetyPreference, 5),
          'speed': round(walkSpeed / 3.6, 5),
        },
      },
      'transit': {
        'board': {'waitReluctance': round(transitWaitReluctance, 5)},
        'transfer': {
          'cost': round(transitTransferWorth * 60, 0),
          'slack': '${transitMinimalTransferTime}m',
        },
        'filters': [
          if (agenciesEnabled.entries.any((entry) => !entry.value))
            {
              'exclude': {
                'agencies': agenciesEnabled.entries
                    .where((entry) => !entry.value)
                    .map((entry) => entry.key.gtfsId)
                    .toList(),
              },
            }
        ],
      },
    };
  }

  Map<String, dynamic> getPlanModes() {
    List<String> direct = [];
    if (bike) direct.add('BICYCLE');
    if (car) direct.add('CAR');
    if (!bike && !car && !avoidDirectWalking) direct.add('WALK');

    return {
      'direct': direct,
      'directOnly': !transit,
      'transitOnly': (avoidDirectWalking &&
          !bike &&
          !bikeParkRide &&
          !car &&
          !carKissRide &&
          !carParkRide),
      'transit': {
        'access': [
          if (!bikeFriendly) 'WALK',
          if (bikeParkRide) 'BICYCLE_PARKING',
          if (carParkRide) 'CAR_PARKING',
          if (bikeFriendly) 'BICYCLE',
          if (carKissRide) 'CAR_DROP_OFF',
        ],
        'egress': [
          if (!bikeFriendly) 'WALK',
          if (bikeFriendly) 'BICYCLE',
          if (carPickup) 'CAR_PICKUP',
        ],
        'transfer': [if (!bikeFriendly) 'WALK', if (bikeFriendly) 'BICYCLE'],
        'transit': [
          if (enableModeBus)
            {
              'mode': 'BUS',
              'cost': {
                'reluctance': round(transitPreference / preferenceModeBus, 5)
              }
            },
          if (enableModeMetro)
            {
              'mode': 'SUBWAY',
              'cost': {
                'reluctance': round(transitPreference / preferenceModeMetro, 5)
              }
            },
          if (enableModeTram)
            {
              'mode': 'TRAM',
              'cost': {
                'reluctance': round(transitPreference / preferenceModeTram, 5)
              }
            },
          if (enableModeTrain)
            {
              'mode': 'RAIL',
              'cost': {
                'reluctance': round(transitPreference / preferenceModeTrain, 5)
              }
            },
          if (enableModeFerry)
            {
              'mode': 'FERRY',
              'cost': {
                'reluctance': round(transitPreference / preferenceModeFerry, 5)
              }
            },
        ],
      },
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'avoidDirectWalking': avoidDirectWalking ? 1 : 0,
      'walkPreference': walkPreference,
      'walkSafetyPreference': walkSafetyPreference,
      'walkSpeed': walkSpeed,
      'transit': transit ? 1 : 0,
      'transitPreference': transitPreference,
      'transitWaitReluctance': transitWaitReluctance,
      'transitTransferWorth': transitTransferWorth,
      'transitMinimalTransferTime': transitMinimalTransferTime,
      'wheelchairAccessible': wheelchairAccessible ? 1 : 0,
      'bike': bike ? 1 : 0,
      'bikePreference': bikePreference,
      'bikeFlatnessPreference': bikeFlatnessPreference,
      'bikeSafetyPreference': bikeSafetyPreference,
      'bikeSpeed': bikeSpeed,
      'bikeFriendly': bikeFriendly ? 1 : 0,
      'bikeParkRide': bikeParkRide ? 1 : 0,
      'car': car ? 1 : 0,
      'carPreference': carPreference,
      'carParkRide': carParkRide ? 1 : 0,
      'carKissRide': carKissRide ? 1 : 0,
      'carPickup': carPickup ? 1 : 0,
      'agenciesEnabled': agenciesEnabled.entries
          .map((entry) => '${entry.key.gtfsId}.${entry.value}')
          .join(','),
      'enableModeBus': enableModeBus ? 1 : 0,
      'preferenceModeBus': preferenceModeBus,
      'enableModeMetro': enableModeMetro ? 1 : 0,
      'preferenceModeMetro': preferenceModeMetro,
      'enableModeTram': enableModeTram ? 1 : 0,
      'preferenceModeTram': preferenceModeTram,
      'enableModeTrain': enableModeTrain ? 1 : 0,
      'preferenceModeTrain': preferenceModeTrain,
      'enableModeFerry': enableModeFerry ? 1 : 0,
      'preferenceModeFerry': preferenceModeFerry,
    };
  }

  static Future<List<Profile>> parseAll(List<dynamic> list) async {
    return Future.wait(
      list.map((item) => parse(item as Map<String, dynamic>)),
    );
  }

  static Future<Profile> parse(Map<String, dynamic> map) async {
    return Profile(
      id: map['id'] as int,
      name: map['name'] as String,
      color: Color(map['color'] as int),
      avoidDirectWalking: map['avoidDirectWalking'] == 1,
      walkPreference: map['walkPreference'] as double,
      walkSafetyPreference: map['walkSafetyPreference'] as double,
      walkSpeed: map['walkSpeed'] as double,
      transit: map['transit'] == 1,
      transitPreference: map['transitPreference'] as double,
      transitWaitReluctance: map['transitWaitReluctance'] as double,
      transitTransferWorth: map['transitTransferWorth'] as double,
      transitMinimalTransferTime: map['transitMinimalTransferTime'] as int,
      wheelchairAccessible: map['wheelchairAccessible'] == 1,
      bike: map['bike'] == 1,
      bikePreference: map['bikePreference'] as double,
      bikeFlatnessPreference: map['bikeFlatnessPreference'] as double,
      bikeSafetyPreference: map['bikeSafetyPreference'] as double,
      bikeSpeed: map['bikeSpeed'] as double,
      bikeFriendly: map['bikeFriendly'] == 1,
      bikeParkRide: map['bikeParkRide'] == 1,
      car: map['car'] == 1,
      carPreference: map['carPreference'] as double,
      carParkRide: map['carParkRide'] == 1,
      carKissRide: map['carKissRide'] == 1,
      carPickup: map['carPickup'] == 1,
      agenciesEnabled: (map['agenciesEnabled'] as String).isNotEmpty
          ? Map.fromEntries(
              (await Future.wait(
                (map['agenciesEnabled'] as String).split(',').map((item) async {
                  final parts = item.split('.');
                  final agency = await AgencyDao().get(parts[0]);
                  if (agency == null) return null;

                  return MapEntry(
                      agency, parts.length > 1 && parts[1] == 'true');
                }),
              ))
                  .whereType<MapEntry<Agency, bool>>(),
            )
          : {},
      enableModeBus: map['enableModeBus'] == 1,
      preferenceModeBus: map['preferenceModeBus'] as double,
      enableModeMetro: map['enableModeMetro'] == 1,
      preferenceModeMetro: map['preferenceModeMetro'] as double,
      enableModeTram: map['enableModeTram'] == 1,
      preferenceModeTram: map['preferenceModeTram'] as double,
      enableModeTrain: map['enableModeTrain'] == 1,
      preferenceModeTrain: map['preferenceModeTrain'] as double,
      enableModeFerry: map['enableModeFerry'] == 1,
      preferenceModeFerry: map['preferenceModeFerry'] as double,
    );
  }
}
