import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/daily_actions_screen.dart';
import 'screens/self_reflection_screen.dart';
import 'screens/gratitude_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/reminder_settings_screen.dart';
import 'screens/best_moment_screen.dart';
import 'screens/history_screen.dart';
import 'package:flutter/widgets.dart';
import 'utils/app_colors.dart';
import 'utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: AppColors.teal,
      onSecondary: Colors.white,
      error: Colors.red.shade700,
      onError: Colors.white,
      background: AppColors.background,
      onBackground: AppColors.primaryBlue,
      surface: AppColors.card,
      onSurface: AppColors.primaryBlue,
    );
    return MaterialApp(
      title: 'Euphoric Days',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.card,
          selectedItemColor: AppColors.teal,
          unselectedItemColor: AppColors.primaryBlue.withOpacity(0.5),
          selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: AppColors.teal),
          unselectedLabelStyle: GoogleFonts.nunito(color: AppColors.primaryBlue.withOpacity(0.7)),
          elevation: 12,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.accentYellow,
          foregroundColor: AppColors.primaryBlue,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 0)),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            elevation: MaterialStateProperty.all(3),
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) => Colors.transparent),
            shadowColor: MaterialStateProperty.all(AppColors.teal.withOpacity(0.2)),
            textStyle: MaterialStateProperty.all(GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        cardTheme: CardTheme(
          color: AppColors.card,
          elevation: 6,
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          shadowColor: AppColors.primaryBlue.withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme).copyWith(
          bodyLarge: GoogleFonts.nunito(fontSize: 18, color: AppColors.primaryBlue),
          bodyMedium: GoogleFonts.nunito(fontSize: 16, color: AppColors.primaryBlue),
          titleLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    SelfReflectionScreen(),
    DailyActionsScreen(),
    BestMomentScreen(),
    GratitudeScreen(),
    ProgressScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ReminderSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('SelfReflectionScreen build called');
    final titles = [
      'Self-Reflection',
      'Daily Actions',
      'Best Moment',
      'Gratitude',
      'Progress',
    ];
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 4,
        title: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                titles[_selectedIndex],
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.history, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => HistoryScreen()),
                      );
                    },
                    tooltip: 'History',
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: _openSettings,
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
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
          _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        color: AppColors.primaryBlue,
        child: BottomNavigationBar(
          backgroundColor: AppColors.primaryBlue,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: _gradientIcon(Icons.auto_awesome, _selectedIndex == 0, selectedColor: AppColors.teal),
              label: 'Reflection',
            ),
            BottomNavigationBarItem(
              icon: _gradientIcon(Icons.check_circle_rounded, _selectedIndex == 1, selectedColor: AppColors.teal),
              label: 'Daily Actions',
            ),
            BottomNavigationBarItem(
              icon: _gradientIcon(Icons.star, _selectedIndex == 2, selectedColor: AppColors.teal),
              label: 'Best Moment',
            ),
            BottomNavigationBarItem(
              icon: _gradientIcon(Icons.favorite, _selectedIndex == 3, selectedColor: AppColors.teal),
              label: 'Gratitude',
            ),
            BottomNavigationBarItem(
              icon: _gradientIcon(Icons.timeline_rounded, _selectedIndex == 4, selectedColor: AppColors.teal),
              label: 'Progress',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.teal,
          unselectedItemColor: Colors.white,
          showUnselectedLabels: true,
          elevation: 0,
          onTap: _onItemTapped,
          selectedFontSize: 16,
          unselectedFontSize: 14,
          selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.teal),
          unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.normal, fontSize: 14, color: Colors.white),
          landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        ),
      ),
    );
  }

  // Helper for gradient icon, now supports solid color for selected
  Widget _gradientIcon(IconData icon, bool selected, {Color selectedColor = Colors.white}) {
    if (!selected) {
      return Icon(icon, color: Colors.white, size: 30);
    }
    return Icon(icon, color: selectedColor, size: 34);
  }
}
