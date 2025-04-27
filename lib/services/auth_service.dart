import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;  // Added photoURL

  AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,  // Added photoURL parameter
  });

  factory AuthUser.fromFirebaseUser(firebase_auth.User user) {
    return AuthUser(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoURL: user.photoURL,  // Added photoURL
    );
  }
}

class AuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _currentUser = AuthUser.fromFirebaseUser(user);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> signInWithEmail(String email, String password) async {  // Changed from signInWithEmailAndPassword
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await _syncUserWithBackend(userCredential.user!);
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> registerWithEmail(String email, String password) async {  // Changed from signUp
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await _syncUserWithBackend(userCredential.user!);
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

  Future<void> _syncUserWithBackend(firebase_auth.User firebaseUser) async {
    try {
      final user = AuthUser.fromFirebaseUser(firebaseUser);
      final response = await http.post(
        Uri.parse('http://localhost:3000/users/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebaseId': user.id,
          'email': user.email,
          'displayName': user.displayName,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to sync user with backend');
      }
    } catch (e) {
      debugPrint('Error syncing user with backend: $e');
      // Don't rethrow as this is a background sync operation
    }
  }
}