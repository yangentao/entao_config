part of 'config.dart';

class EMap extends EValue with Iterable<MapEntry<String, EValue>> {
  final Map<String, EValue> data = {};

  @override
  Iterator<MapEntry<String, EValue>> get iterator => data.entries.iterator;

  @override
  int get estimatedSize => this.sumValueBy((e) => e.key.length + e.value.estimatedSize + 1) ?? 2;

  @override
  void serializeTo(IndentBuffer buf, {bool pretty = false}) {
    buf.brace(() {
      bool first = true;
      for (var e in data.entries) {
        if (first) {
          first = false;
        } else {
          buf.write(", ");
        }
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
        e.serializeTo(buf, pretty: p);
      }
    }, indent: pretty);
  }
}

class EString extends EValue implements Comparable<String> {
  String data;

  EString(this.data);

  @override
  String toString() {
    return data;
  }

  @override
  void serializeTo(IndentBuffer buf, {bool pretty = false}) {
    if (pretty) {
      buf.indentLine;
    }
    buf.writeCharCode(CharCode.QUOTE);
    buf << escapeText(data, map: const {CharCode.BSLASH: CharCode.BSLASH, CharCode.QUOTE: CharCode.QUOTE, CharCode.SQUOTE: CharCode.SQUOTE});
    buf.writeCharCode(CharCode.QUOTE);
  }

  @override
  int compareTo(String other) {
    return data.compareTo(other);
  }

  @override
  int get estimatedSize => data.length;
}

sealed class EValue {
  int get estimatedSize;

  String serialize({bool pretty = false}) {
    var buf = IndentBuffer();
    serializeTo(buf, pretty: pretty);
    return buf.toString();
  }

  void serializeTo(IndentBuffer buf, {bool pretty = false});

  @override
  String toString() {
    return serialize(pretty: false);
  }

  EValue path(String path) {
    return paths(path.split(_SEP).map((e) => e.trim()).toList());
  }

  EValue paths(List<String> path) {
    if (path.isEmpty) return this;
    switch (this) {
      case EMap ymap:
        return ymap[path.first].paths(path.sublist(1));
      case EList yList:
        return yList[path.first.toInt!].paths(path.sublist(1));
      default:
        return raise("invalid path: ${path.join(_SEP)}");
    }
  }

  bool setPath(String path, Object value) {
    return setPaths(path.split(_SEP).map((e) => e.trim()).toList(), value);
  }

  bool setPaths(List<String> paths, Object value) {
    if (paths.isEmpty) return false;
    if (paths.length == 1) {
      // this[paths.first] = _toEnValue(value);
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
    // switch (this) {
    //   case EMap em:
    //     return em.data[key.toString()]!;
    //   case EList el:
    //     if (key is int) {
    //       return el.data[key];
    //     } else if (key is String) {
    //       int? idx = key.toInt;
    //       if (idx != null) {
    //         return el.data[idx];
    //       }
    //     }
    // }
    raise("null");
  }

  void operator []=(Object key, Object? value) {
    switch (this) {
      case EMap em:
        String kk = key.toString();
        if (value == null) {
          em.data.remove(kk);
        } else {
          // em.data[kk] = _toEnValue(value);
        }
      case EList el:
        int? idx = key is int ? key : (key is String ? key.toInt : null);
        if (idx == null) raise("index error: $key");
        if (value == null) {
          // el.data[idx] = EnNull.inst;
        } else {
          // el.data[idx] = _toEnValue(value);
        }

      default:
        throw Exception("Unknown type: $value");
    }
  }
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
