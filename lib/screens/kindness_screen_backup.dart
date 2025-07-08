import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../shared/gradient_button.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/background_image.dart';
import '../widgets/gradient_header.dart';
import '../widgets/euphoric_card.dart';
import '../utils/points_utils.dart';

class KindnessScreen extends StatefulWidget {
  @override
  State<KindnessScreen> createState() => _KindnessScreenState();
}

class _KindnessScreenState extends State<KindnessScreen> {
  String? _currentKindness;
  String? _selectedStatus;
  String? _lastLoadedDate;
  final Random _random = Random();
  final TextEditingController _customKindnessController = TextEditingController();
  bool _showCustomInput = false;

  final List<String> _kindnessActs = [
    'Send a heartfelt message to someone you haven\'t talked to in a while',
    'Buy coffee for the person behind you in line',
    // ... (rest of the kindness acts)
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayKindness();
  }

  String get _todayKey {
    final now = DateTime.now();
    return 'kindness_{AppDateUtils.getDateKey(now)}';
  }

  Future<void> _loadTodayKindness() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD format
    
    // Check if we're loading data for a new day
    if (_lastLoadedDate != null && _lastLoadedDate != currentDate) {
      // New day - reset everything
      setState(() {
        _currentKindness = null;
        _selectedStatus = null;
      });
      _lastLoadedDate = currentDate;
      return;
    }
    
    final kindnessData = prefs.getString(_todayKey);
    if (kindnessData != null) {
      final data = json.decode(kindnessData);
      setState(() {
        _currentKindness = data['kindness'];
        _selectedStatus = data['status'];
      });
    }
    _lastLoadedDate = currentDate;
  }

  // ... rest of the KindnessScreen code ...
} 