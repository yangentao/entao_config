part of 'econfig.dart';

class EMap extends EValue with Iterable<MapEntry<String, EValue>> {
  final Map<String, EValue> data = {};

  EMap([Map<String, dynamic>? map]) {
    if (map != null && map.isNotEmpty) {
      for (final e in map.entries) {
        this[e.key] = e.value;
      }
    }
  }

  @override
  EValue operator [](Object key) {
    String k = key.toString();
    if (k.contains(".")) return this.path(k);
    return data[k] ?? nullValue;
  }

  @override
  void operator []=(Object key, Object? value) {
    String k = key.toString();
    if (k.contains(".")) {
      setPath(k, value);
    } else {
      if (value == null) {
        data.remove(key.toString());
      } else {
        data[key.toString()] = _toEValue(value);
      }
    }
  }

  @override
  bool remove(Object key) {
    return null != data.remove(key.toString());
  }

  @override
  Iterator<MapEntry<String, EValue>> get iterator => data.entries.iterator;

  @override
  int get _estimatedSize => this.sumValueBy((e) => e.key.length + e.value._estimatedSize + 1) ?? 2;

  @override
  void _serializeTo(IndentBuffer buf, {bool pretty = false}) {
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
        e.value._serializeTo(buf, pretty: pretty);
      }
    }, indent: pretty);
  }

  String toFileContent() {
    IndentBuffer buf = IndentBuffer();
    bool first = true;
    for (var e in data.entries) {
      if (!first) {
        buf.newLine;
      }
      first = false;
      buf.write(e.key);
      buf.write(":");
      e.value._serializeTo(buf, pretty: true);
    }
    return buf.toString();
  }

  @override
  String toString() {
    return serialize(pretty: false);
  }
}

class EList extends EValue with Iterable<EValue> {
  final List<EValue> data = [];

  EList([List<dynamic>? values]) {
    if (values != null && values.isNotEmpty) {
      data.addAll(values.map((e) => _toEValue(e)));
    }
  }

  EList add(Object? value) {
    data.add(_toEValue(value));
    return this;
  }

  @override
  EValue operator [](Object key) {
    String k = key.toString();
    if (k.contains(".")) return this.path(k);
    return data.getOr(_intKey(key)) ?? nullValue;
  }

  @override
  void operator []=(Object key, Object? value) {
    String k = key.toString();
    if (k.contains(".")) {
      setPath(k, value);
    } else {
      int index = _intKey(key);
      if (index >= 0) {
        if (index < data.length) {
          data[index] = _toEValue(value);
        } else {
          for (int i = data.length; i < index; ++i) {
            data.add(nullValue);
          }
          data.add(_toEValue(value));
        }
      } else if (index == -1) {
        data.add(_toEValue(value));
      }
    }
  }

  @override
  bool remove(Object key) {
    data.removeAt(_intKey(key));
    return true;
  }

  @override
  Iterator<EValue> get iterator => data.iterator;

  @override
  int get _estimatedSize => this.sumValueBy((e) => e._estimatedSize) ?? 2;

  @override
  void _serializeTo(IndentBuffer buf, {bool pretty = false}) {
    bool p = pretty && (this._estimatedSize > 80 || any((e) => e is EMap));
    buf.bracket(() {
      bool first = true;
      for (var e in data) {
        if (!first) buf.write(", ");
        first = false;
        if (p) buf.indentLine;
        e._serializeTo(buf, pretty: p);
      }
    }, indent: p);
  }
}

class EString extends EValue implements Comparable<String> {
  final String data;

  EString(this.data);

  @override
  EValue operator [](Object key) {
    String k = key.toString();
    if (k.contains(".")) return this.path(k);
    int index = _intKey(key);
    return EString(data[index]);
  }

  @override
  void operator []=(Object key, Object? value) {
    raise("String value not support edit");
  }

  @override
  bool remove(Object key) {
    raise("String value no support remove");
  }

  @override
  String toString() {
    return data;
  }

  @override
  void _serializeTo(IndentBuffer buf, {bool pretty = false}) {
    buf << escapeText(data, map: _escapeChars);
  }

  @override
  int compareTo(String other) {
    return data.compareTo(other);
  }

  @override
  int get _estimatedSize => data.length;
}

final ENull nullValue = ENull._();

class ENull extends EValue {
  ENull._();

  @override
  EValue operator [](Object key) {
    return this;
  }

  @override
  void operator []=(Object key, Object? value) {}

  @override
  bool remove(Object key) => false;

  @override
  int get _estimatedSize => 5;

  @override
  void _serializeTo(IndentBuffer buf, {bool pretty = false}) {
    buf << "@null";
  }
}

sealed class EValue {
  bool get isNull => this is ENull;

  Map<String, String> get stringMap {
    if (this case EMap em) {
      return em.data.map((k, v) => MapEntry(k, (v as EString).data));
    }
    raise("NOT a map");
  }

  List<String> get stringList {
    if (this case EList el) {
      return el.data.mapList((e) => (e as EString).data);
    }
    raise("NOT a String list");
  }

  bool get boolValue {
    return _trues.contains(stringValue.toLowerCase());
  }

  int? get intValue => stringValue.toInt;

  double? get doubleValue => stringValue.toDouble;

  String get stringValue {
    if (this case EString es) return es.data;
    if (this is ENull) return "";
    raise("NOT a string");
  }

  EList get listValue {
    if (this case EList ls) return ls;
    raise("NOT a list");
  }

  EMap get mapValue {
    if (this case EMap m) return m;
    raise("NOT a map");
  }

  int get _estimatedSize;

  String serialize({bool pretty = false}) {
    var buf = IndentBuffer();
    _serializeTo(buf, pretty: pretty);
    return buf.toString();
  }

  void _serializeTo(IndentBuffer buf, {bool pretty = false});

  EValue operator [](Object key);

  void operator []=(Object key, Object? value);

  bool remove(Object key);

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

  bool setPath(String path, Object? value) {
    return setPaths(path.split(_SEP).map((e) => e.trim()).toList(), value);
  }

  bool setPaths(List<String> paths, Object? value) {
    if (paths.isEmpty) return false;
    if (paths.length == 1) {
      this[paths.first] = _toEValue(value);
      return true;
    }
    return this[paths.first].setPaths(paths.sublist(1), value);
  }

  bool removePath(String path) {
    return removePaths(path.split(_SEP).map((e) => e.trim()).toList());
  }

  bool removePaths(List<String> paths) {
    if (paths.isEmpty) return false;
    if (paths.length == 1) {
      return remove(paths.first);
    } else {
      return this.paths(paths.sublist(0, paths.length - 1)).remove(paths.last);
    }
  }
}

EValue _toEValue(Object? value) {
  if (value is EValue) return value;
  switch (value) {
    case null:
      return nullValue;
    case num n:
      return EString(n.toString());
    case String s:
      return EString(s);
    case List<dynamic> ls:
      final el = EList();
      el.data.addAll(ls.map((e) => _toEValue(e)));
      return el;
    case Map<String, dynamic> map:
      final em = EMap();
      for (final p in map.entries) {
        em[p.key] = _toEValue(p.value);
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

final List<String> _trues = const ["1", "true", "yes"];
