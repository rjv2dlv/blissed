import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_apis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiClient {

    static const String userBaseUrl = AppAPIs.USER_API_BASE_URL;
    static const String userActionsBaseUrl = AppAPIs.USER_ACTIONS_API_BASE_URL;
    static const String userReflectionBaseUrl = AppAPIs.USER_REFLECTIONS_API_BASE_URL;
    static const String userBestMomentsBaseUrl = AppAPIs.USER_BEST_MOMENTS_API_BASE_URL;
    static const String userGratitudeBaseUrl = AppAPIs.USER_GRATITUDE_API_BASE_URL;

    static Future<String> getOrCreateUserId() async {
        final prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('user_id');
        if (userId == null) {
            userId = const Uuid().v4();
            await prefs.setString('user_id', userId);
        }
        return userId;
    }

    static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
        final url = Uri.parse('$userBaseUrl/users/$userId');
        final response = await http.get(url);
        if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            return data;
        }
        return null;
    }

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

  static Future<void> updateFcmTokenAndTimezone(String userId, String fcmToken, String timeZone) async {
    try {
      // First get current user profile to preserve existing data
      final currentProfile = await getUserProfile(userId);
      if (currentProfile != null) {
        // Update only FCM token and timezone, preserve existing reminders
        final response = await putUser(userId, {
          'fcm_token': fcmToken,
          'reminder_times': currentProfile['reminder_times'] ?? [],
          'timezone': timeZone,
        });
        print('FCM/Timezone update response: ${response.statusCode} ${response.body}');
      } else {
        // If no profile exists, create one with default reminders
        final response = await putUser(userId, {
          'fcm_token': fcmToken,
          'reminder_times': ['08:00', '17:00'],
          'timezone': timeZone,
        });
        print('New user profile created with default reminders: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Failed to update FCM token and timezone: ${e.toString()}');
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

  static Future<http.Response> putBestMoment(String userId, String date, String moment) async {
    final url = Uri.parse('$userBestMomentsBaseUrl/bestMoments/$userId/$date');
    return await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'moment': moment}),
    );
  }

  static Future<http.Response> putGratitudes(String userId, String date, List<String> gratitudes) async {
    final url = Uri.parse('$userGratitudeBaseUrl/gratitude/$userId/$date');
    return await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'gratitudes': gratitudes}),
    );
  }

  static Future<List<String>?> getReflection(String userId, String date) async {
    final url = Uri.parse('$userReflectionBaseUrl/reflections/$userId/$date');
    final response = await http.get(url);
    if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response data: $data');
        return data['answers'] != null ? List<String>.from(data['answers']) : null;
    }
    return null;
  }

  static Future<http.Response> getActions(String userId, String date) async {
    final url = Uri.parse('$userActionsBaseUrl/actions/$userId/$date');
    return await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Future<String?> getBestMoment(String userId, String date) async {
    final url = Uri.parse('$userBestMomentsBaseUrl/bestMoments/$userId/$date');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['moment'] as String?;
    }
    return null;
  }

  static Future<List<String>> getGratitudes(String userId, String date) async {
    final url = Uri.parse('$userGratitudeBaseUrl/gratitude/$userId/$date');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['gratitudes'] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getProgressStats(String userId) async {
    final url = Uri.parse('$userBaseUrl/progress/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }
}