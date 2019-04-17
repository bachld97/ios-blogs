import UIKit

class LoginScreenView: UIView {
    private weak var handler: LoginScreenActionHandler?
    var errorMessage: String? = nil {
        didSet {
            errorMessageLabel.text = errorMessage
        }
    }
    
    override var frame: CGRect {
        didSet {
            let width = frame.width - 2 * 32
            let height = frame.height / 7
            usernameLabel.frame = CGRect(x: 32, y: 16, width: width, height: height - 32)
            usernameTextField.frame = CGRect(x: 32, y: 16 + height, width: width, height: height - 32)
            passwordLabel.frame = CGRect(x: 32, y: 16 + 2 * height, width: width, height: height - 32)
            passwordTextField.frame = CGRect(x: 32, y: 16 + 3 * height, width: width, height: height - 32)
            errorMessageLabel.frame = CGRect(x: 32, y: 16 + 4 * height, width: width, height: height - 32)
            signUpButton.frame = CGRect(x: 32, y: 16 + 5 * height, width: width, height: height - 32)
            signInButton.frame = CGRect(x: 32, y: 16 + 6 * height, width: width, height: height - 32)
        }
    }

    init(handler: LoginScreenActionHandler) {
        self.handler = handler
        super.init(frame: .zero)
        addSubview(usernameLabel)
        addSubview(usernameTextField)
        addSubview(passwordLabel)
        addSubview(passwordTextField)
        addSubview(errorMessageLabel)
        addSubview(signUpButton)
        addSubview(signInButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var usernameLabel: UILabel = {
        let v = UILabel()
        v.text = "Username"
        return v
    }()
    
    private lazy var usernameTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "Username goes here"
        v.autocorrectionType = UITextAutocorrectionType.no
        v.delegate = self
        v.returnKeyType = UIReturnKeyType.next
        return v
    }()
    
    private lazy var passwordLabel: UILabel = {
        let v = UILabel()
        v.text = "Password"
        return v
    }()
    
    private lazy var passwordTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "Password goes here"
        v.autocorrectionType = UITextAutocorrectionType.no
        v.isSecureTextEntry = true
        v.delegate = self
        v.returnKeyType = UIReturnKeyType.go
        return v
    }()
    
    private lazy var errorMessageLabel: UILabel = {
        let v = UILabel()
        v.textColor = .red
        v.text = "No error."
        return v
    }()
    
    private lazy var signUpButton: UIButton = {
        let v = UIButton()
        v.setTitle("Sign up", for: .normal)
        v.setTitleColor(.black, for: .normal)
        v.backgroundColor = UIColor.gray
        v.addTarget(self, action: #selector(signUpOnClicK), for: .touchUpInside)
        return v
    }()
    
    private lazy var signInButton: UIButton = {
        let v = UIButton()
        v.setTitle("Sign in", for: .normal)
        v.setTitleColor(.black, for: .normal)
        v.backgroundColor = UIColor.gray
        v.addTarget(self, action: #selector(signInOnClick), for: .touchUpInside)
        return v
    }()
    
    @objc private func signUpOnClicK() {
        handler?.loginScreenActionHandlerNavigateToSignUp()
    }
    
    @objc private func signInOnClick() {
        handler?.loginScreenActionHanlder(
            performLogin: usernameTextField.text ?? "",
            password: passwordTextField.text ?? "")
    }
}

extension LoginScreenView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            textField.resignFirstResponder()
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return false
    }
}
