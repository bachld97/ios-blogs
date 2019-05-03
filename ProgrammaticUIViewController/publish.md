# Programmatic UIViewcontroller

Programmatic UIViewController is an approach to iOS application development
where we do not rely on storyboards and `.xib` files to create our UIViewController.
Instead, we will launch the UIViewControllers, even the first one, using codes.

## Why should we consider pure code approach?

When beginning with iOS development, storyboards and `.xib` files are great.
They offer quick and reactive way to create UI for our view controllers.

However, as the UI becomes more complicated and the team gets larger,
storyboards start to fall short.
There are multiple drawbacks at the top of my head:

* Dragging `IBOutlet` into source file is tedious and error prone
* Renaming `UIView` causes problem with the storyboard
* Merge conflicts when multiple people are working on a same storyboard

With programmatic layout, we can still use auto layout feature and we can easily
switch to frame-based layout if the UI gets complicated.
Collaborating on source file is also easier compared to using storyboards.
Finally, we do not have to manually click and drag the view into our source files.

So, I decide that I do not want to use storyboards anymore!

## How can we remove the Storyboard?

When creating a `Single page application`, 
XCode automatically creates a storyboard and one view controller for us.
To begin the programmatic `UIViewController` journey, 
we must first know how to do it.

There are already tutorials regarding removal of storyboards in iOS project
(such as [this one](https://medium.com/ios-os-x-development/ios-start-an-app-without-storyboard-5f57e3251a25)).
Therefore, I only provide a short summary in this post.

### Tell XCode not to use Storyboard on launch

Go to `General > Deploment Info` and clear the `Main interface` field.

![No storyboard setting](./no_storyboard.png)


### Launch the UIViewController with code

Go to `AppDelegate.swift` and override function `didFinishLaunchingWithOptions`

```swift
window = UIWindow(frame: UIScreen.main.bounds)
window?.rootViewController = controllerToStart
```

With this approach, we are still able to use navigation controller if we so choose.

```swift
let navController = UINavigationController(
    rootViewController: controllerToSttart)
window?.rootViewController = navController
```

Finally, we will make the controller visible

```swift
window?.makeKeyAnVisible()
```

## Fixing fat UIViewController problem

When opting in for programmatic `UIVIewController`, it is tempting to mix 
child views' initialization and layout into the `UIViewController` source file.
However, that approach is not advisable because the containing UIViewController
tend to 

Instead, we separate the view from our view controller.

Let us walk through an example, which is a `LoginScreenViewController`.

First, we have a look at a fat view controller

```swift
class LoginScreenViewController: UIViewController {
    private var usernameTextField = UITextField()
    private var passwordTextField = UITextField()
    private var loginButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)

        setupViews()
    }

    func setupViews() {
        // Style the textfields, button, set up gesture listener, etc.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Layout views if we use frame-based appraoch
    }
}
```

Our `LoginViewController` gets bigger pretty fast as the number of views increases.
As a result, it is a good idea to separate the view from the view controller.

First we create `LoginScreenView` extending `UIView` and override `loadView()` 
method in `LoginScrenViewController`.

```swift
override func loadView() {
    view = LoginScreenView(delegate: self)
}
```

Notice that we pass `self` to `LoginScreenView` as a delegate because the touch
handling is done from within the view class and we need some mechanism to
notify the view controller of such interactions.
If the screen is simple with limited interactions, we can pass a function or
a closure instead.
However, I prefer using delegate for better naming ability.

The new `LoginViewController` does not care about the view anymore, it only
reacts to user's interaction supported by the view's delegate.

The view's delegate is quite simple in this example

```swift
class LoginScreenViewDelegate {
    loginScreenView(performLogin username: String, password: String)
}
```

The implementation of `LoginScreenView` is quite the same as the code used for
creation and layout of the subviews in original `LoginScreenViewController`
implementation
We will layout subview inside `frame:didSet` method.
In case we want to use a auto layout, we add the constraints inside `init`


```swift
private weak var delegate: LoginScreenViewDelegate?
private lazy var usernameTextField: UILael = {
    // Setup and return an UILabel
}()


private lazy var passwordTextField: UILael = {
    // Setup and return an UILabel
}()

private lazy var loginButton: UIButton = {
    // Setup and return an UIButton, also set up touch handler
}()

override var frame: CGRect {
    didSet {
        // Original code for viewDidLayoutSubview
    }
}

init(delegate: LoginScreenViewDelegate() {
    // Setup layout constraints if we use layout constraints
}

@objc loginButtonOnClick() {
    let username = usernameTextField.text ?? ""
    let password = passwordTextField.text ?? ""
    self.delegate?.loginScreenView(performLogin: username, password: password)
}
```

## Some tiny details

The basic for programmatic and non-fat `UIViewController` is finished and I want
to comment on a few details.

* If the subviews share a significant amount of code, we can consider creating a 
corresponding `UIView` subclass to reuse code.
* The use of lazy variables inside `LoginScreenView` is not necessary, we can 
use lateinit (force unwrap) variables or use `let` and create it inside `init`.
It is just my preference to create it in lazily like that.


Finally, thank you for going through this post.
For associated sample application, 
visit (my repository)[https://bitbucket.org/bachld97/ios-blogs-sample-app/].

## Reference

* Bob the developer's article: [Why I Don't Use Storyboard](https://www.bobthedeveloper.io/blog/why-i-don%E2%80%99t-use-storyboard)
* Boris Ohayon's article: [iOS — Start an app without a storyboard](https://medium.com/ios-os-x-development/ios-start-an-app-without-storyboard-5f57e3251a25)
* Paul Hudson's talk: [Separation of concerns: Refactoring view controllers](https://www.youtube.com/watch?v=hIaPdjS5GNo&t=1568s)
* Lets build that app's Youtube video: [Swift: My Secret to Fixing Fat View Controller: Subclassing](https://www.youtube.com/watch?v=dSdkYEjLI3w)
