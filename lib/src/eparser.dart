part of 'econfig.dart';

class _EParser {
  static const Set<int> _ASSIGN = {CharCode.COLON, CharCode.EQUAL};
  static const Set<int> _LN_COMMA = {CharCode.CR, CharCode.LF, CharCode.COMMA};
  static const Set<int> _WHITE_COMMA = {CharCode.SP, CharCode.HTAB, CharCode.CR, CharCode.LF, CharCode.COMMA};

  // static const Set<int> _STR_STOP = {CharCode.CR, CharCode.LF, CharCode.COMMA, CharCode.RCUB, CharCode.RSQB};
  static const Set<int> _STR_STOP_IN_LIST = {CharCode.CR, CharCode.LF, CharCode.COMMA, CharCode.RSQB};
  static const Set<int> _STR_STOP_IN_MAP = {CharCode.CR, CharCode.LF, CharCode.COMMA, CharCode.RCUB};
  final TextScanner ts;
  final String cwd;
  final Stack<Object> scope = Stack();

  // ignore: unused_element_parameter
  _EParser(String text, {this.cwd = ""}) : ts = TextScanner(text);

  EMap parse() {
    EMap map = EMap();
    scope.push(map);
    while (ts.notEnd) {
      ts.skipWhites();
      if (ts.isEnd) break;
      String key;
      int ch = ts.currentChar;
      switch (ch) {
        case CharCode.AT:
          key = _parseKey();
        case CharCode.DOLLAR:
          key = _parseKey();
        case CharCode.QUOTE:
          key = _parseStringQuoted();
        default:
          key = _parseKey();
      }
      ts.skipSpTab();
      ts.expectAnyChar(_ASSIGN);
      dynamic v = _parseValue();
      _assignMap(map, key, v);
      List<int> trails = ts.skipChars(_WHITE_COMMA);
      if (ts.notEnd) {
        if (trails.intersect(_LN_COMMA).isEmpty) _raise();
      }
    }
    scope.pop();
    return map;
  }

  void _assignMap(EMap emap, String key, dynamic value) {
    println("assign, ", key, value);
    String firstChar = key[0];
    if (firstChar == "@") {
      // todo
    } else if (firstChar == r"$") {
      String newKey = key.substring(1);
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
    } else {
      switch (value) {
        case "@null":
          emap[key] = nullValue;
        case "@empty":
          emap[key] = "";
        case "@remove":
          emap.remove(key);
        default:
          emap[key] = value;
      }
    }
  }

  String _parseKey() {
    List<int> charList = ts.moveNext(acceptor: (e) => CharCode.isIdent(e) || e == CharCode.DOT || e == CharCode.DOLLAR || e == CharCode.AT || e == CharCode.MINUS);
    if (charList.isEmpty) _raise();
    return String.fromCharCodes(charList);
  }

  EMap parseObject() {
    ts.skipWhites();
    EMap map = EMap();
    scope.push(map);
    ts.expectChar(CharCode.LCUB);
    ts.skipWhites();
    while (ts.nowChar != null && ts.nowChar != CharCode.RCUB) {
      ts.skipWhites();
      if (ts.isEnd) break;
      String key = ts.nowChar == CharCode.QUOTE ? _parseStringQuoted() : _parseKey();
      ts.skipSpTab();
      ts.expectAnyChar(_ASSIGN);
      dynamic v = _parseValue();
      map[key] = v;
      List<int> trails = ts.skipChars(_WHITE_COMMA);
      if (ts.nowChar != null && ts.nowChar != CharCode.RCUB) {
        if (trails.intersect(_LN_COMMA).isEmpty) _raise();
      }
    }
    ts.expectChar(CharCode.RCUB);
    scope.pop();
    return map;
  }

  dynamic _parseValue() {
    ts.skipSpTab();
    if (ts.isEnd) return null;
    switch (ts.currentChar) {
      case CharCode.LCUB:
        return parseObject();
      case CharCode.LSQB:
        return parseArray();
      case CharCode.AT:
        return _parseAtValue();
      case CharCode.QUOTE:
        return _parseStringQuoted();
      default:
        return _parseString();
    }
  }

  EList parseArray() {
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
