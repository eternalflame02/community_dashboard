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
            theme: ThemeData.light(useMaterial3: true),
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
