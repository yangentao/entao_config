import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  group('dollar', () {
    final String text = r"""
    methods: [GET,POST,HEAD]
    services: {
        name:blog
        fee: false
        area: {
          country: US
          city: New York
        }
      }
    $methods.0 = GGEETT
    $services.name = blogger
    $services.area.city = Washington
    $services.fee = @remove
    $services.addr = US
    temp: TEMP
    $temp: @remove
    empty: Empty
    $empty: @empty
    empty2: @empty
    $methods.-1 = PUT
    rawstr: "@remove"
    """;

    setUp(() {
      // Additional setup goes here.
    });

    test('t1', () {
      EMap map = EConfig.parse(text);
      println(map.toFileContent());

      expect(map['methods'][0].stringValue, equals("GGEETT"));
      expect(map['methods'][1].stringValue, equals("POST"));
      expect(map['methods'][2].stringValue, equals("HEAD"));
      expect(map['methods'].stringList, equals(["GGEETT", "POST", "HEAD", "PUT"]));

      expect(map['services.name'].stringValue, equals("blogger"));
      expect(map.path("services.area.city").stringValue, equals("Washington"));
      expect(map['services.fee'].isNull, isTrue);
      expect(map['services.addr'].stringValue, "US");
      expect(map['temp'].isNull, isTrue);
      expect(map['empty'].stringValue, "");
      expect(map['empty2'].stringValue, "");
      expect(map['rawstr'].stringValue, "@remove");

      // println(map['services.name'].runtimeType);
      // println(map['services.name'].stringValue);
    });
  });
}
