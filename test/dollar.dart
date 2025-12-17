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
    $methods += PUT
    rawstr: "@remove"
    """;

    setUp(() {
      // Additional setup goes here.
    });

    test('t1', () {
      EMap map = EConfig.parse(text);
      println(map.toFileContent());

      expect(map['methods'][0].string, equals("GGEETT"));
      expect(map['methods'][1].string, equals("POST"));
      expect(map['methods'][2].string, equals("HEAD"));
      expect(map['methods'].list?.strings, equals(["GGEETT", "POST", "HEAD", "PUT"]));

      expect(map['services.name'].string, equals("blogger"));
      expect(map.path("services.area.city").string, equals("Washington"));
      expect(map['services.fee'].isNull, isTrue);
      expect(map['services.addr'].string, "US");
      expect(map['temp'].isNull, isTrue);
      expect(map['empty'].string, "");
      expect(map['empty2'].string, "");
      expect(map['rawstr'].string, "@remove");

      // println(map['services.name'].runtimeType);
      // println(map['services.name'].stringValue);
    });
  });
}
