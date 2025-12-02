part of 'config.dart';

class EMap extends EValue with Iterable<MapEntry<String, EValue>> {
  final Map<String, EValue> data = {};

  @override
  Iterator<MapEntry<String, EValue>> get iterator => data.entries.iterator;

  @override
  void serializeTo(StringBuffer buf) {
    buf.write("{");
    bool first = true;
    for (var e in data.entries) {
      if (first) {
        first = false;
      } else {
        buf.write(", ");
      }
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

  @override
  Iterator<EValue> get iterator => data.iterator;

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
    // buf.writeCharCode(CharCode.LSQB);
    // bool needIdent = data.firstOrNull is EList || data.firstOrNull is EMap;
    // bool first = true;
    // for (var e in data) {
    //   if (!first) buf.write(", ");
    //   first = false;
    //   if (needIdent) buf.space(ident);
    //   e.serializePretty(buf, ident + 1);
    // }
    // if (needIdent) buf.space(ident);
    // buf.writeCharCode(CharCode.RSQB);
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

sealed class EValue {
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
