import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/gradient_button.dart';
import '../utils/app_colors.dart';
import '../widgets/background_image.dart';
import '../widgets/gradient_header.dart';
import '../widgets/euphoric_card.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/api_client.dart';
import '../utils/app_cache.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class ReminderSettingsScreen extends StatefulWidget {
  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  List<TimeOfDay> _reminders = [];
  bool _isLoading = true;
  final AppCache _cache = AppCache();

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    // Try to load from cache first
    final cachedReminders = _cache.get<List<String>>('reminders');
    if (cachedReminders != null && cachedReminders.isNotEmpty) {
      print('Loading reminders from cache: $cachedReminders');
      setState(() {
        _reminders = cachedReminders.map((s) {
          final parts = s.split(':');
          return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }).toList();
        _reminders.sort((a, b) => a.hour != b.hour ? a.hour - b.hour : a.minute - b.minute);
        _isLoading = false;
      });
    } else {
      // No cache or SharedPreferences, fetch from backend
      print('No local reminders found, fetching from backend...');
      
      // Clear any existing cache to ensure fresh data
      _cache.remove('reminders');
      
      try {
        final userId = await ApiClient.getOrCreateUserId();
        final userProfile = await ApiClient.getUserProfile(userId);
        
        if (userProfile != null && userProfile['reminder_times'] != null) {
          final backendReminders = List<String>.from(userProfile['reminder_times']);
          if (backendReminders.isNotEmpty) {
            // Update cache with backend data
            _cache.set('reminders', backendReminders);
            
            setState(() {
              _reminders = backendReminders.map((s) {
                final parts = s.split(':');
                if (parts.length != 2) {
                  print('Invalid time format: $s');
                  return const TimeOfDay(hour: 8, minute: 0); // fallback
                }
                final hour = int.tryParse(parts[0]) ?? 8;
                final minute = int.tryParse(parts[1]) ?? 0;
                return TimeOfDay(hour: hour, minute: minute);
              }).toList();
              _reminders.sort((a, b) => a.hour != b.hour ? a.hour - b.hour : a.minute - b.minute);
              _isLoading = false;
            });
          } else {
            print('Backend returned empty reminders, using defaults');
            // Backend returned empty, use defaults
            _setDefaultReminders();
          }
        } else {
          print('No user profile or no reminder_times field, using defaults');
          // No user profile or no reminders, use defaults
          _setDefaultReminders();
        }
      } catch (e) {
        print('Error fetching reminders from backend: $e');
        // Fallback to defaults on error
        _setDefaultReminders();
      }
    }
  }

  void _setDefaultReminders() {
    setState(() {
      _reminders = [
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 17, minute: 0),
      ];
      _isLoading = false;
    });
    // Save defaults to cache and backend
    _saveReminders();
  }

  Future<void> _saveReminders() async {
    final reminderStrings = _reminders.map((t) => 
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
    ).toList();
    
    // Update cache first
    _cache.set('reminders', reminderStrings);
    
    // Update user profile in backend (Lambda will handle notifications)
    final userId = await ApiClient.getOrCreateUserId();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final timeZone = await FlutterNativeTimezone.getLocalTimezone();
    await ApiClient.updateUserProfile(userId, fcmToken ?? '', reminderStrings, timeZone);
  }

  Future<void> _addReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && !_reminders.contains(picked)) {
      setState(() {
        _reminders.add(picked);
        _reminders.sort((a, b) => a.hour != b.hour ? a.hour - b.hour : a.minute - b.minute);
      });
      await _saveReminders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder added at ${picked.format(context)}')),
      );
    }
  }

  void _removeReminder(int index) async {
    setState(() {
      _reminders.removeAt(index);
    });
    await _saveReminders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder Removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Color(0xFF23272F),
        elevation: 4,
        title: Text(
          'Reminders',
          style: GoogleFonts.nunito(
            color: Color(0xFF00B4FF),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: BackgroundImage(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GradientHeader(
                      icon: Icons.alarm,
                      title: 'Set daily reminders to reflect and take action!',
                      iconColor: Colors.white,
                      iconSize: 28,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _reminders.isEmpty
                          ? Center(
                              child: Text(
                                'No reminders set yet.',
                                style: GoogleFonts.nunito(fontSize: 16, color: AppColors.primaryBlue),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _reminders.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final t = _reminders[index];
                                return EuphoricCardWithBorder(
                                  borderColor: Color(0xFF00B4FF),
                                  child: ListTile(
                                    leading: Icon(Icons.alarm, color: AppColors.primaryBlue),
                                    title: Text(
                                      t.format(context),
                                      style: GoogleFonts.nunito(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete, color: AppColors.error),
                                      onPressed: () => _removeReminder(index),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: GradientButton(
                        onPressed: _addReminder,
                        text: 'Add Reminder',
                        height: 50,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
} 