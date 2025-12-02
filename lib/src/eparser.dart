part of 'econfig.dart';

//  \, ", ',  ',',  CR, LF, =, :
class _EParser {
  static final Set<int> _ASSIGN = {CharCode.COLON, CharCode.EQUAL};
  static final Set<int> _LN_COMMA = {CharCode.CR, CharCode.LF, CharCode.COMMA};
  static final Set<int> _WHITE_COMMA = {CharCode.SP, CharCode.HTAB, CharCode.CR, CharCode.LF, CharCode.COMMA};
  final TextScanner ts;

  _EParser(String text) : ts = TextScanner(text);

  Map<String, dynamic> parse() {
    Map<String, dynamic> map = {};
    while (ts.notEnd) {
      ts.skipWhites();
      if (ts.isEnd) break;
      if (ts.currentChar == CharCode.AT) {
        _parseAt();
        // TODO @xxx
      } else {
        String key = ts.currentChar == CharCode.QUOTE ? _parseStringQuoted() : _parseKey();
        ts.skipSpTab();
        ts.expectAnyChar(_ASSIGN);
        dynamic v = _parseValue();
        map[key] = v;
        List<int> trails = ts.skipChars(_WHITE_COMMA);
        if (ts.notEnd) {
          if (trails.intersect(_LN_COMMA).isEmpty) _raise();
        }
      }
    }
    return map;
  }

  dynamic _parseValue() {
    ts.skipWhites();
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

  Map<String, dynamic> parseObject() {
    ts.skipWhites();
    Map<String, dynamic> map = {};
    ts.expectChar(CharCode.LCUB);
    ts.skipWhites();
    while (ts.nowChar != null && ts.nowChar != CharCode.RCUB) {
      ts.skipWhites();
      if (ts.isEnd) break;
      String key = ts.nowChar == CharCode.QUOTE ? _parseStringQuoted() : _parseKey();
      ts.skipWhites();
      ts.expectAnyChar(_ASSIGN);
      dynamic v = _parseValue();
      map[key] = v;
      List<int> trails = ts.skipChars(_WHITE_COMMA);
      if (ts.nowChar != null && ts.nowChar != CharCode.RCUB) {
        if (trails.intersect(_LN_COMMA).isEmpty) _raise();
      }
    }
    ts.expectChar(CharCode.RCUB);
    return map;
  }

  List<dynamic> parseArray() {
    ts.skipWhites();
    List<dynamic> list = [];
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
    return list;
  }

  // @xxx
  String _parseAt() {
    ts.expectChar(CharCode.AT);
    List<int> buf = ts.moveNext(acceptor: (e) => CharCode.isAlpha(e));
    return String.fromCharCodes(buf);
  }

  String _parseAtValue() {
    ts.expectChar(CharCode.AT);
    List<int> buf = ts.moveNext(acceptor: (e) => CharCode.isAlpha(e));
    return String.fromCharCodes(buf);
  }

  String _parseKey() {
    List<int> charList = ts.moveNext(acceptor: (e) => ts.matched.isEmpty ? (CharCode.isAlpha(e) || e == CharCode.LOWBAR) : (CharCode.isIdent(e) || e == CharCode.DOT));
    if (charList.isEmpty) _raise();
    return String.fromCharCodes(charList);
  }

  String _parseStringQuoted() {
    ts.expectChar(CharCode.QUOTE);
    List<int> charList = ts.moveUntil(const [CharCode.QUOTE, CharCode.CR, CharCode.LF], escapeChar: CharCode.BSLASH);
    String s = _codesToString(charList);
    ts.expectChar(CharCode.QUOTE);
    return s;
  }

  String _parseString() {
    List<int> charList = ts.moveUntil(_LN_COMMA, escapeChar: CharCode.BSLASH);
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

final Map<int, int> _unescapeChars = _escapeChars.map((k, v) => MapEntry(v, k));
const Map<int, int> _escapeChars = {
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
