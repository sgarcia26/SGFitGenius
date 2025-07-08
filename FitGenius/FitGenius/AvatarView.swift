//
//  AvatarView.swift
//  FitGenius
//
//  Created by Isai Flores on 4/1/25.
//

//1. Create Avatar Button → Opens WebView (Ready Player Me)
/*↓
2. Finished Design → Saves Avatar URL → Stores ID in UserDefaults
↓
3. Homepage Loads → Checks UserDefaults → Downloads Avatar
↓
4. Displays in 3D Viewer with Lights/Camera*/

//  Created by Isai Flores on 3/31/25.
//

import SwiftUI

// Displays the avatar image or appropriate view depending on loading/error state
struct AvatarView: View {
    @ObservedObject var loader: AvatarLoader
    
    var body: some View {
        Group {
            if loader.isLoading {
                loadingView
            } else if let avatarImage = loader.avatarImage {
                avatarImageView(avatarImage)
            } else if let errorMessage = loader.errorMessage {
                errorView(errorMessage)
            } else {
                emptyView
            }
        }
    }
    
    // MARK: - Subviews
    // View shown while avatar is downloading, with progress bar and percentage
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView(value: loader.downloadProgress, total: 1.0)
                .tint(.blue)
                .scaleEffect(1.5)
            
            if loader.downloadProgress > 0 {
                Text("\(Int(loader.downloadProgress * 100))%")
                    .font(.caption)
            }
        }
    }
    
    // View that renders the avatar image once successfully loaded
    private func avatarImageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            //.scaleEffect(1.5) // Double the size
            .cornerRadius(10)
            .shadow(radius: 10)
    }
    
    // View displayed when an error occurs, includes retry button
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("Error loading avatar")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
            
            Button(action: {
                self.loader.loadAvatar()
            }) {
                Text("Retry")
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
    
    // Default view shown when no avatar is loaded or started yet
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("Create Avatar")
                .font(.headline)
        }
    }
}
