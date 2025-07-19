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
import '../utils/api_client.dart';
import '../utils/notification_service.dart';
import 'package:intl/intl.dart';
import '../utils/app_cache.dart';
import '../utils/progress_utils.dart';


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
    _loadBestMoment();
  }

  Future<void> _loadBestMoment() async {
    final userId = await getOrCreateUserId();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cache = AppCache();
    // Clear old cache for best moments
    cache.clearOldCacheForType('best_moment_', today);
    final cacheKey = 'best_moment_$today';
    // Try cache first
    final cached = cache.get<String>(cacheKey);
    if (cached != null) {
      setState(() {
        _savedMoment = cached;
        _isLoading = false;
      });
      print('got the best moment from the cache.');
      return;
    }
    // Otherwise, fetch from backend
    final moment = await ApiClient.getBestMoment(userId, today);
    if (moment != null) {
      cache.set(cacheKey, moment);
      setState(() {
        _savedMoment = moment;
        _isLoading = false;
      });
    } else {
      setState(() {
        _savedMoment = '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBestMoment() async {
    setState(() {
      _savedMoment = _momentController.text;
    });
    // Save to backend only
    final userId = await getOrCreateUserId();
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    await ApiClient.putBestMoment(userId, date, _momentController.text);
    // Update cache
    final cache = AppCache();
    final cacheKey = 'best_moment_$date';
    cache.set(cacheKey, _momentController.text);
    // Invalidate progress cache
    cache.remove('progress_$date');
    print('savig best moment $cacheKey');
    await ProgressUtils.addBestMoment();
  }

  void _editMoment() {
    setState(() {
      _momentController.text = _savedMoment ?? '';
      _savedMoment = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
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
                (_savedMoment ?? '').trim().isNotEmpty
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
            onPressed: _saveBestMoment,
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