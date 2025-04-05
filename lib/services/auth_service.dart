import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/web_utils.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _ensureInitialized() async {
    if (!kIsWeb || _initialized) return;
    
    // Check Firebase Auth state
    try {
      await _auth.authStateChanges().first;
      _initialized = true;
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      // Wait for Firebase to fully initialize
      await Future.delayed(const Duration(milliseconds: 200));
      _initialized = true;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      await _ensureInitialized();
      
      if (email.isEmpty) throw Exception('Email cannot be empty');
      if (password.isEmpty) throw Exception('Password cannot be empty');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      await _ensureInitialized();
      
      if (email.isEmpty) throw Exception('Email cannot be empty');
      if (password.isEmpty) throw Exception('Password cannot be empty');
      if (password.length < 6) throw Exception('Password must be at least 6 characters');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'email-already-in-use':
        return Exception('This email is already registered.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'weak-password':
        return Exception('The password is too weak.');
      case 'operation-not-allowed':
        return Exception('Email/password accounts are not enabled. Please contact support.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      default:
        return Exception(e.message ?? 'Authentication error occurred.');
    }
  }
}