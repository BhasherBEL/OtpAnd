import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otpand/objects/location.dart';

Future<Location?> geoCodeNominatimApi(String query) async {
  final resp = await http.get(
    Uri.parse(
      Uri.encodeFull(
        'https://nominatim.openstreetmap.org/search?q=$query&countrycodes=be&format=json',
      ),
    ),
    headers: {'User-Agent': 'OtpAnd/1.0'},
  );

  if (resp.statusCode != 200) {
    throw Exception('Failed to load geocode data');
  }

  final List<Map<String, dynamic>> data =
      jsonDecode(resp.body) as List<Map<String, dynamic>>;
  return data.map((e) => Location.parse(e)).firstOrNull;
}
