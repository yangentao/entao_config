part of 'econfig.dart';

extension EMapExt on EMap {
  String stringValue(String key, {String absent = ""}) => this[key].string ?? absent;

  String? stringOpt(String key) => this[key].string;

  bool boolValue(String key, {bool absent = false}) => this[key].text?.boolOpt ?? absent;

  bool? boolOpt(String key) => this[key].text?.boolOpt;

  int intValue(String key, {int absent = 0}) => this[key].text?.intValue ?? absent;

  int? intOpt(String key) => this[key].text?.intOpt;

  double doubleValue(String key, {double absent = 0}) => this[key].text?.doubleValue ?? absent;

  double? doubleOpt(String key) => this[key].text?.doubleOpt;

  Map<String, String> get stringMap {
    return data.map((k, v) => MapEntry(k, (v as EText).data));
  }
}

extension EListExt on EList {
  List<String> get strings => this.mapList((e) => e.text!.string);

  List<int> get ints => this.mapList((e) => e.text!.intValue);

  List<double> get doubles => this.mapList((e) => e.text!.doubleValue);

  List<bool> get bools => this.mapList((e) => e.text!.boolValue);
}

extension ETextExt on EText {
  String get string => data;

  bool get boolValue => bool.parse(data);

  bool? get boolOpt => bool.tryParse(data, caseSensitive: false);

  int get intValue => int.parse(data);

  int? get intOpt => int.tryParse(data);

  double get doubleValue => double.parse(data);

  double? get doubleOpt => double.tryParse(data);
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

  EText? get text {
    if (this case EText s) return s;
    return null;
  }

  String? get string {
    if (this case EText es) return es.data;
    return null;
  }
}
