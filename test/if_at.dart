import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  test('belong', () {
    final String text = r"""
    methods: [GET,POST,HEAD]
    port: 80
    @if port =@ [433,8433]
      SAFE : true 
    @else 
      SAFE : false 
    @end
    user: entao
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['methods'].stringList, equals(["GET", "POST", "HEAD"]));
    expect(map['port'].stringValue, "80");
    expect(map['user'].stringValue, "entao");
    expect(map['SAFE'].stringValue, "false");
  });
  test('belong2', () {
    final String text = r"""
    methods: [GET,POST,HEAD]
    port: 433
    @if port =@ [433,8433]
      SAFE : true 
    @else 
      SAFE : false 
    @end
    user: entao
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['methods'].stringList, equals(["GET", "POST", "HEAD"]));
    expect(map['port'].stringValue, "433");
    expect(map['user'].stringValue, "entao");
    expect(map['SAFE'].stringValue, "true");
  });
  test('contains', () {
    final String text = r"""
    methods: [GET,POST,HEAD]
    @if methods @= GET
      HAS_GET : true 
    @else 
      HAS_GET : false 
    @end
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['methods'].stringList, equals(["GET", "POST", "HEAD"]));
    expect(map['HAS_GET'].stringValue, "true");
  });
  test('contains2', () {
    final String text = r"""
    methods: [ POST,HEAD]
    @if methods @= GET
      HAS_GET : true 
    @else 
      HAS_GET : false 
    @end
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['methods'].stringList, equals(["POST", "HEAD"]));
    expect(map['HAS_GET'].stringValue, "false");
  });
  test('eq', () {
    final String text = r"""
    port: 80
    @if port = 80
      HTTP80 : true 
    @else 
      HTTP80 : false 
    @end
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['HTTP80'].stringValue, "true");
  });
  test('eq2', () {
    final String text = r"""
    port: 80
    @if port = 8080
      HTTP8080 : true 
    @else 
      HTTP8080 : false 
    @end
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['HTTP8080'].stringValue, "false");
  });

  test('gt', () {
    final String text = r"""
    port: 80
    @if port > 80
      GT80 : true 
    @else 
      GT80 : false 
    @end
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['GT80'].stringValue, "false");
  });
  test('ge', () {
    final String text = r"""
    port: 80
    @if port >= 80
      GE80 : true 
    @else 
      GE80 : false 
    @end
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['GE80'].stringValue, "true");
  });

  test('lt', () {
    final String text = r"""
    port: 80
    @if port < 80
      LT80 : true 
    @else 
      LT80 : false 
    @end
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['LT80'].stringValue, "false");
  });
  test('le', () {
    final String text = r"""
    port: 80
    @if port <= 80
      LE80 : true 
    @else 
      LE80 : false 
    @end
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['LE80'].stringValue, "true");
  });

  test('ne', () {
    final String text = r"""
    port: 80
    @if port != 80
      HTTP80 : true 
    @else 
      HTTP80 : false 
    @end
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['HTTP80'].stringValue, "false");
  });
  test('ne2', () {
    final String text = r"""
    port: 80
    @if port != 8080
      HTTP8080 : true 
    @else 
      HTTP8080 : false 
    @end
    """;
    EMap map = EConfig.parse(text);
    println(map.toFileContent());
    expect(map['HTTP8080'].stringValue, "true");
  });
}
