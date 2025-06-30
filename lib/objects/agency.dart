import 'package:flutter/material.dart';

class Agency {
  final String gtfsId;
  final String? name;
  final String? url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Agency &&
          runtimeType == other.runtimeType &&
          gtfsId == other.gtfsId;

  @override
  int get hashCode => gtfsId.hashCode;

  static final currentAgencies = ValueNotifier<List<Agency>>([]);

  Agency({required this.gtfsId, required this.name, required this.url});

  static Agency parse(Map<String, dynamic> json) {
    return Agency(
      gtfsId: json['gtfsId'] as String,
      name: json['name'] as String?,
      url: json['url'] as String?,
    );
  }

  static List<Agency> parseAll(List<dynamic> list) {
    return list.map((e) => Agency.parse(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toMap() {
    return {'gtfsId': gtfsId, 'name': name, 'url': url};
  }
}
