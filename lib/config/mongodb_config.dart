class MongoConfig {
  // Replace these with your MongoDB Atlas connection details
  static const String mongoUri = String.fromEnvironment('MONGO_URI', defaultValue: 'mongodb://localhost:27017');
  static const String dbName = String.fromEnvironment('MONGO_DB', defaultValue: 'community_dashboard');
  
  // Collections
  static const String incidentsCollection = 'incidents';
  static const String usersCollection = 'users';
}
