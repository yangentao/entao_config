import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  group('Simple', () {
    final String text = r"""
    host: https\://pub.dev
    port: 443
    """;

    setUp(() {
      // Additional setup goes here.
    });

    test('t1', () {
      EMap map = EConfig.parse(text);
      println(map.serialize(pretty: true ));
      expect(map['host'].stringValue, 'https://pub.dev');
      expect(map['port'].intValue, 443);
    });
  });
}
