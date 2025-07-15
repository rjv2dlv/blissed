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
import '../shared/text_styles.dart';

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
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GradientHeader(
                        icon: Icons.favorite_border,
                        title: 'What are you grateful for today?',
                        iconColor: Colors.white,
                        iconSize: 24,
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
                                'What are you grateful for today?',
                                style: AppTextStyles.question.copyWith(color: Color(0xFF00B4FF)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reflect on the people, experiences, or things that bring you joy and appreciation.',
                                style: AppTextStyles.description,
                              ),
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _gratitudeController,
                                    minLines: 2,
                                    maxLines: 5,
                                    textAlignVertical: TextAlignVertical.top,
                                    decoration: InputDecoration(
                                      hintText: 'Enter gratitude...',
                                      hintStyle: AppTextStyles.description.copyWith(color: AppColors.textPrimary.withOpacity(0.5)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Color(0xFF00B4FF).withOpacity(0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Color(0xFF00B4FF), width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.8),
                                    ),
                                    style: AppTextStyles.answer,
                                    onSubmitted: (_) => _addGratitude(),
                                  ),
                                  const SizedBox(height: 14),
                                  GradientButton(
                                    onPressed: _addGratitude,
                                    text: 'Add',
                                    height: 48,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _gratitudes.isEmpty
                          ? Center(child: Text('No gratitudes added yet.', style: AppTextStyles.answer))
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _gratitudes.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final gratitude = _gratitudes[index];
                                return EuphoricCard(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Text(
                                      gratitude,
                                      style: AppTextStyles.answer,
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 