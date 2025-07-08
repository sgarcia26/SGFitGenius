//
//  HomePageView.swift
//  FitGenius
//
//  Created by Sergio Garcia on 2/3/25.
//  

import SwiftUI

// Displays the home page for FitGenius, featuring avatar loading and avatar creator access
struct HomePageView: View {
    @StateObject private var avatarLoader = AvatarLoader()
    @State private var showAvatarCreator = false
    @State private var showErrorAlert = false
    
    func errorAlertButtons(message: String) -> some View {
        Button("OK", role: .cancel) { }
    }

    var body: some View {
        ZStack {
            backgroundImage
            mainContent
        }
        .sheet(isPresented: $showAvatarCreator) {
            avatarCreatorSheet
        }
        .alert("Error",
               isPresented: $showErrorAlert,
               presenting: avatarLoader.errorMessage) { message in
            errorAlertButtons(message: message)
        } message: { message in
            Text(message)
        }
        .onReceive(avatarLoader.$errorMessage) { _ in
            showErrorAlert = avatarLoader.errorMessage != nil
        }
        .sheet(isPresented: $showAvatarCreator, onDismiss: {
            avatarLoader.loadAvatar()
        }) {
            avatarCreatorSheet
        }
    }
    
    // MARK: - Subviews
    
    // Background image filling the entire screen
    private var backgroundImage: some View {
        Image("ForestBackground")
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
    }
    
    // Main layout containing the header and avatar view
    private var mainContent: some View {
        VStack {
            header
            Spacer()
            Button(action: {
                showAvatarCreator = true
            }) {
                AvatarView(loader: avatarLoader)
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
        .padding()
    }

    // Displays app name with styling
    private var header: some View {
        Text("FitGenius")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .shadow(color: .black, radius: 2, x: 1, y: 1)
            .padding(.top, 40)
    }
    
    // Conditional buttons for editing, creating, or refreshing avatars
    private var overlayButtons: some View {
        VStack(spacing: 16) {
            if avatarLoader.avatarImage != nil && !avatarLoader.isLoading {
                Button(action: { showAvatarCreator = true }) {
                    Text("Edit Avatar")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    avatarLoader.clearCache()
                    avatarLoader.loadAvatar()
                }) {
                    Text("Refresh")
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.white)
                        .cornerRadius(10)
                }
            } else if avatarLoader.avatarImage == nil && !avatarLoader.isLoading {
                Button(action: { showAvatarCreator = true }) {
                    Text("Create Avatar")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // Web view for Ready Player Me avatar creator
    private var avatarCreatorSheet: some View {
        WebViewControllerRepresentable(
            isLoading: $avatarLoader.isLoading,
            onAvatarExported: { event in
                showAvatarCreator = false
                UserDefaults.standard.set(event.avatarId, forKey: "avatarId")
                avatarLoader.clearCache()
                avatarLoader.loadAvatar()
            },
            onError: { error in
                print("Error occurred: \(error.localizedDescription)")
            }
           
        )
    }
}
