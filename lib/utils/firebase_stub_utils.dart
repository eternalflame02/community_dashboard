// Stub implementation for non-web platforms
Future<T> handleThenable<T>(Object thenable) async {
  throw UnsupportedError('Web utilities are not available on this platform');
}

dynamic jsify(Object? obj) {
  throw UnsupportedError('Web utilities are not available on this platform');
}

dynamic dartify(Object? obj) {
  throw UnsupportedError('Web utilities are not available on this platform');
}