import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentReflections = [];
  List<Map<String, dynamic>> _recentActions = [];
  List<Map<String, dynamic>> _recentKindness = [];
  List<Map<String, dynamic>> _recentBestMoments = [];
  bool _isLoading = true;
  Map<String, int> _contributionMap = {};
  int _totalActionsTaken = 0;
  int _totalKindnessDone = 0;
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
    final recentKindness = [];
    final recentBestMoments = [];
    final contributionMap = <String, int>{};
    int totalReflections = 0;
    int totalActions = 0;
    int totalKindness = 0;
    int completedActions = 0;
    int completedKindness = 0;
    int totalActionsTaken = 0;
    int totalKindnessDone = 0;
    int totalBestMoments = 0;

    // Last 6 months (about 26 weeks)
    for (int i = 0; i < 26 * 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}_${date.month}_${date.day}';
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

      // Kindness
      final kindnessKey = 'kindness_$dateKey';
      final kindnessData = prefs.getString(kindnessKey);
      if (kindnessData != null) {
        final kindness = json.decode(kindnessData);
        if (kindness['kindness'] != null) {
          totalKindness++;
          if (kindness['status'] == 'completed') {
            completedKindness++;
            totalKindnessDone++;
          }
          activityCount++;
          if (i < 21) {
            recentKindness.add({
              'date': date,
              'kindness': kindness['kindness'],
              'status': kindness['status'],
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
        'totalKindness': totalKindness,
        'completedActions': completedActions,
        'completedKindness': completedKindness,
        'streakDays': _calculateStreak(prefs),
        'currentStreak': _calculateCurrentStreak(prefs),
      };
      _recentReflections = List<Map<String, dynamic>>.from(recentReflections);
      _recentActions = List<Map<String, dynamic>>.from(recentActions);
      _recentKindness = List<Map<String, dynamic>>.from(recentKindness);
      _recentBestMoments = List<Map<String, dynamic>>.from(recentBestMoments);
      _contributionMap = contributionMap;
      _totalActionsTaken = totalActionsTaken;
      _totalKindnessDone = totalKindnessDone;
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

  int _calculateStreak(SharedPreferences prefs) {
    // Calculate longest streak in the last 30 days
    final now = DateTime.now();
    int maxStreak = 0;
    int currentStreak = 0;
    
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}_${date.month}_${date.day}';
      
      final hasReflection = prefs.getStringList('self_reflection_$dateKey') != null;
      final hasActions = prefs.getString('daily_actions_$dateKey') != null;
      final hasKindness = prefs.getString('kindness_$dateKey') != null;
      
      if (hasReflection || hasActions || hasKindness) {
        currentStreak++;
        maxStreak = maxStreak < currentStreak ? currentStreak : maxStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    return maxStreak;
  }

  int _calculateCurrentStreak(SharedPreferences prefs) {
    final now = DateTime.now();
    int currentStreak = 0;
    
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}_${date.month}_${date.day}';
      
      final hasReflection = prefs.getStringList('self_reflection_$dateKey') != null;
      final hasActions = prefs.getString('daily_actions_$dateKey') != null;
      final hasKindness = prefs.getString('kindness_$dateKey') != null;
      
      if (hasReflection || hasActions || hasKindness) {
        currentStreak++;
      } else {
        break;
      }
    }
    
    return currentStreak;
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // No AppBar here; provided by MainNavigation
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/wa_background.jpeg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.08),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF223A5E)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header - move to top
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF223A5E), Color(0xFF26A69A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timeline, color: Color(0xFFFFD600), size: 36),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Your Euphoric Journey Progress!',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Contribution Grid
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _gridScrollController,
                        child: _buildContributionGrid(),
                      ),
                      const SizedBox(height: 24),
                      // Statistics Cards
                      _buildStatisticsSection(),
                      const SizedBox(height: 24),
                      // Recent Reflections
                      if (_recentReflections.isNotEmpty) ...[
                        _buildSwipeableRecentReflections(),
                        const SizedBox(height: 24),
                      ],
                      // Recent Actions
                      if (_recentActions.isNotEmpty) ...[
                        _buildSwipeableRecentActions(),
                        const SizedBox(height: 24),
                      ],
                      // Recent Kindness
                      if (_recentKindness.isNotEmpty) ...[
                        _buildSwipeableRecentKindness(),
                        const SizedBox(height: 24),
                      ],
                      // Recent Best Moments
                      if (_recentBestMoments.isNotEmpty) ...[
                        _buildSwipeableRecentBestMoments(),
                        const SizedBox(height: 24),
                      ],
                      // Empty State
                      if (_recentReflections.isEmpty && _recentActions.isEmpty && _recentKindness.isEmpty) ...[
                        _buildEmptyState(),
                      ],
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildContributionGrid() {
    // 26 weeks x 7 days = 182 days
    final now = DateTime.now();
    final days = List.generate(26 * 7, (i) => now.subtract(Duration(days: 26 * 7 - 1 - i)));
    // Group by week (columns)
    final weeks = List.generate(26, (w) => days.skip(w * 7).take(7).toList());
    // Month labels
    final monthLabels = <int, String>{};
    for (int w = 0; w < weeks.length; w++) {
      final firstDay = weeks[w].first;
      if (firstDay.day <= 7) {
        monthLabels[w] = _monthAbbr(firstDay.month);
      }
    }
    // Weekday labels (Mon, Wed, Fri)
    final weekdayLabels = [1, 3, 5]; // Monday, Wednesday, Friday
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 6 Months', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF223A5E))),
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
                        width: 15,
                        alignment: Alignment.centerLeft,
                        child: label != null
                            ? Text(label, style: GoogleFonts.nunito(fontSize: 10, color: Color(0xFF223A5E)))
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
                            child: Text(_weekdayAbbr(d), style: GoogleFonts.nunito(fontSize: 10, color: Color(0xFF223A5E))),
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
                        final dateKey = '${date.year}_${date.month}_${date.day}';
                        final count = _contributionMap[dateKey] ?? 0;
                        final now = DateTime.now();
                        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                        final color = count == 0
                            ? const Color(0xFF151b23)
                            : count == 1
                                ? Colors.green[200]
                                : count == 2
                                    ? Colors.green[400]
                                    : count == 3
                                        ? Colors.green[600]
                                        : Colors.green[800];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                            border: isToday ? Border.all(color: Colors.yellow, width: 2) : null,
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
              Text('Less', style: GoogleFonts.nunito(fontSize: 12, color: Color(0xFF223A5E))),
              Row(
                children: [
                  Container(width: 13, height: 13, color: const Color(0xFFD0D7DE)),
                  Container(width: 13, height: 13, color: Colors.green[200]),
                  Container(width: 13, height: 13, color: Colors.green[400]),
                  Container(width: 13, height: 13, color: Colors.green[600]),
                  Container(width: 13, height: 13, color: Colors.green[800]),
                ],
              ),
              Text('More', style: GoogleFonts.nunito(fontSize: 12, color: Color(0xFF223A5E))),
            ],
          ),
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

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF223A5E),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Current Streak',
                '${_stats['currentStreak']} days',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Best Streak',
                '${_stats['streakDays']} days',
                Icons.emoji_events,
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Reflections',
                '${_stats['totalReflections']} days',
                Icons.auto_awesome,
                Color(0xFF223A5E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Actions',
                '${_stats['completedActions']}/${_stats['totalActions']}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Kindness',
                '${_stats['completedKindness']}/${_stats['totalKindness']}',
                Icons.favorite,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Days',
                '${_stats['totalReflections'] + _stats['totalActions'] + _stats['totalKindness']}',
                Icons.calendar_today,
                Color(0xFF26A69A),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Best Moments',
            '$_totalBestMoments',
            Icons.star,
            Colors.amber,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Actions Taken',
                '$_totalActionsTaken',
                Icons.list_alt,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Kindness Done',
                '$_totalKindnessDone',
                Icons.volunteer_activism,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF223A5E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Color(0xFF223A5E).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Swipeable recent cards
  Widget _buildSwipeableRecentReflections() {
    return _buildSwipeableCard(
      title: 'Recent Reflections',
      icon: Icons.auto_awesome,
      color: Color(0xFF223A5E),
      items: _recentReflections,
      itemBuilder: (context, reflection) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatDate(reflection['date']), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(reflection['answers'].length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(reflection['answers'][i], style: GoogleFonts.nunito(fontSize: 14)),
          )),
        ],
      ),
    );
  }

  Widget _buildSwipeableRecentActions() {
    return _buildSwipeableCard(
      title: 'Recent Actions',
      icon: Icons.check_circle,
      color: Colors.green,
      items: _recentActions,
      itemBuilder: (context, action) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDate(action['date']), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              Text('${action['completed']}/${action['total']}', style: GoogleFonts.nunito(color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(action['actions'].length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(action['actions'][i]['text'], style: GoogleFonts.nunito(fontSize: 14)),
          )),
        ],
      ),
    );
  }

  Widget _buildSwipeableRecentKindness() {
    return _buildSwipeableCard(
      title: 'Recent Kindness',
      icon: Icons.favorite,
      color: Colors.red,
      items: _recentKindness,
      itemBuilder: (context, kindness) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDate(kindness['date']), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getKindnessStatusColor(kindness['status']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_getKindnessStatusText(kindness['status']), style: GoogleFonts.nunito(color: _getKindnessStatusColor(kindness['status']))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(kindness['kindness'] ?? '', style: GoogleFonts.nunito(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSwipeableRecentBestMoments() {
    return _buildSwipeableCard(
      title: 'Recent Best Moments',
      icon: Icons.star,
      color: Colors.amber,
      items: _recentBestMoments,
      itemBuilder: (context, moment) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatDate(moment['date']), style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(moment['moment'] ?? '', style: GoogleFonts.nunito(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSwipeableCard({
    required String title,
    required IconData icon,
    required Color color,
    required List items,
    required Widget Function(BuildContext, dynamic) itemBuilder,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color, width: 2),
      ),
      color: const Color(0xFFF8F9FB),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: PageView.builder(
                itemCount: items.length,
                controller: PageController(viewportFraction: 0.92),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: itemBuilder(context, items[index]),
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

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF223A5E), width: 2),
      ),
      color: const Color(0xFFF8F9FB),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Color(0xFF223A5E).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No History Yet',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF223A5E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your euphoric journey by completing reflections, actions, and acts of kindness!',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Color(0xFF223A5E).withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getKindnessStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'not_applicable':
        return Colors.orange;
      case 'not_interested':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getKindnessStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'not_applicable':
        return 'N/A';
      case 'not_interested':
        return 'Not Interested';
      default:
        return 'Pending';
    }
  }

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }
} 