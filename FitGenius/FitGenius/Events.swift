//
//  AvatarLoader.swift
//  FitGenius
//
//  Created by Isai Flores on 4/1/25.
//

import Foundation

/// Event triggered when an avatar is successfully exported from Ready Player Me
struct AvatarExportedEvent: Equatable, Codable {
    /// The URL of the exported avatar model (GLB format expected)
    let url: String
    
    /// Extracts the avatar ID from the URL
    var avatarId: String? {
        URL(string: url)?.deletingPathExtension().lastPathComponent
    }
    
    let userId: String?
    
    /// The expression applied to the avatar during export (optional)
    let expression: String?
    
    /// The pose applied to the avatar during export (optional)
    let pose: String?
    
    /// The blend shapes applied to the avatar (optional)
    let blendShapes: String?
    
    /// The camera preset used for the export (optional)
    let camera: String?
    
    /// The background color used for the export (RGB as a string, optional)
    let background: String?
    
    /// The image quality of the exported avatar (optional)
    let quality: Int?
    
    /// The size (dimensions) of the exported avatar image (optional)
    let size: Int?
    
    /// The avatar's last modified timestamp (optional)
    let uat: String?
}

/// Event triggered when a user unlocks a new asset
struct AssetUnlockedEvent: Equatable, Codable {
    /// The ID of the user who unlocked the asset
    let userId: String
    
    /// The ID of the unlocked asset
    let assetId: String
    
    /// Any additional details related to the unlocked asset (optional)
    let unlockedAssetDetails: String?
}

/// Event triggered when a user profile is set
struct UserSetEvent: Equatable, Codable {
    /// The user's unique identifier
    let id: String
    
    /// Avatar settings applied to the user (optional)
    let avatarSettings: AvatarSettings?
}

/// Event triggered when a user successfully authorizes
struct UserAuthorizedEvent: Equatable, Codable {
    /// The user's unique identifier
    let id: String
}

/// Event triggered when user data is updated
struct UserUpdatedEvent: Equatable, Codable {
    /// The user's unique identifier
    let id: String
    
    /// The updated avatar settings (optional)
    let avatarSettings: AvatarSettings?
}

/// Struct to hold avatar settings for easier tracking of changes like expressions, poses, etc.
struct AvatarSettings: Equatable, Codable {
    /// The expression currently applied to the avatar (optional)
    let expression: String?
    
    /// The pose currently applied to the avatar (optional)
    let pose: String?
    
    /// The blend shapes currently applied to the avatar (optional)
    let blendShapes: String?
    
    /// The camera preset used for rendering the avatar (optional)
    let camera: String?
    
    /// The background color used for rendering (RGB as a string, optional)
    let background: String?
    
    /// The quality of the rendered avatar image (default 100)
    let quality: Int
    
    /// The size of the rendered avatar image (default 1024)
    let size: Int
    
    // You can add other potential fields that may be added later to support customization
    /// Avatar's hair color (optional) - placeholder for future fields
    let hairColor: String?
    
    /// Avatar's skin tone (optional) - placeholder for future fields
    let skinTone: String?
    
    // Initializer with default values to simplify avatar creation
    init(expression: String? = nil, pose: String? = nil, blendShapes: String? = nil,
         camera: String? = nil, background: String? = nil, quality: Int = 100,
         size: Int = 1024, hairColor: String? = nil, skinTone: String? = nil) {
        self.expression = expression
        self.pose = pose
        self.blendShapes = blendShapes
        self.camera = camera
        self.background = background
        self.quality = quality
        self.size = size
        self.hairColor = hairColor
        self.skinTone = skinTone
    }
}
