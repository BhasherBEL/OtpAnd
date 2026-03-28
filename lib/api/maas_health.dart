import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

enum MaasHealthStatus { ok, unreachable, timeout, httpError, notGraphQL, incompatible, graphqlError }

class MaasHealthResult {
  final MaasHealthStatus status;
  final String title;
  final String message;
  final Duration? latency;
  final int? httpStatusCode;

  const MaasHealthResult({
    required this.status,
    required this.title,
    required this.message,
    this.latency,
    this.httpStatusCode,
  });
}

Future<MaasHealthResult> checkMaasHealth(String maasUrl) async {
  final uri = Uri.tryParse('$maasUrl/graphql');
  if (uri == null) {
    return const MaasHealthResult(
      status: MaasHealthStatus.unreachable,
      title: 'Invalid URL',
      message: 'The configured URL is not valid. Check the maas-rs URL in settings.',
    );
  }

  final stopwatch = Stopwatch()..start();

  http.Response response;
  try {
    response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'query': '{ ping }'}),
        )
        .timeout(const Duration(seconds: 8));
  } on TimeoutException {
    return MaasHealthResult(
      status: MaasHealthStatus.timeout,
      title: 'Connection timed out',
      message: 'No response from $maasUrl after 8 seconds.\n\n'
          'Make sure the server is running and the device is on the same network.',
    );
  } on SocketException catch (e) {
    return MaasHealthResult(
      status: MaasHealthStatus.unreachable,
      title: 'Server unreachable',
      message: 'Could not open a connection to $maasUrl.\n\n'
          'Network error: ${e.message}',
    );
  } on HandshakeException catch (e) {
    return MaasHealthResult(
      status: MaasHealthStatus.unreachable,
      title: 'TLS handshake failed',
      message: 'Connected to $maasUrl but TLS negotiation failed.\n\n'
          'Details: ${e.message}',
    );
  } catch (e) {
    return MaasHealthResult(
      status: MaasHealthStatus.unreachable,
      title: 'Connection error',
      message: 'Unexpected error connecting to $maasUrl:\n\n$e',
    );
  }

  stopwatch.stop();
  final latency = stopwatch.elapsed;

  if (response.statusCode != 200) {
    return MaasHealthResult(
      status: MaasHealthStatus.httpError,
      title: 'HTTP ${response.statusCode}',
      message: 'The server responded with an unexpected HTTP status code.\n\n'
          'This may mean the URL path is wrong, the server returned an error, '
          'or this is not a maas-rs instance.\n\n'
          'Response body (first 200 chars):\n${response.body.length > 200 ? '${response.body.substring(0, 200)}…' : response.body}',
      latency: latency,
      httpStatusCode: response.statusCode,
    );
  }

  Map<String, dynamic> body;
  try {
    body = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    return MaasHealthResult(
      status: MaasHealthStatus.notGraphQL,
      title: 'Not a GraphQL endpoint',
      message: 'The server at $maasUrl returned non-JSON content.\n\n'
          'This is not a maas-rs instance (or the URL path is wrong — expected /graphql).',
      latency: latency,
      httpStatusCode: response.statusCode,
    );
  }

  final errors = body['errors'];
  if (errors != null && errors is List && errors.isNotEmpty) {
    final msgs = (errors)
        .map((e) => (e as Map<String, dynamic>)['message']?.toString() ?? '')
        .join('\n• ');
    final isUnknownField = msgs.toLowerCase().contains('cannot query field') ||
        msgs.toLowerCase().contains('unknown field') ||
        msgs.toLowerCase().contains('no field named');
    return MaasHealthResult(
      status: isUnknownField
          ? MaasHealthStatus.incompatible
          : MaasHealthStatus.graphqlError,
      title: isUnknownField ? 'Incompatible API' : 'GraphQL error',
      message: isUnknownField
          ? 'Reached a GraphQL server at $maasUrl but it does not expose the '
              'maas-rs API (field "ping" not found).\n\n'
              'This might be a different GraphQL service or an old version of maas-rs.\n\n'
              'Error:\n• $msgs'
          : 'The server returned a GraphQL error:\n\n• $msgs',
      latency: latency,
      httpStatusCode: response.statusCode,
    );
  }

  final data = body['data'];
  if (data == null || data is! Map<String, dynamic>) {
    return MaasHealthResult(
      status: MaasHealthStatus.incompatible,
      title: 'Unexpected response shape',
      message: 'The server returned a 200 OK with valid JSON but without a '
          '"data" field.\n\nRaw response:\n${response.body.length > 300 ? '${response.body.substring(0, 300)}…' : response.body}',
      latency: latency,
      httpStatusCode: response.statusCode,
    );
  }

  final ping = data['ping'];
  if (ping != 'pong') {
    return MaasHealthResult(
      status: MaasHealthStatus.incompatible,
      title: 'Unexpected ping response',
      message: 'Connected to $maasUrl but the ping response was "$ping" '
          'instead of "pong".\n\nThis might be a different GraphQL service.',
      latency: latency,
      httpStatusCode: response.statusCode,
    );
  }

  return MaasHealthResult(
    status: MaasHealthStatus.ok,
    title: 'Connected',
    message: 'maas-rs is reachable and responding correctly at $maasUrl.',
    latency: latency,
    httpStatusCode: response.statusCode,
  );
}
