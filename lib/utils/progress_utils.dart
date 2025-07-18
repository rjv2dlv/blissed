import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../utils/date_utils.dart';
import '../utils/points_utils.dart';

class ProgressUtils {
  static String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());
  static String get weekKey {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    return DateFormat('yyyy-MM-dd').format(startOfWeek);
  }
  static String get monthKey => DateFormat('yyyy-MM').format(DateTime.now());

  static Future<Map<String, dynamic>> _getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = prefs.getString('progress_stats');
    if (stats != null) {
      return json.decode(stats) as Map<String, dynamic>;
    }
    // Initialize structure
    return {
      'd': {'r': 0, 'a': 0, 'g': 0, 'b': 0, 'p': 0},
      'w': {'r': 0, 'a': 0, 'g': 0, 'b': 0, 'p': 0, 'k': weekKey},
      'm': {'r': 0, 'a': 0, 'g': 0, 'b': 0, 'p': 0, 'k': monthKey},
      'ph': {},
      'hph': [],
    };
  }

  static Future<void> _saveStats(Map<String, dynamic> stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('progress_stats', json.encode(stats));
  }

  static Future<void> addReflection() async {
    final stats = await _getStats();
    stats['d']['r'] = (stats['d']['r'] ?? 0) + 1;
    stats['w']['r'] = (stats['w']['r'] ?? 0) + 1;
    stats['m']['r'] = (stats['m']['r'] ?? 0) + 1;
    await _saveStats(stats);
    await addPoints(1);
  }

  static Future<void> addActionCompleted() async {
    final stats = await _getStats();
    stats['d']['a'] = (stats['d']['a'] ?? 0) + 1;
    stats['w']['a'] = (stats['w']['a'] ?? 0) + 1;
    stats['m']['a'] = (stats['m']['a'] ?? 0) + 1;
    await _saveStats(stats);
    await addPoints(1);
  }

  static Future<void> addGratitude() async {
    final stats = await _getStats();
    stats['d']['g'] = (stats['d']['g'] ?? 0) + 1;
    stats['w']['g'] = (stats['w']['g'] ?? 0) + 1;
    stats['m']['g'] = (stats['m']['g'] ?? 0) + 1;
    await _saveStats(stats);
    await addPoints(1);
  }

  static Future<void> addBestMoment() async {
    final stats = await _getStats();
    stats['d']['b'] = (stats['d']['b'] ?? 0) + 1;
    stats['w']['b'] = (stats['w']['b'] ?? 0) + 1;
    stats['m']['b'] = (stats['m']['b'] ?? 0) + 1;
    await _saveStats(stats);
    await addPoints(1);
  }

  static Future<void> addPoints(int points) async {
    final stats = await _getStats();
    stats['d']['p'] = (stats['d']['p'] ?? 0) + points;
    stats['w']['p'] = (stats['w']['p'] ?? 0) + points;
    stats['m']['p'] = (stats['m']['p'] ?? 0) + points;
    // Update points history
    final today = todayKey;
    stats['ph'][today] = (stats['ph'][today] ?? 0) + points;
    await _saveStats(stats);
  }

  // Call this at midnight or on app open to roll over stats if the day/week/month changed
  static Future<void> rolloverIfNeeded() async {
    final stats = await _getStats();
    final now = DateTime.now();
    final today = todayKey;
    final week = weekKey;
    final month = monthKey;
    // Rollover day
    if (stats['d']['date'] != today) {
      stats['d'] = {'r': 0, 'a': 0, 'g': 0, 'b': 0, 'p': 0, 'date': today};
    }
    // Rollover week
    if (stats['w']['k'] != week) {
      stats['w'] = {'r': 0, 'a': 0, 'g': 0, 'b': 0, 'p': 0, 'k': week};
    }
    // Rollover month
    if (stats['m']['k'] != month) {
      stats['m'] = {'r': 0, 'a': 0, 'g': 0, 'b': 0, 'p': 0, 'k': month};
    }
    await _saveStats(stats);
  }

  // Optionally, add methods to decrement stats if an entry is deleted/edited
}