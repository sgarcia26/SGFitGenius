//
//  WebViewDelegate.swift
//  FitGenius
//
//  Created by Isai Flores on 3/31/25.
//

import Foundation

// Defines delegate protocols for handling Ready Player Me events and error states from the WebView.

// Handles successful events from the embedded Ready Player Me WebView.
protocol WebViewDelegate: AnyObject {
    func onAvatarExported(event: AvatarExportedEvent)
    func onAssetUnlocked(event: AssetUnlockedEvent)
    func onUserSet(event: UserSetEvent)
    func onUserAuthorized(event: UserAuthorizedEvent)
    func onUserUpdated(event: UserUpdatedEvent)
    func onUserLoggedOut()
}

// Handles WebView-specific errors like network failures or malformed avatar data.
protocol WebViewErrorDelegate: AnyObject {
    func webViewDidFail(with error: Error)
    func webViewDidFailToLoadAvatar()
}
