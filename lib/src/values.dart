part of 'config.dart';

class EMap extends EValue with Iterable<MapEntry<String, EValue>> {
  Map<String, EValue> data = {};

  @override
  Iterator<MapEntry<String, EValue>> get iterator => data.entries.iterator;

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

class EList extends EValue with Iterable<EValue> {
  List<EValue> data = [];

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
  Iterator<EValue> get iterator => data.iterator;

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
    bool needIdent = data.firstOrNull is EList || data.firstOrNull is EMap;
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

class EnString extends EValue implements Comparable<String> {
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

class EnInt extends EValue implements Comparable<int> {
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

class EnDouble extends EValue implements Comparable<double> {
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

class EnBool extends EValue {
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

class EnNull extends EValue {
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

abstract class EValue {
  EMap? get asMap => this.castTo();

  EList? get asList => this.castTo();

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

  EValue path(String path, {String sep = "."}) {
    assert(sep.isNotEmpty);
    return paths(path.split(sep).map((e) => e.trim()).toList());
  }

  EValue paths(List<String> path) {
    if (path.isEmpty) return this;
    switch (this) {
      case EMap ymap:
        return ymap[path.first].paths(path.sublist(1));
      case EList yList:
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
    EValue v = this[paths.first];
    if (v is EnNull) {
      if (this is EMap) {
        this[paths.first] = EMap(); //auto create
      }
    }
    return this[paths.first].setPaths(paths.sublist(1), value);
  }

  EValue operator [](Object key) {
    switch (this) {
      case EMap em:
        return em.data[key.toString()] ?? EnNull.inst;
      case EList el:
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
      case EMap em:
        String kk = key.toString();
        if (value == null) {
          em.data.remove(kk);
        } else {
          em.data[kk] = _toEnValue(value);
        }
      case EList el:
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

  EValue _toEnValue(Object value) {
    switch (value) {
      case EValue ev:
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
