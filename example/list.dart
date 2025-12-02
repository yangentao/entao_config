import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';

void main() {
  EString es = EString("Hello");
  println(es.toString());
  println(nullValue);

  EMap em = EMap({
    "name": "entao",
    "age": 33,
    "children": [
      1,
      2,
      3,
      {"ip": "1.2.3.4", "port": 80}
    ]
  });
  EList el = EList([es, nullValue, 123, em, "forever", EList(["entao", "yang"])]);
  println(el.serialize(pretty: true));
}
