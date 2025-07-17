import '../utils/app_cache.dart';
import 'package:intl/intl.dart';

final cache = AppCache();

class AppCache {
  static final AppCache _instance = AppCache._internal();
  factory AppCache() => _instance;
  AppCache._internal();

  final Map<String, dynamic> _cache = {};

  void set(String key, dynamic value) {
    _cache[key] = value;
  }

  T? get<T>(String key) {
    return _cache[key] as T?;
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  /// Remove all cache entries for a given type except for today
  void clearOldCacheForType(String type, String todayDate) {
    final keysToRemove = _cache.keys
        .where((k) => k.startsWith(type) && !k.endsWith(todayDate))
        .toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }
} 