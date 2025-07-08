//
//  MainView.swift
//  FitGenius
//
//  Created by Sergio Garcia on 2/3/25.
//

import SwiftUI
import FirebaseAuth

struct MainView: View {
    @State private var selectedTab = 2 // Default to HomePageView
    @State private var showWebView = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var avatarExportedEvent: AvatarExportedEvent?

    @StateObject private var healthManager = HealthManager()
    @StateObject private var keyboard = KeyboardResponder()
    
    // Renders the main app UI with a TabView and a custom tab bar that hides when the keyboard is open.
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    ActivityView()
                        .tag(0)
                        .environmentObject(healthManager)

                    WorkoutPlanView(selectedTab: $selectedTab)
                        .tag(1)
                        .environmentObject(CurrentUser.shared)

                    HomePageView()
                        .tag(2)

                    AIChatbotView(selectedTab: $selectedTab)
                        .tag(3)
                        .environmentObject(CurrentUser.shared)
                        .environmentObject(keyboard)

                    SettingsView()
                        .tag(4)
                        .environmentObject(CurrentUser.shared)
                        .environmentObject(keyboard)
                }
                // Logs when the user switches tabs (specifically useful for AI tab debugging).
                .onChange(of: selectedTab) { newTab, _ in
                    if newTab == 3 {
                        print("🧠 Switched to AI tab")
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }

            // Hide tab bar when keyboard is visible
            if keyboard.currentHeight == 0 {
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeOut(duration: 0.25), value: keyboard.currentHeight)
            }
        }

        // Displays the full-screen avatar creator WebView when `showWebView` is true.
        .overlay(
            Group {
                if showWebView {
                    WebViewControllerRepresentable(
                        isLoading: $isLoading,
                        onAvatarExported: { event in
                            self.avatarExportedEvent = event
                            self.showWebView = false
                        },
                        onError: { error in
                            self.errorMessage = error.localizedDescription
                            self.showWebView = false
                        }
                    )
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        )
        // Presents an error alert if `errorMessage` is not nil.
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        // Logs the current Firebase user UID when the view appears.
        .onAppear {
            print("👤 Current UID:", Auth.auth().currentUser?.uid ?? "nil")
        }
    }
}



struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let icons = ["flame.fill", "figure.walk", "house.fill", "bubble.left.and.bubble.right.fill", "gearshape.fill"]
    
    // Builds the custom tab bar UI with icons for each section and highlights the selected tab.
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Loops through all tab icons and renders a TabButton for each.
                ForEach(0..<icons.count, id: \.self) { index in
                    Spacer()
                    TabButton(icon: icons[index], isSelected: selectedTab == index) {
                        selectedTab = index
                    }
                    Spacer()
                }
            }
            .padding(.vertical, 10)
            .frame(height: 60)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
        }
    }
}

struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    // Displays a single tab icon button that updates the selected tab when tapped.
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .green : .gray)
                .padding(.horizontal, 10)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(CurrentUser.shared)
            .environmentObject(WorkoutPlanManager())
    }
}
