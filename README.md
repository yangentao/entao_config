## dart config file with struct formats.

String? , List, Map
@include, @if, @end, @null, @empty 
.@add, .@remove, .1, .2, .3
@"this is raw string"
$host: @remove

```
@include: default.config
@include: "u s e r.config"
@include: {
    from: user.config
    keys:[host,port,user]
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