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
import '../utils/api_client.dart';
import '../utils/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../utils/app_cache.dart';

class GratitudeScreen extends StatefulWidget {
  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> {
  List<String> _gratitudes = [];
  final TextEditingController _gratitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGratitudes();
  }

  Future<void> _loadGratitudes() async {
    final userId = await getOrCreateUserId();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cache = AppCache();
    // Clear old cache for gratitudes
    cache.clearOldCacheForType('gratitude_', today);
    final cacheKey = 'gratitude_$today';
    // Try cache first
    final cached = cache.get<List<String>>(cacheKey);
    if (cached != null) {
      setState(() {
        _gratitudes = List<String>.from(cached);
      });
      print('got the gratitudes from the cache.');
      return;
    }
    // Otherwise, fetch from backend
    final gratitudes = await ApiClient.getGratitudes(userId, today);
    if (gratitudes != null) {
      cache.set(cacheKey, gratitudes);
      setState(() {
        _gratitudes = List<String>.from(gratitudes);
      });
    } else {
      setState(() {
        _gratitudes = [];
      });
    }
  }

  Future<void> _addGratitude() async {
    final text = _gratitudeController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _gratitudes.add(text);
        _gratitudeController.clear();
      });
      final userId = await getOrCreateUserId();
      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(now);
      print('Current: $_gratitudes');
      await ApiClient.putGratitudes(userId, date, _gratitudes);
      // Update cache
      final cache = AppCache();
      final cacheKey = 'gratitude_$date';
      cache.set(cacheKey, _gratitudes);
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
                                    text: 'Add Gratitude',
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
                                    child: Text(gratitude, style: AppTextStyles.answer),
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