import 'dart:io';

import 'package:entao_dutil/entao_dutil.dart';

part 'parse.dart';
part 'values.dart';

class EConfig {
  EConfig._();
  static EMap? load(File file){
    return null ;
  }


  //map or list
  static EValue? tryParse(String text) {
    try {
      var v = parse(text);
      return v.isNull ? null : v;
    } catch (e) {
      return null;
    }
  }

  //map or list
  static EValue parse(String text) {
    _EParser p = _EParser(text);
    return p.parse();
  }

  static String escape(String value) {
    return _enEscape(value);
  }
}

extension StrignEnExt on String {
  String get enEscaped => _enEscape(this);
}

class EError implements Exception {
  dynamic message;

  EError(this.message);

  @override
  String toString() {
    Object? message = this.message;
    if (message == null) return "YConfigError";
    return "YConfigError: $message";
  }
}
