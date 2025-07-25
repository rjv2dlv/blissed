import 'package:flutter/material.dart';
import 'dart:convert';
import '../shared/gradient_button.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/background_image.dart';
import '../widgets/gradient_header.dart';
import '../widgets/euphoric_card.dart';
import '../utils/points_utils.dart';
import '../shared/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/api_client.dart';
import '../utils/app_cache.dart';
import '../utils/progress_utils.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';


class DailyActionsScreen extends StatefulWidget {
  @override
  State<DailyActionsScreen> createState() => _DailyActionsScreenState();
}

class _DailyActionsScreenState extends State<DailyActionsScreen> {
  final TextEditingController _actionController = TextEditingController();
  final List<Map<String, dynamic>> _actions = [];
  String? _lastLoadedDate;
  final Set<int> _fadingIndexes = {}; // Track which indexes are fading
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  String get _todayKey {
    final now = DateTime.now();
    return 'daily_actions_${AppDateUtils.getDateKey(now)}';
  }

  Future<void> _loadActions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final cache = AppCache();
      final cacheKey = 'actions_$today';
      cache.clearOldCacheForType('actions_', today);
      print('date: $today, cache key: $cacheKey');
      final cached = cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        print('returning from cache: $cached');
        setState(() {
          _actions.clear();
          _actions.addAll(List<Map<String, dynamic>>.from(cached));
          // If you have controllers for each action, update them here as well
          // Example: for (int i = 0; i < _actions.length; i++) { _controllers[i].text = _actions[i]['text']; }
        });
        return;
      }
      // Otherwise, fetch from backend
      final userId = await ApiClient.getOrCreateUserId();
      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(now);
      final response = await ApiClient.getActions(userId, date);
      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final actions = (data != null && data['actions'] != null)
            ? (data['actions'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
            : <Map<String, dynamic>>[];
        
        cache.set(cacheKey, actions);
        if (!mounted) return;
        setState(() {
          _actions.clear();
          _actions.addAll(List<Map<String, dynamic>>.from(actions));
          // If you have controllers for each action, update them here as well
          // Example: for (int i = 0; i < _actions.length; i++) { _controllers[i].text = _actions[i]['text']; }
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _actions.clear();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load actions. (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading actions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveActions() async {
    // Only save to backend
    final userId = await ApiClient.getOrCreateUserId();
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    await ApiClient.putActions(userId, date, _actions);

    final cache = AppCache();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cacheKey = 'actions_$today';
    cache.set(cacheKey, _actions);
    // Invalidate progress cache
    cache.remove('progress_$today');
  }

  void _addAction() {
    final text = _actionController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _actions.add({'text': text, 'status': 'pending'});
        _actionController.clear();
      });
      _saveActions();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action Added')),
      );
    }
  }

  void _markAction(int index, String status) {
    setState(() {
      _fadingIndexes.add(index);
    });
    Future.delayed(const Duration(milliseconds: 250), () async {
      setState(() {
        _actions[index]['status'] = status;
        _fadingIndexes.remove(index);
      });
      _saveActions();
      print('saved action. $status');
      if (status == 'completed') {
        await PointsUtils.incrementToday();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action Marked Completed')),
        );
        await ProgressUtils.addActionCompleted();
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action Marked Rejected')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedActions = List<Map<String, dynamic>>.from(_actions)
      ..sort((a, b) {
        if (a['status'] == b['status']) return 0;
        if (a['status'] == 'pending') return -1;
        if (b['status'] == 'pending') return 1;
        return 0;
      });
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: BackgroundImage(
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
                        // Modern blue pill banner
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF00B4FF), Color(0xFF1976D2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Plan and conquer your day with purposeful actions!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                  'Add your actions for today:',
                                  style: AppTextStyles.question.copyWith(color: Color(0xFF00B4FF)),
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _actionController,
                                      minLines: 1,
                                      maxLines: 4,
                                      textAlignVertical: TextAlignVertical.top,
                                      decoration: InputDecoration(
                                        hintText: 'Enter an action...',
                                        hintStyle: AppTextStyles.description.copyWith(color: AppColors.textPrimary.withOpacity(0.5)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Color(0xFF00B4FF).withOpacity(0.5)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Color(0xFF00B4FF).withOpacity(0.5)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Color(0xFF00B4FF), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.8),
                                      ),
                                      style: AppTextStyles.answer,
                                      onSubmitted: (_) => _addAction(),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ButtonStyle(
                                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                                          backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                          elevation: MaterialStateProperty.all(0),
                                          shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                          shadowColor: MaterialStateProperty.all(Colors.transparent),
                                        ),
                                        onPressed: _addAction,
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF00B4FF), Color(0xFF1976D2)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            height: 48,
                                            child: Text(
                                              'Add',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        sortedActions.isEmpty
                          ? Center(child: Text('No actions added yet.', style: AppTextStyles.answer))
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: sortedActions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final action = sortedActions[index];
                                final originalIndex = _actions.indexOf(action);
                                Color? borderColor;
                                if (action['status'] == 'completed') {
                                  borderColor = const Color(0xFF00B4FF); // Blueish accent for completed
                                } else if (action['status'] == 'rejected') {
                                  borderColor = Colors.red;
                                }
                                Widget cardContent = Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        action['text'],
                                        style: AppTextStyles.answer.copyWith(
                                          decoration: action['status'] == 'completed'
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: action['status'] == 'rejected'
                                              ? Colors.red
                                              : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    if (action['status'] == 'pending')
                                      Row(
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(20),
                                            onTap: () => _markAction(originalIndex, 'completed'),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Color(0xFF00B4FF).withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(Icons.check, color: Color(0xFF00B4FF), size: 22),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(20),
                                            onTap: () => _markAction(originalIndex, 'rejected'),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(Icons.close, color: Colors.red, size: 22),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (action['status'] == 'completed')
                                      const Icon(Icons.check_circle, color: Color(0xFF00B4FF), size: 28),
                                    if (action['status'] == 'rejected')
                                      const Icon(Icons.cancel, color: Colors.red, size: 28),
                                  ],
                                );
                                if (borderColor != null && action['status'] != 'pending') {
                                  return EuphoricCardWithBorder(
                                    borderColor: borderColor,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: cardContent,
                                    ),
                                  );
                                } else {
                                  return EuphoricCard(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: cardContent,
                                    ),
                                  );
                                }
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
      ),
    );
  }

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }
} 