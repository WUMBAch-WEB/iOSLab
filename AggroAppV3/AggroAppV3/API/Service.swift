//
//  Service.swift
//  AggroAppV3
//
//  Created by WUMBAch on 10.04.2022.
//

import Firebase
import GoogleSignIn

typealias DatabaseCompletion = ((Error?, DatabaseReference) -> Void)
typealias FirestoreCompletion = (Error?) -> Void

struct Service {
    static func logUserIn(withEmail email: String, password: String, completion: AuthDataResultCallback?) {
        Auth.auth().signIn(withEmail: email, password: password, completion: completion)
    }
    
    static func registerUserWithFirebase(withEmail email: String, password: String, fullname: String, completion: @escaping(DatabaseCompletion)) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("DEBUG: Failed to create user with error: \(error.localizedDescription)")
                completion(error, DB_USERS_REF)
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            let values = ["email": email,
                          "fullname": fullname,
                          "hasSeenOnboarding": false] as [String : Any]
            
            DB_USERS_REF.child(uid).updateChildValues(values, withCompletionBlock: completion)
        }
    }
    
    static func registerUserWithFirestore(withEmail email: String, password: String, fullname: String, profileImageUrl: String, completion: @escaping(FirestoreCompletion)) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("DEBUG: Failed to create user with error: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            let values = ["email": email,
                          "fullname": fullname,
                          "hasSeenOnboarding": false,
                          "profileImageUrl" : profileImageUrl,
                          "uid": uid] as [String : Any]
            
            Firestore.firestore().collection("users").document(uid).setData(values, completion: completion)
        }
    }
    
    static func signInWithGoogle(didSignInFor user: GIDGoogleUser, completion: @escaping(DatabaseCompletion)) {
        let authentication = user.authentication
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken ?? "", accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                print("DEBUG: Failed to sign in with google: \(error.localizedDescription)")
                return
            }
            
            guard let uid = result?.user.uid else { return }
                        
            
            DB_USERS_REF.child(uid).observeSingleEvent(of: .value) { snapshot in
                if !snapshot.exists() {
                    print("DEBUG: User doesn't exist, create user...")
                    guard let email = result?.user.email else { return }
                    guard let fullname = result?.user.displayName else { return }
                    let values = ["email": email,
                                  "fullname": fullname,
                                  "hasSeenOnboarding": false] as [String : Any]
                    
                    DB_USERS_REF.updateChildValues(values, withCompletionBlock: completion)
                    
                } else {
                    print("DEBUG: User already exists...")
                    completion(error, DB_USERS_REF.child(uid))
                }
            }
        }
    }
    
    static func signInWitnGoogleFirestore(didSignInFor user: GIDGoogleUser, completion: @escaping(FirestoreCompletion)) {
        let authentication = user.authentication
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken ?? "", accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                print("DEBUG: Failed to sign in with google: \(error.localizedDescription)")
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            
            Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
                if !snapshot!.exists {
                    print("DEBUG: User doesn't exist, create user...")
                    guard let email = result?.user.email else { return }
                    guard let fullname = result?.user.displayName else { return }
                    guard let profileImageUrl = result?.user.photoURL?.absoluteString else { return }
                    
                    let values = ["email": email,
                                  "fullname": fullname,
                                  "hasSeenOnboarding": false,
                                  "profileImageUrl" : profileImageUrl,
                                  "uid": uid] as [String : Any]
                    
                    Firestore.firestore().collection("users").document(uid).setData(values, completion: completion)
                } else {
                    print("DEBUG: User already exists...")
                    completion(error)
                }
            }
        }
    }
    
    static func fetchUser(comletion: @escaping(User) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        DB_USERS_REF.child(uid).observeSingleEvent(of: .value) { snapshot in
            let uid = snapshot.key
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            
            let user = User(uid: uid, dictionary: dictionary)
            comletion(user)
        }
    }
    
    static func fetchUserWithFirestore(comletion: @escaping(User) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            print("DEBUG: Snapshot is \(snapshot?.data())")
            guard let dictionary = snapshot?.data() else { return }
            
            let user = User(dictionary: dictionary)
            comletion(user)
        }
    }
    
    static func updateUserHasSeenOnboarding(completion: @escaping(DatabaseCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        DB_USERS_REF.child(uid).child("hasSeenOnboarding").setValue(true, withCompletionBlock: completion)
    }
    
    static func updateUserHasSeenOnboardingFirestore(completion: @escaping(FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let data = ["hasSeenOnboarding": true]
        
        Firestore.firestore().collection("users").document(uid).updateData(data, completion: completion)
    }
    
    static func resetPassword(forEmail email: String, completion: SendPasswordResetCallback?) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }
    
    static func updateUserData(user: User, completion: @escaping(FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let data = ["fullname": user.fullname]
        print(data)
        
        Firestore.firestore().collection("users").document(uid).updateData(data, completion: completion)
    }
    
    static func updateProfileImage(image: UIImage,
                                   completion: @escaping(String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.3) else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let filename = NSUUID().uuidString
        let storageRef = STORAGE_PROFILE_IMAGES.child(filename)
        
        storageRef.putData(imageData, metadata: nil) { meta, error in
            storageRef.downloadURL { url, error in
                guard let profileImageUrl = url?.absoluteString else { return }
                let data = ["profileImageUrl": profileImageUrl]
                Firestore.firestore().collection("users").document(uid).updateData(data) { error in
                    completion(profileImageUrl)
                }
            }
        }
    }
}
