import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_apis.dart';

class ApiClient {

    static const String userBaseUrl = AppAPIs.USER_API_BASE_URL;

  static Future<http.Response> putUser(String userId, Map<String, dynamic> data) async {
    final url = Uri.parse('$userBaseUrl/users/$userId');
    return await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  static Future<void> updateUserProfile(String userId, String fcmToken, List<String> reminderTimes) async {
    try {
      final response = await putUser(userId, {
        'fcm_token': fcmToken,
        'reminder_times': reminderTimes,
      });
      print('User update response: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('Failed to update user profile: $e');
    }
  }
}