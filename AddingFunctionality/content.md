# Adding functionality

In my [previous post](www.google.com),
we have made a nice separation between our `LoginViewController` and business logic (login)
by creating a `LoginUseCase` inside the `LoginViewController`.
Today, we are going to look at its implementation.

A quick recap of `LoginUseCase`

```swift
class LoginUseCase {
    private weak var delegate: LoginUseCaseDelegate?
    
    init(delegate: LoginUseCaseDelegate) {
        self.delegate = delegate
    }

    func execute(username: String, password: String) {
        // Call API to login
    }
}
```

## The call site // Is this neccessary?

When I look at the `execute()` method, I think we need a little bit of redesign.
I prefer the argument type to be clearer 
(The benefit is even greater when it comes to languages who do not enforce named parameter like Java or Kotlin).

So let us create a new type called `Credential`, which will be nested inside `LoginUseCase`.
We can make use of a struct, or just simply use a named tuple.

```swift
class LoginUseCase {
    struct Credential {
        let username: String
        let password: String
    }

    typealias (usename: String, password: String)
}
```
Also, I want to alter the `execute()` method name a little bit.

```swift
let credential = LoginUseCase.Credential(username: "bachld", password: "hello")
loginUseCase.doLogin(using: credential)
```

##  API calls

To login, we have to talk to a server and ask it to verify the credential information.
It is acceptable to implement networking code right in our `LoginUseCase` class.
However, I do not find this approach a good practice for some reason:

* `LoginUseCase` has no business with networking details
* Networking is a recurring task in most projects and separating it away from the use case enables us to reuse the code elsewhere
* We want to keep as many class as small as possible and there is a clear line between the use case and networking implementation.
* It is difficult to write unit test for our `LoginUseCase` class because it is impossible to fake a server response if the networking is buried deep inside our `execute` method.

**NOTE:**

In unit test point above, we can alternatively make a method to do networking and override it in our unit tests.
However, the method must be public (or internal) and user of `LoginUseCase` can potentially misuse it by calling networking code directly.

As a result, we create a separate class for making network calls.

## NetworkingService

```swift
class NetworkingService {
    func post<T>(
        to endpoint: String, 
        encodedWith parameters [String: AnyObject],
        then completion: @escaping (Result<T>) -> Void
    ) {
        // Networking code here
    }

    func get(...) { ... }
    func put(...) { ... }
}
```

Our login use case now looks something like this

```swift
class LoginUseCase {
    private weak var delegate: LoginUseCaseDelegate
    private let networkingService: NetworkingService 

    init(delegate: LoginUseCaseDelegate, networkingService NetworkingService = .init()) {
        self.delegate = delegate
        self.networkingService = networkingService
    }

    func execute(username: String, password: String) {
        let endpoint = "www.sampleurl.com/login/"
        let params = ["username": username, "password": password)
        networkingService.post(to: endpoint, encodedWith: params) { result: Result<LoginResult> in 
            // Handle result
        }
    }
}
```

It looks promising already. 
However, how can we actually call the `completion` closure with the appropriate data?
Because the `post<T>()` method is generic, we have no concrete way convert response data into meaningful form to use.

## Decodable to the rescue

The solution is simple, and built-in in Swift.
Decodable is a protocol which indicates that this object can be created using json data.
To be more accurate: **decodable from json data**.

In order to work with our `post<T>(...)` method, we define a decodable class and change its signature to `post<T: Decodable>`.
This decodable class represent the response from our server.

Let us arbitrarily define the response structure from server

For success

```json
{
    "status": 0,
    "message": "Success",
    "user": {
        "id": "123",
        "username": "bachld",
        "avatar": "url to avatar",
        "dob": "08/10/1997"
    }
}
```

For failure
```json
{
    "status": 1,
    "message": "Invalid credentials"
}
```

The decodable object

```swift
struct LoginResponse: Decodable {
    private let status: Int
    private let message: String
    private let user: UData?

    struct UData: Decodable {
        let id: String
        let username: String
        let avatar: String
        let dob: Date
    }

    // If response's json key is not the same as variable name
    private enum CodingKeys: CodingKey, String {
        case status = "stt" // match response's key
        case message
        case user
    }
}
```

In my opinion, it is a good idea to create a frontier to separate networking related object and application object.
As a result, we will not use the `UData` class directly inside our application 
(As you can tell by its name, I do not expect that ugly name to travel far in our application).
Clear separation is also beneficial in case we want to aggregate data from multiple data sources with different response structure.

Also, because the `UData` is optional, we should unwrap it before handing it to the application.
One way is to use the `Result<>` type (like we did in the closure)

```swift
struct LoginResponse: Decodable {
    ...

    struct UData {
        ...

        func toUserInfo() -> UserInfo {
            return UserInfo(id: id, name: name, avatar: avatar, birthday: dob)
        }
    }

    func toUserInfo() -> Result<UserInfo> {
        guard let u = user else {
            return .erorr(LoginError(message: message))
        }

        return .success(user.toUserInfo())
    }
}
```

Finally, let us review our `LoginUseCase` class

```swift
class LoginUseCase {
    private weak var delegate: LoginUseCaseDelegate
    private let networkingService: NetworkingService 

    init(delegate: LoginUseCaseDelegate, networkingService NetworkingService = .init()) {
        self.delegate = delegate
        self.networkingService = networkingService
    }

    func execute(username: String, password: String) {
        let endpoint = "www.sampleurl.com/login/"
        let params = ["username": username, "password": password)
        networkingService.post(to: endpoint, encodedWith: params, then: completion)
    }

    // create a separated closure to avoid nesting
    let completion: (Result<LoginResponse>) -> Void = { [weak self] r in
        switch r {
            case .error(let e):
                self?.delegate?.loginUseCase(didFail: e)
            case .value(let r):
                self?.handleLoginResponse(r)
        }
    }
    
    // create a separated function to avoid nesting
    private func handleLoginResponse(_ r: LoginResponse) {
        switch r {
            case .error(let e):
                self.delegate?.loginUseCase(didFail: e)
            case .value(let userInfo):
                self.delegate?.loginUseCase(didSucceed: userInfo)
        }
    }
}
```

## Cleaner result types

TODO TODO TODO TODO TODO TODO TODO TODO
The premise is to change `Result<Decodable, ConvertibleToClientData>` into `Result<ClientData, inheriting error>`
TODO TODO TODO TODO TODO TODO TODO TODO

This make our result handling code less nested.

## Do we actually need a `NetworkingService` class

Some reader may consider an alternative path of making an extension for UrlSession

```swift
extension UrlSession {
    func post<T: Decodable>(to endpoint: String, encodedWith parameters: [String : AnyObject]) {
        // Code goes here
    }
}
```

This approach is sound in case you want to stick with UrlSession forever.
However, when started out with networking in iOS, I used Alamofire to simplify the process.
With the `NetworkingService` class approach, we can change our mind and changing the underlying networking framework without affecting any of the call sites.

We can also mix 2 framework in our project by simply define another `NetworkingService` object and inject it to our use cases.

## The actual networking code

Since the post is pretty lengthy already, 
I recommend you having a look at other tutorials using 
[UrlSession](<++>) or
[Alamofire](<++>).

Alternatively, take a look at the [sample project](<++>) for the Alamofire implementation.

## Reference

