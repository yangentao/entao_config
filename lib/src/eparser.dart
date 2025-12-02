part of 'econfig.dart';

class _EParser {
  static const Set<int> _ASSIGN = {CharCode.COLON, CharCode.EQUAL};
  static const Set<int> _LN_COMMA = {CharCode.CR, CharCode.LF, CharCode.COMMA};
  static const Set<int> _WHITE_COMMA = {CharCode.SP, CharCode.HTAB, CharCode.CR, CharCode.LF, CharCode.COMMA};

  // static const Set<int> _STR_STOP = {CharCode.CR, CharCode.LF, CharCode.COMMA, CharCode.RCUB, CharCode.RSQB};
  static const Set<int> _STR_STOP_IN_LIST = {CharCode.CR, CharCode.LF, CharCode.COMMA, CharCode.RSQB};
  static const Set<int> _STR_STOP_IN_MAP = {CharCode.CR, CharCode.LF, CharCode.COMMA, CharCode.RCUB};
  final TextScanner ts;
  final String? currentDir;
  final Stack<Object> scope = Stack();

  // ignore: unused_element_parameter
  _EParser(String text, {this.currentDir}) : ts = TextScanner(text);

  EMap parse() {
    return parseObject(root: true);
  }

  EMap parseObject({bool root = false}) {
    EMap map = EMap();
    scope.push(map);

    if (!root) {
      ts.skipWhites();
      ts.expectChar(CharCode.LCUB);
      ts.skipWhites();
    }
    while (!_isObjectEnd(root)) {
      ts.skipWhites();
      if (ts.isEnd) break;
      String key;
      switch (ts.currentChar) {
        case CharCode.QUOTE:
          key = _parseStringQuoted();
        case CharCode.AT:
          if (ts.peek("@if ")) {
            ts.skip(size: 4);
            ts.skipSpTab();
            key = _parseKey();
            ts.skipSpTab();
            List<String> opList = const ["@=", "=@", ">=", "<=", "!=", "=", ">", "<"];
            int index = ts.expectAnyString(opList);
            dynamic v = _parseValue();
            _ifProcess(map, key, opList[index], v);
            continue;
          } else if (ts.peek("@end")) {
            ts.skip(size: 4);
            if (ts.notEnd) ts.expectAnyChar(CharCode.SP_TAB_CR_LF);
            continue;
          } else if (ts.peek("@else")) {
            ts.skip(size: 5);
            ts.expectAnyChar(CharCode.SP_TAB_CR_LF);
            ts.moveUntilString("@end", escapeChar: CharCode.BSLASH);
            ts.skip(size: 4);
            if (ts.notEnd) ts.expectAnyChar(CharCode.SP_TAB_CR_LF);
            continue;
          } else {
            key = _parseKey();
          }

        default:
          key = _parseKey();
      }
      ts.skipSpTab();
      ts.expectAnyChar(_ASSIGN);
      dynamic v = _parseValue();
      _assignMap(map, key, v);
      List<int> trails = ts.skipChars(_WHITE_COMMA);
      if (!_isObjectEnd(root)) {
        if (trails.intersect(_LN_COMMA).isEmpty) _raise();
      }
    }
    if (!root) {
      ts.expectChar(CharCode.RCUB);
    }
    scope.pop();
    return map;
  }

  bool _cmpString(EValue ev, String op, dynamic value) {
    if (ev is! EString) return false;
    if (value is! String) return false;
    String s1 = ev.data;
    String s2 = value;
    if (s1.allNum && s2.allNum) {
      if (s1.contains(".") || s2.contains(".")) {
        double? d1 = s1.toDouble;
        double? d2 = s2.toDouble;
        if (d1 != null && d2 != null) {
          switch (op) {
            case ">=":
              return d1 >= d2;
            case "<=":
              return d1 <= d2;
            case ">":
              return d1 > d2;
            case "<":
              return d1 < d2;
          }
        }
      } else {
        int? n1 = s1.toInt;
        int? n2 = s2.toInt;
        if (n1 != null && n2 != null) {
          switch (op) {
            case ">=":
              return n1 >= n2;
            case "<=":
              return n1 <= n2;
            case ">":
              return n1 > n2;
            case "<":
              return n1 < n2;
          }
        }
      }
    }
    switch (op) {
      case ">=":
        return s1.compareTo(s2) >= 0;
      case "<=":
        return s1.compareTo(s2) <= 0;
      case ">":
        return s1.compareTo(s2) > 0;
      case "<":
        return s1.compareTo(s2) < 0;
    }
    raise("Unsupport operator: $op");
  }

