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
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  // Ensure Flutter is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler for all uncaught Dart errors

  runZonedGuarded(() async {
    print('Initializing');
    
    // Initialize Firebase first
    print('Initializing Firebase');
    try {
      await Firebase.initializeApp();
      print('Firebase initialized');
      
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();

if (settings.authorizationStatus == AuthorizationStatus.authorized ||
    settings.authorizationStatus == AuthorizationStatus.provisional) {
  print('Notification permission granted: ${settings.authorizationStatus}');

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    print('New FCM Token (refreshed): $newToken');
    // Send to backend here
  });

  // Delay a bit to let APNs assign a token (especially on fresh installs)
  await Future.delayed(Duration(seconds: 2));

  try {
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    print('APNs Token: $apnsToken');

    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $fcmToken');
  } catch (e) {
    print('Failed to get APNs/FCM Token: $e');
  }
} else {
  print('User declined or has not accepted notification permissions');
}

      print('Notification settings initialized');

      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FirebaseCrashlytics.instance.setCustomKey("build_mode", kReleaseMode ? "release" : "debug");
    } catch (e) {
      print('Firebase initialization failed: $e');
      // Continue without Firebase if it fails
    }

    // Initialize Crashlytics after Firebase
    try {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      print('Crashlytics initialized');
    } catch (e) {
      print('Crashlytics setup failed: $e');
      // Continue without Crashlytics if it fails
    }
    
    // Initialize other services last
    try {
      await NotificationService.initialize();
      print('Notifications initialized');
    } catch (e) {
      print('Notification service initialization failed: $e');
      // Continue without notifications if it fails
    }

    print('All services initialized, starting app');
    runApp(const MyApp());
  }, (error, stackTrace) {
    // TODO: Send error and stackTrace to a crash reporting service
    print('Uncaught Dart error: $error');
    print(stackTrace);
    try {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    } catch (e) {
      print('Failed to record error to Crashlytics: $e');
    }
  });
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
          backgroundColor: Color(0xFF23272F),
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
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.primaryBlue.withOpacity(0.5),
          selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      SelfReflectionScreen(),
      DailyActionsScreen(),
      BestMomentScreen(),
      GratitudeScreen(),
      ProgressScreen(),
    ];
  }


  /*List<Widget> get _screens => [
    SelfReflectionScreen(),
    DailyActionsScreen(),
    BestMomentScreen(),
    GratitudeScreen(),
    ProgressScreen(),
  ];*/

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
    print('Building MainNavigation');
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
        backgroundColor: Color(0xFF23272F),
        elevation: 4,
        title: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                titles[_selectedIndex],
                style: GoogleFonts.nunito(
                  color: Color(0xFF00B4FF),
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
              cacheWidth: 1080,
            ),
          ),
          _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        color: const Color(0xFF23272F),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF23272F),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: _gradientIcon(Icons.auto_awesome_outlined, _selectedIndex == 0, selectedColor: Color(0xFF00B4FF)),
              label: 'Reflection',
            ),
            BottomNavigationBarItem(
              icon: _gradientIcon(Icons.check_circle_outline, _selectedIndex == 1, selectedColor: Color(0xFF00B4FF)),
              label: 'Daily Actions',
            ),
            BottomNavigationBarItem(
              icon: _gradientIcon(Icons.star_outline, _selectedIndex == 2, selectedColor: Color(0xFF00B4FF)),
              label: 'Best Moment',
            ),
            BottomNavigationBarItem(
              icon: _gradientIcon(Icons.favorite_border, _selectedIndex == 3, selectedColor: Color(0xFF00B4FF)),
              label: 'Gratitude',
            ),
            BottomNavigationBarItem(
              icon: _gradientIcon(Icons.insights_outlined, _selectedIndex == 4, selectedColor: Color(0xFF00B4FF)),
              label: 'Progress',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color(0xFF00B4FF),
          unselectedItemColor: Colors.white,
          showUnselectedLabels: true,
          elevation: 0,
          onTap: _onItemTapped,
          selectedFontSize: 16,
          unselectedFontSize: 14,
          selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00B4FF)),
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
    return Icon(icon, color: Color(0xFF00B4FF), size: 34);
  }
}
