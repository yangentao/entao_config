part of 'config.dart';

class _EParser {
  final List<int> data;
  int _current = 0;

  _EParser(String text) : data = text.codeUnits;

  bool get _end {
    if (_current >= data.length) return true;
    if (data[_current] == CharCode.SHARP && CharCode.BSLASH != _preChar) {
      while (_current < data.length && !data[_current].isCRLF) {
        _current += 1;
      }
    }
    return _current >= data.length;
  }

  int get _currentChar => data[_current];

  int? get _preChar => data.getOr(_current - 1);

  int _firstChar() {
    _skipSpTabCrLf();
    if (_end) return 0;
    return _currentChar;
  }

  /// object OR array
  EValue parse() {
    int ch = _firstChar();
    if (ch == 0) return EnNull.inst;
    if (ch == CharCode.LSQB) return parseArray();
    return parseObject(isRoot: ch != CharCode.LCUB);
  }

  EValue _parseValue() {
    _skipSpTab();
    if (_end) return EnNull.inst;
    int ch = _currentChar;
    switch (ch) {
      case CharCode.LCUB:
        return parseObject();
      case CharCode.LSQB:
        return parseArray();
      case CharCode.t:
        String s = _parseIdent().toLowerCase();
        if (s == "true") return EnBool(true);
        if (s == "false") return EnBool(false);
        _parseError("Except true or false. ");
      case CharCode.n:
        String s = _parseIdent().toLowerCase();
        if (s == "null") return EnNull.inst;
        _parseError("Except null.  ");
      case >= CharCode.NUM0 && <= CharCode.NUM9:
        String s = _parseNum();
        if (s.contains(".")) {
          double v = s.toDouble ?? _parseError("Expect double value. ");
          return EnDouble(v);
        } else {
          int v = s.toInt ?? _parseError("Expect double value. ");
          return EnInt(v);
        }
      case CharCode.QUOTE || CharCode.SQUOTE:
        String s = _parseString(ch);
        return EnString(s);
      default:
        _parseError("parse error.");
    }
  }

  EValue parseArray() {
    _skipSpTab();
    _tokenc([CharCode.LSQB]);
    _skipSpTabCrLf();
    EList ya = EList();
    while (!_end) {
      _skipSpTabCrLf();
      if (_currentChar == CharCode.RSQB) break;
      var v = _parseValue();
      ya.data.add(v);
      if (_SEPS.contains(_currentChar)) {
        _next();
        continue;
      }
    }
    _tokenc([CharCode.RSQB]);
    return ya;
  }

  EMap parseObject({bool isRoot = false}) {
    _skipSpTab();
    if (!isRoot) {
      _tokenc([CharCode.LCUB]);
      _skipSpTabCrLf();
    }
    EMap yo = EMap();
    while (!_end) {
      _skipSpTab();
      if (_end) break;
      if (_currentChar == CharCode.RCUB) {
        _skipSpTabCrLf();
        break;
      }
      if (_SEPS.contains(_currentChar)) {
        _next();
        continue;
      }
      String key = _parseIdent();
      if (key.isEmpty) _parseError("Key is empty.");
      _tokenc([CharCode.COLON, CharCode.EQUAL]);
      var yv = _parseValue();
      yo.setPath(key, yv);
    }
    if (!isRoot) _tokenc([CharCode.RCUB]);
    _skipSpTabCrLf();
    return yo;
  }

  String _parseNum() {
    _skipSpTab();
    StringBuffer buf = StringBuffer();
    while (!_end) {
      int ch = _currentChar;
      switch (ch) {
        case >= CharCode.NUM0 && <= CharCode.NUM9:
          buf.writeCharCode(ch);
          _next();
        case CharCode.DOT:
          buf.writeCharCode(ch);
          _next();
        default:
          if (buf.isEmpty) _parseError("Expect ident.");
          return buf.toString();
      }
    }
    if (buf.isEmpty) _parseError("Expect ident.");
    return buf.toString();
  }

  String _parseIdent() {
    _skipSpTab();
    StringBuffer buf = StringBuffer();
    while (!_end) {
      int ch = _currentChar;
      switch (ch) {
        case >= CharCode.A && <= CharCode.Z:
          buf.writeCharCode(ch);
          _next();
        case >= CharCode.a && <= CharCode.z:
          buf.writeCharCode(ch);
          _next();
        case CharCode.LOWBAR:
          buf.writeCharCode(ch);
          _next();
        default:
          if (buf.isEmpty) _parseError("Expect ident.");
          return buf.toString();
      }
    }
    if (buf.isEmpty) _parseError("Expect ident.");
    return buf.toString();
  }

