import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';

void main() {
  final String text = r"""
    methods: [GET,POST,HEAD]
    @include: a.txt
    """;

  EMap map = EConfig.parse(text);
  println("-------");
  println(map.toFileContent());

  // expect(map['methods'][1].stringValue, equals("POST"));
  // expect(map['methods'][2].stringValue, equals("HEAD"));
}
