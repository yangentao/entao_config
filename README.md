## dart config file with struct formats.

comment:  '#...'

instructs:
    @include
    @if
    @end

key:
    String
    $referenced path,   $person.name, $list.0

value:
    String? , List, Map
    @null
    @empty
    @remove
 

```
@include: default.config
@include: "u s e r.config"
@include: {
    file: user.config
    charset: utf-8/system
    keys:[host,port,user]
    excludes:[pwd]
}

host: https://pub.dev
port= 443

account: {
    user:jerry
    pwd: xxx
}

$account.token: xxxxx
userName: $account.user

methods: [GET,POST]
action: $methods.0

@if $userName = Tom
$methods.2= PUT
@end

$methods.3= HEAD
$methods.3= @null
$methods.-1: DELETE
$methods.@remove: delete
newMethods = $methods.copy

```