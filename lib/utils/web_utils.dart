export 'firebase_web_utils.dart' if (dart.library.io) 'firebase_stub_utils.dart';

// Re-export common utilities
Future<T> handleThenable<T>(Object thenable) async {
  throw UnsupportedError('handleThenable is only available in web environment');
}

dynamic jsify(Object? obj) {
  throw UnsupportedError('jsify is only available in web environment');
}

dynamic dartify(Object? obj) {
  throw UnsupportedError('dartify is only available in web environment');
}