//
//  UnLockOutfits.swift
//  FitGenius
//
//  Created by Isai Flores on 4/4/25.
//

import Foundation

// MARK: - Request Body Structures
// Structures used to encode the request body for the Ready Player Me unlock API.
// Format: { "data": { "userId": "..." } }

struct UnlockRequestBody: Codable {
    let data: UnlockData
}

struct UnlockData: Codable {
    let userId: String
}

// MARK: - Ready Player Me API Client

class ReadyPlayerMeAPI {
    private let apiKey = "sk_live_59ctcjPDVs8bMJz9O_ukz-kodC4yskx6bG5T" // Replace with secure key management in production
    private let endpoint = "https://api.readyplayer.me/v1/assets"
    
    /// Unlocks an outfit (asset) for a specific user
    /// - Parameters:
    ///   - assetId: The ID of the outfit or asset to unlock
    ///   - userId: The ID of the user the asset should be unlocked for
    func unlockOutfit(assetId: String, for userId: String) {
        guard let url = URL(string: "\(endpoint)/\(assetId)/unlock") else {
            print("❌ Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = UnlockRequestBody(data: UnlockData(userId: userId))
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            print("❌ Failed to encode request body: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Request failed: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 204:
                    print("✅ Asset \(assetId) successfully unlocked for user \(userId)")
                case 400:
                    print("⚠️ Bad Request - Make sure the asset and user ID are valid.")
                case 401:
                    print("⚠️ Unauthorized - Check API key.")
                case 404:
                    print("⚠️ Not Found - Asset or user ID might not exist.")
                default:
                    print("⚠️ Unexpected status code: \(httpResponse.statusCode)")
                }
            }
        }

        task.resume()
    }
}
