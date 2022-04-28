//
//  HomeViewController.swift
//  AggroAppV3
//
//  Created by WUMBAch on 10.04.2022.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    private var user: User? {
        didSet {
            presentOnboardingViewControllerIfNeccessary()
            configureProfileImage()
            showWelcomeLable()
        }
    }
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 28)
        label.alpha = 0
        return label
    }()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticateUSer()
        configureUI()
    }

    // MARK: - Selectors
    
    @objc func handleLogout() {
        let alert = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            self.logout()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func handleEditProfile() {
        let controller = EditProfileViewController()
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
        return
    }
    
    // MARK: - API
    
    func fetchUser() {
        Service.fetchUser { user in
            self.user = user
        }
    }
    
    func fetchUserWithFirestore() {
        Service.fetchUserWithFirestore { user in
            self.user = user
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            self.presentLoginController()
        } catch {
            print("DEBUG: Error signing out")
        }
    }
    
    func authenticateUSer() {
        if Auth.auth().currentUser?.uid == nil {
            DispatchQueue.main.async {
                self.presentLoginController()
            }
        } else {
//            fetchUser()
            fetchUserWithFirestore()
        }
    }

    // MARK: - Helpers
    
    func configureUI() {
        configureGradientBackground()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.barStyle = .black
        navigationItem.title = "Profile"
        
        let logoutButtonImage = UIImage(systemName: "arrow.left")
        let settingsButtonImage = UIImage(systemName: "pencil")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: logoutButtonImage, style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: settingsButtonImage, style: .plain, target: self, action: #selector(handleEditProfile))
        navigationItem.rightBarButtonItem?.tintColor = .white
        
        view.addSubview(welcomeLabel)
        welcomeLabel.centerX(inView: view)
        welcomeLabel.centerY(inView: view)
    }
    
    func configureProfileImage() {
        guard let user = user else { return }
        let profileImageView = UIImageView()
        showLoader(true)
        
        guard let profileImageUrl = URL(string: user.profileImageUrl) else { return }
//        profileImageView.sd_setImage(with: profileImageUrl, completed: nil)
        profileImageView.sd_setImage(with: profileImageUrl)
        showLoader(false)
        view.addSubview(profileImageView)
        profileImageView.centerX(inView: view)
        profileImageView.setDimensions(height: 120, width: 120)
        profileImageView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        
        profileImageView.layer.cornerRadius = 64 / 2
        profileImageView.layer.masksToBounds = true

        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.borderWidth = 3
    }
    
    fileprivate func presentLoginController() {
        let controller = LoginViewController()
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    fileprivate func presentOnboardingViewControllerIfNeccessary() {
        guard let user = user else { return }
        guard !user.hasSeenOnboarding else { return }
        
        let controller = OnboardingViewController()
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    fileprivate func showWelcomeLable() {
        guard let user = user else { return }
        guard user.hasSeenOnboarding else { return }
        
        welcomeLabel.text = "Welcome, \(user.fullname)!"
        
        UIView.animate(withDuration: 1) {
            self.welcomeLabel.alpha = 1
        }
    }

}

// MARK: - OnboardingViewControllerDelegate

extension HomeViewController: OnboardingViewControllerDelegate {
    func controllerWantsToDismiss(_ controller: OnboardingViewController) {
        controller.dismiss(animated: true, completion: nil)
        
//        Service.updateUserHasSeenOnboarding { error, ref in
//            self.user?.hasSeenOnboarding = true
//        }
        
        Service.updateUserHasSeenOnboardingFirestore { error in
            self.user?.hasSeenOnboarding = true
        }
    }
    
    
}

// MARK: - AuthenticationDelegate
extension HomeViewController: AuthenticationDelegate {
    func authenticationComplete() {
        dismiss(animated: true, completion: nil)
        
//        fetchUser()
        fetchUserWithFirestore()
    }
}

// MARK: - EditProfileViewControllerDelegate
extension HomeViewController: EditProfileViewControllerDelegate {
    func controller(_ controller: EditProfileViewController, wantsToUpdate user: User) {
        controller.dismiss(animated: true)
        self.user = user
//        self.loadView()
        self.configureUI()
        self.configureProfileImage()
    }
}
