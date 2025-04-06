import 'package:mongo_dart/mongo_dart.dart';

Future<void> main() async {
  print('Setting up MongoDB database...');
  
  final db = await Db.create('mongodb://localhost:27017/community_dashboard');
  await db.open();
  
  print('Connected to MongoDB');
  
  // Get collections
  final incidents = db.collection('incidents');
  
  // Create indexes
  print('Creating indexes...');
  
  // Index for location-based queries
  await incidents.createIndex(
    keys: {'location': '2dsphere'},
  );
  
  // Index for status-based queries
  await incidents.createIndex(
    keys: {'status': 1},
  );
  
  // Index for createdAt for sorting
  await incidents.createIndex(
    keys: {'createdAt': -1},
  );
  
  print('Setup complete!');
  await db.close();
}
