import 'dart:convert';
import 'dart:io';

import 'package:entao_config/src/IndentBuffer.dart';
import 'package:entao_dutil/entao_dutil.dart';
import 'package:path/path.dart' as pathUtil;

part 'parser.dart';
part 'ext.dart';
part 'values.dart';

class EConfig {
  EConfig._();

  static void Function(String) errorLog = (s) => stderr.writeln(s);
  static void Function(String) requireFailed = (s) {
    stderr.writeln(s);
    exit(-1);
  };

  static void save(EMap map, {required File file, Encoding encoding = utf8}) {
    String s = map.toFileContent();
    file.writeAsStringSync(s, encoding: encoding);
  }

  static EMap load(File file, {Encoding encoding = utf8}) {
    String s = file.readAsStringSync(encoding: encoding);
    return _EParser(s, currentDir: pathUtil.dirname(file.path)).parse();
  }

  @Deprecated('Use load() instead.')
  static EMap parseFile(File file, {Encoding encoding = utf8}) {
    String s = file.readAsStringSync(encoding: encoding);
    return _EParser(s, currentDir: pathUtil.dirname(file.path)).parse();
  }

  static EMap parse(String text, {String? currentDir}) {
    return _EParser(text, currentDir: currentDir).parse();
  }
}

void _loge(String s) => EConfig.errorLog(s);
