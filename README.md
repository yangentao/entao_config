## Config file with struct formats.
## Samples 
```dart
String text = r'''
    # this is comment
    host: https://pub.dev
    port: 443 # comment again
    empty:
    methods: [GET,POST,"HEAD"]
    account: {
      name: Jerry
      type: animal
    }
''';
EMap map = EConfig.parse(text);
print(map.toFileContent());
expect(map['host'].stringValue, 'https://pub.dev');
expect(map['port'].intValue, 443);
```
There are three value types, Map, List and String.  
Map, separate key-value with ':' or '=', and separate items with '\n' or ','  
List separate items with '\n' or ','
String, can be quoted or not,  when quoted, it's a strict string, it can contains new line charactor.  
Comment is start with '#', end with '\n' or end of file.

* Map
```
host: google.com
host = google.com,
host : "google.com"
desc: "this is 
multiline description.
"
desc: this is \
multiline description.
server:{
    host: https://google.com
    port: 433
}
```
* List
```
methods: [GET,POST]
methods:[
    GET,
    POST,
    PUT,
]
methods:[
    GET
    POST
    PUT
]
```
* Comment
```
# comment
host: google.com # comment
list: [
    1
    #comment
    2 #comment
    3
]
```
* Reference
```
user:{
    name: Jerry
    age: 2
    addr:         #empty
    addr: @empty  #also emtpy
    addr: @null   #null
}
$user.name = Tom
$user.addr: @remove     # remove key 'addr'

days:[1,2,3]
$days.0 = 999       # days[0] = 999
$days.3 = 4         # days[3] = 4,  allow assign value at end index.
$days.-1 = 6        # days.append(6)
$days.0: @remove    # days.removeAt(0)
```
* Include
```
@include: b.txt
@include: {
    file: b.txt
    charset:system  # utf-8, system, ....
    keys: [host, port]
    excludes: [pwd]
}
```
* If-else-end
```
@if $port = 433
    SAFE = true
@else 
    SAFE = false 
@end

@if $user.age >= 18   # compare by try convert to int or double
    adult = true
    @include: adult.txt
@end
```
Normal operators: '=', '!=', '>', '<', '>=', '<='  
check contains with '@=' or '=@'  
A @= B  means  A.contains(B)  or A.containsKey(B)   
A =@ B  means  B.contains(A)  or B.containsKey(A)  
```
port: 80
@if $port =@ [80, 8080]
    SAFE = false
@end

methods: [GET,POST,PUT]
@if $methods @= GET
    ALLOW_HEAD = true
@end
```
* Unicode
```
desc: \uXXXX\uXXXX
```
* Escape charators
```
desc: \\, \", \0, \b, \t, \r, \n, \#, \}, \], \=, \:, \,
```
