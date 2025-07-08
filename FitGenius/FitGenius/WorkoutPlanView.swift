//
// WorkoutPlan.swift
// FitGenius
//
// Created by Sergio Garcia on 04/23/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Represents a day in the week and its assigned workout module
struct DayPlan: Identifiable, Hashable {
    let id = UUID()
    let dayName: String
    let date: Date
    var assignedModule: WorkoutModule?
    var rewardClaimed: Bool = false  // Prevent editing after reward claimed
}

/// View that shows a user's weekly workout plan with drag-and-drop module assignment,
/// reward logic, and integration with Firestore for week persistence.
struct WorkoutPlanView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var workoutManager: WorkoutPlanManager
    @State private var dayPlans: [DayPlan] = []
    
    // Layout for the weekly plan view
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Week header
                    weekHeader
                    // Weekly schedule
                    weeklySchedule
                    // Available Workout Plans
                    availableWorkoutPlans
                    Spacer()
                }
                .padding(.bottom)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Workout Plan")
        }
        .onAppear {
            
            workoutManager.loadModulesFromFirebase()
            
            let currentID = currentWeekID()
            let lastSyncedID = UserDefaults.standard.string(forKey: "lastSyncedWeekID")
            
            if currentID != lastSyncedID {
                // Check Firestore before overwriting
                checkIfWeekExistsInFirestore(currentID) { exists in
                    if exists {
                        // Week already exists — just load it
                        loadSavedDayPlansFromFirestore()
                    } else {
                        // New week — generate and save
                        print("🆕 No week data — generating new week")
                        dayPlans = generateWeek()
                        saveDayPlansToFirestore()
                    }
                    UserDefaults.standard.set(currentID, forKey: "lastSyncedWeekID")
                }
            } else {
                loadSavedDayPlansFromFirestore()
            }
        }

    }
    
    /// Checks if the given date is today
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Checks Firestore if a given week's data already exists
    private func checkIfWeekExistsInFirestore(_ weekID: String, completion: @escaping (Bool) -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userUID)
            .collection("weeklyWorkoutPlans").document(weekID)

        docRef.getDocument { snapshot, error in
            if let error = error {
                print("Error checking week existence: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(snapshot?.exists == true)
            }
        }
    }

    // MARK: - Week Header
    
    /// Displays the formatted date range for the current workout week (e.g. "Apr 28 – May 4").
    /// Helps users understand which week they are viewing or managing.
    private var weekHeader: some View {
        VStack {
            Text(weekDateRange())
                .font(.headline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal)
        }
        .padding(.top)
    }

    // MARK: - Weekly Schedule
    /// Renders the 7-day weekly schedule of workouts.
    /// Each day shows either a rest state or a linked module view.
    /// Supports drag-and-drop to assign modules, and includes delete buttons
    /// with rules for locking if today’s reward has been claimed.
    private var weeklySchedule: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Schedule")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            ForEach(dayPlans.indices, id: \.self) { index in
                let day = dayPlans[index]
                HStack {
                    if let module = day.assignedModule {
                        NavigationLink(
                            destination: WorkoutModuleDetailView(
                                module: module,
                                moduleDate: day.date // Pass the assigned day’s date
                            )
                        ) {
                            DayCardView(day: day)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        DayCardView(day: day)
                    }
                    if day.assignedModule != nil && !(Calendar.current.isDateInToday(day.date) && day.rewardClaimed) {
                        deleteWorkoutButton(dayIndex: index, day: day)
                    }
                }
                .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                    // Prevent drop if today and rewardClaimed is true
                    if isToday(day.date) && day.rewardClaimed {
                        print("🚫 Drop rejected: Reward already claimed for today.")
                        return false
                    }
                    return handleDropForIndex(providers: providers, index: index)
                }
            }
        }
    }

    // MARK: - Delete Workout Button
    // Deletes a specific workout plan document from Firestore by matching its title
    private func deleteWorkoutButton(dayIndex: Int, day: DayPlan) -> some View {
        Button(action: {
            if let assignedModule = day.assignedModule {
                workoutManager.removeWorkoutPlan(assignedModule.id)  // Remove from local savedPlans
                deleteWorkoutPlanFromFirebase(plan: WorkoutPlan(title: assignedModule.title, exercises: assignedModule.exercises))  // Delete from Firebase
                dayPlans[dayIndex].assignedModule = nil  // Clear the assigned module from the day
                
                // Trigger UI update
                dayPlans = dayPlans // Update the state with new dayPlans array
                saveDayPlansToFirestore()  // Save changes to Firestore
            }
        }) {
            Text("–")
                .font(.title)
                .foregroundColor(.red)
        }
        .padding(.trailing)
    }


    // MARK: - Available Workout Plans
    
    /// Displays a list of saved workout modules that the user can drag and assign to a day.
    /// Each module shows its title, a drag handle icon, and a trash button to remove it from both
    /// local state and Firebase. Supports drag-and-drop for weekly assignment.
    private var availableWorkoutPlans: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Workout Modules")
                .font(.title2).bold()
                .padding(.horizontal)

            ForEach(workoutManager.savedPlans) { plan in
                HStack {
                    Text(plan.title)
                        .font(.headline)
                    Spacer()

                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.gray)

                    // Trash button removes saved plan
                    Button(action: {
                        workoutManager.removeWorkoutPlan(plan.id)  // Remove from local savedPlans
                        deleteWorkoutPlanFromFirebase(plan: plan)  // Delete from Firebase
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .padding(.leading, 8)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .onDrag {
                    NSItemProvider(object: plan.id.uuidString as NSString)
                }
            }
        }
    }

    // MARK: - Helper Functions
    /// Generates a new list of DayPlan objects for the current week
    private func generateWeek() -> [DayPlan] {
        var plans: [DayPlan] = []
        let calendar = Calendar.current
        let today = Date()

        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) {
            for offset in 0..<7 {
                if let dayDate = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) {
                    let name = calendar.weekdaySymbols[calendar.component(.weekday, from: dayDate) - 1]
                    plans.append(DayPlan(dayName: name, date: dayDate, assignedModule: nil))
                }
            }
        }
        return plans
    }
    
    /// Formats and returns the date range of the current week
    private func weekDateRange() -> String {
        guard let first = dayPlans.first?.date, let last = dayPlans.last?.date else { return "" }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }
    
    /// Handles drop logic when a user drags a workout plan onto a day
    private func handleDropForIndex(providers: [NSItemProvider], index: Int) -> Bool {
        let day = dayPlans[index]

        // ❌ Reject drop if it's today and reward is already claimed
        if Calendar.current.isDateInToday(day.date) && day.rewardClaimed {
            print("❌ Drop rejected — reward already claimed for today.")
            return false
        }

        guard let item = providers.first else { return false }

        _ = item.loadObject(ofClass: NSString.self) { data, _ in
            if let nsID = data as? NSString {
                let idString = nsID as String
                DispatchQueue.main.async {
                    if let plan = workoutManager.savedPlans.first(where: { $0.id.uuidString == idString }) {
                        let module = WorkoutModule(title: plan.title, exercises: plan.exercises)
                        dayPlans[index].assignedModule = module
                        dayPlans = dayPlans // Trigger UI update
                        saveDayPlansToFirestore()
                    }
                }
            }
        }
        return true
    }

    // MARK: - Save Day Plans to Firestore
    
    /// Saves the current dayPlans to Firestore under the user's weeklyWorkoutPlans
    private func saveDayPlansToFirestore() {
        guard let userUID = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }

        let db = Firestore.firestore()
        let weekRef = db.collection("users").document(userUID)
            .collection("weeklyWorkoutPlans")
            .document(currentWeekID())

        let serializedDayPlans: [[String: Any]] = dayPlans.map { day in
            var dict: [String: Any] = [
                "dayName": day.dayName,
                "date": day.date,
                "rewardClaimed": day.rewardClaimed
            ]

            if let module = day.assignedModule {
                dict["assignedModule"] = [
                    "title": module.title,
                    "notes": module.notes ?? "",
                    "exercises": module.exercises.map { ex in
                        return [
                            "name": ex.name,
                            "sets": ex.sets,
                            "reps": ex.reps,
                            "isCompleted": ex.isCompleted
                        ]
                    }
                ]
            }

            return dict
        }

        weekRef.setData(["dayPlans": serializedDayPlans]) { error in
            if let error = error {
                print("Error saving weekly plan: \(error.localizedDescription)")
            } else {
                print("✅ Weekly plan saved successfully.")
            }
        }
    }

    // MARK: - Load Saved Day Plans from Firestore
    
    /// Loads the saved dayPlans for the current week from Firestore
    private func loadSavedDayPlansFromFirestore() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let weekRef = db.collection("users").document(userUID)
            .collection("weeklyWorkoutPlans")
            .document(currentWeekID())

        weekRef.getDocument { snapshot, error in
            if let error = error {
                print("Error loading week: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(),
                  let savedPlans = data["dayPlans"] as? [[String: Any]] else {
                print("No saved plan found — generating new week.")
                dayPlans = generateWeek()
                return
            }

            let parsedPlans = savedPlans.map { dict -> DayPlan in
                let dayName = dict["dayName"] as? String ?? ""
                let date = (dict["date"] as? Timestamp)?.dateValue() ?? Date()
                let rewardClaimed = dict["rewardClaimed"] as? Bool ?? false

                if let moduleData = dict["assignedModule"] as? [String: Any] {
                    let title = moduleData["title"] as? String ?? ""
                    let notes = moduleData["notes"] as? String ?? ""
                    let exercisesData = moduleData["exercises"] as? [[String: Any]] ?? []
                    let exercises = exercisesData.map { ex -> Exercise in
                        let name = ex["name"] as? String ?? ""
                        let sets = ex["sets"] as? Int ?? 0
                        let reps = ex["reps"] as? String ?? ""
                        let isCompleted = ex["isCompleted"] as? Bool ?? false
                        return Exercise(name: name, sets: sets, reps: reps, isCompleted: isCompleted)
                    }

                    return DayPlan(
                        dayName: dayName,
                        date: date,
                        assignedModule: WorkoutModule(title: title, exercises: exercises, notes: notes),
                        rewardClaimed: rewardClaimed
                    )
                } else {
                    return DayPlan(
                        dayName: dayName,
                        date: date,
                        assignedModule: nil,
                        rewardClaimed: rewardClaimed
                    )
                }
            }

            dayPlans = parsedPlans
        }
    }
    
    /// Deletes a workout module document from Firestore
    func deleteWorkoutPlanFromFirebase(plan: WorkoutPlan) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }

        let db = Firestore.firestore()
        let userWorkoutRef = db.collection("users").document(userUID).collection("workoutModules")

        // Find the document with the workout plan title and delete it
        userWorkoutRef.whereField("title", isEqualTo: plan.title).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching workout module for deletion: \(error.localizedDescription)")
                return
            }

            // Assuming the title is unique, delete the document
            for document in querySnapshot!.documents {
                document.reference.delete { err in
                    if let err = err {
                        print("Error deleting workout module: \(err)")
                    } else {
                        print("Workout module successfully deleted from Firebase.")
                    }
                }
            }
        }
    }
    
    /// Returns a deterministic ID for the current week (e.g. week-2025-05-05)
    private func currentWeekID() -> String {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "week-\(formatter.string(from: weekStart))"
    }
    
    /// Deletes the previous week's plan document from Firestore
    private func deletePreviousWeek(_ previousWeekID: String) {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let ref = db.collection("users").document(userUID)
            .collection("weeklyWorkoutPlans").document(previousWeekID)

        ref.delete { error in
            if let error = error {
                print("Error deleting previous week: \(error.localizedDescription)")
            } else {
                print("✅ Previous week \(previousWeekID) deleted.")
            }
        }
    }

}




