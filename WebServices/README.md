# Clean web services

Beside `UICollectionView`, handling networking is also a tedious and repeating task.
Json response from servers are now prevalent and manually handle the dictionary is time consuming and error prone.
Fortunately, the Apple SDK assists us tremendously in json parsing with `Decodable` protocol.

## Decodable

In short, `Decodable` is a protocol to indicate that your custom types can be decoded by a decoder (e.g: `JsonDecoder`).
If a type consists only of Decodable type, the task is fairly trivial.

Consider an User with name and age property:

```swift
struct User {
    let name: String
    let age: Int
}
```

We can easily decode data of a user by making it of type `Decodable`.

```swift
struct User: Decodable {
    let name: String
    let age: Int
}
```

This code is able to be parsed from the following Json, not that the json keys and the variable names must exactly match each other.

```json
{
    'name': 'Bach Le',
    'age': 21,
}
```

Contained `Decodable` type can be of custom types as well, and an array of `Decodable` is also `Decodable`.
For example: 

struct User: Decodable {
    let name: String
    let age: Int
    let children: [User]
}

The previous struct can be constructed by decoding the following json object


```json
{
    'name': 'Father of Bach',
    'age': 50,
    'children': [
        {'name': 'Bach Le', 'age': 21, 'children': []},
        {'name': 'Bach Le 2', 'age': 21, 'children': []},
        {'name': 'Bach Le 3', 'age': 21, 'children': []}
    ]
}
```

ALternatively, you can decide which properties are used to decode or specify which key is used to decode each variable by using `CodingKeys`.
For example, the following json response cannot be decoded using previous struct although it represent the same user.


```json
{
    'user_name': 'Bach Le',
    'age': 21,
}
```

To cope with this problem, we can specify `CodingKeys` in the user struct

```swift
struct User {
    // Codes from above example

    enum CodingKeys: String, CodingKey {
        case name = "user_name"
        case age // Use default key, similar to previous example
    }
}
```

Note that if we leave out `case age`, we have to initialize the age property on our own in `init(from:)`.
`init(from:)` is useful in various other cases, for that please refer to 
[Apple's documentation on Codable](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types)

## Network calls

Let us consider a network call to fetch user detail assuming that the server responses with the json from above.

```swift
func fetchUser(callback: (User?) -> Void) {

    let url = URL(string: fetchUserUrl)!
    let task = URLSession.dataTask(with: url, completionHandler: { data, _, error in
        ...... // Handle errors
        ...... // Handle nil data
        let user = try? JsonDecoder().decode(User.self, from: data!)
        callback(user)
        
    })
}
```

The code itself is not so long, however, having to repeat such snippet of code again and again is kind of tedious.
Instead, I want the call site to look as follows:

```swift
func fetchUser(callback: (User?) -> Void) {
    let ws = WebService()
    let request = WebService.Request(fetchUserUrl)
    ws.performGet(request, completion: callback)
}
```

`WebService` is a user defined object I create to encapsulate networking code and `get(...)` is a routine to call a REST API with `GET` method.
In this routine, it construct the request, talk to server, parse the response, then notify us using the callback.
With this shortened version, you save more than 10 lines of code for each APIs request you make.
Note that you can use UrlSession extension instead of creating another class, however, I prefer this approach since we can later switch to using Alamofire (or other networking framework of your choice, who knows) if we want.

## WebService class

The small snippet above may leave you thinking how do we parse another type of object rather than `User` because the code exposes no details about type of the object to be decoded.
The answer is that it makes use of generics, and the type that is used is the type of first parameter of the callback closure.
The signature of the `get(...)` method:

```swift
func performGet<T: Decodable>(
    request: Request,
    completion: @escaping (T) -> Void
)
```

We will visit the detail of this method later, let us first discuss the requirements of the method, and the structure of `Request`.

### Requirement

In order to be effective, our method must allow:

* Encoding query parameters
* Setting cookies
* Specifying the ports in use

This list is to my limited knowledge, it can get longer and/or shorter based on your specific needs.

### Request object

`Request` is a nested struct inside `WebService`, which encapsulate data related to the request.
With this encapsulation, we can extend the `WebService` to support multiple requirements from the above list without breaking existing call site.

```swift
class WebService {

    struct Request {
        let api: String
        let endpoint: String
        let params: [String : String]?
        let cookies: String?
        let port: Int
    }

    var httpRequest: URLRequest {
        guard let url = encodedUrl else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        if let cookies = cookies {
            request.httpShouldHandleCookies = true
            request.setValue(cookies, forHTTPHeaderField: "Cookie")
        }
        return request
    }

    private var encodedUrl: URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = api
        components.path = endpoint
        components.queryItems = params?.map { URLQueryItem(name: $0, value: $1) }
        return components.url
    }
}
```

In this Request object, we use `URLComponents` to construct an URL, this helps us to encode query parameters more easily.

### performGet(...)

Now let us walk through the body of this method

```swift
func performGet<T: Decodable>(
    request: Request,
    completion: @escaping (T) -> Void
) {

    guard let httpRequest = request.httpRequest else {
        return completion(nil)
    }

    let networkDone: (Data?, URLResponse?, Error?) -> Void = { data, _, error in
        if let er = error { return completion(nil) }
        guard let data = data elst { return completion(nil) }

        let decoder = JSONDecoder()
        let clientData = try? decoder.decode(T.self, from: data)
        return completion(clientData)
    }
    
    let task = urlSession.dataTask(with: httpRequest, completionHandler: networkDone)
    task.resume
}
```

The `urlSession` is a member property of `WebService` and the that's all we need to implement.

There a few refinements you can tailor to your preference, such as using Result<T, Error> in the callback:

```swift
func performGet<T: Decodable>(
    request: Request,
    completion: @escaping (Result<T, Error>) -> Void
)
```

..., or turning `performGet` into a universal method, handling all POST, GET, and PUT.
To do this, we add a field to our `WebService.Request` named httpMethod, for example.

```swift
struct Request {
    struct HttpMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }
}
```

### The usage

This implementation ignores error messages (if your server decides to use such approach) because it only cares about the actual data.
However, we can get creative when it comes to using the `WebService`, for example:

```swift
struct FetchUserResponse: Decodable {
    let fetchStatus: Int
    let message: String // "OK" if success, Error message if failure
    let realUser: User?

    func toClientData() -> Result<User, Error> {
        if fetchStatus == SUCCESS {
            return .success(realUser!)
        } else {
            let error = NetworkingError(message: message)
        }
    }
}
```

## References

https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types

https://www.nodesagency.com/urlcomponents/

https://www.swiftbysundell.com/posts/constructing-urls-in-swift
