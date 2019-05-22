# Adding functionality

In my previous blog, [programmatic UIViewController](www.google.com),
we stopped at calling `delegate?.performLogin(...)` inside `LoginScreenView`.
It is tempting to stuff the login implementation inside the view controller.
However, as the view controller increases in functionalities, it gets bulky.
So let us create another class to handle the functionality, namely `LoginUseCase`.

## Login use case

```swift
class LoginUseCase {
    func execute(username: String, password: String) {
        // Do login here
    }
}
```

Since performing login requires a network call, the `execute()` function is done asynchronously.

## Using closure

The quickest and easiest way to handle asynchronous callback is to use a completion block.

```swift
func execute(username: String, password: String,
            completion: @escaping (LoginResult) -> Void) {

}
```

Since the login request is quite simple, it is not that necessary to encapsulate it into a data structure.
However, if you want the method to be expressive, feel free to do so.

```swift
struct LoginRequest {
    let username: String
    let password: String
}
```

One advantage of closure approach is that we can use generics to assist the use case creation development flow.

```swift
protocol UseCase {
    protocol UseCase {
    associatedtype Request
    associatedtype Response
    
    func execute(_ request: Request, onComplete: @escaping (Response) -> Void)
}

class LoginUseCase: UseCase {
    typealias Request = LoginRequest
    typealias Response = LoginResponse
    
    func execute(_ request: LoginRequest, onComplete: @escaping (LoginResponse) -> Void) {
        // ...
    }
}
```

## Using delegate

Another way that I like to use is delegate.

```swift
class LoginUseCase {
    init(delegate: LoginDelegate) {
        this.delegate = delegate
    }
}
```

The advantages of this approach is that we can have expressive callback names.

```swift
// Inside LoginScreenViewController

func loginDelegate(didSuccess userInfo: UserInfo) { /* Navigate to home */ }
```

## Other ways to handle asynchronous code

There are definitely other ways to handle asynchronous request such as using `Future` or using streams with `RxSwift`.
However, I would like to stick with the standard Swift library and not use so many third party library for now to keep the application simple.

If you are interested in other method of handling asynchronous request, have a look at [this blog post](https://medium.com/ios-os-x-development/managing-async-code-in-swift-d7be44cae89f).


## Handling server response

When we send request to server, we usually receive a structured response like JSON or XML.
In swift, there is a built in way to decode JSON data into object or structure by using `Decodable` protocol.

```swift
struct LoginResponse: Decodable {
    let loginSuccess: Boolean
    let userInfo: UserInfo?
}
```

By default, the `Decodable` protocol use the variable name to parse the key inside JSON data.
For example the `LoginResponse` above is able to parse the following JSON.


```json
{
    'loginSuccess': true,
    'userInfo': null
}
```

However, when the response from server has its keys changed such as

```json
{
    'login_success': true,
    'user_info': null
}
```

Now the `LoginResponse` cannot decode the response automatically.
We do not want to change the variable name because the underscored version does not follow Swift coding convention of camel case variable naming.
Instead, we can specify custom JSON key name by specifying coding keys.

```swift
// inside LoginResponse
private enum CodingKeys: String, CodingKey {
    case loginSuccess = "login_success"
    case userInfo = "user_info"
}
```

## Pretty client

The response is fine for now.
We can take it a little bit  further by eliminating optional unwrapping at the call site.

Instead of:

```swift
let completion: (LoginResponse) -> Void = { response in
    guard response.loginSuccess, 
        let userInfo = response.userInfo else {
        // Do something if login failed
    }
    // Do something if login success
}
```


We will have:

```swift
let completion: (LoginResponse) -> Void = { response in
    switch response.result {
        case .failure(let error):
            // handle error
        case .success(let userInfo):
            // handle user info
    }
}
```

To get here, we add a property inside `LoginResponse`.

```swift
var result: Result<UserInfo, LoginError> {
    if loginSuccess {
        guard let ui = userInfo else {
            return error(UnknownLoginError())
        }

        return .success(ui)
    }

    return error(LoginFailureError("Wrong username or password"))
}
```

The server may returns additional information for us to construct a more descriptive login error.
For now just hard code a string if login fail.
