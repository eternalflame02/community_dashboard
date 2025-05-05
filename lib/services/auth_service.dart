import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../config/api.dart';

class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;

  AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
  });

  factory AuthUser.fromFirebaseUser(firebase_auth.User user) {
    return AuthUser(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }
}

class AuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  // Add this getter to expose FirebaseAuth instance
  firebase_auth.FirebaseAuth get firebaseAuth => _auth;

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        _currentUser = await _fetchUserWithRole(user);
      } else {
        _currentUser = null;
        debugPrint('No user logged in');
      }
      notifyListeners();
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        // Check if email is verified
        await userCredential.user!.reload();
        final refreshedUser = _auth.currentUser;
        if (refreshedUser != null && !refreshedUser.emailVerified) {
          throw Exception('Email not verified. Please check your inbox.');
        }
        await _syncUserWithBackend(userCredential.user!);
        _currentUser = await _fetchUserWithRole(userCredential.user!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        // Send email verification
        await userCredential.user!.sendEmailVerification();
        await _syncUserWithBackend(userCredential.user!);
        _currentUser = await _fetchUserWithRole(userCredential.user!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Add this method to reload the current user and notify listeners
  Future<void> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      notifyListeners();
    }
  }

  Future<void> _syncUserWithBackend(firebase_auth.User firebaseUser) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebaseId': firebaseUser.uid,
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to sync user with backend');
      }
    } catch (e) {
      debugPrint('Error syncing user with backend: $e');
    }
  }

  Future<AppUser?> _fetchUserWithRole(firebase_auth.User firebaseUser) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/by-firebase-id/${firebaseUser.uid}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppUser.fromMap(data);
      }
    } catch (e) {
      debugPrint('Error fetching user with role: $e');
    }
    // fallback to default user if backend fails
    return AppUser(
      id: firebaseUser.uid,
      firebaseId: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      role: 'user',
    );
  }
}