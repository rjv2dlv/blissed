import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/background_image.dart';
import '../widgets/gradient_header.dart';
import '../widgets/euphoric_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/swipeable_card_section.dart';

class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentReflections = [];
  List<Map<String, dynamic>> _recentActions = [];
  List<Map<String, dynamic>> _recentGratitude = [];
  List<Map<String, dynamic>> _recentBestMoments = [];
  bool _isLoading = true;
  Map<String, int> _contributionMap = {};
  int _totalActionsTaken = 0;
  int _totalGratitude = 0;
  int _totalBestMoments = 0;
  final ScrollController _gridScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final recentReflections = [];
    final recentActions = [];
    final recentGratitude = [];
    final recentBestMoments = [];
    final contributionMap = <String, int>{};
    int totalReflections = 0;
    int totalActions = 0;
    int totalGratitude = 0;
    int completedActions = 0;
    int totalActionsTaken = 0;
    int totalBestMoments = 0;

    // Last 6 months (about 26 weeks)
    for (int i = 0; i < 26 * 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = AppDateUtils.getDateKey(date);
      int activityCount = 0;

      // Reflections
      final reflectionKey = 'self_reflection_$dateKey';
      final reflectionData = prefs.getStringList(reflectionKey);
      if (reflectionData != null && reflectionData.length == 4) {
        totalReflections++;
        activityCount++;
        if (i < 21) {
          recentReflections.add({
            'date': date,
            'answers': reflectionData,
          });
        }
      }

      // Actions
      final actionsKey = 'daily_actions_$dateKey';
      final actionsData = prefs.getString(actionsKey);
      if (actionsData != null) {
        final actions = List<Map<String, dynamic>>.from(json.decode(actionsData));
        if (actions.isNotEmpty) {
          totalActions++;
          final completedCount = actions.where((a) => a['status'] == 'completed').length;
          completedActions += completedCount;
          totalActionsTaken += actions.length;
          activityCount += actions.length;
          if (i < 21) {
            recentActions.add({
              'date': date,
              'actions': actions,
              'completed': completedCount,
              'total': actions.length,
            });
          }
        }
      }

      // Gratitude
      final gratitudeKey = 'gratitude_$dateKey';
      final gratitudeData = prefs.getString(gratitudeKey);
      if (gratitudeData != null) {
        final gratitudeList = List<String>.from(json.decode(gratitudeData));
        if (gratitudeList.isNotEmpty) {
          totalGratitude += gratitudeList.length;
          activityCount += gratitudeList.length;
          if (i < 21) {
            recentGratitude.add({
              'date': date,
              'gratitude': gratitudeList,
            });
          }
        }
      }

      // Best Moment
      final bestMomentKey = 'best_moment_$dateKey';
      final bestMoment = prefs.getString(bestMomentKey);
      if (bestMoment != null && bestMoment.trim().isNotEmpty) {
        totalBestMoments++;
        activityCount++;
        if (i < 21) {
          recentBestMoments.add({
            'date': date,
            'moment': bestMoment,
          });
        }
      }
      contributionMap[dateKey] = activityCount;
    }

    setState(() {
      _stats = {
        'totalReflections': totalReflections,
        'totalActions': totalActions,
        'totalGratitude': totalGratitude,
        'completedActions': completedActions,
        'streakDays': AppDateUtils.calculateStreak(prefs),
        'currentStreak': AppDateUtils.calculateCurrentStreak(prefs),
      };
      _recentReflections = List<Map<String, dynamic>>.from(recentReflections);
      _recentActions = List<Map<String, dynamic>>.from(recentActions);
      _recentGratitude = List<Map<String, dynamic>>.from(recentGratitude);
      _recentBestMoments = List<Map<String, dynamic>>.from(recentBestMoments);
      _contributionMap = contributionMap;
      _totalActionsTaken = totalActionsTaken;
      _totalGratitude = totalGratitude;
      _totalBestMoments = totalBestMoments;
      _isLoading = false;
    });

    // Schedule a scroll to today after the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gridScrollController.hasClients) {
        _gridScrollController.animateTo(
          _gridScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BackgroundImage(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : DefaultTabController(
                length: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    GradientHeader(
                      icon: Icons.history,
                      title: 'Reflect on Your Achievements',
                      iconColor: AppColors.accentYellow,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TabBar(
                          labelColor: AppColors.primaryBlue,
                          unselectedLabelColor: AppColors.primaryBlue.withOpacity(0.5),
                          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                          indicator: BoxDecoration(
                            color: AppColors.accentYellow.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          indicatorWeight: 0,
                          tabs: const [
                            Tab(text: 'Reflections', icon: Icon(Icons.auto_awesome)),
                            Tab(text: 'Actions', icon: Icon(Icons.check_circle)),
                            Tab(text: 'Best Moments', icon: Icon(Icons.star)),
                            Tab(text: 'Gratitude', icon: Icon(Icons.favorite)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Reflections Tab
                          _recentReflections.isNotEmpty
                              ? ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
                                  itemCount: _recentReflections.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, idx) {
                                    final reflection = _recentReflections[idx];
                                    return EuphoricCardWithBorder(
                                      borderColor: AppColors.primaryBlue,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(AppDateUtils.formatDate(reflection['date']), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            ...List.generate(reflection['answers'].length, (i) => Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Text(reflection['answers'][i], style: GoogleFonts.nunito(fontSize: 14)),
                                            )),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(child: Text('No reflections yet.', style: GoogleFonts.nunito())),
                          // Actions Tab
                          _recentActions.isNotEmpty
                              ? ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
                                  itemCount: _recentActions.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, idx) {
                                    final action = _recentActions[idx];
                                    return EuphoricCardWithBorder(
                                      borderColor: AppColors.success,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(AppDateUtils.formatDate(action['date']), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                                                Text('${action['completed']}/${action['total']}', style: GoogleFonts.nunito(color: AppColors.success)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ...List.generate(action['actions'].length, (i) {
                                              final a = action['actions'][i];
                                              IconData statusIcon;
                                              Color statusColor;
                                              String statusText;
                                              switch (a['status']) {
                                                case 'completed':
                                                  statusIcon = Icons.check_circle;
                                                  statusColor = AppColors.success;
                                                  statusText = 'Completed';
                                                  break;
                                                case 'rejected':
                                                  statusIcon = Icons.cancel;
                                                  statusColor = AppColors.error;
                                                  statusText = 'Rejected';
                                                  break;
                                                default:
                                                  statusIcon = Icons.access_time;
                                                  statusColor = Colors.grey;
                                                  statusText = 'Incomplete';
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(statusIcon, color: statusColor, size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(a['text'], style: GoogleFonts.nunito(fontSize: 14))),
                                                    Text(statusText, style: GoogleFonts.nunito(fontSize: 12, color: statusColor)),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(child: Text('No actions yet.', style: GoogleFonts.nunito())),
                          // Best Moments Tab
                          _recentBestMoments.isNotEmpty
                              ? ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
                                  itemCount: _recentBestMoments.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, idx) {
                                    final moment = _recentBestMoments[idx];
                                    return EuphoricCardWithBorder(
                                      borderColor: AppColors.accentYellow,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(AppDateUtils.formatDate(moment['date']), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            Text(moment['moment'] ?? '', style: GoogleFonts.nunito(fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(child: Text('No best moments yet.', style: GoogleFonts.nunito())),
                          // Gratitude Tab
                          _recentGratitude.isNotEmpty
                              ? ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
                                  itemCount: _recentGratitude.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, idx) {
                                    final gratitude = _recentGratitude[idx];
                                    return EuphoricCardWithBorder(
                                      borderColor: AppColors.teal,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(AppDateUtils.formatDate(gratitude['date']), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            ...List.generate(gratitude['gratitude'].length, (i) => Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Text(gratitude['gratitude'][i], style: GoogleFonts.nunito(fontSize: 14)),
                                            )),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(child: Text('No gratitude entries yet.', style: GoogleFonts.nunito())),
                        ],
                      ),
                    ),
                    if (_recentReflections.isEmpty && _recentActions.isEmpty && _recentGratitude.isEmpty && _recentBestMoments.isEmpty)
                      Expanded(child: _buildEmptyState()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EuphoricCardWithBorder(
      borderColor: AppColors.primaryBlue,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.primaryBlue.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No History Yet',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your euphoric journey by completing reflections, actions, and acts of gratitude!',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: AppColors.primaryBlue.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  String _weekdayAbbr(int weekday) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[weekday];
  }

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }
}