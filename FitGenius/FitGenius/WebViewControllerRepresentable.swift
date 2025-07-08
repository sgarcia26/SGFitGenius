//
//  WebViewControllerRepresentable.swift
//  FitGenius
//
//  Created by Isai Flores on 4/4/25.
//

import SwiftUI
import UIKit

// SwiftUI wrapper that bridges a UIKit-based WebViewController into SwiftUI using UIViewControllerRepresentable.
struct WebViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var isLoading: Bool
    var onAvatarExported: (AvatarExportedEvent) -> Void
    var onError: (Error) -> Void

    // Instantiates the WebViewController and sets its delegates to the SwiftUI Coordinator.
    func makeUIViewController(context: Context) -> WebViewController {
        let webViewController = WebViewController()
        webViewController.webViewDelegate = context.coordinator
        webViewController.errorDelegate = context.coordinator
        return webViewController
    }
    
    // Required by protocol but unused in this case (no live updates to WebViewController needed).
    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {}
    
    // Creates a Coordinator instance to handle WebView delegate communication between UIKit and SwiftUI.
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, isLoading: $isLoading)
    }
    
    // Acts as the bridge for delegate callbacks between WebViewController and the SwiftUI parent.
    class Coordinator: NSObject, WebViewDelegate, WebViewErrorDelegate {
        var parent: WebViewControllerRepresentable
        @Binding var isLoading: Bool
        
        init(parent: WebViewControllerRepresentable, isLoading: Binding<Bool>) {
            self.parent = parent
            self._isLoading = isLoading
        }
        
        // MARK: - WebViewDelegate
        
        // Triggered when an avatar is successfully exported. Stops loading and calls the SwiftUI handler.
        func onAvatarExported(event: AvatarExportedEvent) {
            isLoading = false
            parent.onAvatarExported(event)
        }
        
        func onAssetUnlocked(event: AssetUnlockedEvent) {
            // Handle if needed, or leave empty
        }
        
        func onUserSet(event: UserSetEvent) {
            // Handle if needed, or leave empty
        }
        
        func onUserAuthorized(event: UserAuthorizedEvent) {
            // Handle if needed, or leave empty
        }
        
        func onUserUpdated(event: UserUpdatedEvent) {
            // Handle if needed, or leave empty
        }
        
        func onUserLoggedOut() {
            // Handle if needed, or leave empty
        }
        
        // MARK: - WebViewErrorDelegate
        
        // Called when an error occurs in the WebView. Passes the error to the SwiftUI view and stops loading.
        func webViewDidFail(with error: Error) {
            isLoading = false
            parent.onError(error)
        }
        
        // Called when avatar data fails to load. Passes a custom error to the SwiftUI view.
        func webViewDidFailToLoadAvatar() {
            isLoading = false
            parent.onError(NSError(domain: "WebView", code: -3, userInfo: [
                NSLocalizedDescriptionKey: "Failed to load avatar"
            ]))
        }
    }
}
