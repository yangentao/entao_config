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
    expect(map['methods'].list?.strings, equals(["GET", "POST", "HEAD"]));
    expect(map['port'].string, "80");
    expect(map['user'].string, "entao");
    expect(map['SAFE'].string, "false");
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
    expect(map['methods'].list?.strings, equals(["GET", "POST", "HEAD"]));
    expect(map['port'].string, "433");
    expect(map['user'].string, "entao");
    expect(map['SAFE'].string, "true");
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
    expect(map['methods'].list?.strings, equals(["GET", "POST", "HEAD"]));
    expect(map['HAS_GET'].string, "true");
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
    expect(map['methods'].list?.strings, equals(["POST", "HEAD"]));
    expect(map['HAS_GET'].string, "false");
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
    expect(map['HTTP80'].string, "true");
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
    expect(map['HTTP8080'].string, "false");
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
    expect(map['GT80'].string, "false");
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
    expect(map['GE80'].string, "true");
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
    expect(map['LT80'].string, "false");
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
    expect(map['LE80'].string, "true");
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
    expect(map['HTTP80'].string, "false");
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
    expect(map['HTTP8080'].string, "true");
  });
}