  bool _cmpContains(EValue ev, String op, dynamic value) {
    if (value == null) {
      return ev is ENull;
    }
    if (ev is ENull) return false;
    if (ev is EString) {
      if (op == "@=") {
        if (value is String) {
          return ev.data.contains(value);
        }
      } else if (op == "=@") {
        if (value is String) {
          return value.contains(ev.data);
        } else if (value is EList) {
          return value.any((a) => a.equal(ev));
        } else if (value is EMap) {
          return value.data.containsKey(ev.data);
        }
      }
    }
    if (ev is EList) {
      if (op == "@=") {
        if (value is String) {
          return ev.any((a) => a.equal(value));
        } else if (value is EList) {
          for (final a in value.data) {
            if (!ev.any((b) => b.equal(a))) return false;
          }
          return true;
        }
      } else if (op == "=@") {
        if (value is EList) {
          for (final a in ev.data) {
            if (!value.any((b) => b.equal(a))) return false;
          }
          return true;
        }
      }
    }
    if (ev is EMap) {
      if (op == "@=") {
        if (value is String) {
          return ev.data.containsKey(value);
        }
      }
    }
    raise("NOT support operator: $op");
  }

  void _ifProcess(EMap emap, String key, String op, dynamic value) {
    println(key, op, value);
    if (key.startsWith(r"$")) key = key.substring(1);
    EValue ev = emap.path(key);
    bool result = false;
    switch (op) {
      case "=":
        result = ev.equal(value);
      case "!=":
        result = !ev.equal(value);
      case "@=":
        result = _cmpContains(ev, op, value);
      case "=@":
        result = _cmpContains(ev, op, value);
      default:
        result = _cmpString(ev, op, value);
    }

    if (!result) {
      int n = ts.moveUntilAnyString(const ["@else", "@end"], escapeChar: CharCode.BSLASH);
      if (n < 0) {
        raise("@if but no @else or @end");
      }
      ts.skip(size: n == 0 ? 5 : 4);
      if (ts.notEnd) {
        ts.expectAnyChar(CharCode.SP_TAB_CR_LF);
      }
    }
  }

  bool _isObjectEnd(bool root) {
    if (root) return ts.isEnd;
    return ts.isEnd || ts.nowChar == CharCode.RCUB;
  }

  File? _includeFile(String name) {
    if (name.isEmpty) return null;
    if (pathUtil.isAbsolute(name)) return File(name);
    if (currentDir == null || currentDir!.isEmpty) return File(name);
    return File(pathUtil.join(currentDir!, name));
  }

  Encoding _includeCharset(EMap em) {
    String? charset = em['charset'].stringValue;
    if (charset == null || charset.isEmpty) return utf8;
    if (charset == "system") return systemEncoding;
    return Encoding.getByName(charset) ?? utf8;
  }

  void _include(EMap emap, String key, dynamic value) {
    if (value case String s) {
      File? file = _includeFile(s.trim());
      if (file != null) {
        EMap inMap = EConfig.parseFile(file);
        emap.data.addAll(inMap.data);
      } else {
        _loge("read file error: $s");
      }
      return;
    }
    if (value case EMap em) {
      String? filename = em['file'].stringValue;
      if (filename == null) {
        _loge("no file name in @include params");
        return;
      }
      File? file = _includeFile(filename);
      if (file == null) {
        _loge("read file error: $filename");
        return;
      }
      EMap inMap = EConfig.parseFile(file, encoding: _includeCharset(em));
      List<String>? keys = em['keys'].stringList;
      List<String>? excludes = em['excludes'].stringList;
      Set<String> keySet = inMap.data.keys.toSet();
      if (keys != null && keys.isNotEmpty) {
        keySet.retainAll(keys);
      }
      if (excludes != null && excludes.isNotEmpty) {
        keySet.removeAll(excludes);
      }
      for (String k in keySet) {
        emap.data[k] = inMap[k];
      }
    }
  }

