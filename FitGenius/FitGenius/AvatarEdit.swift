//
//  AvatarEditURLBuilder.swift
//  FitGenius
//
//  Created by Isai Flores on 4/4/25.
//

import Foundation

// A builder for constructing a Ready Player Me avatar editing URL
struct AvatarEditURLBuilder {
    var subdomain: String = "fitgenius"
    var avatarId: String?
    var frameApiEnabled: Bool = true
    var clearCache: Bool = false
    var source: String = "ios-swift-avatar-creator"
    
    // Builds and returns the full avatar editor URL with the configured parameters
    func build() -> URL? {
        var url = "https://\(subdomain).readyplayer.me/avatar?"
        
        var params: [String] = []
        
        if let avatarId = avatarId, !avatarId.isEmpty {
            params.append("id=\(avatarId)")
        }
        
        if frameApiEnabled {
            params.append("frameApi")
        }
        
        if clearCache {
            params.append("clearCache")
        }

        params.append("source=\(source)")
        
        url += params.joined(separator: "&")
        
        print("🔗 Final Avatar Edit URL: \(url)")
        
        return URL(string: url)
    }
}
