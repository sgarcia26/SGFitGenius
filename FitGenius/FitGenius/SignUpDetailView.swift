//
//  SignUpDetailView.swift
//  FitGenius
//
//  Created by Emanuel Diaz
//

import SwiftUI

// View that collects basic user details (name, email, password) as the first step in sign-up.
struct SignUpDetailView: View {
    // State for user-entered fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""

    // Controls navigation to the next view
    @State private var showNextStep = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title
                Text("Create Your Account")
                    .font(.title)
                    .padding(.top)

                // Input fields
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                // Next Button
                Button("Next") {
                    showNextStep = true // Triggers navigation
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                // Disclaimer
                Text("Disclaimer: This app provides general fitness guidance and is not a substitute for professional medical advice.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
            // Modern navigation (replaces deprecated NavigationLink)
            .navigationDestination(isPresented: $showNextStep) {
                SignUpMetricsView(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    password: password
                )
            }
        }
    }
}