  void _assignMap(EMap emap, String key, dynamic value) {
    // println("assign, ", key, value);
    String firstChar = key[0];
    if (firstChar == "@") {
      if (key == "@include") {
        _include(emap, key, value);
      }
      return;
    }
    String newKey = firstChar == r"$" ? key.substring(1) : key;
    switch (value) {
      case "@null":
        emap.setPath(newKey, nullValue);
      case "@empty":
        emap.setPath(newKey, "");
      case "@remove":
        emap.removePath(newKey);
      default:
        emap.setPath(newKey, value);
    }
  }

  String _parseKey() {
    List<int> charList = ts.moveNext(acceptor: (e) => CharCode.isIdent(e) || e == CharCode.DOT || e == CharCode.DOLLAR || e == CharCode.AT || e == CharCode.MINUS);
    if (charList.isEmpty) _raise();
    return String.fromCharCodes(charList);
  }

  dynamic _parseValue() {
    ts.skipSpTab();
    if (ts.isEnd) return null;
    switch (ts.currentChar) {
      case CharCode.LCUB:
        return parseObject();
      case CharCode.LSQB:
        return _parseArray();
      case CharCode.AT:
        return _parseAtValue();
      case CharCode.QUOTE:
        return _parseStringQuoted();
      default:
        return _parseString();
    }
  }

  EList _parseArray() {
    ts.skipWhites();
    EList list = EList();
    scope.push(list);
    ts.expectChar(CharCode.LSQB);
    while (ts.nowChar != CharCode.RSQB) {
      ts.skipWhites();
      dynamic v = _parseValue();
      list.add(v);
      List<int> trails = ts.skipChars(_WHITE_COMMA);
      if (ts.nowChar != CharCode.RSQB) {
        if (trails.intersect(_LN_COMMA).isEmpty) _raise();
      }
    }
    ts.expectChar(CharCode.RSQB);
    scope.pop();
    return list;
  }

  String _parseAtValue() {
    List<int> buf = ts.moveNext(acceptor: (e) => ts.matched.isEmpty ? e == CharCode.AT : CharCode.isAlpha(e));
    return String.fromCharCodes(buf);
  }

  String _parseStringQuoted() {
    ts.expectChar(CharCode.QUOTE);
    List<int> charList = ts.moveUntilChar(CharCode.QUOTE, escapeChar: CharCode.BSLASH);
    String s = _codesToString(charList);
    ts.expectChar(CharCode.QUOTE);
    return s;
  }

  String _parseString() {
    Set<int> untilSet = scope.peek() is EMap ? _STR_STOP_IN_MAP : _STR_STOP_IN_LIST;
    List<int> charList = ts.moveUntil(untilSet, escapeChar: CharCode.BSLASH);
    if (charList.isEmpty) return "";
    String s = _codesToString(charList);
    return s;
  }

  Never _raise([String msg = "Parse Error"]) {
    throw Exception("$msg. ${ts.position}, ${ts.rest}");
  }
}

String _codesToString(List<int> charList) {
  return unescapeCharCodes(charList, map: _unescapeChars);
}

final Map<int, int> _escapeChars = _unescapeChars.map((k, v) => MapEntry(v, k));
const Map<int, int> _unescapeChars = {
  CharCode.BSLASH: CharCode.BSLASH,
  CharCode.SQUOTE: CharCode.SQUOTE,
  CharCode.QUOTE: CharCode.QUOTE,
  CharCode.NUM0: CharCode.NUL,
  CharCode.BEL: CharCode.BEL,
  CharCode.b: CharCode.BS,
  CharCode.t: CharCode.HTAB,
  CharCode.r: CharCode.CR,
  CharCode.n: CharCode.LF,
  CharCode.SEMI: CharCode.SEMI,
  CharCode.SHARP: CharCode.SHARP,
  CharCode.EQUAL: CharCode.EQUAL,
  CharCode.COLON: CharCode.COLON,
  CharCode.COMMA: CharCode.COMMA,
  CharCode.LCUB: CharCode.LCUB,
  CharCode.RCUB: CharCode.RCUB,
  CharCode.LSQB: CharCode.LSQB,
  CharCode.RSQB: CharCode.RSQB,
  CharCode.AT: CharCode.AT,
};

extension _StringIsNumExt on String {
  bool get allNum {
    for (int c in this.codeUnits) {
      if (!_isNum(c)) return false;
    }
    return true;
  }
}

bool _isNum(int c) {
  return CharCode.isNum(c) || c == CharCode.DOT || c == CharCode.MINUS || c == CharCode.PLUS || c == CharCode.e || c == CharCode.E;
}
