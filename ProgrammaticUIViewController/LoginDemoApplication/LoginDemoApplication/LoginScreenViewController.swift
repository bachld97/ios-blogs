import UIKit

class LoginScreenViewController: UIViewController {
    private lazy var loginScreenView = LoginScreenView(handler: self)
    private lazy var loginUseCase = LoginUseCase(delegate: self)

    override func loadView() {
        view = loginScreenView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
}

extension LoginScreenViewController: LoginScreenActionHandler {
    func loginScreenActionHanlder(performLogin username: String, password: String) {
        loginUseCase.execute(username: username, password: password)
    }
    
    func loginScreenActionHandlerNavigateToSignUp() {
        loginScreenView.errorMessage = "No signup feature here."
    }
}

extension LoginScreenViewController: LoginUseCaseDelegate {
    func loginUseCase(didFail errorMessage: String) {
        loginScreenView.errorMessage = errorMessage
    }
}