// MARK: - DayCardView

/// Displays a single day's workout card in the weekly workout plan view.
/// Shows the date, assigned workout module (if any), and a reward checkmark if claimed.
struct DayCardView: View {
    var day: DayPlan
    
    /// The main body of the view, showing the day name, date, and assigned module or "Rest Day" label.
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(day.dayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(formattedDate(day.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            if let module = day.assignedModule {
                HStack {
                    Text(module.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    if day.rewardClaimed {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .padding(.leading, 4)
                    }
                }
            } else {
                Text("Rest Day")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isToday(day.date) ? Color.green.opacity(0.3) : Color.white)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    /// Formats a `Date` into a short string like "May 5"
    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }
    
    /// Checks if the given date is today's date
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - WorkoutModuleDetailView (unchanged)

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Detail view for a single assigned workout module on a given day.
/// Allows users to mark exercises as completed and claim a reward.
struct WorkoutModuleDetailView: View {
    var module: WorkoutModule
    var moduleDate: Date
    @State private var moduleExercises: [Exercise]
    @State private var userUID: String = ""
    @State private var rewardWasJustClaimed = false
    @State private var showRewardToast = false

    init(module: WorkoutModule, moduleDate: Date) {
        self.module = module
        self.moduleDate = moduleDate
        _moduleExercises = State(initialValue: module.exercises)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(moduleDate)
    }

    private var isModuleComplete: Bool {
        moduleExercises.allSatisfy { $0.isCompleted }
    }

    private var rewardAlreadyClaimed: Bool {
        rewardWasJustClaimed || isRewardMarkedClaimedInFirestore
    }

    @State private var isRewardMarkedClaimedInFirestore = false

    private var progress: Double {
        let done = moduleExercises.filter { $0.isCompleted }.count
        let total = moduleExercises.count
        return total > 0 ? Double(done) / Double(total) : 0
    }
    
    // Layout for progress bar, notes, and exercise list
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Progress Bar with gift icon
            HStack(spacing: 12) {
                ProgressView(value: progress)
                    .tint(.green)
                    .scaleEffect(x: 1.0, y: 1.4, anchor: .center)
                    .frame(height: 14)

                if isToday && isModuleComplete && !rewardAlreadyClaimed {
                    Button(action: claimReward) {
                        Image(systemName: "gift.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.orange)
                            .padding(.trailing, 8)
                    }
                    .transition(.scale)
                }
            }
            .padding(.horizontal)

            // Notes section
            if let notes = module.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes:")
                        .font(.headline)
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

            // Info when not editable
            if !isToday {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                    Text("You can only check off exercises on today's workout.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
            }

            // Exercise List
            List {
                ForEach($moduleExercises.indices, id: \.self) { index in
                    let exercise = $moduleExercises[index]
                    HStack {
                        Text("\(exercise.wrappedValue.name) — \(exercise.wrappedValue.sets > 0 ? "\(exercise.wrappedValue.sets) sets of \(exercise.wrappedValue.reps)" : exercise.wrappedValue.reps)")
                        Spacer()
                        Button(action: {
                            if isToday && !rewardAlreadyClaimed {
                                exercise.wrappedValue.isCompleted.toggle()
                                saveProgressToFirestore()
                            }
                        }) {
                            Image(systemName: exercise.wrappedValue.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(exercise.wrappedValue.isCompleted ? .green : .gray)
                        }
                        .disabled(!isToday || rewardAlreadyClaimed)
                    }
                }
            }
        }
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            userUID = Auth.auth().currentUser?.uid ?? ""
            fetchRewardStatus()
        }
        
        
        .alert("Outfit Unlocked!", isPresented: $showRewardToast) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You’ve unlocked a new outfit. Check your avatar wardrobe!")
        }
    }
    
    /// Loads whether the reward has already been claimed for this workout day
    private func fetchRewardStatus() {
        guard !userUID.isEmpty else { return }

        let db = Firestore.firestore()
        let weekRef = db.collection("users").document(userUID)
            .collection("weeklyWorkoutPlans").document(currentWeekID())

        weekRef.getDocument { snapshot, _ in
            guard let plans = snapshot?.data()?["dayPlans"] as? [[String: Any]] else { return }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let target = formatter.string(from: moduleDate)

            for entry in plans {
                if let ts = entry["date"] as? Timestamp {
                    let dateStr = formatter.string(from: ts.dateValue())
                    if dateStr == target {
                        let claimed = entry["rewardClaimed"] as? Bool ?? false
                        DispatchQueue.main.async {
                            isRewardMarkedClaimedInFirestore = claimed
                        }
                    }
                }
            }
        }
    }

    // MARK: - Reward Logic
    
    /// Marks the reward as claimed and saves to Firestore
    private func claimReward() {
        rewardWasJustClaimed = true

        guard !userUID.isEmpty else { return }

        let db = Firestore.firestore()
        let weekID = currentWeekID()
        let weekRef = db.collection("users").document(userUID)
            .collection("weeklyWorkoutPlans").document(weekID)

        weekRef.getDocument { snapshot, error in
            guard var data = snapshot?.data(),
                  var dayPlans = data["dayPlans"] as? [[String: Any]],
                  error == nil else {
                print("❌ Failed to fetch week document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let targetDateString = formatter.string(from: moduleDate)

            for i in 0..<dayPlans.count {
                if let rawDate = dayPlans[i]["date"] as? Timestamp {
                    let dateString = formatter.string(from: rawDate.dateValue())
                    if dateString == targetDateString {
                        dayPlans[i]["rewardClaimed"] = true
                        break
                    }
                }
            }

            weekRef.setData(["dayPlans": dayPlans]) { error in
                if let error = error {
                    print("❌ Error claiming reward: \(error.localizedDescription)")
                } else {
                    print("🎁 Reward successfully claimed and saved.")
                    unlockRandomOutfit()
                    showRewardToast = true
                }
            }
        }
    }
    
    /// Randomly selects and unlocks an outfit model using the Ready Player Me API
    private func unlockRandomOutfit() {
        let modelIds = ["55255882", "107519403", "38134006", "120366131", "120728151", "29273765"]
        guard let randomId = modelIds.randomElement() else { return }

        let api = ReadyPlayerMeAPI()
        let assetId = randomId /
        let userId = "6816b37e5d024be53a3a9839"
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            print(userId)
        }
        api.unlockOutfit(assetId: assetId, for: userId)
    }

    // MARK: - Save Progress
    
    /// Saves the current completion progress of exercises to Firestore
    private func saveProgressToFirestore() {
        guard !userUID.isEmpty else { return }

        let db = Firestore.firestore()
        let weekID = currentWeekID()
        let weekRef = db.collection("users").document(userUID)
            .collection("weeklyWorkoutPlans").document(weekID)

        weekRef.getDocument { snapshot, error in
            guard var data = snapshot?.data(),
                  var dayPlans = data["dayPlans"] as? [[String: Any]],
                  error == nil else {
                print("❌ Error fetching week for saving progress: \(error?.localizedDescription ?? "Unknown")")
                return
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let targetDateString = formatter.string(from: moduleDate)

            for i in 0..<dayPlans.count {
                if let rawDate = dayPlans[i]["date"] as? Timestamp {
                    let dateString = formatter.string(from: rawDate.dateValue())
                    if dateString == targetDateString {
                        var updatedModule = dayPlans[i]["assignedModule"] as? [String: Any] ?? [:]
                        updatedModule["title"] = module.title
                        updatedModule["notes"] = module.notes ?? ""
                        updatedModule["exercises"] = moduleExercises.map { ex in
                            [
                                "name": ex.name,
                                "sets": ex.sets,
                                "reps": ex.reps,
                                "isCompleted": ex.isCompleted
                            ]
                        }
                        dayPlans[i]["assignedModule"] = updatedModule
                        break
                    }
                }
            }

            weekRef.setData(["dayPlans": dayPlans]) { error in
                if let error = error {
                    print("❌ Error saving exercise progress: \(error.localizedDescription)")
                } else {
                    print("✅ Progress saved.")
                }
            }
        }
    }

    // MARK: - Helpers
    
    /// Returns a Firestore-compatible ID string for the current week
    private func currentWeekID() -> String {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: moduleDate)?.start ?? moduleDate
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "week-\(formatter.string(from: weekStart))"
    }
    
    /// Formats the name of the day (e.g., Monday) from a date
    private func formattedDayName(_ date: Date) -> String {
        let calendar = Calendar.current
        return calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
    }

    /// Returns a string-based UUID based on the assigned date
    private func dayUUID(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date) // e.g., "2025-04-30"
    }

}

struct WorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutPlanView(selectedTab: .constant(1)) // <- Provide a constant binding
            .environmentObject(WorkoutPlanManager())
            .environmentObject(CurrentUser.shared)
    }
}
