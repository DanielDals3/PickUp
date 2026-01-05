import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<http.Response> fetchOverpassData(String url) async {
    return await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('Timeout'),
    );
  }
}