class Agency {
  final int id;
  final String otpId;
  final String name;
  final String url;

  Agency({
    required this.id,
    required this.otpId,
    required this.name,
    required this.url,
  });

  static Agency parse(Map<String, dynamic> json) {
    return Agency(
      id: json['id'] ?? '',
      otpId: json['otpId'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  static List<Agency> parseAll(List<dynamic> list) {
    return list.map((e) => Agency.parse(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'otpId': otpId, 'name': name, 'url': url};
  }
}
