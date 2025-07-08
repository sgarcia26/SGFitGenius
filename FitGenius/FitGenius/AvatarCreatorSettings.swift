//
//  AvatarCreatorSettings.swift
//  FitGenius
//
//  Created by Isai Flores on 4/4/25.
//

import Foundation

// Represents supported languages for avatar creation
enum Language: String {
    case DEFAULT = ""
    case CHINESE = "ch"
    case GERMAN = "de"
    case ENGLISH_IRELAND = "en-IE"
    case ENGLISH = "en"
    case SPANISH_MEXICO = "es-MX"
    case SPANISH = "es"
    case FRENCH = "fr"
    case ITALIAN = "it"
    case JAPANESE = "jp"
    case KOREAN = "kr"
    case PORTUGAL_BRAZIL = "pt-BR"
    case PORTUGESE = "pt"
    case TURKISH = "tr"
}

// Represents body type options for the avatar
enum BodyType: String {
    case SELECTABLE = ""
    case FULLBODY = "fullbody"
    case HALFBODY = "halfbody"
}

// Represents gender options for the avatar
enum Gender: String {
    case NONE = ""
    case MALE = "male"
    case FEMALE = "female"
}

// Holds all configurable properties for the avatar creator URL
struct AvatarCreatorConfig {
    // Update your subdomain URL here
    var subdomain: String = "fitgenius"
    var clearCache: Bool = false
    var quickStart: Bool = false
    var gender: Gender = .MALE
    var bodyType: BodyType = .SELECTABLE
    var loginToken: String = ""
    var language: Language = .DEFAULT
    var userId: String = ""
}

// Builds the URL for launching the Ready Player Me avatar creator with the given config
class AvatarCreatorSettings {
    private let config: AvatarCreatorConfig
    
    // Initializes with custom configuration
    init(config: AvatarCreatorConfig) {
        self.config = config
    }
    
    // Initializes with default configuration
    init() {
        self.config = AvatarCreatorConfig()
    }
    
    // Constructs and returns the full URL for launching the avatar creator
    func generateUrl() -> URL {
        var url = "https://\(config.subdomain).readyplayer.me/"
        
        if (config.language != .DEFAULT) {
            url += "\(config.language.rawValue)/"
        }
        
        url += "avatar?frameApi&source=ios-swift-avatar-creator"
        
        if (config.clearCache) {
            url += "&clearCache"
        }
        
        if (!config.loginToken.isEmpty) {
            url += "&token=\(config.loginToken)"
        }
        
        if (config.quickStart) {
            url += "&quickStart"
        }
        
        if (!config.quickStart && config.gender != .NONE) {
            url += "&gender=\(config.gender.rawValue)"
        }
        
        if (!config.quickStart && config.bodyType == .SELECTABLE) {
            url += "&selectBodyType"
        }
        
        if (!config.quickStart && config.bodyType != .SELECTABLE) {
            url += "&bodyType=\(config.bodyType.rawValue)"
        }
      
        return URL(string: url)!
    }
}
