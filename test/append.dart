import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  group('append', () {
    final String text = r"""
    methods: [GET,POST,"HEAD"]
    methods+= PUT
    server: {
      host: localhost
    }
    server+= {
      host: pub.dev
    }
    nums += 1
    nums += 2
    nums += 3
    ns += 100
    """;

    test('a', () {
      EMap map = EConfig.parse(text);
      println(map.toFileContent());
      expect(map['methods'].listValue<String>(), equals(["GET", "POST", "HEAD", "PUT"]));
      expect(map['server'].list?.length, 2);
      expect(map['server'].list?[0]['host'].string, 'localhost');
      expect(map['server'].list?[1]['host'].string, 'pub.dev');
      expect(map['nums'].listValue<String>(), equals(['1', '2', '3']));
      expect(map['ns'].listValue<int>(), equals([100]));
    });
  });
}
