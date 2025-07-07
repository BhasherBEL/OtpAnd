import 'package:intl/intl.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/objects/profile.dart';
import 'package:otpand/widgets/datetime_picker.dart';

class PlansQueryVariables {
  final Location fromLocation;
  final Location toLocation;
  final Profile profile;
  final DateTimePickerValue dateTimeValue;
  final String? after;
  final String? before;
  final int? first;
  final int? last;
  final String? searchWindow;

  const PlansQueryVariables({
    required this.fromLocation,
    required this.toLocation,
    required this.profile,
    required this.dateTimeValue,
    this.after,
    this.before,
    this.first,
    this.last,
    this.searchWindow,
  });

  String get directionType => dateTimeValue.mode == DateTimePickerMode.arrival
      ? 'latestArrival'
      : 'earliestDeparture';

  String get dtIso {
    String localTZ = DateTime.now().timeZoneOffset.isNegative
        ? '-${DateTime.now().timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:00'
        : '+${DateTime.now().timeZoneOffset.inHours.toString().padLeft(2, '0')}:00';

    if (dateTimeValue.mode == DateTimePickerMode.now ||
        dateTimeValue.dateTime == null) {
      return DateFormat('yyyy-MM-ddTHH:mm').format(DateTime.now()) + localTZ;
    }

    DateTime dateTime = dateTimeValue.dateTime!;

    if (dateTimeValue.precisionMode == DateTimePrecisionMode.around) {
      dateTime = dateTime.subtract(Duration(hours: 1));
    }

    switch (dateTimeValue.mode) {
      case DateTimePickerMode.now:
        if (dateTimeValue.precisionMode == DateTimePrecisionMode.before) {
          dateTime = dateTime.subtract(Duration(hours: 2));
        }
        break;
      case DateTimePickerMode.departure:
        if (dateTimeValue.precisionMode == DateTimePrecisionMode.before) {
          dateTime = dateTime.subtract(Duration(hours: 2));
        }
        break;
      case DateTimePickerMode.arrival:
        if (dateTimeValue.precisionMode == DateTimePrecisionMode.after) {
          dateTime = dateTime.add(Duration(hours: 2));
        }
        break;
    }

    return DateFormat('yyyy-MM-ddTHH:mm').format(dateTime) + localTZ;
  }

  Map<String, dynamic> get() {
    Map<String, dynamic> variables = {
      'origin': {
        'location': {
          'coordinate': {
            'latitude': fromLocation.lat,
            'longitude': fromLocation.lon
          },
        },
        'label': fromLocation.name,
      },
      'destination': {
        'location': {
          'coordinate': {
            'latitude': toLocation.lat,
            'longitude': toLocation.lon
          },
        },
        'label': toLocation.name,
      },
      'dateTime': {directionType: dtIso},
      'searchWindow': searchWindow,
      'modes': profile.getPlanModes(),
      'preferences': profile.getPlanPreferences(),
    };
    if (after != null) variables['after'] = after;
    if (before != null) variables['before'] = before;
    if (first != null) variables['first'] = first;
    if (last != null) variables['last'] = last;

    return variables;
  }

  PlansQueryVariables copyWith({
    Location? fromLocation,
    Location? toLocation,
    Profile? profile,
    DateTimePickerValue? dateTimeValue,
    String? after,
    String? before,
    int? first,
    int? last,
    String? searchWindow,
  }) {
    return PlansQueryVariables(
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      profile: profile ?? this.profile,
      dateTimeValue: dateTimeValue ?? this.dateTimeValue,
      after: after ?? this.after,
      before: before ?? this.before,
      first: first ?? this.first,
      last: last ?? this.last,
      searchWindow: searchWindow ?? this.searchWindow,
    );
  }
}

class PlansPageInfo {
  final String? startCursor;
  final String? endCursor;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PlansPageInfo({
    this.startCursor,
    this.endCursor,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PlansPageInfo.fromJson(Map<String, dynamic> json) {
    return PlansPageInfo(
      startCursor: json['startCursor'] as String?,
      endCursor: json['endCursor'] as String?,
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
    );
  }
}
