## dart config file with struct formats.

String? , List, Map

```
@include: default.config
@include: "u s e r.config"
@include: {
    keys:[host,port,user]
    from: user.config
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

$methods.@3= HEAD
$methods.@add: delete
$methods.@remove: delete
newMethods = $methods.copy

```