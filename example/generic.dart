void main() {
  ff<String>();
  ff<String?>();
}

void ff<T>() {
  if (T == String) {
    print("str");
    return;
  }
  if (T == A<String?>().type) {
    print("String?");
    return;
  }
  print('not str: $T ');
}

class A<T> {
  final type = T;
}

// class B extends A {
//   @override
//   List<T> value<T>() {
//     if (T == String) return ["A"] as T;
//     if (T == int) return [10] as T;
//     return [];
//   }
// }
