//
//  SignUpMetricsView.swift
//  FitGenius
//
//  Created by Emanuel Diaz
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignUpMetricsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    // Inject the singleton that listens & syncs Firestore for us
    // Sergio Garcia
    @EnvironmentObject private var currentUser: CurrentUser   // ← CHANGED

    // Values passed from SignUpDetailView
    let firstName: String
    let lastName: String
    let email: String
    let password: String

    // User selection states
    @State private var selectedGoal: Goal = .toneUp
    @State private var selectedEquipment: Equipment = .homeGymFull
    @State private var selectedExperience: ExperienceLevel = .beginner

    // Health metrics
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var weight: String = ""

    // Injuries (stored as booleans in Firestore)
    @State private var kneeInjury = false
    @State private var shoulderInjury = false
    @State private var lowerBackPain = false
    @State private var asthma = false
    @State private var arthritis = false

    // Error message
    @State private var errorMessage: String?
    
    @FocusState private var focusedField: Field?

    enum Field {
        case feet, inches, weight
    }
    
    // Builds the main sign-up form where users input their fitness goals, experience, height, weight, and injury history.
    var body: some View {
        VStack(spacing: 20) {
            Text("Tell us about yourself")
                .font(.title)
                .bold()
                .padding(.top)

            // Picker section with aligned labels
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Goal:")
                        .frame(width: 100, alignment: .leading)
                    Picker("Goal", selection: $selectedGoal) {
                        ForEach(Goal.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                HStack {
                    Text("Equipment:")
                        .frame(width: 100, alignment: .leading)
                    Picker("Equipment", selection: $selectedEquipment) {
                        ForEach(Equipment.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                HStack {
                    Text("Experience:")
                        .frame(width: 100, alignment: .leading)
                    Picker("Experience Level", selection: $selectedExperience) {
                        ForEach(ExperienceLevel.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }

            // Height input (feet and inches)
            HStack {
                TextField("Feet", text: $heightFeet)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .feet)

                TextField("Inches", text: $heightInches)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .inches)
            }

            // Weight input
            TextField("Weight (in pounds)", text: $weight)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .weight)

            // Injury Toggles
            Toggle("Knee Injury", isOn: $kneeInjury)
            Toggle("Shoulder Injury", isOn: $shoulderInjury)
            Toggle("Lower Back Pain", isOn: $lowerBackPain)
            Toggle("Asthma / Respiratory Conditions", isOn: $asthma)
            Toggle("Arthritis / Joint Pain", isOn: $arthritis)

            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            // Create Account Button
            Button("Create Account") {
                createAccount()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }

    // MARK: - Create Firebase User + Store Firestore Data
    func createAccount() {
        // Validate fields
        guard
            let feet = Int(heightFeet),
            let inches = Int(heightInches),
            let weightValue = Double(weight)
        else {
            errorMessage = "Please enter valid height and weight values."
            return
        }

        // Sergio Garcia
        let totalInches = feet * 12 + inches

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Auth Error: \(error.localizedDescription)"
                return
            }

            guard let userID = result?.user.uid else {
                errorMessage = "Could not retrieve user ID."
                return
            }

            // 3) Build your Firestore payload
            // Sergio Garcia
            let injuriesArray: [String] = [
                kneeInjury     ? Injury.kneeInjury.rawValue     : nil,
                shoulderInjury ? Injury.shoulderInjury.rawValue : nil,
                lowerBackPain  ? Injury.lowerBackPain.rawValue  : nil,
                asthma         ? Injury.asthma.rawValue         : nil,
                arthritis      ? Injury.arthritis.rawValue      : nil
            ].compactMap { $0 }

            let db = Firestore.firestore()

            let userData: [String:Any] = [
                "firstName":         firstName,
                "lastName":          lastName,
                "email":             email,
                "goal":              selectedGoal.rawValue,
                "equipment":         selectedEquipment.rawValue,
                "experienceLevel":   selectedExperience.rawValue,
                "heightInInches":    totalInches,                   // ← CHANGED
                "weight":            weightValue,
                "injuries":          injuriesArray                  // ← CHANGED
            ]

            // 4) Write to Firestore
            db.collection("users").document(userID).setData(userData) { error in
                if let error = error {
                    errorMessage = "Firestore Error: \(error.localizedDescription)"
                } else {
                    isLoggedIn = true
                }
            }
        }
    }
}

// Sergio Garcia
// Enumerations defining user options for goals, equipment access, injuries, and experience level.
// These are used in form pickers and stored in Firestore as raw values.

enum Goal: String, CaseIterable, Codable {
    case toneUp           = "Tone up"
    case loseWeight       = "Lose weight"
    case buildMuscle      = "Build Muscle"
    case strengthTraining = "Strength Training"
    case improvedEndurance = "Improved Endurance"
}

enum Equipment: String, CaseIterable, Codable {
    case homeGymFull    = "At Home Gym (Dumbells and Yoga Mat)"
    case homeGymMatOnly = "At Home Gym (Yoga Mat)"
    case gymAccess      = "Gym Access"
    case noEquipment    = "No Equipment"
}

enum Injury: String, CaseIterable, Codable {
    case kneeInjury     = "Knee Injury"
    case shoulderInjury = "Shoulder Injury"
    case lowerBackPain  = "Lower Back Pain"
    case asthma         = "Asthma/Respiratory Conditions"
    case arthritis      = "Arthritis/Joint Pain"
}

enum ExperienceLevel: String, CaseIterable, Codable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"
}
