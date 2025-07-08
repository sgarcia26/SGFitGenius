//
//  SettingsView.swift
//  FitGenius
//
//  Created by Sergio Garcia on 2/24/25.
//  Updated by Emanuel Diaz
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true
    @EnvironmentObject private var currentUser: CurrentUser
    @EnvironmentObject var keyboard: KeyboardResponder

    // 🔹 Editable Fields
    @State private var selectedGoal: Goal = .toneUp
    @State private var selectedEquipment: Equipment = .homeGymFull
    @State private var selectedExperience: ExperienceLevel = .beginner
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var weight: String = ""

    @State private var kneeInjury = false
    @State private var shoulderInjury = false
    @State private var lowerBackPain = false
    @State private var asthma = false
    @State private var arthritis = false

    @State private var errorMessage: String?
    
    //@StateObject private var keyboard = KeyboardResponder()

    // 🔹 Focus management
    @FocusState private var focusedField: Field?

    enum Field {
        case feet, inches, weight
    }

    var body: some View {
        NavigationView {
            ZStack {
                Image("ForestBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Settings")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                            .padding(.top)
                    
                    // 🔹 Goal Picker
                    HStack {
                        Text("Goal:")
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                            .frame(width: 120, alignment: .leading)
                        
                        // 🔹 Wrap Picker in a fixed-width container
                        ZStack {
                            // Transparent background so it has width but invisible
                            Text("//////////////////////////////////////////////")
                                .opacity(0)
                                .padding(.horizontal)
                            
                            Picker("", selection: $selectedGoal) {
                                ForEach(Goal.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    
                    // 🔹 Equipment Picker
                    HStack {
                        Text("Equipment:")
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                            .frame(width: 120, alignment: .leading)
                        
                        // 🔹 Wrap Picker in a fixed-width container
                        ZStack {
                            // Transparent background so it has width but invisible
                            Text("//////////////////////////////////////////////")
                                .opacity(0)
                                .padding(.horizontal)
                            
                            Picker("", selection: $selectedEquipment) {
                                ForEach(Equipment.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    
                    
                    // 🔹 Experience Picker
                    HStack {
                        Text("Experience:")
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                            .frame(width: 120, alignment: .leading)
                        
                        // 🔹 Wrap Picker in a fixed-width container
                        ZStack {
                            // Transparent background so it has width but invisible
                            Text("//////////////////////////////////////////////")
                                .opacity(0)
                                .padding(.horizontal)
                            
                            Picker("", selection: $selectedExperience) {
                                ForEach(ExperienceLevel.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    
                    // 🔹 Height
                    HStack {
                        HStack {
                            Text("Height (ft, in):")
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                            Spacer()
                        }
                        .frame(width: 120, alignment: .leading)
                        
                        TextField("Feet", text: $heightFeet)
                            .padding()
                            .frame(width: 80, height: 45)
                            .background(Color.white)
                            .cornerRadius(10)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .feet)
                            .submitLabel(.done)
                        
                        TextField("Inches", text: $heightInches)
                            .padding()
                            .frame(width: 80, height: 45)
                            .background(Color.white)
                            .cornerRadius(10)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .inches)
                            .submitLabel(.done)
                    }
                    
                    // 🔹 Weight
                    HStack {
                        HStack {
                            Text("Weight (lbs):")
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                            Spacer()
                        }
                        .frame(width: 120, alignment: .leading)
                        
                        TextField("Weight", text: $weight)
                            .padding()
                            .frame(width: 100, height: 45)
                            .background(Color.white)
                            .cornerRadius(10)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .weight)
                            .submitLabel(.done)
                    }
                    
                    // 🔹 Injury Toggles
                    Group {
                        HStack {
                            Text("Knee Injury")
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                                .frame(width: 220, alignment: .leading)
                            Toggle("", isOn: $kneeInjury)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Shoulder Injury")
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                                .frame(width: 220, alignment: .leading)
                            Toggle("", isOn: $shoulderInjury)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Lower Back Pain")
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                                .frame(width: 220, alignment: .leading)
                            Toggle("", isOn: $lowerBackPain)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Asthma / Respiratory Conditions")
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                                .frame(width: 220, alignment: .leading)
                            Toggle("", isOn: $asthma)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Arthritis / Joint Pain")
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                                .frame(width: 220, alignment: .leading)
                            Toggle("", isOn: $arthritis)
                                .labelsHidden()
                        }
                    }
                    .padding(.top)
                    
                    // 🔹 Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }
                    
                    // 🔹 Save Button
                    Button("Save Changes") {
                        updateUserProfile()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    // 🔹 Logout Button
                    Button("Log Out") {
                        AuthManager.shared.logOut { success, error in
                            if success {
                                isLoggedIn = false
                            } else {
                                print("❌ Logout failed:", error ?? "Unknown error")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    }
                    .padding()
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { focusedField = nil }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(keyboard.currentHeight > 0)
            .animation(.easeOut(duration: 0.2), value: keyboard.currentHeight)
            .onAppear { loadUserProfile() }
        }
    }
    
    // MARK: - Load Profile Data
    func loadUserProfile() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User not logged in."
            return
        }

        let db = Firestore.firestore()
        let ref = db.collection("users").document(user.uid)

        ref.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()

                selectedGoal = Goal(rawValue: data?["goal"] as? String ?? "") ?? .toneUp
                selectedEquipment = Equipment(rawValue: data?["equipment"] as? String ?? "") ?? .homeGymFull
                selectedExperience = ExperienceLevel(rawValue: data?["experienceLevel"] as? String ?? "") ?? .beginner

                if let heightInInches = data?["heightInInches"] as? Int {
                    heightFeet = "\(heightInInches / 12)"
                    heightInches = "\(heightInInches % 12)"
                }

                if let weightVal = data?["weight"] as? Double {
                    weight = "\(weightVal)"
                }

                if let injuries = data?["injuries"] as? [String] {
                    kneeInjury     = injuries.contains(Injury.kneeInjury.rawValue)
                    shoulderInjury = injuries.contains(Injury.shoulderInjury.rawValue)
                    lowerBackPain  = injuries.contains(Injury.lowerBackPain.rawValue)
                    asthma         = injuries.contains(Injury.asthma.rawValue)
                    arthritis      = injuries.contains(Injury.arthritis.rawValue)
                }
            } else {
                errorMessage = "Failed to load profile."
            }
        }
    }

    // MARK: - Save Changes to Firestore
    func updateUserProfile() {
        guard
            let user = Auth.auth().currentUser,
            let feet = Int(heightFeet),
            let inches = Int(heightInches),
            let weightVal = Double(weight)
        else {
            errorMessage = "Please check your height and weight entries."
            return
        }

        let totalInches = feet * 12 + inches

        let injuriesArray: [String] = [
            kneeInjury     ? Injury.kneeInjury.rawValue     : nil,
            shoulderInjury ? Injury.shoulderInjury.rawValue : nil,
            lowerBackPain  ? Injury.lowerBackPain.rawValue  : nil,
            asthma         ? Injury.asthma.rawValue         : nil,
            arthritis      ? Injury.arthritis.rawValue      : nil
        ].compactMap { $0 }

        let db = Firestore.firestore()
        let ref = db.collection("users").document(user.uid)

        let updatedData: [String: Any] = [
            "goal": selectedGoal.rawValue,
            "equipment": selectedEquipment.rawValue,
            "experienceLevel": selectedExperience.rawValue,
            "heightInInches": totalInches,
            "weight": weightVal,
            "injuries": injuriesArray
        ]

        ref.updateData(updatedData) { error in
            if let error = error {
                errorMessage = "Failed to update: \(error.localizedDescription)"
            } else {
                errorMessage = "Profile updated!"
            }
        }
    }
}
