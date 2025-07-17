import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_apis.dart';

class ApiClient {

    static const String userBaseUrl = AppAPIs.USER_API_BASE_URL;
    static const String userActionsBaseUrl = AppAPIs.USER_ACTIONS_API_BASE_URL;
    static const String userReflectionBaseUrl = AppAPIs.USER_REFLECTIONS_API_BASE_URL;

  static Future<http.Response> putUser(String userId, Map<String, dynamic> data) async {
    final url = Uri.parse('$userBaseUrl/users/$userId');
    return await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  static Future<void> updateUserProfile(String userId, String fcmToken, List<String> reminderTimes, String timeZone) async {
    try {
      final response = await putUser(userId, {
        'fcm_token': fcmToken,
        'reminder_times': reminderTimes,
        'timezone': timeZone,
      });
      print('User update response: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('Failed to update user profile: ${e.toString()}');
    }
  }

  static Future<http.Response> putActions(String userId, String date, List<dynamic> actions) async {
    final url = Uri.parse('$userActionsBaseUrl/actions/$userId/$date');
    print('adding action to the backend');
    return await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'actions': actions}),
    );
  }

  static Future<http.Response> putReflection(String userId, String date, List<dynamic> answers) async {
    final url = Uri.parse('$userReflectionBaseUrl/reflections/$userId/$date');
    return await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'answers': answers}),
    );
  }
}