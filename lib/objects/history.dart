import 'package:flutter/foundation.dart';
import 'package:otpand/objects/config.dart';
import 'package:otpand/objects/profile.dart';
import 'package:otpand/widgets/datetime_picker.dart';
import 'package:otpand/objects/location.dart';

class History {
  Location? fromLocation;
  Location? toLocation;
  DateTimePickerValue? dateTime;
  Profile? profile;

  History({this.fromLocation, this.toLocation, this.dateTime, this.profile});

  History copyWith({
    Location? fromLocation,
    Location? toLocation,
    DateTimePickerValue? dateTime,
    Profile? profile,
  }) {
    return History(
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      dateTime: dateTime ?? this.dateTime,
      profile: profile ?? this.profile,
    );
  }

  static final ValueNotifier<History> current = ValueNotifier<History>(
    History(),
  );

  static void update({
    Location? fromLocation,
    Location? toLocation,
    DateTimePickerValue? dateTime,
    Profile? profile,
  }) {
    final old = current.value;
    current.value = old.copyWith(
      fromLocation: fromLocation,
      toLocation: toLocation,
      dateTime: dateTime,
      profile: profile,
    );
    if (profile != null) {
      Config().setValue(ConfigKey.defaultProfileId, profile.id);
    }
  }
}
