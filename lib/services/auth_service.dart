import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../config/mongodb_config.dart';
import 'mongodb_service.dart';

class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? photoURL;
  final String? displayName;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.photoURL,
    this.displayName,
  });

  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
      photoURL: user.photoURL,
      displayName: user.displayName,
    );
  }

  Map<String, dynamic> toMongoDB() {
    return {
      'firebaseId': id,
      'email': email,
      'name': name,
      'photoURL': photoURL,
      'displayName': displayName,
    };
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUser = AppUser.fromFirebaseUser(user);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _ensureInitialized() async {
    if (!kIsWeb || _initialized) return;
    
    try {
      await _auth.authStateChanges().first;
      _initialized = true;
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      await Future.delayed(const Duration(milliseconds: 200));
      _initialized = true;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      await _ensureInitialized();
      
      if (email.isEmpty) throw Exception('Email cannot be empty');
      if (password.isEmpty) throw Exception('Password cannot be empty');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user in MongoDB if not exists
      await _syncUserToMongoDB(credential.user!);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint('Error: $e');
      throw AuthException('An unexpected error occurred. Please try again later.');
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

      // Store user in MongoDB
      await _syncUserToMongoDB(credential.user!);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint('Error: $e');
      throw AuthException('An unexpected error occurred. Please try again later.');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error: $e');
      throw AuthException('An unexpected error occurred. Please try again later.');
    }
  }

  Future<void> _syncUserToMongoDB(User firebaseUser) async {
    if (kIsWeb) {
      debugPrint('Skipping MongoDB sync in web environment.');
      return;
    }

    try {
      final collection = MongoDBService.getCollection(MongoConfig.usersCollection);
      final user = AppUser.fromFirebaseUser(firebaseUser);
      
      // Check if user exists in MongoDB
      final existingUser = await collection.findOne(
        where.eq('firebaseId', user.id)
      );

      if (existingUser == null) {
        // Create new user in MongoDB
        await collection.insertOne(user.toMongoDB());
      } else {
        // Update existing user in MongoDB
        await collection.updateOne(
          where.eq('firebaseId', user.id),
          modify.set('email', user.email)
            .set('name', user.name)
            .set('photoURL', user.photoURL)
            .set('displayName', user.displayName)
            .set('lastLogin', DateTime.now())
            .set('updatedAt', DateTime.now())
        );
      }
    } catch (e) {
      debugPrint('Error syncing user to MongoDB: $e');
      // Don't throw - this shouldn't block auth flow
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