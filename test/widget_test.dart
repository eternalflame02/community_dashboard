// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'widget_test.mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
// Remove the following line if widget_test.mocks.dart does not exist yet
// import 'widget_test.mocks.dart';
// If widget_test.mocks.dart is missing, run:
// flutter pub run build_runner build
// to generate the mocks file for mockito.
import 'package:community_dashboard/main.dart';
import 'package:community_dashboard/services/auth_service.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';


@GenerateMocks([AuthService])

class MockFirebaseAppPlatform extends FirebaseAppPlatform {
  MockFirebaseAppPlatform() : super(defaultFirebaseAppName, FirebaseOptions(
    apiKey: 'test',
    appId: 'test',
    messagingSenderId: 'test',
    projectId: 'test',
  ));

  @override
  String get name => defaultFirebaseAppName;
}

class MockFirebasePlatform extends FirebasePlatform with MockPlatformInterfaceMixin {
  MockFirebaseAppPlatform? _app;
  
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    _app ??= MockFirebaseAppPlatform();
    return _app!;
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return app(name ?? defaultFirebaseAppName);
  }

  @override
  List<FirebaseAppPlatform> get apps => [app()];

  Future<List<Map<String, dynamic>>> initializeCore() async {
    return [
      {
        'name': defaultFirebaseAppName,
        'options': {
          'apiKey': 'test',
          'appId': 'test',
          'messagingSenderId': 'test',
          'projectId': 'test',
        }
      }
    ];
  }

  bool get isIOS => false;

  bool get isMacOS => false;
}

void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();
}

void main() {
  setupFirebaseMocks();
  late MockAuthService mockAuth;

  setUp(() {
    mockAuth = MockAuthService();
  });

  testWidgets('App shows login screen when not authenticated', (WidgetTester tester) async {
    when(mockAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuth),
        ],
        child: const MaterialApp(
          home: MyApp(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify that the login screen elements are shown
    expect(find.text('Community Dashboard'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Need an account? Register'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
  });

  testWidgets('Login screen toggles between login and register states', (WidgetTester tester) async {
    when(mockAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuth),
        ],
        child: const MaterialApp(
          home: MyApp(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initial state should be login
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Need an account? Register'), findsOneWidget);

    // Tap register button
    await tester.tap(find.text('Need an account? Register'));
    await tester.pumpAndSettle();

    // Should now show register state
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Already have an account? Login'), findsOneWidget);
  });

  testWidgets('Login screen validates form fields', (WidgetTester tester) async {
    when(mockAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuth),
        ],
        child: const MaterialApp(
          home: MyApp(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Try to submit empty form
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Should show validation errors
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Login screen handles successful login', (WidgetTester tester) async {
    when(mockAuth.currentUser).thenReturn(null);
    when(mockAuth.signInWithEmail(any, any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuth),
        ],
        child: const MaterialApp(
          home: MyApp(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fill in the form
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');

    // Submit the form
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Verify login was attempted
    verify(mockAuth.signInWithEmail('test@example.com', 'password123')).called(1);
  });
}
