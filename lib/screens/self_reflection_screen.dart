import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/gradient_button.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/background_image.dart';
import '../widgets/gradient_header.dart';
import '../widgets/euphoric_card.dart';
import '../utils/points_utils.dart';
import '../utils/api_client.dart';
import 'package:intl/intl.dart';
import '../utils/notification_service.dart';
import 'dart:convert';
import '../utils/app_cache.dart';

class SelfReflectionScreen extends StatefulWidget {
  @override
  State<SelfReflectionScreen> createState() => _SelfReflectionScreenState();
}

class _SelfReflectionScreenState extends State<SelfReflectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _q1Controller = TextEditingController();
  final _q2Controller = TextEditingController();
  final _q3Controller = TextEditingController();
  final _q4Controller = TextEditingController();

  int _currentCard = 0;
  bool _submitted = false;
  List<String> _todayAnswers = [];
  String? _lastLoadedDate;
  bool _isLoading = false;
  String? _errorMessage;

  // Comprehensive suggestion lists for each question
  final List<String> _identitySuggestions = [
    'Focused Warrior', 'Calm Leader', 'Energetic Creator', 'Go-Getter Spirit',
    'Mindful Observer', 'Bold Achiever', 'Peaceful Force', 'Dynamic Dreamer',
    'Steady Climber', 'Bright Beacon', 'Gentle Power', 'Unstoppable Force',
    'Centered Guide', 'Passionate Builder', 'Wise Explorer', 'Radiant Light',
    'Determined Pathfinder', 'Serene Strength', 'Vibrant Soul', 'Grounded Visionary',
    'Confident Pioneer', 'Balanced Master', 'Inspiring Catalyst', 'Authentic Champion'
  ];

  final List<String> _connectionSuggestions = [
    'With Deep Presence', 'Through Active Listening', 'With Genuine Curiosity', 'Through Warm Empathy',
    'With Calm Confidence', 'Through Encouraging Words', 'With Patient Understanding', 'Through Authentic Interest',
    'With Supportive Energy', 'Through Mindful Attention', 'With Compassionate Heart', 'Through Inspiring Presence',
    'With Open Mind', 'Through Gentle Guidance', 'With Positive Energy', 'Through Sincere Care',
    'With Focused Attention', 'Through Encouraging Spirit', 'With Peaceful Strength', 'Through Loving Kindness'
  ];

  final List<String> _amazingDaySuggestions = [
    'Focus on One Priority', 'Complete One Major Task', 'Learn Something New', 'Help Someone Today',
    'Practice Deep Gratitude', 'Take One Bold Action', 'Create Something Meaningful', 'Connect with a Loved One',
    'Move My Body Mindfully', 'Read Something Inspiring', 'Write My Thoughts Down', 'Meditate for Clarity',
    'Finish What I Started', 'Take a Calculated Risk', 'Celebrate Small Wins', 'Plan Tomorrow Today',
    'Express My Creativity', 'Listen to My Intuition', 'Step Out of Comfort Zone', 'Practice Self-Care'
  ];

  final List<String> _showUpSuggestions = [
    'Focused & Present', 'Calm & Confident', 'Energetic & Determined', 'Mindful & Grounded',
    'Bold & Authentic', 'Patient & Persistent', 'Joyful & Grateful', 'Steady & Reliable',
    'Passionate & Driven', 'Peaceful & Centered', 'Courageous & Strong', 'Gentle & Powerful',
    'Clear & Intentional', 'Warm & Welcoming', 'Dynamic & Inspiring', 'Balanced & Harmonious',
    'Enthusiastic & Motivated', 'Compassionate & Understanding', 'Authentic & True', 'Radiant & Bright'
  ];

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Who do you want to be today?',
      'desc': 'Define your euphoric self in 2 words',
      'examples': [
        'Calm Angel', 'Fast learner', 'Driven Dragon', 'Creative Tiger', 'Electric Dreamer', 'Freaking Finisher'
      ],
    },
    {
      'question': 'How am I going to connect with people today?',
      'desc': 'Choose your way to share joy',
      'examples': [
        'With Positivity', 'Engaging manner', 'Radiating Confidence', 'With Empathy', 'With Compassion'
      ],
    },
    {
      'question': 'What can I do today to make the day amazing?',
      'desc': 'One meaningful joy-creating action',
      'examples': [
        'Focus on one move', 'Layout vision on the future', 'Finish what I start', 'Active Listener', 'Complete a pending task', "Do something that I haven't done before"
      ],
    },
    {
      'question': '2 simple changes on how you show up?',
      'desc': ",2 ways you'll embody euphoria",
      'examples': [
        'Show up with Energy & Confidence', 'Patience & Discipline', 'Love & Compassion', 'Clarity & Focus'
      ],
    },
  ];

  List<TextEditingController> get _controllers => [
    _q1Controller, _q2Controller, _q3Controller, _q4Controller
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayReflection();
  }

  Future<void> _loadTodayReflection() async {
    final userId = await getOrCreateUserId();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cache = AppCache();
    // Clear old cache for reflections
    cache.clearOldCacheForType('reflection_', today);
    final cacheKey = 'reflection_$today';
    // Try cache first
    final cached = cache.get<List<String>>(cacheKey);
    if (cached != null) {
      setState(() {
        _todayAnswers = List<String>.from(cached);
        for (int i = 0; i < _controllers.length; i++) {
          _controllers[i].text = i < cached.length ? cached[i] : '';
        }
        _submitted = true;
      });
      print('got the reflections from the cache.');
      return;
    }
    // Otherwise, fetch from backend
    final reflection = await ApiClient.getReflection(userId, today);
    if (reflection != null) {
      cache.set(cacheKey, reflection);
      setState(() {
        _todayAnswers = List<String>.from(reflection);
        for (int i = 0; i < _controllers.length; i++) {
          _controllers[i].text = i < reflection.length ? reflection[i] : '';
        }
        _submitted = true;
      });
    }
  }

  Future<void> _saveTodayAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final answers = _controllers.map((c) => c.text).toList();
    await prefs.setStringList(todayKey, answers);
    setState(() {
      _todayAnswers = answers;
      _submitted = true;
    });
    await PointsUtils.incrementToday();
    // Update cache
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cache = AppCache();
    final cacheKey = 'reflection_$today';
    cache.set(cacheKey, answers);
    // Also save to backend
    final userId = await getOrCreateUserId();
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    await ApiClient.putReflection(userId, date, answers);
  }

  String _todayKey() {
    final now = DateTime.now();
    return 'self_reflection_${AppDateUtils.getDateKey(now)}';
  }

  void _resetAnswers() {
    setState(() {
      _submitted = false;
      for (int i = 0; i < _questions.length; i++) {
        _controllers[i].text = _todayAnswers.isNotEmpty ? _todayAnswers[i] : '';
      }
      _currentCard = 0;
    });
  }

  @override
  void dispose() {
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    _q4Controller.dispose();
    super.dispose();
  }

  void _nextCard() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        if (_currentCard < _questions.length - 1) {
          _currentCard++;
        }
      });
    }
  }

  void _prevCard() {
    setState(() {
      if (_currentCard > 0) {
        _currentCard--;
      }
    });
  }

  Widget _buildQuestionCard(String question, String desc, TextEditingController controller, List<String> examples) {
    // Pick 2 random examples
    final random = Random();
    final shuffled = List<String>.from(examples)..shuffle(random);
    final hint = 'eg: ' + shuffled.take(2).join(', ');
    
    return EuphoricCardWithBorder(
      borderColor: AppColors.primaryBlue,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00B4FF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.primaryBlue.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              style: GoogleFonts.nunito(fontSize: 16, color: AppColors.primaryBlue),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.nunito(color: AppColors.primaryBlue.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF00B4FF).withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF00B4FF), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
              validator: (value) {
                return value == null || value.isEmpty ? 'Please answer' : null;
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00B4FF), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00B4FF).withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _generateSuggestion,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Suggest Me',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return EuphoricCardWithBorder(
      borderColor: AppColors.primaryBlue,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_questions.length, (i) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _questions[i]['question'],
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00B4FF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _controllers[i].text,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: AppColors.primaryBlue.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 24),
            ],
          )),
        ),
      ),
    );
  }
  

  // Get suggestions for the current question
  List<String> _getSuggestionsForCurrentQuestion() {
    switch (_currentCard) {
      case 0:
        return _identitySuggestions;
      case 1:
        return _connectionSuggestions;
      case 2:
        return _amazingDaySuggestions;
      case 3:
        return _showUpSuggestions;
      default:
        return [];
    }
  }

  // Generate a random suggestion
  void _generateSuggestion() {
    final suggestions = _getSuggestionsForCurrentQuestion();
    if (suggestions.isNotEmpty) {
      final random = Random();
      final suggestion = suggestions[random.nextInt(suggestions.length)];
      _controllers[_currentCard].text = suggestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
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
                      Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reflect and set your intention for today!',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _submitted
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 150),
                        child: Column(
                          children: [
                            _buildSummaryCard(),
                            const SizedBox(height: 12),
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
                                onPressed: _resetAnswers,
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
                                      'Reset',
                                      style: GoogleFonts.nunito(
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
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 150),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildQuestionCard(
                                _questions[_currentCard]['question'],
                                _questions[_currentCard]['desc'],
                                _controllers[_currentCard],
                                List<String>.from(_questions[_currentCard]['examples']),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (_currentCard > 0)
                                    Expanded(
                                      child: GradientButton(
                                        onPressed: _prevCard,
                                        text: 'Back',
                                      ),
                                    ),
                                  if (_currentCard > 0) const SizedBox(width: 16),
                                  Expanded(
                                    child: _currentCard == _questions.length - 1
                                        ? GradientButton(
                                            onPressed: () {
                                              if (_formKey.currentState!.validate()) {
                                                _saveTodayAnswers();
                                              }
                                            },
                                            text: 'Submit',
                                          )
                                        : GradientButton(
                                            onPressed: _nextCard,
                                            text: 'Next',
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 