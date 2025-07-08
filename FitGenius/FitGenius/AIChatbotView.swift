//
// AIChatbotView.swift
// FitGenius
//
// Created by Sergio Garcia on 04/23/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// Builds the chat bubble for each message depending on whether it's from the user or assistant
struct ChatBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 10)
            } else {
                Text(message.text)
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .padding(.horizontal, 10)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// Main chatbot interface that handles chat state, message display, keyboard behavior, and input field
struct AIChatbotView: View {
    @Binding var selectedTab: Int

    // MARK: – Chat state
    @State private var userMessage = ""
    @State private var chatHistory: [ChatMessage] = []
    @State private var conversation: [ChatMessageData] = []
    @State private var profileInjected = false
    @State private var currentModules: [WorkoutModule] = []

    // MARK: – Environment
    @EnvironmentObject var workoutManager: WorkoutPlanManager
    @EnvironmentObject var currentUser: CurrentUser
    @EnvironmentObject var keyboard: KeyboardResponder

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Messages ─────────────────────────────────────────────────
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        warningBanner

                        // All messages
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(chatHistory) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Module previews (if any)
                        if !currentModules.isEmpty {
                            Divider().padding(.vertical, 6)
                            modulesDisplay
                        }
                    }
                    // scroll to bottom when new message arrives
                    .onChange(of: chatHistory.count) { _ in
                        guard let last = chatHistory.last else { return }
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                    // also re-scroll when keyboard appears
                    .onChange(of: keyboard.currentHeight) { _ in
                        guard let last = chatHistory.last else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                // do not let the ScrollView inset itself under the keyboard
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }

            // ── Input Bar ────────────────────────────────────────────────
            inputArea
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemBackground))
                // when keyboard is up, lift by exactly 346pts; otherwise stay put
                .offset(y: keyboard.currentHeight > 0 ? +5 : 0)
                .animation(.easeOut(duration: 0.25), value: keyboard.currentHeight)
        }
        // hide our nav–bar (if you had one) when keyboard is up
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(keyboard.currentHeight > 0)
        .onAppear {
            profileInjected = false
            currentUser.refreshMetrics {
                injectUserProfile()
                profileInjected = true
            }
        }
        // tap anywhere to dismiss
        .onTapGesture {
            UIApplication.shared.sendAction(
              #selector(UIResponder.resignFirstResponder),
              to: nil, from: nil, for: nil
            )
        }
    }

    // MARK: – Subviews

    // Displays a warning banner for disclaimer about AI advice
    private var warningBanner: some View {
        Text("⚠️ This chatbot provides general fitness and nutrition advice. For any medical or mental health concerns, please consult your physician or a qualified healthcare provider.")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, 6)
    }
    
    // Displays a preview of any AI-generated workout modules with an Add button
    private var modulesDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(currentModules) { module in
                HStack {
                    Text("Module Preview: \(module.title)")
                        .font(.headline)
                    Spacer()
                    if workoutManager.savedPlans.contains(where: { $0.title == module.title }) {
                        Text("✓ Added")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    } else {
                        Button("Add") { addModuleToManager(module: module) }
                            .padding(8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                ForEach(module.exercises) { ex in
                    let line = ex.sets > 0
                        ? "• \(ex.name) — \(ex.sets) sets of \(ex.reps)"
                        : "• \(ex.name) — \(ex.reps)"
                    Text(line).font(.caption).foregroundColor(.gray)
                }
                if let notes = module.notes, !notes.isEmpty {
                    Text("Notes: \(notes)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // Text field and send button for user input, with keyboard-aware padding
    private var inputArea: some View {
        HStack {
            TextField("Type your message…", text: $userMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(minHeight: 50)
                .submitLabel(.send)

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.purple)
                    .padding(10)
            }
            .disabled(!currentUser.metricsLoaded)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // Sends user message to OpenAI and handles AI response parsing and display
    private func sendMessage() {
        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !profileInjected {
            injectUserProfile()
        }

        chatHistory.append(.init(text: trimmed, isUser: true))
        conversation.append(.init(role: "user", content: trimmed))
        userMessage = ""

        OpenAIService.shared.sendConversation(conversation: conversation) { fullReply in
            guard let fullReply = fullReply else {
                addAssistantMessage("Sorry, I couldn't generate a response.")
                return
            }

            let displayText: String
            if let marker = fullReply.range(of: "RAW MODULE DATA") {
                displayText = String(fullReply[..<marker.lowerBound])
                    .components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).elementsEqual("---") }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                displayText = fullReply
                    .components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).elementsEqual("---") }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }

            addAssistantMessage(displayText)
            currentModules = parseWorkoutModules(fullReply) ?? []
        }
    }
    
    // Adds a new assistant message to chat history and conversation state
    private func addAssistantMessage(_ text: String) {
        conversation.append(.init(role: "assistant", content: text))
        chatHistory.append(.init(text: text, isUser: false))
    }

    // Injects the user profile into the conversation if not already added
    private func injectUserProfile() {
        guard !profileInjected else { return }
        conversation.append(.init(role: "user", content: buildProfileMessage()))
        profileInjected = true
    }
    
    // Builds a profile message from user metrics to guide AI responses
    private func buildProfileMessage() -> String {
        guard let m = currentUser.metrics else {
            return "No user profile available."
        }

        let injuriesText = m.injuries.isEmpty ? "None" : m.injuries.map(\.rawValue).joined(separator: ", ")
        let ft = m.heightInInches / 12
        let inch = m.heightInInches % 12

        return [
            "Goal: \(m.goal.rawValue)",
            "Equipment: \(m.equipment.rawValue)",
            "Experience Level: \(m.experience.rawValue)",
            "Injuries: \(injuriesText)",
            "Weight: \(Int(m.weight)) lbs",
            "Height: \(ft) ft \(inch) in",
            "",
            "Use this profile to personalize all upcoming routines."
        ].joined(separator: "\n")
    }
    
    // Saves a selected AI-generated workout module to local manager and Firestore, resets state, switches tab
    private func addModuleToManager(module: WorkoutModule) {
        workoutManager.addSavedPlan(WorkoutPlan(title: module.title, exercises: module.exercises))
        saveWorkoutModuleToFirebase(module: module)

        chatHistory.removeAll()
        conversation.removeAll()
        currentModules.removeAll()
        userMessage = ""

        profileInjected = false
        currentUser.refreshMetrics {
            injectUserProfile()
            profileInjected = true
        }

        selectedTab = 1
    }

    // Parses raw JSON workout module data from AI response
    private func parseWorkoutModules(_ response: String) -> [WorkoutModule]? {
        guard let marker = response.range(of: "RAW MODULE DATA") else {
            print("❌ Marker not found")
            return nil
        }

        var jsonPortion = String(response[marker.upperBound...])
        if jsonPortion.hasPrefix("```") {
            var lines = jsonPortion.components(separatedBy: "\n")
            if lines.count > 2 {
                lines.removeFirst()
                lines.removeLast()
            }
            jsonPortion = lines.joined(separator: "\n")
        }

        guard let start = jsonPortion.firstIndex(of: "["),
              let end = jsonPortion.lastIndex(of: "]"),
              let data = String(jsonPortion[start...end]).data(using: .utf8) else {
            print("❌ Failed to extract JSON")
            return nil
        }

        do {
            return try JSONDecoder().decode([WorkoutModule].self, from: data)
        } catch {
            print("❌ JSON decode error:", error)
            return nil
        }
    }

    // Saves the selected workout module to the user's Firestore subcollection
    private func saveWorkoutModuleToFirebase(module: WorkoutModule) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }

        let db = Firestore.firestore()
        let ref = db.collection("users").document(userUID)
            .collection("workoutModules")
            .document(module.id.uuidString)

        let workoutData: [String: Any] = [
            "title": module.title,
            "exercises": module.exercises.map {
                ["name": $0.name, "sets": $0.sets, "reps": $0.reps]
            },
            "notes": module.notes ?? ""
        ]

        ref.setData(workoutData) { error in
            if let error = error {
                print("Error saving workout module: \(error.localizedDescription)")
            } else {
                print("✅ Workout module saved to Firebase")
            }
        }
    }
}

// View extension to dismiss keyboard when tapping outside input
extension View {
    
    // Dismisses keyboard on tap gesture
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}


struct AIChatbotView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatbotView(selectedTab: .constant(0))
            .environmentObject(WorkoutPlanManager())
            .environmentObject(CurrentUser.shared)
    }
}
