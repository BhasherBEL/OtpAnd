class Agency {
  final String gtfsId;
  final String name;
  final String url;

  Agency({required this.gtfsId, required this.name, required this.url});

  static Agency parse(Map<String, dynamic> json) {
    return Agency(
      gtfsId: json['gtfsId'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  static List<Agency> parseAll(List<dynamic> list) {
    return list.map((e) => Agency.parse(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toMap() {
    return {'gtfsId': gtfsId, 'name': name, 'url': url};
  }
}
