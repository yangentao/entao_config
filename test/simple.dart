import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  group('Simple', () {
    final String text = r"""
    # this is comment
    host: https://pub.dev
    port: 443 # comment again
    empty:
    methods: [GET,POST,"HEAD"]
    methods2: [GET,POST,HEAD,]
    # this is comment
    methods3: [
        GET
        # comment
        POST # comment
        HEAD
    ]
    services: [
      {
      # comment
        name:blog
        # comment
        fee: false # comment
      }
      {
        name:repo
        fee: true
      },
      {
        name:repo2
        fee: true
      }
    ]
    names: [a,b{}]
    area:{city:peiking[]}
    mline:"this is 
    multi line"
    """;

    test('t0', () {
      EMap map = EConfig.parse("");
      println(map.toString());
      println(map.toFileContent());
    });

    test('t1', () {
      EMap map = EConfig.parse(text);
      println(map.toFileContent());

      expect(map['host'].string, 'https://pub.dev');
      expect(map['port'].text?.intValue, 443);
      expect(map['empty'].string!.isEmpty, true);

      expect(map['methods'].list?.strings, equals(["GET", "POST", "HEAD"]));
      expect(map['methods2'].list?.strings, equals(["GET", "POST", "HEAD"]));
      expect(map['methods3'].list?.strings, equals(["GET", "POST", "HEAD"]));

      expect(map['methods'][0].string, equals("GET"));
      expect(map['methods'][1].string, equals("POST"));
      expect(map['methods'][2].string, equals("HEAD"));

      expect(map.path('methods.0').string, equals("GET"));
      expect(map.path('methods.1').string, equals("POST"));
      expect(map.path('methods.2').string, equals("HEAD"));

      expect(map.path('services.0.name').string, equals("blog"));
      expect(map.path('services.0.fee').text?.boolOpt, equals(false));

      expect(map.path('services.1.name').string, equals("repo"));
      expect(map.path('services.1.fee').text?.boolOpt, equals(true));
      expect(map.path('services.0').map_?.stringMap, equals({"name": "blog", "fee": "false"}));

      expect(map['names'].list?.strings, equals(["a", "b{}"]));
      expect(map.path('area.city').string, equals("peiking[]"));
      expect(map['mline'].string, equals("this is \n    multi line"));
    });
  });
}
