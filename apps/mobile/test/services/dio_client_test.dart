import 'package:flutter_test/flutter_test.dart';
import 'package:medapp/config.dart';
import 'package:medapp/utils/dio_client.dart';

void main() {
  test('bearer tokens are restricted to the configured API origin', () {
    final api = Uri.parse(Config.apiBaseUrl);
    expect(DioHttpClient.isApiOrigin(api.resolve('auth/profile')), isTrue);
    expect(
      DioHttpClient.isApiOrigin(Uri.parse('https://api.fda.gov/drug/')),
      isFalse,
    );
    expect(DioHttpClient.isApiOrigin(api.replace(port: api.port + 1)), isFalse);
  });
}
