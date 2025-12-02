import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  group('Simple', () {
    final String text = r"""
    host: https\://pub.dev
    port: 443
    methods: [GET,POST,HEAD]
    """;

    setUp(() {
      // Additional setup goes here.
    });

    test('t1', () {
      EMap map = EConfig.parse(text);
      println(map.toFileContent());
      expect(map['host'].stringValue, 'https://pub.dev');
      expect(map['port'].intValue, 443);
      expect(map['methods'].listString, equals(["GET", "POST", "HEAD"]));
      expect(map['methods'][0].stringValue, equals("GET"));
      expect(map['methods'][1].stringValue, equals("POST"));
      expect(map['methods'][2].stringValue, equals("HEAD"));
    });
  });
}
