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
      String key = ts.currentChar == CharCode.QUOTE ? _parseStringQuoted() : _parseKey();
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

  void _assignMap(EMap emap, String key, dynamic value) {
    println("assign, ", key, value);
    String firstChar = key[0];
    if (firstChar == "@") {
      if (key == "@include") {
        if (value case String s) {
          File? file = _includeFile(s.trim());
          if (file != null) {
            EMap inMap = EConfig.parseFile(file);
            emap.data.addAll(inMap.data);
          }
        } else if (value case EMap em) {
          String? filename = em['file'].stringValue;
          if (filename == null) return;
          File? file = _includeFile(filename);
          if (file != null) {
            String? charset = em['charset'].stringValue;
            EMap inMap = EConfig.parseFile(file, encoding: charset != null ? (Encoding.getByName(charset) ?? utf8) : utf8);
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
