//
// Models.swift
// FitGenius
//
// Created by Sergio Garcia on 04/23/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct Exercise: Identifiable, Codable, Hashable {
    var id = UUID()
    let name: String
    let sets: Int
    let reps: String
    var isCompleted: Bool = false

    enum CodingKeys: CodingKey {
        case name, sets, reps
    }
    
    // Initializes an Exercise from JSON data (used when decoding from Firebase)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        sets = try container.decode(Int.self, forKey: .sets)
        reps = try container.decode(String.self, forKey: .reps)
        isCompleted = false
        id = UUID()
    }
    
    // Creates a new Exercise with name, sets, reps, and optional completion state
    init(name: String, sets: Int, reps: String, isCompleted: Bool = false) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.isCompleted = isCompleted
    }

}

struct WorkoutModule: Identifiable, Codable, Hashable {
    var id = UUID()
    let title: String
    let exercises: [Exercise]
    let notes: String?

    enum CodingKeys: CodingKey {
        case title, exercises, notes
    }
    
    // Initializes a WorkoutModule from JSON data (used when decoding from Firebase)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        exercises = try container.decode([Exercise].self, forKey: .exercises)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        id = UUID()
    }
    
    // Creates a new WorkoutModule with a title, exercises, and optional notes
    init(title: String, exercises: [Exercise], notes: String? = nil) {
        self.title = title
        self.exercises = exercises
        self.notes = notes
    }
}

// Automatically synthesized init for WorkoutPlan — holds a plan’s title and exercises
struct WorkoutPlan: Identifiable, Codable, Hashable {
    var id = UUID()
    let title: String
    let exercises: [Exercise]
}

final class WorkoutPlanManager: ObservableObject {
    @Published private(set) var suggestedModules: [WorkoutModule] = []
    @Published private(set) var savedPlans: [WorkoutPlan] = []
    
    // Replaces the list of suggested workout modules (typically from AI)
    func setSuggestedModules(_ modules: [WorkoutModule]) {
        suggestedModules = modules
    }
    
    // Clears all suggested workout modules
    func clearSuggestions() {
        suggestedModules.removeAll()
    }

    // Adds a new workout plan to the list of saved plans
    func addSavedPlan(_ plan: WorkoutPlan) {
        savedPlans.append(plan)
    }
    
    // Removes a workout plan from savedPlans using its UUID
    func removeWorkoutPlan(_ id: UUID) {
        savedPlans.removeAll { $0.id == id }
    }
    
    // Loads saved workout modules from Firestore and converts them into local WorkoutPlans
    func loadModulesFromFirebase() {
        guard let userUID = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userUID).collection("workoutModules").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching modules: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            let fetchedPlans: [WorkoutPlan] = documents.compactMap { doc in
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let exercisesData = data["exercises"] as? [[String: Any]] else {
                    return nil
                }

                let exercises = exercisesData.map { dict -> Exercise in
                    Exercise(
                        name: dict["name"] as? String ?? "",
                        sets: dict["sets"] as? Int ?? 0,
                        reps: dict["reps"] as? String ?? ""
                    )
                }

                return WorkoutPlan(title: title, exercises: exercises)
            }

            DispatchQueue.main.async {
                self.savedPlans = fetchedPlans
            }
        }
    }
}