  String _parseString(int quoteChar) {
    _skipSpTab();
    _tokenc([quoteChar]);
    StringBuffer buf = StringBuffer();
    bool escing = false;
    while (!_end) {
      if (!escing) {
        if (_currentChar == quoteChar) {
          _skip();
          String s = buf.toString();
          return s;
        }
        if (_currentChar == CharCode.BSLASH) {
          escing = true;
        } else {
          buf.writeCharCode(_currentChar);
        }
        _next();
        continue;
      }

      escing = false;

      int ch = _currentChar;
      switch (ch) {
        case CharCode.SLASH:
          buf.writeCharCode(ch);
        case CharCode.b:
          buf.write(CharCode.BS);
        case CharCode.f:
          buf.writeCharCode(CharCode.FF);
        case CharCode.n:
          buf.writeCharCode(CharCode.LF);
        case CharCode.r:
          buf.writeCharCode(CharCode.CR);
        case CharCode.t:
          buf.writeCharCode(CharCode.HTAB);
        case CharCode.u:
        case CharCode.U:
          _skip();
          if (!_end && _currentChar == CharCode.PLUS) {
            _skip();
          }
          ListInt sb = [];
          while (!_end && _currentChar.isHex) {
            sb.add(_currentChar);
            _next();
          }
          if (sb.isEmpty) {
            _parseError("parse unicode failed.");
          }
          String s = String.fromCharCodes(sb);
          int? nval = int.tryParse(s, radix: 16);
          if (nval == null) {
            _parseError("parse unicode failed.");
          } else {
            _current -= 1;
            buf.write(nval.charCodeString);
          }
        default:
          buf.writeCharCode(ch);
      }
      _next();
    }
    if (escing) {
      _parseError("解析错误,转义.");
    }
    return buf.toString().trim();
  }

  void _tokenc(List<int> cs) {
    _skipSpTab();
    if (_end) {
      _parseError("Expect ${cs.map((e) => e.charCodeString)}, but text is end.");
    }
    if (!cs.contains(_currentChar)) {
      _parseError("Expect char:${cs.map((e) => e.charCodeString)}");
    }
    _next();
    _skipSpTab();
  }

  void _tokens(String tk) {
    _skipSpTab();
    for (int ch in tk.codeUnits) {
      if (_end || _currentChar != ch) {
        _parseError("Expect $tk.");
      }
      _next();
    }
  }

  void _next() {
    _current += 1;
  }

  void _skip([int size = 1]) {
    _current += size;
  }

  void _skipSpTabCrLf() {
    while (!_end) {
      if (_currentChar.isWhite) {
        _next();
      } else {
        return;
      }
    }
  }

  void _skipSpTab() {
    while (!_end) {
      if (_currentChar.isSpTab) {
        _next();
      } else {
        return;
      }
    }
  }

  Never _parseError([String msg = "YConfigParser Error"]) {
    if (!_end) throw Exception("$msg: position: $_current, char: ${String.fromCharCode(_currentChar)}, left text:$_leftString");
    throw Exception(msg);
  }

  String get _leftString {
    if (_current >= data.length) return "";
    StringBuffer sb = StringBuffer();
    int n = 0;
    while (n < 20) {
      if (_current + n >= data.length) break;
      sb.writeCharCode(data[_current + n]);
      n += 1;
    }
    return sb.toString();
  }
}

String _enEscape(String s) {
  List<int> codes = s.codeUnits;
  StringBuffer sb = StringBuffer();
  for (int i = 0; i < codes.length; ++i) {
    int c = codes[i];
    if (_ESCAPES.contains(c)) {
      sb.writeCharCode(CharCode.BSLASH);
    }
    sb.writeCharCode(c);
  }
  return sb.toString();
}

const Set<int> _WHITES = {CharCode.CR, CharCode.LF, CharCode.SP, CharCode.HTAB};
const Set<int> _BRACKETS = {CharCode.LCUB, CharCode.RCUB, CharCode.LSQB, CharCode.RSQB};
const Set<int> _ASSIGNS = {CharCode.COLON, CharCode.EQUAL};
const Set<int> _SEPS = {CharCode.CR, CharCode.LF, CharCode.SEMI, CharCode.COMMA};
Set<int> _END_VALUE = _SEPS.union(_BRACKETS); //TODO string value 允许出现[]{}
Set<int> _END_KEY = _END_VALUE.union(_ASSIGNS);
Set<int> _ESCAPES = _END_KEY.union({CharCode.BSLASH});

extension _IntHexExt on int {
  bool get isHex {
    return (this >= 48 && this <= 57) || (this >= 65 && this <= 90) || (this >= 97 && this <= 122);
  }

  bool get isWhite => _WHITES.contains(this);

  bool get isSpTab => this == CharCode.SP || this == CharCode.HTAB;

  bool get isCRLF => this == CharCode.CR || this == CharCode.LF;

  String get charCodeString => String.fromCharCode(this);
}

extension _StringBufferExt on StringBuffer {
  StringBuffer space(int n) {
    for (int i = 1; i < n * 4; ++i) {
      writeCharCode(CharCode.SP);
    }
    return this;
  }
}
