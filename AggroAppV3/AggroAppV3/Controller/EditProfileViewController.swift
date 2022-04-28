//
//  EditProfileViewController.swift
//  AggroAppV3
//
//  Created by WUMBAch on 18.04.2022.
//

import UIKit
import Firebase
import SnapKit

protocol EditProfileViewControllerDelegate: class {
    func controller(_ controller: EditProfileViewController, wantsToUpdate user: User)
}

class EditProfileViewController: UIViewController {
    
    // MARK: - UI
    
    let profileImageView = UIImageView()
    private let imagePicker = UIImagePickerController()
    private var selectedImage: UIImage? {
        didSet {
            profileImageView.image = selectedImage
        }
    }
    //    let changeLoginLabel: UILabel = {
    //        let label = UILabel()
    //        label.text = "Edit Login"
    //        label.font = UIFont.boldSystemFont(ofSize: 14)
    //        return label
    //    }()
    let changeLoginLabel = UILabel()
    let changeButton = UIButton(type: .system)
    var fullnameTextField =  UITextField()
    let saveButton = UIButton(type: .system)
    
    // MARK: - Properties

    private var fullnameChanged = false
    private var imageChanged = false
    private var viewModel = UpdateUserDataViewModel()
    weak var delegate: EditProfileViewControllerDelegate?
    
    private var user: User? {
        didSet {
            configureProfileImage()
        }
    }
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserWithFirestore()
        configureUI()
        // Do any additional setup after loading the view.
    }
    
    // MARK: - Selectors
    
    @objc func handleCancel() {
        dismiss(animated: true)
    }
    
    @objc func handleDone() {
        updateUserData()
    }
    
    @objc func handleChangeProfilePhoto() {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func handleUpdateUserFullname(_ sender: UITextField) {
        if sender == fullnameTextField {
            viewModel.fullname = fullnameTextField.text
            fullnameChanged = true
        }
        updateForm()
    }
    
    // MARK: - API
    
    func fetchUserWithFirestore() {
        Service.fetchUserWithFirestore { user in
            self.user = user
        }
    }
    
    func updateUserData() {
        guard var user = user else { return }
        if imageChanged {
            user.profileImageUrl = viewModel.profileImageUrl!
            self.delegate?.controller(self, wantsToUpdate: user)
        }
        if fullnameChanged {
            user.fullname = viewModel.fullname!
            Service.updateUserData(user: user) { err in
                self.delegate?.controller(self, wantsToUpdate: user)
            }
        }
        if fullnameChanged && imageChanged {
            user.profileImageUrl = viewModel.profileImageUrl!
            user.fullname = viewModel.fullname!
            Service.updateUserData(user: user) { err in
                self.delegate?.controller(self, wantsToUpdate: user)
            }
        }
    }
    
    // MARK: - Helpers
    
    func configureUI() {
        configureGradientBackground()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.barStyle = .black
        navigationItem.title = "Edit profile"
        
        let backButtonImage = UIImage(systemName: "arrow.left")

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backButtonImage, style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
    }
    
    func configureProfileImage() {
        guard let user = user else { return }
        
        guard let profileImageUrl = URL(string: user.profileImageUrl) else { return }
        profileImageView.sd_setImage(with: profileImageUrl, completed: nil)
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.cornerRadius = 64 / 2
        profileImageView.layer.borderWidth = 3
        view.addSubview(profileImageView)
        profileImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 150, height: 150))
            make.top.equalToSuperview().inset(200)
        }
        configureChangeButton()
    }
    
    func configureChangeButton() {
        
        changeButton.setTitle("Change Profile Photo", for: .normal)
        changeButton.addTarget(self, action: #selector(handleChangeProfilePhoto), for: .touchUpInside)
        changeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        changeButton.setTitleColor(.white, for: .normal)
        view.addSubview(changeButton)
        changeButton.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        configureFullnameLabel()
    }
    
    func configureFullnameLabel() {
        view.addSubview(changeLoginLabel)
        changeLoginLabel.textAlignment = .left
        changeLoginLabel.font = UIFont.systemFont(ofSize: 25)
        changeLoginLabel.text = "Fullname: "
        changeLoginLabel.textColor = .white
        changeLoginLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(changeButton.snp.bottom).offset(20)
        }
        configureFullnameTextField()
    }
    
    func configureFullnameTextField() {
        guard let user = user else { return }
        let fullname = user.fullname
        fullnameTextField = CustomTextField(placeholder: fullname)
        fullnameTextField.addTarget(self, action: #selector(handleUpdateUserFullname), for: .editingChanged)
        
        view.addSubview(fullnameTextField)
        fullnameTextField.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.right.equalToSuperview().inset(20)
            make.top.equalTo(changeLoginLabel.snp.bottom).offset(20)
        }
        configureSaveButton()
    }
    
    func configureSaveButton() {
        saveButton.setTitle("Save", for: .normal)
        saveButton.isEnabled = false
        saveButton.addTarget(self, action: #selector(handleDone), for: .touchUpInside)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(40)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.editedImage] as? UIImage else { return }
        self.selectedImage = image
        self.imageChanged = true
        self.showLoader(true)
        Service.updateProfileImage(image: image) { profileImageUrl in
            self.viewModel.profileImageUrl = profileImageUrl
            self.updateForm()
            self.showLoader(false)
        }
        dismiss(animated: true)
    }
}

extension EditProfileViewController: FormViewModel {
    func updateForm() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.saveButton.isEnabled = ((self?.viewModel.shouldEnableButton) != nil)
            self?.saveButton.setTitleColor(self?.viewModel.buttonTitleColor, for: .normal)
        }
    }
}
