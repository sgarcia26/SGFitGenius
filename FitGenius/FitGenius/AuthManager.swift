//
//  AuthManager.swift
//  FitGenius
//
//  Created by Emanuel Diaz on 2/13/25.
//

import FirebaseAuth

class AuthManager {
    static let shared = AuthManager()
    
    private init() {} // Singleton instance
    
    
    

    
    // Sign Up Function
    func signUp(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    
    // Log In Function
    func logIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    
    // Log Out Function
    func logOut(completion: @escaping (Bool, String?) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true, nil)
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    // Get Current User
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
}

