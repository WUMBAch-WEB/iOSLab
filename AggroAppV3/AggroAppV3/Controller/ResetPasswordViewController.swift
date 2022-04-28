//
//  ResetPasswordViewController.swift
//  AggroAppV3
//
//  Created by WUMBAch on 10.04.2022.
//

import UIKit

protocol ResetPasswordViewControllerDelegate: class {
    func didSendResetPasswordLink()
}

class ResetPasswordViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: ResetPasswordViewControllerDelegate?
    private var viewModel = ResetPasswordViewModel()
    var email: String?
    
    private let iconImage = UIImageView(image: UIImage(named: "firebase-logo"))
    
    private let emailTextField: UITextField = CustomTextField(placeholder: "Email")
    
    private let resetPasswordButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.title = "Send Reset Link"
        button.addTarget(self,
                         action: #selector(handleResetPassword),
                         for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        return button
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.addTarget(self,
                         action: #selector(handleDismissal),
                         for: .touchUpInside)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        return button
    }()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureNotificationObservers()
        loadEmail()
    }
    
    // MARK: - Selectors
    
    @objc func handleResetPassword() {
        guard let email = viewModel.email else { return }
        
        showLoader(true)
        
        Service.resetPassword(forEmail: email) { error in
            self.showLoader(false)
            if let error = error {
                self.showMessage(withTitle: "Error", message: error.localizedDescription)
                return
            }
            
            self.delegate?.didSendResetPasswordLink()
        }
    }
    
    @objc func handleDismissal() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func textDidChange(_ sender: UITextField) {
        if sender == emailTextField {
            viewModel.email = sender.text
        }
        updateForm()
    }

    // MARK: - Helpers
    
    func configureUI() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
        
        configureGradientBackground()
        
        view.addSubview(backButton)
        backButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 16)
        
        view.addSubview(iconImage)
        iconImage.centerX(inView: view)
        iconImage.setDimensions(height: 120, width: 120)
        iconImage.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        
        let stack = UIStackView(arrangedSubviews: [emailTextField,
                                                   resetPasswordButton])
        stack.axis = .vertical
        stack.spacing = 20
        
        view.addSubview(stack)
        stack.anchor(top: iconImage.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 32, paddingLeft: 32, paddingRight: 32)
    }
    
    func loadEmail() {
        guard let email = email else { return }
        viewModel.email = email
        
        emailTextField.text = email
        
        updateForm()
    }
    
    func configureNotificationObservers() {
        emailTextField.addTarget(self, action: #selector(textDidChange),
                                 for: .editingChanged)
    }
    
}

// MARK: - FormViewModel
extension ResetPasswordViewController: FormViewModel {
    func updateForm() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.resetPasswordButton.isEnabled = ((self?.viewModel.shouldEnableButton) != nil)
            self?.resetPasswordButton.backgroundColor = self?.viewModel.buttonBackgroundColor
            self?.resetPasswordButton.setTitleColor(self?.viewModel.buttonTitleColor, for: .normal)
        }
    }
}
