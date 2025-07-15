import 'package:shared_preferences/shared_preferences.dart';

class AppDateUtils {
  static String formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  static String getDateKey(DateTime date) {
    print('fetching key for: ${date.year}_${date.month}_${date.day}');
    return '${date.year}_${date.month}_${date.day}';
  }

  static int calculateStreak(SharedPreferences prefs) {
    // Calculate longest streak in the last 30 days
    final now = DateTime.now();
    int maxStreak = 0;
    int currentStreak = 0;
    
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = getDateKey(date);
      
      final hasReflection = prefs.getStringList('self_reflection_$dateKey') != null;
      final hasActions = prefs.getString('daily_actions_$dateKey') != null;
      final hasKindness = prefs.getString('kindness_$dateKey') != null;
      final hasBestMoment = prefs.getString('best_moment_$dateKey') != null;
      
      if (hasReflection || hasActions || hasKindness || hasBestMoment) {
        currentStreak++;
        maxStreak = maxStreak < currentStreak ? currentStreak : maxStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    return maxStreak;
  }

  static int calculateCurrentStreak(SharedPreferences prefs) {
    final now = DateTime.now();
    int currentStreak = 0;
    
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = getDateKey(date);
      
      final hasReflection = prefs.getStringList('self_reflection_$dateKey') != null;
      final hasActions = prefs.getString('daily_actions_$dateKey') != null;
      final hasKindness = prefs.getString('kindness_$dateKey') != null;
      final hasBestMoment = prefs.getString('best_moment_$dateKey') != null;
      
      if (hasReflection || hasActions || hasKindness || hasBestMoment) {
        currentStreak++;
      } else {
        break;
      }
    }
    
    return currentStreak;
  }
} 