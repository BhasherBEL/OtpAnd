import 'package:flutter/foundation.dart';
import 'package:otpand/objects/location.dart';
import 'package:otpand/objects/profile.dart';

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

  factory SearchHistory.fromSearch({
    required Location fromLocation,
    required Location toLocation,
    required Profile profile,
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
      profileId: profile.id,
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
    DateTime? searchedAt,
  }) {
    return SearchHistory(
      id: id ?? this.id,
      fromLocationName: fromLocationName ?? this.fromLocationName,
      fromLocationDisplayName:
          fromLocationDisplayName ?? this.fromLocationDisplayName,
      fromLocationLat: fromLocationLat ?? this.fromLocationLat,
      fromLocationLon: fromLocationLon ?? this.fromLocationLon,
      toLocationName: toLocationName ?? this.toLocationName,
      toLocationDisplayName:
          toLocationDisplayName ?? this.toLocationDisplayName,
      toLocationLat: toLocationLat ?? this.toLocationLat,
      toLocationLon: toLocationLon ?? this.toLocationLon,
      profileId: profileId ?? this.profileId,
      searchedAt: searchedAt ?? this.searchedAt,
    );
  }

  String get displayText {
    return '$fromLocationDisplayName → $toLocationDisplayName';
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
