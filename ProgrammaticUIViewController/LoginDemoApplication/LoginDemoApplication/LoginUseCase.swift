class LoginUseCase {
    private weak var delegate: LoginUseCaseDelegate?
    
    init(delegate: LoginUseCaseDelegate) {
        self.delegate = delegate
    }
    
    func execute(username: String, password: String) {
        guard !username.isEmpty, !password.isEmpty else {
            delegate?.loginUseCase(didFail: "Username or password is empty.")
            return
        }
        
        delegate?.loginUseCase(didFail: "Account \(username) not found.")
    }
}

