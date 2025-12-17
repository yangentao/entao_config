import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  group('include', () {
    final String text = r"""
    methods: [GET,POST,HEAD]
    @include: a.txt
    """;

    setUp(() {
      // Additional setup goes here.
    });

    test('t1', () {
      EMap map = EConfig.parse(text);
      println(map.toFileContent());

      expect(map['methods'][1].string, equals("POST"));
      expect(map['methods'][2].string, equals("HEAD"));
    });
  });
}
