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
    _loadTodayAnswers();
    Future.microtask(() => _printAllReflectionKeys());
  }

  Future<void> _loadTodayAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final currentDate = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD format
    
    // Check if we're loading data for a new day
    if (_lastLoadedDate != null && _lastLoadedDate != currentDate) {
      // New day - reset everything
      setState(() {
        _todayAnswers.clear();
        _submitted = false;
        _currentCard = 0;
        for (int i = 0; i < _questions.length; i++) {
          _controllers[i].clear();
        }
      });
      _lastLoadedDate = currentDate;
      return;
    }
    
    final answers = prefs.getStringList(todayKey);
    if (answers != null && answers.length == _questions.length) {
      setState(() {
        _todayAnswers = answers;
        for (int i = 0; i < _questions.length; i++) {
          _controllers[i].text = answers[i];
        }
        _submitted = true;
      });
    }
    _lastLoadedDate = currentDate;
  }

  Future<void> _saveTodayAnswers() async {
    print('Attempting to save reflection...');
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final answers = _controllers.map((c) => c.text).toList();
    await prefs.setStringList(todayKey, answers);
    setState(() {
      _todayAnswers = answers;
      _submitted = true;
    });
    await PointsUtils.incrementToday();
    print('Saving reflection to key: self_reflection_${AppDateUtils.getDateKey(DateTime.now())}');
    print('Value: ${_controllers.map((c) => c.text).toList()}');
  }

  String _todayKey() {
    final now = DateTime.now();
    return AppDateUtils.getDateKey(now);
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

  void _saveAnswers() {
    if (_formKey.currentState!.validate()) {
      // Will add persistence later
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answers saved! 🌞')),
      );
    }
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
                color: AppColors.primaryBlue,
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
            const SizedBox(height: 12),
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
                  borderSide: BorderSide(color: AppColors.primaryBlue.withOpacity(0.1)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (value) {
                print('Validating: $value');
                return value == null || value.isEmpty ? 'Please answer' : null;
              },
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
                  color: AppColors.primaryBlue,
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

  Future<void> _printAllReflectionKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('self_reflection_')) {
        print('Reflection key: $key, value: ${prefs.getStringList(key)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //const SizedBox(height: 2),
            GradientHeader(
              icon: Icons.auto_awesome,
              title: 'Reflect and set your intention for today!',
              iconColor: AppColors.accentYellow,
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
                        ElevatedButton(
                          onPressed: _resetAnswers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: GradientButton(
                            onPressed: _resetAnswers,
                            text: 'Reset',
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
                                          print('About to call _saveTodayAnswers');
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
    );
  }
} 