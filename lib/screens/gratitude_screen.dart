import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../shared/gradient_button.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/background_image.dart';
import '../widgets/gradient_header.dart';
import '../widgets/euphoric_card.dart';
import '../utils/points_utils.dart';

class GratitudeScreen extends StatefulWidget {
  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> {
  final TextEditingController _gratitudeController = TextEditingController();
  final List<String> _gratitudes = [];
  String? _lastLoadedDate;

  @override
  void initState() {
    super.initState();
    _loadGratitudes();
  }

  String get _todayKey {
    final now = DateTime.now();
    return 'gratitude_${AppDateUtils.getDateKey(now)}';
  }

  Future<void> _loadGratitudes() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD format
    if (_lastLoadedDate != null && _lastLoadedDate != currentDate) {
      setState(() {
        _gratitudes.clear();
        _gratitudeController.clear();
      });
      _lastLoadedDate = currentDate;
      return;
    }
    final gratitudesString = prefs.getString(_todayKey);
    if (gratitudesString != null) {
      setState(() {
        _gratitudes.clear();
        _gratitudes.addAll(List<String>.from(json.decode(gratitudesString)));
      });
    }
    _lastLoadedDate = currentDate;
  }

  Future<void> _saveGratitudes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayKey, json.encode(_gratitudes));
  }

  void _addGratitude() {
    final text = _gratitudeController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _gratitudes.add(text);
        _gratitudeController.clear();
      });
      _saveGratitudes();
      PointsUtils.incrementToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientHeader(
              icon: Icons.favorite,
              title: 'What are you grateful for today?',
              iconColor: AppColors.accentYellow,
            ),
            const SizedBox(height: 24),
            EuphoricCardWithBorder(
              borderColor: AppColors.primaryBlue,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add something you are grateful for:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _gratitudeController,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Enter gratitude...',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            ),
                            onSubmitted: (_) => _addGratitude(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: GradientButton(
                            onPressed: _addGratitude,
                            text: 'Add',
                            height: 48,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _gratitudes.isEmpty
                  ? Center(child: Text('No gratitudes added yet.'))
                  : ListView.separated(
                      itemCount: _gratitudes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final gratitude = _gratitudes[index];
                        return EuphoricCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Text(
                              gratitude,
                              style: TextStyle(fontSize: 16, color: AppColors.primaryBlue),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 