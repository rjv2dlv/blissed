import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/gradient_button.dart';
import '../utils/app_colors.dart';
import '../widgets/background_image.dart';
import '../widgets/gradient_header.dart';
import '../widgets/euphoric_card.dart';
import '../utils/notification_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  List<TimeOfDay> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderStrings = prefs.getStringList('reminders') ?? [];
    setState(() {
      _reminders = reminderStrings.map((s) {
        final parts = s.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
      // Sort reminders by time (hour first, then minute)
      _reminders.sort((a, b) => a.hour != b.hour ? a.hour - b.hour : a.minute - b.minute);
      _isLoading = false;
    });
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderStrings = _reminders.map((t) => '${t.hour}:${t.minute}').toList();
    await prefs.setStringList('reminders', reminderStrings);
    // Cancel all previous notifications and reschedule
    await NotificationService.cancelAllReminders();
    for (final t in _reminders) {
      await NotificationService.scheduleDailyReflectionReminder(t);
      await NotificationService.scheduleDailyActionsReminder(t);
    }
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
      _saveReminders();
    }
  }

  void _removeReminder(int index) async {
    setState(() {
      _reminders.removeAt(index);
    });
    _saveReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 4,
        title: Text(
          'Reminders',
          style: GoogleFonts.nunito(
            color: Colors.white,
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
                    // Gradient header card
                    GradientHeader(
                      icon: Icons.alarm,
                      title: 'Set daily reminders to reflect and take action!',
                      iconColor: AppColors.accentYellow,
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
                                  borderColor: AppColors.teal,
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