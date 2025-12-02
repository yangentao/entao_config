part of 'config.dart';

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
    return _YsonParser(json).parse();
  }
}

class _YsonParser {
  static final Set<int> _ASSIGN = {CharCode.COLON, CharCode.EQUAL};
  static final Set<int> _SEP = {CharCode.COMMA, CharCode.SEMI, CharCode.CR, CharCode.LF};
  static final Set<int> _TRAIL = {CharCode.SP, CharCode.HTAB, CharCode.CR, CharCode.LF, CharCode.COMMA, CharCode.SEMI};
  final TextScanner _ts;

  _YsonParser(String json) : _ts = TextScanner(json);

  dynamic parse() {
    dynamic v = _parseValue();
    _ts.skipWhites();
    if (!_ts.isEnd) _raise();
    return v;
  }

  dynamic _parseValue() {
    _ts.skipWhites();
    if (_ts.isEnd) return null;
    int? ch = _ts.nowChar;
    switch (ch) {
      case null:
        return null;
      case CharCode.LCUB:
        return parseObject();
      case CharCode.LSQB:
        return parseArray();
      case CharCode.QUOTE:
        return _parseString();
      case CharCode.MINUS:
        return _parseNum();
      case >= CharCode.NUM0 && <= CharCode.NUM9:
        return _parseNum();
      case CharCode.n:
        _ts.expectString("null");
        return null;
      case CharCode.t:
        _ts.expectString("true");
        return true;
      case CharCode.f:
        _ts.expectString("false");
        return false;
      default:
        _raise();
    }
  }

  Map<String, dynamic> parseObject() {
    _ts.skipWhites();
    Map<String, dynamic> map = {};
    _ts.expectChar(CharCode.LCUB);
    _ts.skipWhites();
    while (_ts.nowChar != null && _ts.nowChar != CharCode.RCUB) {
      _ts.skipWhites();
      String key = _ts.nowChar == CharCode.QUOTE ? _parseString() : _parseIdent();
      _ts.skipWhites();
      _ts.expectAnyChar(_ASSIGN);
      // _ts.expectChar(CharCode.COLON);
      dynamic v = _parseValue();
      map[key] = v;
      List<int> trails = _ts.skipChars(_TRAIL);
      if (_ts.nowChar != null && _ts.nowChar != CharCode.RCUB) {
        if (trails.intersect(_SEP).isEmpty) _raise();
      }
    }
    _ts.expectChar(CharCode.RCUB);
    return map;
  }

  List<dynamic> parseArray() {
    _ts.skipWhites();
    List<dynamic> list = [];
    _ts.expectChar(CharCode.LSQB);
    _ts.skipWhites();
    while (_ts.nowChar != CharCode.RSQB) {
      _ts.skipWhites();
      dynamic v = _parseValue();
      list.add(v);
      List<int> trails = _ts.skipChars(_TRAIL);
      if (_ts.nowChar != CharCode.RSQB) {
        if (trails.intersect(_SEP).isEmpty) _raise();
      }
    }
    _ts.expectChar(CharCode.RSQB);
    return list;
  }

  num _parseNum() {
    List<int> buf = _ts.moveNext(acceptor: (e) => _isNum(e));
    String s = String.fromCharCodes(buf);
    num n = num.parse(s);
    return n;
  }

  String _parseIdent() {
    List<int> charList = _ts.expectIdent();
    if (charList.isEmpty) _raise();
    return String.fromCharCodes(charList);
  }

  String _parseString() {
    _ts.expectChar(CharCode.QUOTE);
    List<int> charList = _ts.moveNext(terminator: (e) => e == CharCode.QUOTE && _ts.matched.lastOrNull != CharCode.BSLASH);
    String s = _codesToString(charList);
    _ts.expectChar(CharCode.QUOTE);
    return s;
  }

  Never _raise([String msg = "Parse Error"]) {
    throw Exception("$msg. ${_ts.position}, ${_ts.rest}");
  }
}

Set<int> _WHITES = {CharCode.SP, CharCode.HTAB, CharCode.CR, CharCode.LF};
Set<int> _SPTAB = {CharCode.SP, CharCode.HTAB};

extension _TextScannerExt on TextScanner {
  List<int> skipWhites() {
    return skipChars(_WHITES);
  }

  void skipSpTab() {
    skipChars(_SPTAB);
  }
}

