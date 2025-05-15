import 'dart:convert';
import 'package:otpand/extractor.dart';
import 'package:otpand/objs.dart';
import 'package:http/http.dart' as http;

const OTP_INSTANCE = 'https://maps.bhasher.com';

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

  final List<dynamic> data = jsonDecode(resp.body);
  return data.map((e) => parseLocation(e)).firstOrNull;
}
