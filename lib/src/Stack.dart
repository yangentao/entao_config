class Stack<T> extends Iterable<T> {
  final List<T> _list = [];

  Stack();

  @override
  bool get isEmpty => _list.isEmpty;

  @override
  bool get isNotEmpty => _list.isNotEmpty;

  T? getOr(int index) {
    if (index >= 0 && index < _list.length) return _list[index];
    return null;
  }

  T operator [](int index) {
    return _list[index];
  }

  void operator []=(int index, T value) {
    if (index == _list.length) {
      _list.add(value);
    } else {
      _list[index] = value;
    }
  }

  void push(T value) {
    _list.add(value);
  }

  T? pop() {
    if (_list.isEmpty) return null;
    return _list.removeLast();
  }

  T? peek() {
    return _list.lastOrNull;
  }

  @override
  int get length => _list.length;

  @override
  Iterator<T> get iterator => _list.iterator;
}
