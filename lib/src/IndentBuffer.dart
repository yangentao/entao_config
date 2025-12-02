import 'package:entao_dutil/entao_dutil.dart';

class IndentBuffer {
  final StringBuffer buffer = StringBuffer();
  int _indent;

  IndentBuffer([this._indent = 0]);

  IndentBuffer brace(VoidCallback callback) {
    push("{");
    callback();
    pop("}");
    return this;
  }

  IndentBuffer bracket(VoidCallback callback) {
    push("[");
    callback();
    pop("]");
    return this;
  }

  void push([String s = ""]) {
    write(s);
    _indent += 1;
  }

  void pop([String s = ""]) {
    _indent -= 1;
    if (_indent < 0) _indent = 0;
    newLine;
    if (s.isNotEmpty) {
      indent.write(s);
    }
  }

  IndentBuffer get indentLine => newLine.indent;

  IndentBuffer get newLine {
    buffer.writeln();
    return this;
  }

  IndentBuffer write(Object? object) {
    buffer.write(object);
    return this;
  }

  IndentBuffer writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    buffer.writeAll(objects, separator);
    return this;
  }

  IndentBuffer writeCharCode(int charCode) {
    buffer.writeCharCode(charCode);
    return this;
  }

  IndentBuffer get indent {
    for (int i = 0; i < _indent; ++i) {
      writeCharCode(CharCode.SP);
      writeCharCode(CharCode.SP);
      writeCharCode(CharCode.SP);
      writeCharCode(CharCode.SP);
    }
    return this;
  }

  IndentBuffer operator <<(String s) {
    write(s);
    return this;
  }

  @override
  String toString() {
    return buffer.toString();
  }
}
