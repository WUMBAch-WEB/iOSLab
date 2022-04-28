//
//  LoginContoller.swift
//  AggroAppV3
//
//  Created by WUMBAch on 09.04.2022.
//

import UIKit
import Firebase
import GoogleSignIn
import SDWebImage

protocol AuthenticationDelegate: class {
    func authenticationComplete()
}

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    
    let signInConfig = GIDConfiguration.init(
        clientID: "727889538671-dk72bldihdahlbfejq6reapru009g1nh.apps.googleusercontent.com")

    
    private var viewModel = LoginViewModel()
    weak var delegate: AuthenticationDelegate?
    
    private let iconImage = UIImageView(image: UIImage(named: "firebase-logo"))
    private let emailTextField: UITextField = CustomTextField(placeholder: "Email")
    
    private let passwordTextField: CustomTextField = {
        let tf = CustomTextField(placeholder: "Password")
        tf.isSecureTextEntry = true
        return tf
    }()
    
    private let loginButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.title = "Log In"
        button.addTarget(self,
                         action: #selector(handleLogin),
                         for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        return button
    }()
    
    private let forgotPasswordButton: UIButton = {
        let button = HelpButton(type: .system)
        
        button.configure(text: "Forgot your password? ", boldText: "Get help")
        
        button.addTarget(self, action: #selector(showForgotPassword),
                         for: .touchUpInside)
        
        return button
    }()
    
    private let dividerView = DivederView()
    
    private let googleLoginButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "btn_google_light_pressed_ios")?.withRenderingMode(.alwaysOriginal)
        button.imageView?.contentMode = .scaleAspectFill
        button.imageView?.layer.cornerRadius = button.imageView?.frame.height ?? 20 / 2
        button.setImage(image, for: .normal)
        button.setTitle("Log in with Google", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleGoogleLogin), for: .touchUpInside)
        return button
    }()
    
    private let dontHaveAccountButton: UIButton = {
        let button = HelpButton(type: .system)
        button.configure(text: "Don't have an account? ", boldText: "Sign Up")
        
        button.addTarget(self, action: #selector(showRegistrationViewController),
                         for: .touchUpInside)
        
        return button
    }()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureNotificationObservers()
        
    }
    
    // MARK: - Selectors
    @objc func handleLogin() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        showLoader(true)
        
        Service.logUserIn(withEmail: email, password: password) { result, error in
            self.showLoader(false)
            
            if let error = error {
                self.showMessage(withTitle: "Error", message: error.localizedDescription)
                return
            }
            
            self.delegate?.authenticationComplete()
        }
    }
    
    @objc func showForgotPassword() {
        let controller = ResetPasswordViewController()
        controller.email = emailTextField.text
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc func handleGoogleLogin() {
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: self) { user, error in
            guard error == nil else { return }
            Service.signInWitnGoogleFirestore(didSignInFor: user!) { error in
                self.delegate?.authenticationComplete()
            }
          }
    }
    
    @objc func showRegistrationViewController() {
        let viewController = RegistrationViewController()
        viewController.delegate = delegate
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func textDidChange(_ sender: UITextField) {
        if sender == emailTextField {
            viewModel.email = sender.text
        } else {
            viewModel.password = sender.text
        }
        updateForm()
    }
    
    // MARK: - Helpers
    func configureUI() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
        
        configureGradientBackground()
        
        view.addSubview(iconImage)
        iconImage.centerX(inView: view)
        iconImage.setDimensions(height: 120, width: 120)
        iconImage.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        
        let stack = UIStackView(
            arrangedSubviews: [
                emailTextField,
                passwordTextField,
                loginButton
            ]
        )
        stack.axis = .vertical
        stack.spacing = 20
        
        view.addSubview(stack)
        stack.anchor(top: iconImage.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 32, paddingLeft: 32, paddingRight: 32)
        
        let secondStack = UIStackView(arrangedSubviews: [forgotPasswordButton, dividerView, googleLoginButton])
        
        secondStack.axis = .vertical
        secondStack.spacing = 28
        
        view.addSubview(secondStack)
        secondStack.anchor(top: stack.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 24, paddingLeft: 32, paddingRight: 32)
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.centerX(inView: view)
        dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor)
        
    }
    
    func configureNotificationObservers() {
        emailTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    func configureGoogleSignIn() {
    }
}

// MARK: - FormViewModel

extension LoginViewController: FormViewModel {
    func updateForm() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.loginButton.isEnabled = ((self?.viewModel.shouldEnableButton) != nil)
            self?.loginButton.backgroundColor = self?.viewModel.buttonBackgroundColor
            self?.loginButton.setTitleColor(self?.viewModel.buttonTitleColor, for: .normal)
        }
        
        
    }
}

// MARK: - ResetPasswordViewControllerDelegate


extension LoginViewController: ResetPasswordViewControllerDelegate {
    func didSendResetPasswordLink() {
        navigationController?.popViewController(animated: true)
        self.showMessage(withTitle: "Success", message: MSG_RESET_PASSWORD_LINK_SENT)
    }
}
