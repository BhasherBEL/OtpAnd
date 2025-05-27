import 'package:flutter/material.dart';
import 'package:otpand/utils.dart';

class Profile {
  int id;
  String name;
  Color color;

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

  Profile({
    required this.id,
    required this.name,
    required this.color,
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
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> getPlanPreferences() {
    num bikeFlatnessRatio = round(
      bikeFlatnessPreference * (1 - bikeSafetyPreference / 2),
      5,
    );
    num bikeSafetyRatio =
        bikeSafetyPreference * (1 - bikeFlatnessPreference / 2);
    num bikeTimeRatio = 1 - bikeFlatnessRatio - bikeSafetyRatio;

    return {
      "accessibility": {
        "wheelchair": {"enabled": wheelchairAccessible},
      },
      "street": {
        "bicycle": {
          "optimization": {
            "triangle": {
              "flatness": round(bikeFlatnessRatio, 5),
              "safety": round(bikeSafetyRatio, 5),
              "time": round(bikeTimeRatio, 5),
            },
          },
          "reluctance": round(transitPreference / bikePreference, 5),
          "speed": round(bikeSpeed / 3.6, 5),
        },
        "car": {"reluctance": round(transitPreference / carPreference, 5)},
        "walk": {
          "reluctance": round(transitPreference / walkPreference, 5),
          "safetyFactor": round(walkSafetyPreference, 5),
          "speed": round(walkSpeed / 3.6, 5),
        },
      },
      "transit": {
        "board": {"waitReluctance": round(transitWaitReluctance, 5)},
        "transfer": {
          "cost": round(transitTransferWorth * 60, 0),
          "slack": "${transitMinimalTransferTime}m",
        },
      },
    };
  }

  Map<String, dynamic> getPlanModes() {
    List<String> direct = [];
    if (bike) direct.add('BICYCLE');
    if (car) direct.add('CAR');
    if (!bike && !car && !avoidDirectWalking) direct.add('WALK');

    return {
      "direct": direct,
      "directOnly": !transit,
      "transitOnly": (avoidDirectWalking && !bike && !car),
      "transit": {
        "access": [
          if (!bikeFriendly) "WALK",
          if (bikeParkRide) "BICYCLE_PARKING",
          if (carParkRide) "CAR_PARKING",
          if (bikeFriendly) "BICYCLE",
          if (carKissRide) "CAR_DROP_OFF",
        ],
        "egress": [
          if (!bikeFriendly) "WALK",
          if (bikeFriendly) "BICYCLE",
          if (carPickup) "CAR_PICKUP",
        ],
        "transfer": [if (!bikeFriendly) "WALK", if (bikeFriendly) "BICYCLE"],
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
    };
  }

  static List<Profile> parseAll(List<dynamic> list) {
    return list.map((e) => Profile.parse(e as Map<String, dynamic>)).toList();
  }

  static Profile parse(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
      avoidDirectWalking: map['avoidDirectWalking'] == 1,
      walkPreference: map['walkPreference'],
      walkSafetyPreference: map['walkSafetyPreference'],
      walkSpeed: map['walkSpeed'],
      transit: map['transit'] == 1,
      transitPreference: map['transitPreference'],
      transitWaitReluctance: map['transitWaitReluctance'],
      transitTransferWorth: map['transitTransferWorth'],
      transitMinimalTransferTime: map['transitMinimalTransferTime'],
      wheelchairAccessible: map['wheelchairAccessible'] == 1,
      bike: map['bike'] == 1,
      bikePreference: map['bikePreference'],
      bikeFlatnessPreference: map['bikeFlatnessPreference'],
      bikeSafetyPreference: map['bikeSafetyPreference'],
      bikeSpeed: map['bikeSpeed'],
      bikeFriendly: map['bikeFriendly'] == 1,
      bikeParkRide: map['bikeParkRide'] == 1,
      car: map['car'] == 1,
      carPreference: map['carPreference'],
      carParkRide: map['carParkRide'] == 1,
      carKissRide: map['carKissRide'] == 1,
      carPickup: map['carPickup'] == 1,
    );
  }
}
