import 'package:flutter/material.dart';
import 'package:otpand/utils.dart';

class Profile {
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

  factory Profile.blank() => Profile(
    name: 'New profile',
    color: Colors.blue,
    avoidDirectWalking: false,
    walkPreference: 1.0, // 0.1 - 2
    walkSafetyPreference: 0.5, // 0 - 1
    walkSpeed: 5, // 2 - 10
    transit: true,
    transitPreference: 1.0, // 0.1 - 2
    transitWaitReluctance: 1.0, // 0.1 - 2
    transitTransferWorth: 0.0, // 0 - 15
    transitMinimalTransferTime: 60, // 0 - 1800
    wheelchairAccessible: false,
    bike: false,
    bikePreference: 1.0, // 0.1 - 2
    bikeFlatnessPreference: 0.5, // 0 - 1
    bikeSafetyPreference: 0.5, // 0 - 1
    bikeSpeed: 15.0, // 5 - 40
    bikeFriendly: false,
    bikeParkRide: false,
    car: false,
    carPreference: 1.0, // 0.1 - 2
    carParkRide: false,
    carKissRide: false,
    carPickup: false,
  );

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
          "WALK",
          if (bikeParkRide) "BICYCLE_PARKING",
          if (carParkRide) "CAR_PARKING",
          if (bikeFriendly) "BICYCLE",
          if (carKissRide) "CAR_DROP_OFF",
        ],
        "egress": [
          "WALK",
          if (bikeFriendly) "BICYCLE",
          if (carPickup) "CAR_PICKUP",
        ],
        "transfer": ["WALK", if (bikeFriendly) "BICYCLE"],
      },
    };
  }
}
