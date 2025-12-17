part of 'econfig.dart';

extension EMapExt on EMap {
  Map<String, String> get stringMap {
    return data.map((k, v) => MapEntry(k, (v as EText).data));
  }
}

extension EListExt on EList {
  List<String> get strings => this.mapList((e) => e.string);

  List<int> get ints => this.mapList((e) => e.intValue);

  List<double> get doubles => this.mapList((e) => e.doubleValue);

  List<bool> get bools => this.mapList((e) => e.boolValue);
}

extension EValueExt on EValue {
  EMap? get dic => map_;

  EMap? get map_ {
    if (this case EMap m) return m;
    return null;
  }

  EList? get list {
    if (this case EList ls) return ls;
    return null;
  }

  String get string {
    if (this case EText es) return es.data;
    return "";
  }

  String? get stringOpt {
    if (this case EText es) return es.data;
    return null;
  }

  bool get boolValue => stringOpt?.let((s) => bool.parse(s)) ?? false;

  bool? get boolOpt => stringOpt?.let((s) => bool.tryParse(s));

  int get intValue => stringOpt?.let((s) => int.parse(s)) ?? 0;

  int? get intOpt => stringOpt?.let((s) => int.tryParse(s));

  double get doubleValue => stringOpt?.let((s) => double.parse(s)) ?? 0;

  double? get doubleOpt => stringOpt?.let((s) => double.tryParse(s));

  Map<String, T> mapValue<T>() {
    assert(T != Object && T != dynamic);
    if (this case EMap m) {
      return m.data.map((k, e) => MapEntry(k, e.value<T>()));
    }
    return {};
  }

  List<T> listValue<T>() {
    assert(T != Object && T != dynamic);
    if (this case EList ls) {
      return ls.data.mapList((e) => e.value<T>());
    }
    return [];
  }

  T value<T>() {
    assert(T != Object && T != dynamic);
    if (this case EText text) {
      if (T == String || T == _Type.stringOpt) return text.data as T;
      if (text.data.isNotEmpty) {
        if (T == int || T == _Type.intOpt) {
          if (text.data.length > 2 && text.data[1].toLowerCase() == 'x') {
            return int.parse(text.data, radix: 16) as T;
          }
          return int.parse(text.data) as T;
        }
        if (T == double || T == _Type.doubleOpt) return double.parse(text.data) as T;
        if (T == bool || T == _Type.boolOpt) return bool.parse(text.data, caseSensitive: false) as T;
        if (T == Uri || T == _Type.uriOpt) return Uri.parse(text.data) as T;
      } else {
        if (null is T) return null as T;
        raise("value is empty");
      }
    }
    if (null is T) return null as T;
    raise("Failed get value, type : $T, value : $this");
  }
}

class _Type<T> {
  final Type type = T;
  static final Type stringOpt = _Type<String?>().type;
  static final Type intOpt = _Type<int?>().type;
  static final Type doubleOpt = _Type<double?>().type;
  static final Type boolOpt = _Type<bool?>().type;
  static final Type uriOpt = _Type<Uri?>().type;
}
