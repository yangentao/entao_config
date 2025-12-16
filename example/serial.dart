
import 'package:entao_config/entao_config.dart';

void main(){
  EMap m = EMap();
  m['name'] = 'entao';
  m['port'] = 80;
  m['host'] = 'localhose';
  String s = m.serialize(pretty: true );
  print(s);

  EList ls = EList([1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3]);
  print(ls.serialize(pretty: true ));
}