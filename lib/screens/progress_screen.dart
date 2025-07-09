import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../utils/points_utils.dart';
import '../widgets/background_image.dart';
import '../widgets/gradient_header.dart';
import '../widgets/euphoric_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/swipeable_card_section.dart';
import 'package:fl_chart/fl_chart.dart';


class ProgressScreen extends StatefulWidget {
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentReflections = [];
  List<Map<String, dynamic>> _recentActions = [];
  List<Map<String, dynamic>> _recentGratitude = [];
  List<Map<String, dynamic>> _recentBestMoments = [];
  bool _isLoading = true;
  Map<String, int> _contributionMap = {};
  Map<String, int> _pointsHistory = {};
  int _totalActionsTaken = 0;
  int _totalGratitude = 0;
  int _totalBestMoments = 0;
  final ScrollController _gridScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
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

    // Load points history
    final pointsHistory = await PointsUtils.getLast30DaysPoints();

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
        'totalDays': totalReflections + totalGratitude,
      };
      _recentReflections = List<Map<String, dynamic>>.from(recentReflections);
      _recentActions = List<Map<String, dynamic>>.from(recentActions);
      _recentGratitude = List<Map<String, dynamic>>.from(recentGratitude);
      _recentBestMoments = List<Map<String, dynamic>>.from(recentBestMoments);
      _contributionMap = contributionMap;
      _pointsHistory = pointsHistory;
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
    return BackgroundImage(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  GradientHeader(
                    icon: Icons.timeline,
                    title: 'Track your growth and celebrate your wins!',
                    iconColor: AppColors.accentYellow,
                  ),
                  const SizedBox(height: 24),
                  // Stat List (List with Icons)
                  _buildStatisticsSection(),
                  const SizedBox(height: 24),
                  // Points Trend Section
                  _buildPointsTrendSection(),
                  const SizedBox(height: 24),
                  // Recent Reflections
                  if (_recentReflections.isNotEmpty) ...[
                    SwipeableCardSection(
                      title: 'Recent Reflections',
                      icon: Icons.auto_awesome,
                      color: AppColors.primaryBlue,
                      items: _recentReflections,
                      itemBuilder: (context, reflection) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppDateUtils.formatDate(reflection['date']), 
                               style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...List.generate(reflection['answers'].length, (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(reflection['answers'][i], 
                                       style: GoogleFonts.nunito(fontSize: 14)),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Contribution Grid (calendar view) at the end
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _gridScrollController,
                    child: _buildContributionGrid(),
                  ),
                  // Add extra space at the bottom for better scrollability
                  const SizedBox(height: 150),
                ],
              ),
            ),
    );
  }

  Widget _buildPointsTrendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Points Trend (Last 30 Days)',
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.teal,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildImprovedCustomBarChart(),
      ],
    );
  }

  // A. Improved Custom Bar Chart
  Widget _buildImprovedCustomBarChart() {
    final now = DateTime.now();
    final days = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
    final points = days.map((date) => _pointsHistory[AppDateUtils.getDateKey(date)] ?? 0).toList();
    final maxPoints = points.isEmpty ? 1 : points.reduce((a, b) => a > b ? a : b).toDouble();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(30, (index) {
                final point = points[index];
                final height = maxPoints > 0 ? (point / maxPoints) : 0.0;
                final date = days[index];
                return Expanded(
                  child: Tooltip(
                    message: '${_formatShortDate(date)}: $point point${point == 1 ? '' : 's'}',
                    waitDuration: const Duration(milliseconds: 200),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryBlue.withOpacity(0.85),
                            AppColors.teal.withOpacity(0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          if (point > 0)
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.18),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                        ],
                      ),
                      height: height * 90,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatShortDate(days.first)),
              Text(_formatShortDate(days[14])),
              Text(_formatShortDate(days.last)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return "${date.day}/${date.month}";
  }

  Widget _buildContributionGrid() {
    // 26 weeks x 7 days = 182 days
    final now = DateTime.now();
    final days = List.generate(26 * 7, (i) => now.subtract(Duration(days: 26 * 7 - 1 - i)));
    // Group by week (columns)
    final weeks = List.generate(26, (w) => days.skip(w * 7).take(7).toList());
    // Month labels
    final monthLabels = <int, String>{};
    final shownMonths = <String>{};
    for (int w = 0; w < weeks.length; w++) {
      final firstDay = weeks[w].first;
      final monthKey = '${firstDay.year}_${firstDay.month}';
      
      // Show month label only for the first occurrence of each month
      if (!shownMonths.contains(monthKey)) {
        monthLabels[w] = _monthAbbr(firstDay.month);
        shownMonths.add(monthKey);
      }
    }
    // Weekday labels (Mon, Wed, Fri)
    final weekdayLabels = [1, 3, 5]; // Monday, Wednesday, Friday
    
    // Calculate max points for color scaling
    final maxPoints = _pointsHistory.values.isEmpty ? 1 : _pointsHistory.values.reduce((a, b) => a > b ? a : b);
    
    return EuphoricCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 6 Months (Points)', 
               style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month labels
                Row(
                  children: [
                    const SizedBox(width: 28), // space for weekday labels
                    ...List.generate(weeks.length, (w) {
                      final label = monthLabels[w];
                      return Container(
                        width: 20,
                        alignment: Alignment.centerLeft,
                        child: label != null
                            ? Text(label, style: GoogleFonts.nunito(fontSize: 10, color: AppColors.primaryBlue))
                            : const SizedBox.shrink(),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 2),
                // Grid with weekday labels
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weekday labels
                    Column(
                      children: List.generate(7, (d) {
                        if (weekdayLabels.contains(d)) {
                          return Container(
                            height: 15,
                            alignment: Alignment.centerRight,
                            child: Text(_weekdayAbbr(d), style: GoogleFonts.nunito(fontSize: 10, color: AppColors.primaryBlue)),
                          );
                        } else {
                          return SizedBox(height: 15);
                        }
                      }),
                    ),
                    // The grid
                    ...weeks.map((week) => Column(
                      children: List.generate(7, (d) {
                        final date = week[d];
                        final dateKey = AppDateUtils.getDateKey(date);
                        final points = _pointsHistory[dateKey] ?? 0;
                        final now = DateTime.now();
                        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                        
                        // Color based on points: higher points = darker color
                        Color color;
                        if (points == 0) {
                          color = Colors.grey[300]!; // Light grey for no points
                        } else if (points == 1) {
                          color = Colors.green[200]!; // Light green for 1 point
                        } else if (points == 2) {
                          color = Colors.green[400]!; // Medium green for 2 points
                        } else if (points == 3) {
                          color = Colors.green[600]!; // Dark green for 3 points
                        } else {
                          color = Colors.green[800]!; // Darkest green for 4+ points
                        }
                        
                        // Highlight today with yellow border
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('0 pts', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primaryBlue)),
                  const SizedBox(width: 10),
                ],
              ),
              Row(
                children: [
                  Container(width: 13, height: 13, color: const Color(0xFF151b23)),
                  Container(width: 13, height: 13, color: Colors.green[200]),
                  Container(width: 13, height: 13, color: Colors.green[400]),
                  Container(width: 13, height: 13, color: Colors.green[600]),
                  Container(width: 13, height: 13, color: Colors.green[800]),
                  const SizedBox(width: 10),
                ],
              ),
              Text('4+ pts', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primaryBlue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.teal,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildStatRow(Icons.local_fire_department, 'Current Streak', '${_stats['currentStreak']} days', AppColors.warning),
        _buildStatRow(Icons.emoji_events, 'Best Streak', '${_stats['streakDays']} days', AppColors.warning),

        _buildStatRow(Icons.stars, 'Total Points', '${_pointsHistory.values.fold(0, (sum, points) => sum + points)}', Colors.purple),
        _buildStatRow(Icons.list_alt, 'Total Actions Taken', '$_totalActionsTaken', Colors.purple),
        
        _buildStatRow(Icons.calendar_today, 'Total Days', '${_stats['totalDays']} days', AppColors.warning),
        _buildStatRow(Icons.auto_awesome, 'Total Reflections', '${_stats['totalReflections']} days', AppColors.warning),
        
        _buildStatRow(Icons.favorite, 'Total Gratitude Added', '$_totalGratitude', Colors.purple),
        _buildStatRow(Icons.star, 'Total Best Moments', '$_totalBestMoments', Colors.purple),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String title, String value, Color titleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: titleColor, size: 26),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor))),
          Text(value, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor)),
        ],
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