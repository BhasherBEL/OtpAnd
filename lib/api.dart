import 'package:otpAnd/extractor.dart';
import 'package:otpAnd/objs.dart';
import 'package:http/http.dart' as http;

const OTP_INSTANCE = 'https://maps.bhasher.com';

Future<List<Stop>> geoCodeApi(String query) async {
  final resp = await http.get(
    Uri.parse(
      '$OTP_INSTANCE/otp/geocode?query=$query&autocomplete=true&stops=true&clusters=true',
    ),
  );

  if (resp.statusCode != 200) {
    throw Exception('Failed to load geocode data');
  }

  return (resp.body as List).map((e) => parseGeocodeStop(e)).toList();
}
