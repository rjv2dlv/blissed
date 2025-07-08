import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'date_utils.dart';

class PointsUtils {
  static const String _pointsKey = 'points_history';

  /// Increment points for today by [amount] (default 1)
  static Future<void> incrementToday({int amount = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = AppDateUtils.getDateKey(DateTime.now());
    final pointsMap = await getPointsMap();
    pointsMap[todayKey] = (pointsMap[todayKey] ?? 0) + amount;
    await prefs.setString(_pointsKey, json.encode(pointsMap));
  }

  /// Get the map of dateKey -> points for the last 30 days
  static Future<Map<String, int>> getLast30DaysPoints() async {
    final pointsMap = await getPointsMap();
    final now = DateTime.now();
    final result = <String, int>{};
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final key = AppDateUtils.getDateKey(date);
      result[key] = pointsMap[key] ?? 0;
    }
    return result;
  }

  /// Get the full points map (all time)
  static Future<Map<String, int>> getPointsMap() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pointsKey);
    if (jsonString == null) return {};
    final decoded = json.decode(jsonString);
    return Map<String, int>.from(decoded);
  }
} 