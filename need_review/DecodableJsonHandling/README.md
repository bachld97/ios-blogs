# Networking request and response

When I was workign on some of my first project, I ran into a recurring task of making network calls and handling their results.
I am quite certain that most iOS applications nowadays have to complete such task as well.

As a result, I want to share my approach dealing with such task.

Let us resume with the application from my [previous post](http://www.google.com).
We will now implement the login function using a network calls.

## Keep LoginScreenViewController fit

In the previous post, we spend much effort in keeping the `LoginScreenViewController` fit,
and we want to keep it that way while adding features to it.
To keep the `LoginViewController` short and clear, we need to separate the network calls from the view controller.

Firstly, we define a new class: `LoginService`.
This class will help us in making network requests related to the login functionality.

```swift
class LoginService {
    static let shared = LoginService()
    func doLogin(...) {...}
}
```

Then, we modify our `LoginUseCase` class to inject our `LoginService` object.
Simple constructor injection with default value is sufficient for our application thanks to its simplicity.
The `LoginService` can be made into a protocol, 
however its functionality is so limited that I did not want to go through such complexity.

```swift
class LoginUseCase {
    private let loginService: LoginService
    private weak var delegate: LoginUseCaseDelegate?

    init(delegate: LoginUseCaseDelegate, loginService: LoginService = .shared) {
        self.loginService = loginService
        self.delegate = delegate
    }

    func execute(username: String, password: String) {
        loginService.doLogin(...)
    }
}
```

Somewhere along the way, the readers may ask why I do not use `LoginService.shared` directly in execute such as:

```swift
class LoginUseCase {
    private weak var delegate: LoginUseCaseDelegate?

    init(delegate: LoginUseCaseDelegate) {
        self.delegate = delegate
    }

    func execute(username: String, password: String) {
        LoginService.shared.doLogin(...)
    }
}
```

The answer is that by injecting the `LoginService`, we decrease the coupling between the `LoginUseCase` and the `LoginService`.
As a result, we can write unit test more easily (passing our mock object in place of the `loginService` parameter).

The default parameter is there to maintain backward compatibility if our `LoginUseCase` was using `LoginService.shared` directly 
instead of constructor injection.
By supplying default parameter we will not break existing call site while achieving what we need.

I learnt the previous point from John Sundell and [his amazing weekly blog](https://www.swiftbysundell.com/).

## Login Service

In this section, we will take a closer look at our `LoginService` class.

### The call site

I want to simplify the call site, so I create a nested type: `Credential` to represent our username and password.
However, the actual content of the `Credential` is so simple, so a typealias is sufficient (instead of a struct or class).
The actual type used to represent credential is a named tuple.

```swift
class LoginService {
    typealias Credential = (username: String, password: String)
    static let shared = LoginService()
    func doLogin(with credential: Credential) { ... }
}
```

Right now, our `LoginService` has no way to report back to our view controller.
So we need to modify it a little bit and add a completion block to the `doLogin(...)` method.

```swift
func doLogin(with credential: Credential, then completion: @escaping (Bool) -> Void) { ... }
```

For the meantime, we use a `Bool` to notify if the login is success.
However, this representation is flawed, the call site has no idea if the `Bool` means `isSuccess` or `isFailure`.
Later on, we may change the type for a more expressive call site.

```swift
    func execute(username: String, password: String) {
        loginService.doLogin(with: (username, password), then: { isSuccess in 
            // Notify delegate
        })
    }
```

### Network call and Decodable protocol

We can write the networking code directly inside the `LoginService` using any framework of choice such as vanila swifty iOS `URLSession` or thrid party framework like `Alamofire`.
However, I think it is a better idea to abstract the networking away from the `LoginService` class just like we abstracted the `LoginService` away from our view controller.
This is because both mentioned framework are verbose and we can avoid code duplication by defining a generic API.

Some readers may notice that we can simply write an extension to `URLSession` or `Alamofire` instead of a whole dedicated class.
However, when I first begin iOS development, I made use of `Alamofire` for simplicity, but I still want the option to change the framework later on without hurting my call sites.
Therefore I will create a dedicated `NetworkService` class and inject it into `LoginService` class.

```swift
class LoginService {
    init(networkService: NetworkService = .init()) {
        self.networkService = networkService
    }
}
```

Now we will have a look at NetworkService class, which will make use of Alamofire framework.
For brevity of the post as a whole, I skip some development step, showing only the final version and justify my decision.

```swift
class NetworkService {
    func execute<Response: Decodable>(
            request: NetworkRequest,
            then completion: (NetworkResult<Response>) -> Void
    ) {
        let alamofireRequest = request.toAlamofireRequest()
        Alamofire.request(alamofireRequest).responseData { responseData in
            // Decode the response
        }
    }

}

enum NetworkResult<ResultType> {
    case success(ResultType)
    case failure(Error)
}

struct NetworkRequest {
    // Simple wrapper containing endpoint, method, params, cookies, etc.
    func toAlamofireRequest() -> URLRequest { ... }
}
```

We use custom `NetworkRequest` type because we can include data specific to our application in.
For example, in my last project, I always had to include userId in cookies field and custom `NetworkRequest` type simplified the process greatly.
