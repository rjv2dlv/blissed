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
import 'dart:math';


class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
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

  // Today's stats
  int _todayStreak = 0;
  int _todayActions = 0;
  int _todayActionsCompleted = 0;
  int _todayGratitude = 0;
  int _todayReflections = 0;
  bool _todayBestMoment = false;
  int _todayPoints = 0;

  // Week stats
  int _weekStreak = 0;
  int _weekActions = 0;
  int _weekActionsCompleted = 0;
  int _weekGratitude = 0;
  int _weekReflections = 0;
  int _weekBestMoments = 0;
  bool _weekStatsLoading = true;

  // Month stats
  int _monthStreak = 0;
  int _monthActions = 0;
  int _monthGratitude = 0;
  int _monthReflections = 0;
  int _monthBestMoments = 0;
  bool _monthStatsLoading = true;

  // Blue color palette (shared)
  static const Color blueMain = Color(0xFF00B4FF);
  static const Color blueLight = Color(0xFFB3E5FC);
  static const Color blueDark = Color(0xFF1976D2);
  static const Color blueGrey = Color(0xFF263238);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProgressData();
    _loadTodayStats();
    _loadWeekStats();
    _loadMonthStats();
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

  Future<void> _loadTodayStats() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey = '${now.year}_${now.month}_${now.day}';

    // Streak (current streak)
    _todayStreak = AppDateUtils.calculateCurrentStreak(prefs);

    // Actions
    final actionsKey = 'daily_actions_$dateKey';
    final actionsData = prefs.getString(actionsKey);
    if (actionsData != null) {
      final actions = List<Map<String, dynamic>>.from(json.decode(actionsData));
      _todayActions = actions.length;
      _todayActionsCompleted = actions.where((a) => a['status'] == 'completed').length;
    } else {
      _todayActions = 0;
      _todayActionsCompleted = 0;
    }

    // Gratitude
    final gratitudeKey = 'gratitude_$dateKey';
    final gratitudeData = prefs.getString(gratitudeKey);
    if (gratitudeData != null) {
      final gratitudeList = List<String>.from(json.decode(gratitudeData));
      _todayGratitude = gratitudeList.length;
    } else {
      _todayGratitude = 0;
    }

    // Reflections
    final reflectionKey = 'self_reflection_$dateKey';
    final reflectionData = prefs.getStringList(reflectionKey);
    if (reflectionData != null && reflectionData.length == 4) {
      _todayReflections = 1;
    } else {
      _todayReflections = 0;
    }

    // Best Moment
    final bestMomentKey = 'best_moment_$dateKey';
    final bestMoment = prefs.getString(bestMomentKey);
    _todayBestMoment = bestMoment != null && bestMoment.trim().isNotEmpty;

    // Points
    final pointsMap = await PointsUtils.getPointsMap();
    _todayPoints = pointsMap[dateKey] ?? 0;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadWeekStats() async {
    final now = DateTime.now();
    // Start week from Sunday
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7)); // Sunday
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    int weekStreak = 0;
    int weekActions = 0;
    int weekActionsCompleted = 0;
    int weekGratitude = 0;
    int weekReflections = 0;
    int weekBestMoments = 0;
    final prefs = await SharedPreferences.getInstance();
    for (final date in weekDays) {
      final dateKey = AppDateUtils.getDateKey(date);
      final hasReflection = prefs.getStringList('self_reflection_$dateKey') != null;
      final actionsData = prefs.getString('daily_actions_$dateKey');
      final actions = actionsData != null ? List<Map<String, dynamic>>.from(json.decode(actionsData)) : [];
      final hasActions = actions.isNotEmpty;
      final completedActions = actions.where((a) => a['status'] == 'completed').length;
      final gratitudeData = prefs.getString('gratitude_$dateKey');
      final hasGratitude = gratitudeData != null && List<String>.from(json.decode(gratitudeData)).isNotEmpty;
      final bestMoment = prefs.getString('best_moment_$dateKey');
      final hasBestMoment = bestMoment != null && bestMoment.trim().isNotEmpty;
      if (hasReflection || hasActions || hasGratitude || hasBestMoment) weekStreak++;
      if (hasActions) weekActions += actions.length;
      weekActionsCompleted += completedActions;
      if (hasGratitude) weekGratitude += List<String>.from(json.decode(gratitudeData!)).length;
      if (hasReflection) weekReflections++;
      if (hasBestMoment) weekBestMoments++;
    }
    setState(() {
      _weekStreak = weekStreak;
      _weekActions = weekActions;
      _weekActionsCompleted = weekActionsCompleted;
      _weekGratitude = weekGratitude;
      _weekReflections = weekReflections;
      _weekBestMoments = weekBestMoments;
      _weekStatsLoading = false;
    });
  }

  Future<void> _loadMonthStats() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final monthDays = List.generate(lastDay.day, (i) => DateTime(now.year, now.month, i + 1));
    int monthStreak = 0;
    int monthActions = 0;
    int monthGratitude = 0;
    int monthReflections = 0;
    int monthBestMoments = 0;
    final prefs = await SharedPreferences.getInstance();
    for (final date in monthDays) {
      final dateKey = AppDateUtils.getDateKey(date);
      final hasReflection = prefs.getStringList('self_reflection_$dateKey') != null;
      final actionsData = prefs.getString('daily_actions_$dateKey');
      final hasActions = actionsData != null && List<Map<String, dynamic>>.from(json.decode(actionsData)).isNotEmpty;
      final gratitudeData = prefs.getString('gratitude_$dateKey');
      final hasGratitude = gratitudeData != null && List<String>.from(json.decode(gratitudeData)).isNotEmpty;
      final bestMoment = prefs.getString('best_moment_$dateKey');
      final hasBestMoment = bestMoment != null && bestMoment.trim().isNotEmpty;
      if (hasReflection || hasActions || hasGratitude || hasBestMoment) monthStreak++;
      if (hasActions) {
        final actions = List<Map<String, dynamic>>.from(json.decode(actionsData!));
        final completedCount = actions.where((a) => a['status'] == 'completed').length;
        monthActions += completedCount;
      }
      if (hasGratitude) monthGratitude += List<String>.from(json.decode(gratitudeData!)).length;
      if (hasReflection) monthReflections++;
      if (hasBestMoment) monthBestMoments++;
    }
    setState(() {
      _monthStreak = monthStreak;
      _monthActions = monthActions;
      _monthGratitude = monthGratitude;
      _monthReflections = monthReflections;
      _monthBestMoments = monthBestMoments;
      _monthStatsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDayTab(),
                    _buildWeekTab(),
                    _buildMonthTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(height: 16);
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Color(0xFF00B4FF),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(text: 'Day'),
        Tab(text: 'Week'),
        Tab(text: 'Month'),
      ],
    );
  }

  Widget _buildDayTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildCircularProgressPlaceholder(),
          const SizedBox(height: 16),
          _buildStatCardsPlaceholder(),
          const SizedBox(height: 16),
          _buildLineChartPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildWeekTab() {
    if (_isLoading || _weekStatsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // 1. Bar chart for the current week (Sunday start)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7)); // Sunday
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final weekPoints = weekDays.map((date) => _pointsHistory[AppDateUtils.getDateKey(date)] ?? 0).toList();
    final maxBar = weekPoints.isEmpty ? 1 : weekPoints.reduce((a, b) => a > b ? a : b);
    final todayIndex = weekDays.indexWhere((d) => d.day == now.day && d.month == now.month && d.year == now.year);
    final totalPoints = weekPoints.fold(0, (a, b) => a + b);
    // Average based on days so far in the week (up to today)
    final daysSoFar = todayIndex + 1;
    final avgPoints = daysSoFar > 0 ? (weekPoints.take(daysSoFar).fold(0, (a, b) => a + b) / daysSoFar).round() : 0;

    // 2. Use precomputed week stats (actions = completed only)
    final weekStats = [
      {'value': _weekStreak.toString(), 'label': 'Streak'},
      {'value': _weekActionsCompleted.toString(), 'label': 'Actions'},
      {'value': _weekGratitude.toString(), 'label': 'Gratitude'},
      {'value': _weekReflections.toString(), 'label': 'Reflections'},
      {'value': _weekBestMoments.toString(), 'label': 'Best Moment'},
    ];

    // 3. Line chart for points per week for last 8 weeks
    final weekStartDates = List.generate(8, (i) => startOfWeek.subtract(Duration(days: 7 * (7 - i))));
    final weekTotals = weekStartDates.map((start) {
      int sum = 0;
      for (int d = 0; d < 7; d++) {
        final date = start.add(Duration(days: d));
        sum += _pointsHistory[AppDateUtils.getDateKey(date)] ?? 0;
      }
      return sum;
    }).toList();
    final maxLine = weekTotals.isEmpty ? 1 : weekTotals.reduce((a, b) => a > b ? a : b).toDouble();
    final avgLine = weekTotals.isEmpty ? 0 : weekTotals.reduce((a, b) => a + b) / weekTotals.length;
    final weekLabels = weekStartDates.map((d) => _shortMonthLabel(d)).toList();
    final currentWeekIndex = 7;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Average and total points row (pill style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pillStat(
                  label: 'POINTS',
                  value: totalPoints.toString(),
                  color: blueMain,
                ),
                _pillStat(
                  label: 'AVG',
                  value: avgPoints.toString(),
                  color: blueMain,
                ),
              ],
            ),
          ),
          // Bar chart for week
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxBar < 8 ? 8 : maxBar * 1.2,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= weekDays.length) return const SizedBox.shrink();
                        final isToday = idx == todayIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _weekdayAbbr(weekDays[idx].weekday),
                            style: TextStyle(
                              color: isToday ? blueMain : Colors.white70,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: [
                  for (int i = 0; i < weekPoints.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weekPoints[i].toDouble(),
                          color: i == todayIndex ? blueMain : blueMain.withOpacity(0.7),
                          width: 22,
                          borderRadius: BorderRadius.circular(12),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxBar < 8 ? 8 : maxBar * 1.2,
                            color: blueGrey,
                          ),
                        ),
                      ],
                      showingTooltipIndicators: [],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Stat cards for week
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: weekStats.map((stat) => _statCard(stat['value']!, stat['label']!)).toList(),
              ),
            ),
          ),
          // Line chart for last 8 weeks
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxLine < 8 ? 8 : maxLine * 1.2,
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= weekLabels.length) return const SizedBox.shrink();
                        final isCurrent = idx == currentWeekIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: isCurrent
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: blueMain, width: 2),
                                  ),
                                  child: Text(
                                    weekLabels[idx],
                                    style: TextStyle(
                                      color: blueMain,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : Text(
                                  weekLabels[idx],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < weekTotals.length; i++)
                        FlSpot(i.toDouble(), weekTotals[i].toDouble()),
                    ],
                    isCurved: true,
                    color: blueMain,
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final isCurrent = index == currentWeekIndex;
                        return FlDotCirclePainter(
                          radius: isCurrent ? 7 : 5,
                          color: Colors.white,
                          strokeColor: isCurrent ? blueMain : Colors.white,
                          strokeWidth: isCurrent ? 4 : 2,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          blueMain.withOpacity(0.3),
                          blueMain.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: avgLine.toDouble(),
                      color: blueLight,
                      strokeWidth: 2,
                      dashArray: [6, 6],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthTab() {
    if (_isLoading || _monthStatsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final monthDays = List.generate(lastDay.day, (i) => DateTime(now.year, now.month, i + 1));
    final firstWeekday = firstDay.weekday % 7; // 0=Sun, 1=Mon, ...
    final totalCells = ((firstWeekday + lastDay.day) / 7).ceil() * 7;
    final calendarCells = List.generate(totalCells, (i) {
      final dayNum = i - firstWeekday + 1;
      if (i < firstWeekday || dayNum > lastDay.day) return null;
      return monthDays[dayNum - 1];
    });
    // For best moment days
    final prefs = SharedPreferences.getInstance();
    // Stat cards for month
    final monthStats = [
      {'value': _monthStreak.toString(), 'label': 'Streak'},
      {'value': _monthActions.toString(), 'label': 'Actions'},
      {'value': _monthGratitude.toString(), 'label': 'Gratitude'},
      {'value': _monthReflections.toString(), 'label': 'Reflections'},
      {'value': _monthBestMoments.toString(), 'label': 'Best Moment'},
    ];
    // Points and average for the month
    final monthPoints = monthDays.fold(0, (sum, date) => sum + (_pointsHistory[AppDateUtils.getDateKey(date)] ?? 0));
    final today = DateTime.now();
    final daysSoFar = today.month == now.month && today.year == now.year ? today.day : lastDay.day;
    final monthAvg = daysSoFar > 0 ? (monthPoints / daysSoFar).round() : 0;
    // Line chart for last 6 months, 2 points per month (1st-15th, 16th-end)
    final monthStartDates = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - 5 + i, 1);
      return date;
    });
    final List<int> halfMonthTotals = [];
    final List<String> halfMonthLabels = [];
    for (final start in monthStartDates) {
      final daysInMonth = DateTime(start.year, start.month + 1, 0).day;
      // 1st half
      int sum1 = 0;
      for (int d = 0; d < 15 && d < daysInMonth; d++) {
        final date = DateTime(start.year, start.month, d + 1);
        sum1 += _pointsHistory[AppDateUtils.getDateKey(date)] ?? 0;
      }
      halfMonthTotals.add(sum1);
      halfMonthLabels.add(_shortMonthLabel(start));
      // 2nd half
      int sum2 = 0;
      for (int d = 15; d < daysInMonth; d++) {
        final date = DateTime(start.year, start.month, d + 1);
        sum2 += _pointsHistory[AppDateUtils.getDateKey(date)] ?? 0;
      }
      halfMonthTotals.add(sum2);
      halfMonthLabels.add('•');
    }
    final maxLine = halfMonthTotals.isEmpty ? 1 : halfMonthTotals.reduce((a, b) => a > b ? a : b).toDouble();
    final avgLine = halfMonthTotals.isEmpty ? 0 : halfMonthTotals.reduce((a, b) => a + b) / halfMonthTotals.length;
    final currentMonthIndex = 11; // last point is current half-month

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Points and Avg pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pillStat(
                  label: 'POINTS',
                  value: monthPoints.toString(),
                  color: blueMain,
                ),
                _pillStat(
                  label: 'AVG',
                  value: monthAvg.toString(),
                  color: blueMain,
                ),
              ],
            ),
          ),
          // Calendar grid
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('S', style: TextStyle(color: Colors.white54)),
                    Text('M', style: TextStyle(color: Colors.white54)),
                    Text('T', style: TextStyle(color: Colors.white54)),
                    Text('W', style: TextStyle(color: Colors.white54)),
                    Text('T', style: TextStyle(color: Colors.white54)),
                    Text('F', style: TextStyle(color: Colors.white54)),
                    Text('S', style: TextStyle(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<SharedPreferences>(
                  future: prefs,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 200);
                    final prefs = snapshot.data!;
                    return Column(
                      children: List.generate((calendarCells.length / 7).ceil(), (row) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (col) {
                            final idx = row * 7 + col;
                            final date = idx < calendarCells.length ? calendarCells[idx] : null;
                            if (date == null) {
                              return Container(width: 32, height: 32);
                            }
                            final dateKey = AppDateUtils.getDateKey(date);
                            final points = _pointsHistory[dateKey] ?? 0;
                            final bestMoment = prefs.getString('best_moment_$dateKey');
                            final hasBestMoment = bestMoment != null && bestMoment.trim().isNotEmpty;
                            final isFilled = points > 0;
                            return Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: isFilled ? blueMain : blueGrey,
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      color: isFilled ? Colors.black : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (hasBestMoment && isFilled)
                                    const Positioned(
                                      bottom: -0.7,
                                      left: 0,
                                      right: 0,
                                      child: Icon(Icons.star, color: Colors.black, size: 9),
                                    ),
                                ],
                              ),
                            );
                          }),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
          // Stat cards for month
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: monthStats.map((stat) => _statCard(stat['value']!, stat['label']!)).toList(),
              ),
            ),
          ),
          // Line chart for last 6 months, 2 points per month
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxLine < 8 ? 8 : maxLine * 1.2,
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= halfMonthLabels.length) return const SizedBox.shrink();
                        final isCurrent = idx == currentMonthIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: isCurrent
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: blueMain, width: 2),
                                  ),
                                  child: Text(
                                    halfMonthLabels[idx],
                                    style: const TextStyle(
                                      color: blueMain,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : Text(
                                  halfMonthLabels[idx],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < halfMonthTotals.length; i++)
                        FlSpot(i.toDouble(), halfMonthTotals[i].toDouble()),
                    ],
                    isCurved: true,
                    color: blueMain,
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final isCurrent = index == currentMonthIndex;
                        return FlDotCirclePainter(
                          radius: isCurrent ? 7 : 5,
                          color: Colors.white,
                          strokeColor: isCurrent ? blueMain : Colors.white,
                          strokeWidth: isCurrent ? 4 : 2,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          blueMain.withOpacity(0.3),
                          blueMain.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: avgLine.toDouble(),
                      color: blueLight,
                      strokeWidth: 2,
                      dashArray: [6, 6],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgressPlaceholder() {
    final int pointsToday = _todayPoints;
    final int pointsGoal = 12; // Max value for full circle
    final double progress = (pointsToday / pointsGoal).clamp(0.0, 1.0);
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _RoundedCircularProgressPainter(
              progress: progress,
              backgroundColor: blueGrey,
              progressColor: blueMain,
              strokeWidth: 14,
            ),
          ),
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Today', style: TextStyle(color: blueMain, fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    pointsToday.toString(),
                    style: const TextStyle(color: blueMain, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  const Text('points', style: TextStyle(color: blueLight, fontSize: 17)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartPlaceholder() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text('Bar Chart Placeholder', style: TextStyle(color: Colors.white54)),
      ),
    );
  }

  Widget _buildCalendarGridPlaceholder() {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text('Calendar Grid Placeholder', style: TextStyle(color: Colors.white54)),
      ),
    );
  }

  Widget _buildStatCardsPlaceholder() {
    final todayStats = [
      {'value': _todayStreak.toString(), 'label': 'Streak'},
      {'value': _todayActionsCompleted.toString(), 'label': 'Actions'},
      {'value': _todayGratitude.toString(), 'label': 'Gratitude'},
      {'value': _todayReflections.toString(), 'label': 'Reflections'},
      {'value': _todayBestMoment ? 'Yes' : 'No', 'label': 'Best Moment'},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: todayStats.map((stat) => _statCard(stat['value']!, stat['label']!)).toList(),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      width: 120,
      constraints: const BoxConstraints(minHeight: 75),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLineChartPlaceholder() {
    // Get last 7 days' points
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final points = days.map((date) => _pointsHistory[AppDateUtils.getDateKey(date)] ?? 0).toList();
    final maxPoints = points.isEmpty ? 1 : points.reduce((a, b) => a > b ? a : b).toDouble();
    final avgPoints = points.isEmpty ? 0 : points.reduce((a, b) => a + b) / points.length;
    final weekLabels = days.map((d) => _weekdayAbbr(d.weekday)).toList();
    final todayIndex = days.indexWhere((d) => d.day == now.day && d.month == now.month && d.year == now.year);

    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxPoints < 8 ? 8 : maxPoints * 1.2,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= weekLabels.length) return const SizedBox.shrink();
                  final isToday = idx == todayIndex;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: isToday
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: blueMain, width: 2),
                            ),
                            child: Text(
                              weekLabels[idx],
                              style: const TextStyle(
                                color: blueMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : Text(
                            weekLabels[idx],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                  );
                },
                interval: 1,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].toDouble()),
              ],
              isCurved: true,
              color: blueMain,
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  final isCurrent = index == todayIndex;
                  return FlDotCirclePainter(
                    radius: isCurrent ? 7 : 5,
                    color: Colors.white,
                    strokeColor: isCurrent ? blueMain : Colors.white,
                    strokeWidth: isCurrent ? 4 : 2,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    blueMain.withOpacity(0.3),
                    blueMain.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: avgPoints.toDouble(),
                color: blueLight,
                strokeWidth: 2,
                dashArray: [6, 6],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayAbbr(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[(weekday % 7)];
  }

  String _shortMonthLabel(DateTime date) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[date.month - 1];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  Widget _pillStat({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 17)),
        ],
      ),
    );
  }
}

// Custom painter for rounded circular progress
class _RoundedCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _RoundedCircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    // Draw background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress arc with rounded ends
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 