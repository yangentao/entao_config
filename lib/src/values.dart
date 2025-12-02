part of 'config.dart';

class EMap extends EValue with Iterable<MapEntry<String, EValue>> {
  final Map<String, EValue> data = {};

  @override
  EValue operator [](Object key) {
    return data[key.toString()] ?? ENull.inst;
  }

  @override
  void operator []=(Object key, Object? value) {
    if (value == null) {
      data.remove(key.toString());
    } else {
      data[key.toString()] = _toEnValue(value);
    }
  }

  @override
  Iterator<MapEntry<String, EValue>> get iterator => data.entries.iterator;

  @override
  int get estimatedSize => this.sumValueBy((e) => e.key.length + e.value.estimatedSize + 1) ?? 2;

  @override
  void serializeTo(IndentBuffer buf, {bool pretty = false}) {
    buf.brace(() {
      bool first = true;
      for (var e in data.entries) {
        if (!first) {
          buf.write(", ");
        }
        first = false;
        if (pretty) buf.indentLine;
        buf.write(e.key);
        buf.write(":");
        e.value.serializeTo(buf, pretty: pretty);
      }
    }, indent: pretty);
  }
}

class EList extends EValue with Iterable<EValue> {
  List<EValue> data = [];

  @override
  EValue operator [](Object key) {
    return data.getOr(_intKey(key)) ?? ENull.inst;
  }

  @override
  void operator []=(Object key, Object? value) {
    int index = _intKey(key);
    if (index >= 0) {
      if (index < data.length) {
        data[index] = _toEnValue(value);
      } else {
        for (int i = data.length; i < index; ++i) {
          data.add(nullValue);
        }
        data.add(_toEnValue(value));
      }
    }
  }

  @override
  Iterator<EValue> get iterator => data.iterator;

  @override
  int get estimatedSize => this.sumValueBy((e) => e.estimatedSize) ?? 2;

  @override
  void serializeTo(IndentBuffer buf, {bool pretty = false}) {
    bool p = pretty && (this.estimatedSize > 80 || any((e) => e is EMap));
    buf.bracket(() {
      bool first = true;
      for (var e in data) {
        if (!first) buf.write(", ");
        first = false;
        switch (e) {
          case ENull en:
            if (p) buf.indentLine;
            en.serializeTo(buf, pretty: p);
          case EString es:
            if (p) buf.indentLine;
            es.serializeTo(buf, pretty: p);
          case EList el:
            el.serializeTo(buf, pretty: p);
          case EMap em:
            em.serializeTo(buf, pretty: p);
        }
      }
    }, indent: p);
  }
}

class EString extends EValue implements Comparable<String> {
  String data;

  EString(this.data);

  @override
  EValue operator [](Object key) {
    int index = _intKey(key);
    return EString(data[index]);
  }

  @override
  void operator []=(Object key, Object? value) {
    raise("String value not support edit");
  }

  @override
  String toString() {
    return data;
  }

  @override
  void serializeTo(IndentBuffer buf, {bool pretty = false}) {
    // buf.writeCharCode(CharCode.QUOTE);
    buf << escapeText(data, map: _stringEscapes);
    // buf.writeCharCode(CharCode.QUOTE);
  }

  @override
  int compareTo(String other) {
    return data.compareTo(other);
  }

  @override
  int get estimatedSize => data.length;
}

final ENull nullValue = ENull.inst;

class ENull extends EValue {
  ENull._();

  static ENull inst = ENull._();

  @override
  EValue operator [](Object key) {
    return this;
  }

  @override
  void operator []=(Object key, Object? value) {}

  @override
  int get estimatedSize => 5;

  @override
  void serializeTo(IndentBuffer buf, {bool pretty = false}) {
    buf << "@null";
  }
}

sealed class EValue {
  bool get isNull => this is ENull;

  String get asString {
    if (this case EString es) return es.data;
    raise("NOT a string");
  }

  EList get asList {
    if (this case EList ls) return ls;
    raise("NOT a list");
  }

  EMap get asMap {
    if (this case EMap m) return m;
    raise("NOT a map");
  }

  int get estimatedSize;

  String serialize({bool pretty = false}) {
    var buf = IndentBuffer();
    serializeTo(buf, pretty: pretty);
    return buf.toString();
  }

  void serializeTo(IndentBuffer buf, {bool pretty = false});

  EValue operator [](Object key);

  void operator []=(Object key, Object? value);

  @override
  String toString() {
    return serialize(pretty: false);
  }

  EValue path(String path) {
    return paths(path.split(_SEP).map((e) => e.trim()).toList());
  }

  EValue paths(List<String> path) {
    if (path.isEmpty) return this;
    return this[path.first].paths(path.sublist(1));
  }

  bool setPath(String path, Object value) {
    return setPaths(path.split(_SEP).map((e) => e.trim()).toList(), value);
  }

  bool setPaths(List<String> paths, Object value) {
    if (paths.isEmpty) return false;
    if (paths.length == 1) {
      this[paths.first] = _toEnValue(value);
      return true;
    }
    return this[paths.first].setPaths(paths.sublist(1), value);
  }
}

EValue _toEnValue(Object? value) {
  switch (value) {
    case null:
      return nullValue;
    case num n:
      return EString(n.toString());
    case String s:
      return EString(s);
    case List<dynamic> ls:
      final el = EList();
      el.data.addAll(ls.map((e) => _toEnValue(e)));
      return el;
    case Map<String, dynamic> map:
      final em = EMap();
      for (final p in map.entries) {
        em[p.key] = _toEnValue(p.value);
      }
      return em;
    default:
      raise("Unknown value: $value");
  }
}

int _intKey(Object key) {
  if (key is int) {
    return key;
  }
  if (key is String) {
    return key.toInt ?? raise("message");
  }
  raise("key is not int value");
}

final String _SEP = ".";

extension _StringBufferExt on StringBuffer {
  StringBuffer space(int n) {
    for (int i = 1; i < n * 4; ++i) {
      writeCharCode(CharCode.SP);
    }
    return this;
  }
}

Map<int, int> _stringEscapes = const {CharCode.BSLASH: CharCode.BSLASH, CharCode.QUOTE: CharCode.QUOTE, CharCode.SQUOTE: CharCode.SQUOTE};
