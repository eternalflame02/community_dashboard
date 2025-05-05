import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'services/auth_service.dart';
import 'services/incident_service.dart';
import 'services/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/email_not_verified_screen.dart';
import 'screens/officer_home_screen.dart';
import 'screens/admin_manage_users_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAUa1_8EdO2LeDO0igEipKc114dMHeygMs",
        authDomain: "communitydashboard-4a923.firebaseapp.com",
        projectId: "communitydashboard-4a923",
        storageBucket: "communitydashboard-4a923.appspot.com",
        messagingSenderId: "624716403094",
        appId: "1:624716403094:web:6fa618ed905370d8bf4db7"
      ),
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('🔥 Initialization error: $e');
    debugPrint('🧵 Stack trace: $stackTrace');
    runApp(AppError(message: 'Failed to initialize app. Error: $e'));
    return;
  }

  runApp(const MyApp());
}

class AppError extends StatelessWidget {
  final String message;
  const AppError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(message, 
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => IncidentService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Community Dashboard',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.light(
                primary: Color(0xFF4F8EFF), // Vibrant blue
                secondary: Color(0xFF7C4DFF), // Accent purple
                background: Color(0xFFF3F7FB), // Soft blue background
                surface: Color(0xFFEAF1FB), // Slightly deeper card background
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onBackground: Color(0xFF222B45),
                onSurface: Color(0xFF222B45),
              ),
              scaffoldBackgroundColor: Color(0xFFF3F7FB),
              cardColor: Color(0xFFEAF1FB),
              appBarTheme: AppBarTheme(
                backgroundColor: Color(0xFFEAF1FB),
                foregroundColor: Color(0xFF222B45),
                elevation: 1,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Color(0xFF4F8EFF),
                foregroundColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Color(0xFFF3F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFF4F8EFF), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
                ),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: Color(0xFF4F8EFF).withOpacity(0.08),
                selectedColor: Color(0xFF7C4DFF).withOpacity(0.18),
                labelStyle: TextStyle(color: Color(0xFF222B45)),
                secondaryLabelStyle: TextStyle(color: Color(0xFF7C4DFF)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            darkTheme: ThemeData.dark(useMaterial3: true),
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthService>(
              builder: (context, authService, _) {
                final user = firebase_auth.FirebaseAuth.instance.currentUser;
                if (authService.currentUser == null) {
                  return const LoginScreen();
                }
                // If user is signed in but email is not verified, show EmailNotVerifiedScreen
                if (user != null && !user.emailVerified) {
                  return EmailNotVerifiedScreen(
                    email: user.email ?? '',
                    password: '', // password can't be retrieved, but not needed for resend
                  );
                }
                if (authService.currentUser!.role == 'admin') {
                  return const AdminManageUsersScreen();
                }
                if (authService.currentUser!.role == 'officer') {
                  return const OfficerHomeScreen();
                }
                return const HomeScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
