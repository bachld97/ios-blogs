protocol LoginUseCaseDelegate: class {
    func loginUseCase(didFail errorMessage: String)
}
