# More on Decodable

Decodable is a great and flexible way to handle response from server.
However, parsing certain response from server is easier than some others.

For example, let assume that we need to load a list of friends for a user.
The model class may look like the following:

```swift
struct UserAsFriend {
    let id: String
    let name: String
}
```

A response from server may be:

```json
{ 
    [
        {'id': 'id1', 'name': 'Bach Le'},
        {'id': 'id2', 'name': 'Bach'},
        {'id': 'id3', 'name': 'Le'},
        {'id': 'id4', 'name': 'Le Bach'},
    ] 
}
```

Parsing this kind of response is fairly trivial because an array of decodable type is also decodable.
However, when a nested type is a dictionary, things get a bit more tricky.

This problem occurs to me when I work on a response which originally serves a native web app.

```json
{
    'friendIds': [],
    'friendsById': {
        'id1': { 'name': 'Bach Le' },
        'id2': { 'name': 'Bach' },
        'id3': { 'name': 'Le' },
        'id4': { 'name': 'Le Bach' },
    }
}
```
This kind of response is useful to implement a sorting scheme which the client should not know about becasue the `friendIds` imposes an explicit order on the collection of friends.

