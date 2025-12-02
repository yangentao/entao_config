import 'dart:io';

import 'package:entao_config/src/IndentBuffer.dart';
import 'package:entao_dutil/entao_dutil.dart';

part 'eparser.dart';
part 'values.dart';

/// 松散模式, 键不需要引号,  逗号/分号/回车/换行都可以分割值.
class yson {
  yson._();


  static dynamic decode(String json) {
    return _EParser(json).parse();
  }
}
