import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApiService {
  static const String _scriptUrl =
      "https://script.google.com/macros/s/AKfycbyvTQ1sLJr-ZzANGPq5h_ktXk-T4Uo6dFzJLoK-nMFh-j1tqmktQ-6L1LUEfR_rJqq9/exec";

  static Future<String> submitAbsensi({
    required String nama,
    required double lat,
    required double lng,
    required String faceStatus,
  }) async {
    String currentTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());

    Map<String, dynamic> body = {
      "timestamp": currentTime,
      "nama": nama,
      "latitude": lat,
      "longitude": lng,
      "face_status": faceStatus,
      "foto_url": "-",
    };

    var request = http.Request('POST', Uri.parse(_scriptUrl))
      ..followRedirects = false
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 302) {
      String? redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        response = await http.get(Uri.parse(redirectUrl));
      }
    }

    if (response.statusCode == 200) {
      return currentTime;
    } else {
      throw Exception("Gagal mengirim data. Status: ${response.statusCode}");
    }
  }
}
