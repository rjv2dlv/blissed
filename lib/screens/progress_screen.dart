import '../widgets/stat_card.dart';
import '../widgets/swipeable_card_section.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
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
import 'package:intl/intl.dart';


class ProgressScreen extends StatefulWidget {
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  Map<String, int> _pointsHistory = {};
  int _todayPoints = 0;
  int _todayStreak = 0;
  int _todayActions = 0;
  int _todayActionsCompleted = 0;
  int _todayGratitude = 0;
  int _todayReflections = 0;
  bool _todayBestMoment = false;
  int _weekStreak = 0;
  int _weekActions = 0;
  int _weekActionsCompleted = 0;
  int _weekGratitude = 0;
  int _weekReflections = 0;
  int _weekBestMoments = 0;
  bool _weekStatsLoading = true;
  int _monthStreak = 0;
  int _monthActions = 0;
  int _monthGratitude = 0;
  int _monthReflections = 0;
  int _monthBestMoments = 0;
  bool _monthStatsLoading = true;
  final ScrollController _gridScrollController = ScrollController();

  // Blue color palette (shared)
  static const Color blueMain = Color(0xFF00B4FF);
  static const Color blueLight = Color(0xFFB3E5FC);
  static const Color blueDark = Color(0xFF1976D2);
  static const Color blueGrey = Color(0xFF263238);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProgressStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProgressStats();
  }

  Future<void> _loadProgressStats() async {
    setState(() { _isLoading = true; });
    final prefs = await SharedPreferences.getInstance();
    int streak = await _calculateCurrentStreak();
    final statsString = prefs.getString('progress_stats');
    if (statsString != null) {
      final stats = json.decode(statsString);
      final d = stats['d'] ?? {};
      final w = stats['w'] ?? {};
      final m = stats['m'] ?? {};
      final ph = stats['ph'] ?? {};
      setState(() {
        _todayReflections = d['r'] ?? 0;
        _todayActionsCompleted = d['a'] ?? 0;
        _todayGratitude = d['g'] ?? 0;
        _todayBestMoment = (d['b'] ?? 0) > 0;
        _todayPoints = d['p'] ?? 0;
        _todayStreak = streak;
        _weekReflections = w['r'] ?? 0;
        _weekActionsCompleted = w['a'] ?? 0;
        _weekGratitude = w['g'] ?? 0;
        _weekBestMoments = w['b'] ?? 0;
        _weekStatsLoading = false;
        _monthReflections = m['r'] ?? 0;
        _monthActions = m['a'] ?? 0;
        _monthGratitude = m['g'] ?? 0;
        _monthBestMoments = m['b'] ?? 0;
        _monthStatsLoading = false;
        _pointsHistory = Map<String, int>.from(ph);
        _isLoading = false;
      });
      _weekStreak = await _calculateWeekStreak();
      _monthStreak = await _calculateMonthStreak();
      return;
    }
    // If no stats, show empty/default
    setState(() {
      _todayReflections = 0;
      _todayActionsCompleted = 0;
      _todayGratitude = 0;
      _todayBestMoment = false;
      _todayPoints = 0;
      _todayStreak = streak;
      _weekReflections = 0;
      _weekActionsCompleted = 0;
      _weekGratitude = 0;
      _weekBestMoments = 0;
      _weekStatsLoading = false;
      _monthReflections = 0;
      _monthActions = 0;
      _monthGratitude = 0;
      _monthBestMoments = 0;
      _monthStatsLoading = false;
      _pointsHistory = {};
      _isLoading = false;
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
    // 1. Bar chart for the current week (Monday start, local time)
    final now = DateTime.now();
    // Dart: weekday 1=Mon, 7=Sun. To get Monday as start:
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final weekPoints = weekDays.map((date) => _pointsHistory[DateFormat('yyyy-MM-dd').format(date)] ?? 0).toList();
    final maxBar = weekPoints.isEmpty ? 1 : weekPoints.reduce((a, b) => a > b ? a : b);
    // Find today index in weekDays (local date)
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    final todayIndex = weekDays.indexWhere((d) => DateFormat('yyyy-MM-dd').format(d) == todayKey);
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
        sum += _pointsHistory[DateFormat('yyyy-MM-dd').format(date)] ?? 0;
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
                                      fontSize: 9,
                                    ),
                                  ),
                                )
                              : Text(
                                  weekLabels[idx],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
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
    final monthPoints = monthDays.fold(0, (sum, date) => sum + (_pointsHistory[DateFormat('yyyy-MM-dd').format(date)] ?? 0));
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
        sum1 += _pointsHistory[DateFormat('yyyy-MM-dd').format(date)] ?? 0;
      }
      halfMonthTotals.add(sum1);
      halfMonthLabels.add(_shortMonthLabel(start));
      // 2nd half
      int sum2 = 0;
      for (int d = 15; d < daysInMonth; d++) {
        final date = DateTime(start.year, start.month, d + 1);
        sum2 += _pointsHistory[DateFormat('yyyy-MM-dd').format(date)] ?? 0;
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
                            final dateKey = DateFormat('yyyy-MM-dd').format(date);
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
                                      fontSize: 9,
                                    ),
                                  ),
                                )
                              : Text(
                                  halfMonthLabels[idx],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
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
    print('Points history: $_pointsHistory');
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    for (final date in days) {
      print('Chart date key: ${DateFormat('yyyy-MM-dd').format(date)} value: ${_pointsHistory[DateFormat('yyyy-MM-dd').format(date)]}');
    }
    final points = days.map((date) => _pointsHistory[DateFormat('yyyy-MM-dd').format(date)] ?? 0).toList();
    final maxPoints = points.isEmpty ? 1 : points.reduce((a, b) => a > b ? a : b).toDouble();
    final avgPoints = points.isEmpty ? 0 : points.reduce((a, b) => a + b) / points.length;
    final weekLabels = days.map((d) => _weekdayAbbr(d.weekday)).toList();
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    //final todayIndex = days.indexWhere((d) => AppDateUtils.getDateKey(d) == todayKey);
    final todayIndex = now.weekday % 7;

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
                                fontSize: 9,
                              ),
                            ),
                          )
                        : Text(
                            weekLabels[idx],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
    const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
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

  Future<int> _calculateCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    int currentStreak = 0;
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = AppDateUtils.getDateKey(date);
      final hasReflection = prefs.getStringList('self_reflection_$dateKey') != null;
      final hasActions = prefs.getString('daily_actions_$dateKey') != null;
      final hasGratitude = prefs.getString('gratitude_$dateKey') != null;
      final hasBestMoment = prefs.getString('best_moment_$dateKey') != null;
      if (hasReflection || hasActions || hasGratitude || hasBestMoment) {
        currentStreak++;
      } else {
        break;
      }
    }
    return currentStreak;
  }

  Future<int> _calculateWeekStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    // Dart: weekday 1=Mon, 7=Sun. To get Monday as start:
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    int weekStreak = 0;
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateKey = AppDateUtils.getDateKey(date); // Use the same format as your data
      final hasReflection = prefs.getStringList('self_reflection_$dateKey') != null;
      final hasActions = prefs.getString('daily_actions_$dateKey') != null;
      final hasGratitude = prefs.getString('gratitude_$dateKey') != null;
      final hasBestMoment = prefs.getString('best_moment_$dateKey') != null;
      if (hasReflection || hasActions || hasGratitude || hasBestMoment) {
        weekStreak++;
      }
    }
    return weekStreak;
  }

  Future<int> _calculateMonthStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    int monthStreak = 0;
    for (int i = 0; i < lastDay.day; i++) {
      final date = firstDay.add(Duration(days: i));
      final dateKey = AppDateUtils.getDateKey(date); // Use the same format as your data
      final hasReflection = prefs.getStringList('self_reflection_$dateKey') != null;
      final hasActions = prefs.getString('daily_actions_$dateKey') != null;
      final hasGratitude = prefs.getString('gratitude_$dateKey') != null;
      final hasBestMoment = prefs.getString('best_moment_$dateKey') != null;
      if (hasReflection || hasActions || hasGratitude || hasBestMoment) {
        monthStreak++;
      }
    }
    return monthStreak;
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