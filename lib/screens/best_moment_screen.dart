import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../widgets/background_image.dart';
import '../widgets/gradient_header.dart';
import '../widgets/euphoric_card.dart';
import '../utils/points_utils.dart';
import '../shared/text_styles.dart';
import '../shared/gradient_button.dart';

class BestMomentScreen extends StatefulWidget {
  @override
  State<BestMomentScreen> createState() => _BestMomentScreenState();
}

class _BestMomentScreenState extends State<BestMomentScreen> {
  final TextEditingController _momentController = TextEditingController();
  String? _savedMoment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedMoment();
  }

  Future<void> _loadSavedMoment() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey = '${now.year}_${now.month}_${now.day}';
    final savedMoment = prefs.getString('best_moment_$dateKey');
    
    setState(() {
      _savedMoment = savedMoment;
      _isLoading = false;
    });
  }

  Future<void> _saveMoment() async {
    if (_momentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your best moment! 🌟')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey = '${now.year}_${now.month}_${now.day}';
    
    await prefs.setString('best_moment_$dateKey', _momentController.text.trim());
    
    setState(() {
      _savedMoment = _momentController.text.trim();
    });
    await PointsUtils.incrementToday();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Best moment saved! ✨')),
    );
  }

  void _editMoment() {
    setState(() {
      _momentController.text = _savedMoment ?? '';
      _savedMoment = null;
    });
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
                // Professional header
                GradientHeader(
                  icon: Icons.star_outline,
                  title: 'Capture your most beautiful moment today!',
                  iconColor: Colors.white,
                ),
                const SizedBox(height: 16),
                // Best Moment card
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                    : _savedMoment != null
                        ? _buildSavedMomentCard()
                        : _buildInputCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return EuphoricCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What was your best moment today?',
            style: AppTextStyles.question.copyWith(color: Color(0xFF00B4FF)),
          ),
          const SizedBox(height: 8),
          Text(
            'Reflect on the most beautiful, meaningful, or joyful experience you had today.',
            style: AppTextStyles.description,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _momentController,
            maxLines: 5,
            minLines: 2,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Describe your best moment...',
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
          ),
          const SizedBox(height: 20),
          GradientButton(
            onPressed: _saveMoment,
            text: 'Save Best Moment',
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMomentCard() {
    return EuphoricCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              //Icon(Icons.star, color: AppColors.accentYellow, size: 28),
              const SizedBox(width: 8),
              Text(
                'Your Best Moment Today',
                style: AppTextStyles.question.copyWith(color: Color(0xFF00B4FF)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _savedMoment!,
            style: AppTextStyles.answer.copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),
          GradientButton(
            onPressed: _editMoment,
            text: 'Update',
            height: 48,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _momentController.dispose();
    super.dispose();
  }
} 