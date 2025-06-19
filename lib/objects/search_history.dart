import 'package:flutter/foundation.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/objects/profile.dart';
import 'package:otpand/widgets/datetime_picker.dart';

class SearchHistory {
  final int? id;
  final String fromLocationName;
  final String fromLocationDisplayName;
  final double fromLocationLat;
  final double fromLocationLon;
  final String toLocationName;
  final String toLocationDisplayName;
  final double toLocationLat;
  final double toLocationLon;
  final int profileId;
  final String profileName;
  final int profileColor;
  final String timeType;
  final DateTime? selectedDateTime;
  final DateTime searchedAt;

  SearchHistory({
    this.id,
    required this.fromLocationName,
    required this.fromLocationDisplayName,
    required this.fromLocationLat,
    required this.fromLocationLon,
    required this.toLocationName,
    required this.toLocationDisplayName,
    required this.toLocationLat,
    required this.toLocationLon,
    required this.profileId,
    required this.profileName,
    required this.profileColor,
    required this.timeType,
    this.selectedDateTime,
    required this.searchedAt,
  });

  Location get fromLocation => Location(
        name: fromLocationName,
        displayName: fromLocationDisplayName,
        lat: fromLocationLat,
        lon: fromLocationLon,
      );

  Location get toLocation => Location(
        name: toLocationName,
        displayName: toLocationDisplayName,
        lat: toLocationLat,
        lon: toLocationLon,
      );

  DateTimePickerValue get dateTimeValue => DateTimePickerValue(
        mode: timeType == 'now'
            ? DateTimePickerMode.now
            : timeType == 'depart'
                ? DateTimePickerMode.departure
                : DateTimePickerMode.arrival,
        dateTime: selectedDateTime ?? DateTime.now(),
      );

  factory SearchHistory.fromSearch({
    required Location fromLocation,
    required Location toLocation,
    required Profile profile,
    required String timeType,
    DateTime? selectedDateTime,
    int? id,
  }) {
    return SearchHistory(
      id: id,
      fromLocationName: fromLocation.name,
      fromLocationDisplayName: fromLocation.displayName,
      fromLocationLat: fromLocation.lat,
      fromLocationLon: fromLocation.lon,
      toLocationName: toLocation.name,
      toLocationDisplayName: toLocation.displayName,
      toLocationLat: toLocation.lat,
      toLocationLon: toLocation.lon,
      profileId: profile.id ?? 0,
      profileName: profile.name,
      profileColor: profile.color.value,
      timeType: timeType,
      selectedDateTime: selectedDateTime,
      searchedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromLocationName': fromLocationName,
      'fromLocationDisplayName': fromLocationDisplayName,
      'fromLocationLat': fromLocationLat,
      'fromLocationLon': fromLocationLon,
      'toLocationName': toLocationName,
      'toLocationDisplayName': toLocationDisplayName,
      'toLocationLat': toLocationLat,
      'toLocationLon': toLocationLon,
      'profileId': profileId,
      'profileName': profileName,
      'profileColor': profileColor,
      'timeType': timeType,
      'selectedDateTime': selectedDateTime?.millisecondsSinceEpoch,
      'searchedAt': searchedAt.millisecondsSinceEpoch,
    };
  }

  factory SearchHistory.fromMap(Map<String, dynamic> map) {
    return SearchHistory(
      id: map['id'] as int?,
      fromLocationName: map['fromLocationName'] as String,
      fromLocationDisplayName: map['fromLocationDisplayName'] as String,
      fromLocationLat: (map['fromLocationLat'] as num).toDouble(),
      fromLocationLon: (map['fromLocationLon'] as num).toDouble(),
      toLocationName: map['toLocationName'] as String,
      toLocationDisplayName: map['toLocationDisplayName'] as String,
      toLocationLat: (map['toLocationLat'] as num).toDouble(),
      toLocationLon: (map['toLocationLon'] as num).toDouble(),
      profileId: map['profileId'] as int,
      profileName: map['profileName'] as String,
      profileColor: map['profileColor'] as int,
      timeType: map['timeType'] as String,
      selectedDateTime: map['selectedDateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['selectedDateTime'] as int)
          : null,
      searchedAt: DateTime.fromMillisecondsSinceEpoch(map['searchedAt'] as int),
    );
  }

  static List<SearchHistory> parseAll(List<Map<String, dynamic>> maps) {
    return maps.map((map) => SearchHistory.fromMap(map)).toList();
  }

  SearchHistory copyWith({
    int? id,
    String? fromLocationName,
    String? fromLocationDisplayName,
    double? fromLocationLat,
    double? fromLocationLon,
    String? toLocationName,
    String? toLocationDisplayName,
    double? toLocationLat,
    double? toLocationLon,
    int? profileId,
    String? profileName,
    int? profileColor,
    String? timeType,
    DateTime? selectedDateTime,
    DateTime? searchedAt,
  }) {
    return SearchHistory(
      id: id ?? this.id,
      fromLocationName: fromLocationName ?? this.fromLocationName,
      fromLocationDisplayName: fromLocationDisplayName ?? this.fromLocationDisplayName,
      fromLocationLat: fromLocationLat ?? this.fromLocationLat,
      fromLocationLon: fromLocationLon ?? this.fromLocationLon,
      toLocationName: toLocationName ?? this.toLocationName,
      toLocationDisplayName: toLocationDisplayName ?? this.toLocationDisplayName,
      toLocationLat: toLocationLat ?? this.toLocationLat,
      toLocationLon: toLocationLon ?? this.toLocationLon,
      profileId: profileId ?? this.profileId,
      profileName: profileName ?? this.profileName,
      profileColor: profileColor ?? this.profileColor,
      timeType: timeType ?? this.timeType,
      selectedDateTime: selectedDateTime ?? this.selectedDateTime,
      searchedAt: searchedAt ?? this.searchedAt,
    );
  }

  String get displayText {
    return '${fromLocationDisplayName} → ${toLocationDisplayName}';
  }

  static final ValueNotifier<List<SearchHistory>> currentHistory = 
      ValueNotifier<List<SearchHistory>>([]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchHistory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

