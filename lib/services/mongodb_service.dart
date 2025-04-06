import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';
import '../config/mongodb_config.dart';

class MongoDBService {
  static Db? _db;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Connecting to MongoDB...');
      _db = await Db.create(MongoConfig.mongoUri);
      await _db!.open();
      debugPrint('Connected to MongoDB successfully!');
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error connecting to MongoDB: $e');
      rethrow;
    }
  }

  static DbCollection getCollection(String collectionName) {
    if (!_isInitialized || _db == null) {
      throw Exception('MongoDB not initialized');
    }
    return _db!.collection(collectionName);
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _isInitialized = false;
    }
  }
}
