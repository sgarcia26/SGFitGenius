//
//  MainView.Swift
//  FitGenius
//
//  Created by Sergio Garcia on 2/3/25.
//  TEST BRANCH

/*
import SwiftUI

struct MainView: View {
    /////////////////////////////////////////////////////////////////////////////////////
    @State private var selectedTab = 2 // Start with HomePageView in the center
    @State private var showWebView = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var avatarExportedEvent: AvatarExportedEvent?
    /////////////////////////////////////////////////////////////////////////////////////
    var body: some View {
        ZStack(alignment: .bottom) {
            // TabView containing all pages
            TabView(selection: $selectedTab) {
                ActivityView()
                    .tag(0)
                
                WorkoutPlanView()
                    .tag(1)
                
                HomePageView()
                    .tag(2)
                
                AIChatbotView()
                    .tag(3)
                
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Custom Floating Navigation Bar
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    TabButton(icon: "flame.fill", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    Spacer()
                    TabButton(icon: "figure.walk", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    Spacer()
                    TabButton(icon: "house.fill", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                    Spacer()
                    TabButton(icon: "bubble.left.and.bubble.right.fill", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                .frame(height: 60)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                )
                .padding(.horizontal, 20)
            }
            
            /////////////////////////////////////////////////////////////////////////////////////
            // Full-screen WebView for avatar creation/editing
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
                    },
                )
                /////////////////////////////////////////////////////////////////////////////////////
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
                .zIndex(1)
                .alert("Error", isPresented: .constant(errorMessage != nil)) {
                    Button("OK") { errorMessage = nil }
                } message: {
                    Text(errorMessage ?? "Unknown error")
                }
            }
            
            // Loading indicator
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(2)
            }
        }
    }
}

// Tab Button (unchanged)
struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
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
    }
}

*/
