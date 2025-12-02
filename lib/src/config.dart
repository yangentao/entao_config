import 'dart:io';

import 'package:entao_config/src/IndentBuffer.dart';
import 'package:entao_dutil/entao_dutil.dart';

part 'parser.dart';
part 'values.dart';

/// 松散模式, 键不需要引号,  逗号/分号/回车/换行都可以分割值.
class yson {
  yson._();

  static String encode(dynamic value, {bool loose = false, bool prety = false}) {
    switch (value) {
      case null:
        return "null";
      case num n:
        return n.toString();
      case String s:
        return _encodeJsonString(s).quoted;
      case bool b:
        return b.toString();
      case List ls:
        Iterable<String> sList = ls.map((e) => encode(e, loose: loose));
        String sep = ", ";
        String a = "";
        if (prety) {
          int sumLen = sList.sumValueBy((String e) => e.length) ?? 0;
          if (sumLen > 50) {
            sep = loose ? "\n" : ",\n";
            a = "\n";
          }
        }
        return "[$a${sList.join(sep)}$a]";
      case Map map:
        String a = prety ? "\n" : "";
        if (loose) {
          String sep = prety ? "\n" : ", ";
          return "{$a${map.entries.map((e) => "${e.key}:${encode(e.value, loose: loose)}").join(sep)}$a}";
        } else {
          String sep = prety ? ",\n" : ", ";
          return "{$a${map.entries.map((e) => "${encode(e.key)}:${encode(e.value, loose: loose)}").join(sep)}$a}";
        }
      default:
        raise("Unknown type: $value");
    }
  }

  static dynamic decode(String json) {
    return _EParser(json).parse();
  }
}
