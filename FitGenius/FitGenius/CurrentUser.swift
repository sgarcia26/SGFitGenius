//
//  CurrentUser.swift
//  FitGenius
//
//  Created by Sergio Garcia on 4/23/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - Shared metric data type

// Holds all the metric fields you store in Firestore
struct UserMetricsData: Codable {
    let goal: Goal
    let heightInInches: Int
    let weight: Double
    let equipment: Equipment
    let injuries: [Injury]
    let experience: ExperienceLevel

    // Convert back into a Firestore-ready dictionary
    var dictionary: [String: Any] {
        [
            "goal": goal.rawValue,
            "heightInInches": heightInInches,
            "weight": weight,
            "equipment": equipment.rawValue,
            "injuries": injuries.map(\.rawValue),
            "experienceLevel": experience.rawValue
        ]
    }
}

// MARK: - Singleton user session

// Manages the current user session, including authentication state and user metrics
final class CurrentUser: ObservableObject {
    static let shared = CurrentUser()

    @Published var uid: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var metrics: UserMetricsData? = nil
    @Published var isLoggedIn: Bool = false
    @Published var metricsLoaded: Bool = false

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    // Initializes Firebase auth listener to track login/logout changes
    private init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                self.uid = user.uid
                self.email = user.email ?? ""
                self.isLoggedIn = true
                self.loadUserMetrics()
            } else {
                self.isLoggedIn = false
                self.uid = ""
                self.firstName = ""
                self.lastName = ""
                self.email = ""
                self.metrics = nil
                self.metricsLoaded = false
            }
        }
    }
    
    // Manually refreshes metrics from Firestore and triggers a completion callback
    func refreshMetrics(completion: @escaping () -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion()
            return
        }

        db.collection("users").document(userUID).getDocument { (document, error) in
            if let error = error {
                print("Error refreshing user metrics: \(error.localizedDescription)")
                completion()
                return
            }

            if let document = document, document.exists, let data = document.data() {
                self.metrics = UserMetricsData(
                    goal: Goal(rawValue: data["goal"] as? String ?? "") ?? .loseWeight,
                    heightInInches: data["heightInInches"] as? Int ?? 0,
                    weight: data["weight"] as? Double ?? 0.0,
                    equipment: Equipment(rawValue: data["equipment"] as? String ?? "") ?? .noEquipment,
                    injuries: (data["injuries"] as? [String] ?? []).compactMap { Injury(rawValue: $0) },
                    experience: ExperienceLevel(rawValue: data["experienceLevel"] as? String ?? "") ?? .beginner
                )
                self.metricsLoaded = true
            }
            completion()
        }
    }

    // Loads the user’s metrics automatically after login
    private func loadUserMetrics() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userUID).getDocument { (document, error) in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                if let data = document.data() {
                    self.metrics = UserMetricsData(
                        goal: Goal(rawValue: data["goal"] as? String ?? "") ?? .loseWeight,
                        heightInInches: data["heightInInches"] as? Int ?? 0,
                        weight: data["weight"] as? Double ?? 0.0,
                        equipment: Equipment(rawValue: data["equipment"] as? String ?? "") ?? .noEquipment,
                        injuries: (data["injuries"] as? [String] ?? []).compactMap { Injury(rawValue: $0) },
                        experience: ExperienceLevel(rawValue: data["experienceLevel"] as? String ?? "") ?? .beginner
                    )
                    self.metricsLoaded = true 
                } else {
                    print("No data found for user metrics.")
                }
            } else {
                print("Document does not exist.")
            }
        }
    }

    deinit {
        authHandle = nil
        listener?.remove()
    }
}
