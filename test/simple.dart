import 'package:entao_config/entao_config.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  group('Simple', () {
    final String text = r"""
    
    host: https://pub.dev
    port: 443
    empty:
    methods: [GET,POST,HEAD]
    methods2: [GET,POST,HEAD,]
    methods3: [
        GET
        POST
        HEAD
    ]
    services: [
      {
        name:blog
        fee: false
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

    setUp(() {
      // Additional setup goes here.
    });

    test('t0', () {
      EMap map = EConfig.parse("");
      println(map.toString());
      println(map.toFileContent());
    });

    test('t1', () {
      EMap map = EConfig.parse(text);
      println(map.toFileContent());

      expect(map['host'].stringValue, 'https://pub.dev');
      expect(map['port'].intValue, 443);
      expect(map['empty'].stringValue!.isEmpty, true);

      expect(map['methods'].stringList, equals(["GET", "POST", "HEAD"]));
      expect(map['methods2'].stringList, equals(["GET", "POST", "HEAD"]));
      expect(map['methods3'].stringList, equals(["GET", "POST", "HEAD"]));

      expect(map['methods'][0].stringValue, equals("GET"));
      expect(map['methods'][1].stringValue, equals("POST"));
      expect(map['methods'][2].stringValue, equals("HEAD"));

      expect(map.path('methods.0').stringValue, equals("GET"));
      expect(map.path('methods.1').stringValue, equals("POST"));
      expect(map.path('methods.2').stringValue, equals("HEAD"));

      expect(map.path('services.0.name').stringValue, equals("blog"));
      expect(map.path('services.0.fee').boolValue, equals(false));

      expect(map.path('services.1.name').stringValue, equals("repo"));
      expect(map.path('services.1.fee').boolValue, equals(true));
      expect(map.path('services.0').stringMap, equals({"name": "blog", "fee": "false"}));

      expect(map['names'].stringList, equals(["a", "b{}"]));
      expect(map.path('area.city').stringValue, equals("peiking[]"));
      expect(map['mline'].stringValue, equals("this is \n    multi line"));
    });
  });
}
