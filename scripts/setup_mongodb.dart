import 'package:mongo_dart/mongo_dart.dart';

Future<void> main() async {
  // ignore: avoid_print
  print('Setting up MongoDB database...');
  
  final db = await Db.create('mongodb://localhost:27017/community_dashboard');
  await db.open();
  
  // ignore: avoid_print
  print('Connected to MongoDB');
  
  // Get collections
  final incidents = db.collection('incidents');
  
  // Create indexes
  // ignore: avoid_print
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
  
  // ignore: avoid_print
  print('Setup complete!');
  await db.close();
}
