import 'dart:convert';
import 'dart:io';

import 'package:entao_config/src/IndentBuffer.dart';
import 'package:entao_config/src/Stack.dart';
import 'package:entao_dutil/entao_dutil.dart';
import 'package:path/path.dart' as pathUtil;
import 'package:println/println.dart';

part 'eparser.dart';
part 'values.dart';

/// 松散模式, 键不需要引号,  逗号/分号/回车/换行都可以分割值.
class EConfig {
  EConfig._();

  static void Function(String) errorLog = (s) => stderr.writeln(s);

  static EMap parseFile(File file, {Encoding encoding = utf8}) {
    String s = file.readAsStringSync(encoding: encoding);
    return _EParser(s, currentDir: pathUtil.dirname(file.path)).parse();
  }

  static EMap parse(String text, {String? currentDir}) {
    return _EParser(text, currentDir: currentDir).parse();
  }
}

void _loge(String s) => EConfig.errorLog(s);
