@JS()
library firebase_web_utils;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS('Promise')
class PromiseJsImpl<T> {
  external PromiseJsImpl(void Function(void Function(T) resolve, void Function(Object) reject) executor);
  external PromiseJsImpl then(Function(T) onFulfilled, [Function(Object) onRejected]);
}

@JS('Object')
class JsObject {
  external dynamic toJSON();
}

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