import 'package:entao_config/src/IndentBuffer.dart';

void main() {
  IndentBuffer buf = IndentBuffer();
  buf.write("user:").brace(() {
    buf.indentLine.write("phone:").write("10086");
    buf.indentLine.write("email:").write("a@b.com");
    buf.indentLine.write("values:").bracket(() {
      buf.indentLine.write("A");
      buf.indentLine.write("B");
    });
  });
  buf.indentLine.write("port: 80");

  print(buf.toString());
}
