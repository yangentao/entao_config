import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  group('if_at', () {
    final String text = r"""
    methods: [GET,POST,HEAD]
    port: 80
    @if port != 80
      $methods.-1 = PUT
    @else 
      $methods.-1 = DELETE
    @end
    user: entao
    """;

    setUp(() {
      // Additional setup goes here.
    });

    test('t1', () {
      EMap map = EConfig.parse(text);
      println(map.toFileContent());

    });
  });
}
