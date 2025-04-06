import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'services/incident_service.dart';
import 'services/mongodb_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';

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

    if (!kIsWeb) {
      await MongoDBService.initialize();
    }
  } catch (e, stackTrace) {
    debugPrint('🔥 Initialization error: $e');
    debugPrint('🧵 Stack trace: $stackTrace');
    runApp(const AppError(message: 'Failed to initialize app. Please try again.'));
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
      ],
      child: MaterialApp(
        title: 'Community Dashboard',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            return authService.currentUser != null
                ? const HomeScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}