bool _isNum(int ch) {
  if (ch >= CharCode.NUM0 && ch <= CharCode.NUM9) return true;
  return ch == CharCode.DOT || ch == CharCode.MINUS || ch == CharCode.PLUS || ch == CharCode.e || ch == CharCode.E;
}

String _codesToString(List<int> charList) {
  List<int> buf = [];
  bool escaping = false;
  int i = 0;
  while (i < charList.length) {
    int ch = charList[i];
    if (!escaping) {
      if (ch == CharCode.BSLASH) {
        escaping = true;
      } else {
        buf.add(ch);
      }
    } else {
      escaping = false;
      switch (ch) {
        case CharCode.SQUOTE || CharCode.BSLASH || CharCode.SLASH:
          buf.add(ch);
        case CharCode.b:
          buf.add(CharCode.BS);
        case CharCode.f:
          buf.add(CharCode.FF);
        case CharCode.n:
          buf.add(CharCode.LF);
        case CharCode.r:
          buf.add(CharCode.CR);
        case CharCode.t:
          buf.add(CharCode.HTAB);
        case CharCode.u || CharCode.U:
          List<int> uls = [];
          i += 1;
          if (i < charList.length && charList[i] == CharCode.PLUS) {
            i += 1;
          }
          while (i < charList.length && uls.length < 4 && CharCode.isHex(charList[i])) {
            uls.add(charList[i]);
            i += 1;
          }
          if (uls.length != 4) throw Exception("Convert to string failed: ${String.fromCharCodes(charList)}.");
          String s = String.fromCharCodes(uls);
          int n = int.parse(s, radix: 16);
          buf.addAll(String.fromCharCode(n).codeUnits);
          i -= 1;
        default:
          buf.add(ch);
      }
    }
    i += 1;
  }
  return String.fromCharCodes(buf);
}

String _encodeJsonString(String s) {
  List<int> chars = s.codeUnits;
  List<int> buf = [];
  int i = 0;
  while (i < chars.length) {
    int ch = chars[i];
    if (ch < 32) {
      switch (ch) {
        case CharCode.BS:
          buf.add(CharCode.BSLASH);
          buf.add(CharCode.b);
        case CharCode.FF:
          buf.add(CharCode.BSLASH);
          buf.add(CharCode.f);
        case CharCode.LF:
          buf.add(CharCode.BSLASH);
          buf.add(CharCode.n);
        case CharCode.CR:
          buf.add(CharCode.BSLASH);
          buf.add(CharCode.r);
        case CharCode.HTAB:
          buf.add(CharCode.BSLASH);
          buf.add(CharCode.t);
        default:
          buf.add(CharCode.BSLASH);
          buf.add(CharCode.u);
          buf.add(CharCode.NUM0);
          buf.add(CharCode.NUM0);
          buf.add(_lastHex(ch >> 4));
          buf.add(_lastHex(ch));
      }
    } else if (ch > _utf16Lead && (i + 1 < chars.length) && _isUtf16(ch, chars[i + 1])) {
      buf.add(CharCode.BSLASH);
      buf.add(CharCode.u);
      buf.add(CharCode.d);
      buf.add(_lastHex(ch >> 8));
      buf.add(_lastHex(ch >> 4));
      buf.add(_lastHex(ch));

      int cc = chars[i + 1];
      buf.add(CharCode.BSLASH);
      buf.add(CharCode.u);
      buf.add(CharCode.d);
      buf.add(_lastHex(cc >> 8));
      buf.add(_lastHex(cc >> 4));
      buf.add(_lastHex(cc));
      i += 1;
    } else {
      switch (ch) {
        case CharCode.SQUOTE:
          buf.add(CharCode.BSLASH);
          buf.add(CharCode.SQUOTE);
        case CharCode.BSLASH:
          buf.add(CharCode.BSLASH);
          buf.add(CharCode.BSLASH);
        case CharCode.SLASH:
          buf.add(CharCode.BSLASH);
          buf.add(CharCode.SLASH);
        default:
          buf.add(ch);
      }
    }
    i += 1;
  }
  return String.fromCharCodes(buf);
}

// '0' + x  or  'a' + x - 10
int _hex4(int x) => x < 10 ? 48 + x : 87 + x;

int _lastHex(int x) => _hex4(x & 0x0F);

int _utf16Lead = 0xD800; // 110110 00
int _utf16Trail = 0xDC00; // 110111 00
int _utf16Mask = 0xFC00; // 111111 00

bool _isUtf16(int a, int b) {
  return (a & _utf16Mask == _utf16Lead) && (b & _utf16Mask == _utf16Trail);
}
