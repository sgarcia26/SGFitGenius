//
//  AuthView.swift
//  FitGenius
//
//  Created by Emanuel Diaz on 2/13/25.
//

import SwiftUI
import FirebaseAuth

struct AuthView: View {
    // User credentials and error message state
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    // Login state tracking
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    // Controls visibility of Sign Up screen
    @State private var showSignUpDetail = false

    var body: some View {
        if isLoggedIn {
            // If already logged in, show MainView
            MainView()
        } else {
            NavigationStack {
                ZStack {
                    // Background image layer
                    Image("ForestBackground")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    // Foreground UI content
                    VStack(spacing: 20) {
                        Spacer()

                        // App title
                        Text("FitGenius")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 4, x: 1, y: 1)

                        // Section header
                        Text("Sign In")
                            .font(.title)
                            .foregroundColor(.white)

                        // Email input field
                        TextField("Email", text: $email)
                            .padding()
                            .frame(width: 300, height: 45)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )

                        // Password input field
                        SecureField("Password", text: $password)
                            .padding()
                            .frame(width: 300, height: 45)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )

                        // Display login or password reset errors
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        // Log In button
                        Button(action: {
                            AuthManager.shared.logIn(email: email, password: password) { success, error in
                                if success {
                                    isLoggedIn = true
                                } else {
                                    self.errorMessage = error
                                }
                            }
                        }) {
                            Text("Log In")
                                .frame(width: 200, height: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        // Navigation: open Sign Up screen
                        Button(action: {
                            showSignUpDetail = true
                        }) {
                            Text("Don't have an account?")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .underline()
                        }

                        // Trigger password reset email
                        Button("Forgot Password?") {
                            resetPassword()
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)

                        Spacer()
                    }
                    .padding()
                }
                // Opens sign-up form in a modal sheet
                .sheet(isPresented: $showSignUpDetail) {
                    SignUpDetailView()
                }
            }
        }
    }

    // Firebase password reset logic
    private func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email to reset password."
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
            } else {
                errorMessage = "Password reset email sent!"
            }
        }
    }
}

// Preview in Xcode canvas
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
