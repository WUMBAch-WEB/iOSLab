//
//  RegistrationViewController.swift
//  AggroAppV3
//
//  Created by WUMBAch on 10.04.2022.
//

import UIKit
import Firebase

class RegistrationViewController: UIViewController {
    
    // MARK: - Properties
    
    private let imagePicker = UIImagePickerController()
    private var profileImage: UIImage?
    
    private let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "plus_photo"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleAddProfilePhoto), for: .touchUpInside)
        return button
    }()
    
    private var viewModel = RegistrationViewModel()
    weak var delegate: AuthenticationDelegate?

    private let iconImage = UIImageView(image: UIImage(named: "firebase-logo"))
    
    private let emailTextField: UITextField = CustomTextField(placeholder: "Email")
    private let fullnameTextField: UITextField = CustomTextField(placeholder: "Fullname")

    
    private let passwordTextField: CustomTextField = {
        let tf = CustomTextField(placeholder: "Password")
        tf.isSecureTextEntry = true
        return tf
    }()
    
    private let signUpButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.title = "Sign Up"
        button.addTarget(self,
                         action: #selector(handleSignUp),
                         for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        return button
    }()
    
    private let alreadyHaveAccountButton: UIButton = {
        let button = HelpButton(type: .system)
        
        button.configure(text: "Already have an account? ", boldText: "Log In")
        
        button.addTarget(self, action: #selector(showLoginViewController),
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
    
    @objc func handleAddProfilePhoto() {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func handleSignUp() {
        
        guard let profileImage = profileImage else {
            showMessage(withTitle: "Error", message: "You need choose profile image")
            return
        }
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let fullname = fullnameTextField.text else { return }
        
        guard let imageData = profileImage.jpegData(compressionQuality: 0.1) else { return }
        let filename = NSUUID().uuidString
        let storageRef = STORAGE_PROFILE_IMAGES.child(filename)
        
        showLoader(true)
        
        storageRef.putData(imageData, metadata: nil) { meta, error in
            storageRef.downloadURL { url, error in
                guard let profileImageUrl = url?.absoluteString else { return }
                Service.registerUserWithFirestore(withEmail: email, password: password, fullname: fullname, profileImageUrl: profileImageUrl) { error in
                    
                    self.showLoader(false)
                    
                    if let error = error {
                        self.showMessage(withTitle: "Error", message: error.localizedDescription)
                        return
                    }
                    
                    self.delegate?.authenticationComplete()
                }
            }
        }
        
        
//        Service.registerUserWithFirebase(withEmail: email, password: password, fullname: fullname) { error, ref in
//            self.showLoader(false)
//            if let error = error {
//                self.showMessage(withTitle: "Error", message: error.localizedDescription)
//                return
//            }
//
//            self.delegate?.authenticationComplete()
//        }
        
    }
    
    @objc func showLoginViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func textDidChange(_ sender: UITextField) {
        if sender == emailTextField {
            viewModel.email = sender.text
        } else if sender == passwordTextField{
            viewModel.password = sender.text
        } else {
            viewModel.fullname = sender.text
        }
        updateForm()
    }
    
    // MARK: - Helpers
    
    func configureUI() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
        
        configureGradientBackground()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        view.addSubview(plusPhotoButton)
        plusPhotoButton.centerX(inView: view)
        plusPhotoButton.setDimensions(height: 120, width: 120)
        plusPhotoButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        
        let stack = UIStackView(arrangedSubviews: [emailTextField,
                                                   passwordTextField,
                                                   fullnameTextField,
                                                   signUpButton])
        stack.axis = .vertical
        stack.spacing = 20
        
        view.addSubview(stack)
        stack.anchor(top: plusPhotoButton.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 32, paddingLeft: 32, paddingRight: 32)
        
        
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor)
        
    }
    
    func configureNotificationObservers() {
        emailTextField.addTarget(self, action: #selector(textDidChange),
                                 for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textDidChange),
                                    for: .editingChanged)
        fullnameTextField.addTarget(self, action: #selector(textDidChange),
                                    for: .editingChanged)
    }

}

// MARK: - FormViewModel

extension RegistrationViewController: FormViewModel {
    func updateForm() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.signUpButton.isEnabled = ((self?.viewModel.shouldEnableButton) != nil)
            self?.signUpButton.backgroundColor = self?.viewModel.buttonBackgroundColor
            self?.signUpButton.setTitleColor(self?.viewModel.buttonTitleColor, for: .normal)
        }
    }
}

extension RegistrationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let profileImage = info[.editedImage] as? UIImage else { return }
        self.profileImage = profileImage
        
        plusPhotoButton.layer.cornerRadius = 128 / 2
        plusPhotoButton.layer.masksToBounds = true
        plusPhotoButton.imageView?.contentMode = .scaleAspectFill
        plusPhotoButton.imageView?.clipsToBounds = true
        plusPhotoButton.layer.borderColor = UIColor.white.cgColor
        plusPhotoButton.layer.borderWidth = 3
        
        self.plusPhotoButton.setImage(profileImage.withRenderingMode(.alwaysOriginal), for: .normal)
        
        dismiss(animated: true)
    }
}
