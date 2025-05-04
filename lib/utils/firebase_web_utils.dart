import 'package:js/js_util.dart' as js_util;

Future<T> handleThenable<T>(Object thenable) async {
  try {
    return await js_util.promiseToFuture<T>(thenable);
  } catch (e) {
    throw Exception('JavaScript Promise error: $e');
  }
}

dynamic jsify(Object? obj) {
  return js_util.jsify(obj);
}

dynamic dartify(Object? obj) {
  return js_util.dartify(obj);
}