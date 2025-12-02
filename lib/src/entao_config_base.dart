import 'package:entao_dutil/entao_dutil.dart';

class EnConfig {
  EnConfig._();

  //map or list
  static EnValue? tryParse(String text, {bool allowKeyPath = true}) {
    try {
      var v = parse(text, allowKeyPath: allowKeyPath);
      return v.isNull ? null : v;
    } catch (e) {
      return null;
    }
  }

  //map or list
  static EnValue parse(String text, {bool allowKeyPath = true}) {
    _EnConfigParser p = _EnConfigParser(text, allowKeyPath: allowKeyPath);
    return p.parse();
  }

  static String escape(String value) {
    return _enEscape(value);
  }
}

extension StrignEnExt on String {
  String get enEscaped => _enEscape(this);
}

class _EnConfigParser {
  final bool allowKeyPath;
  final List<int> data;
  int _current = 0;

  _EnConfigParser(String text, {this.allowKeyPath = true}) : data = text.codeUnits;

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
  EnValue parse() {
    int ch = _firstChar();
    if (ch == 0) return EnNull.inst;
    if (ch == CharCode.LSQB) return parseArray();
    return parseObject(isRoot: ch != CharCode.LCUB);
  }

  EnValue _parseValue() {
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

  EnValue parseArray() {
    _skipSpTab();
    _tokenc([CharCode.LSQB]);
    _skipSpTabCrLf();
    EnList ya = EnList();
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

  EnMap parseObject({bool isRoot = false}) {
    _skipSpTab();
    if (!isRoot) {
      _tokenc([CharCode.LCUB]);
      _skipSpTabCrLf();
    }
    EnMap yo = EnMap();
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
      if (allowKeyPath) {
        yo.setPath(key, yv);
      } else {
        yo.data[key] = yv;
      }
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

class EnMap extends EnValue with Iterable<MapEntry<String, EnValue>> {
  Map<String, EnValue> data = {};

  @override
  Iterator<MapEntry<String, EnValue>> get iterator => data.entries.iterator;

  @override
  String toString() {
    return serialize(pretty: false);
  }

  @override
  void serializeTo(StringBuffer buf) {
    buf.write("{");
    bool first = true;
    for (var e in data.entries) {
      if (!first) buf.write(", ");
      first = false;
      buf.write(e.key);
      buf.write(":");
      e.value.serializeTo(buf);
    }
    buf.write("}");
  }

  @override
  void serializePretty(StringBuffer buf, int ident) {
    buf.write("{");
    if (data.isEmpty) {
      buf.write("}");
      return;
    }
    buf.writeCharCode(CharCode.LF);
    for (var e in data.entries) {
      buf.space(ident + 1).write(e.key);
      buf.write(":");
      e.value.serializePretty(buf, ident + 1);
      buf.writeCharCode(CharCode.LF);
    }
    buf.space(ident);
    buf.write("}");
  }
}

class EnList extends EnValue with Iterable<EnValue> {
  List<EnValue> data = [];

  List<bool> get boolList {
    return data.mapList((e) => e.asBool?.data).nonNullList;
  }

  List<int> get intList {
    return data.mapList((e) => e.asInt?.data).nonNullList;
  }

  List<double> get doubleList {
    return data.mapList((e) => e.asDouble?.data).nonNullList;
  }

  List<String> get stringList {
    return data.mapList((e) => e.asString?.data).nonNullList;
  }

  @override
  Iterator<EnValue> get iterator => data.iterator;

  @override
  String toString() {
    return serialize(pretty: false);
  }

  @override
  void serializeTo(StringBuffer buf) {
    buf.writeCharCode(CharCode.LSQB);
    bool first = true;
    for (var e in data) {
      if (!first) buf.write(", ");
      first = false;
      e.serializeTo(buf);
    }
    buf.writeCharCode(CharCode.RSQB);
  }

  @override
  void serializePretty(StringBuffer buf, int ident) {
    buf.writeCharCode(CharCode.LSQB);
    bool needIdent = data.firstOrNull is EnList || data.firstOrNull is EnMap;
    bool first = true;
    for (var e in data) {
      if (!first) buf.write(", ");
      first = false;
      if (needIdent) buf.space(ident);
      e.serializePretty(buf, ident + 1);
    }
    if (needIdent) buf.space(ident);
    buf.writeCharCode(CharCode.RSQB);
  }
}

class EnString extends EnValue implements Comparable<String> {
  String data;

  EnString(this.data);

  @override
  String toString() {
    return data;
  }

  @override
  void serializeTo(StringBuffer buf) {
    buf.writeCharCode(CharCode.QUOTE);
    for (var ch in data.codeUnits) {
      if (ch == CharCode.QUOTE) {
        buf.writeCharCode(CharCode.BSLASH);
      }
      buf.writeCharCode(ch);
    }
    buf.writeCharCode(CharCode.QUOTE);
  }

  @override
  void serializePretty(StringBuffer buf, int ident) {
    serializeTo(buf);
  }

  @override
  int compareTo(String other) {
    return data.compareTo(other);
  }
}

class EnInt extends EnValue implements Comparable<int> {
  int data;

  EnInt(this.data);

  @override
  String toString() {
    return data.toString();
  }

  @override
  void serializeTo(StringBuffer buf) {
    return buf.write(data.toString());
  }

  @override
  void serializePretty(StringBuffer buf, int ident) {
    return buf.write(data.toString());
  }

  @override
  int compareTo(int other) {
    return data.compareTo(other);
  }
}

class EnDouble extends EnValue implements Comparable<double> {
  double data;

  EnDouble(this.data);

  @override
  String toString() {
    return data.toString();
  }

  @override
  void serializeTo(StringBuffer buf) {
    return buf.write(data.toString());
  }

  @override
  void serializePretty(StringBuffer buf, int ident) {
    return buf.write(data.toString());
  }

  @override
  int compareTo(double other) {
    return data.compareTo(other);
  }
}

class EnBool extends EnValue {
  bool data;

  EnBool(this.data);

  @override
  String toString() {
    return data.toString();
  }

  @override
  void serializeTo(StringBuffer buf) {
    return buf.write(data.toString());
  }

  @override
  void serializePretty(StringBuffer buf, int ident) {
    return buf.write(data.toString());
  }
}

class EnNull extends EnValue {
  EnNull._();

  @override
  String toString() {
    return "null";
  }

  @override
  void serializeTo(StringBuffer buf) {
    return buf.write("null");
  }

  @override
  void serializePretty(StringBuffer buf, int ident) {
    return buf.write("null");
  }

  static EnNull inst = EnNull._();
}

abstract class EnValue {
  EnMap? get asMap => this.castTo();

  EnList? get asList => this.castTo();

  EnString? get asString => this.castTo();

  EnInt? get asInt => this.castTo();

  EnDouble? get asDouble => this.castTo();

  EnBool? get asBool => this.castTo();

  bool get isNull => this is EnNull;

  bool? get boolValue => asBool?.data;

  int? get intValue => asInt?.data;

  double? get doubleValue => asDouble?.data;

  String? get stringValue => asString?.data;

  List<bool>? get listBoolValue => asList?.boolList;

  List<int>? get listIntValue => asList?.intList;

  List<double>? get listDoubleValue => asList?.doubleList;

  List<String>? get listStringValue => asList?.stringList;

  String serialize({bool pretty = false}) {
    var buf = StringBuffer();
    if (pretty) {
      serializePretty(buf, 0);
    } else {
      serializeTo(buf);
    }
    return buf.toString();
  }

  void serializeTo(StringBuffer buf);

  void serializePretty(StringBuffer buf, int ident);

  @override
  String toString() {
    return serialize(pretty: false);
  }

  EnValue path(String path, {String sep = "."}) {
    assert(sep.isNotEmpty);
    return paths(path.split(sep).map((e) => e.trim()).toList());
  }

  EnValue paths(List<String> path) {
    if (path.isEmpty) return this;
    switch (this) {
      case EnMap ymap:
        return ymap[path.first].paths(path.sublist(1));
      case EnList yList:
        return yList[path.first.toInt!].paths(path.sublist(1));
      default:
        return EnNull.inst;
    }
  }

  bool setPath(String path, Object value, {String sep = "."}) {
    return setPaths(path.split(sep).map((e) => e.trim()).toList(), value);
  }

  bool setPaths(List<String> paths, Object value) {
    if (paths.isEmpty) return false;
    if (paths.length == 1) {
      this[paths.first] = _toEnValue(value);
      return true;
    }
    EnValue v = this[paths.first];
    if (v is EnNull) {
      if (this is EnMap) {
        this[paths.first] = EnMap(); //auto create
      }
    }
    return this[paths.first].setPaths(paths.sublist(1), value);
  }

  EnValue operator [](Object key) {
    switch (this) {
      case EnMap em:
        return em.data[key.toString()] ?? EnNull.inst;
      case EnList el:
        if (key is int) {
          return el.data[key];
        } else if (key is String) {
          int? idx = key.toInt;
          if (idx != null) {
            return el.data[idx];
          }
        }
    }
    return EnNull.inst;
  }

  void operator []=(Object key, Object? value) {
    switch (this) {
      case EnMap em:
        String kk = key.toString();
        if (value == null) {
          em.data.remove(kk);
        } else {
          em.data[kk] = _toEnValue(value);
        }
      case EnList el:
        int? idx = key is int ? key : (key is String ? key.toInt : null);
        if (idx == null) raise("index error: $key");
        if (value == null) {
          el.data[idx] = EnNull.inst;
        } else {
          el.data[idx] = _toEnValue(value);
        }

      default:
        throw Exception("Unknown type: $value");
    }
  }

  EnValue _toEnValue(Object value) {
    switch (value) {
      case EnValue ev:
        return ev;
      case bool b:
        return EnBool(b);
      case int n:
        return EnInt(n);
      case double f:
        return EnDouble(f);
      case String s:
        return EnString(s);

      default:
        throw Exception("Unknown type: $value");
    }
  }
}

class EnError implements Exception {
  dynamic message;

  EnError(this.message);

  @override
  String toString() {
    Object? message = this.message;
    if (message == null) return "YConfigError";
    return "YConfigError: $message";
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
