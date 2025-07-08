//
//  AvatarLoader.swift
//  FitGenius
//
//  Created by Isai Flores on 4/1/25.
//

import SwiftUI
import UIKit

// Observable object responsible for loading and caching avatar images from Ready Player Me
class AvatarLoader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    
    // MARK: - Published Properties
    @Published var avatarImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var downloadProgress: Double = 0.0
    @Published var avatarURL: URL?
    
    // MARK: - Private Properties
    private var avatarId: String?
    private var downloadTask: URLSessionDownloadTask?
    
    // Ready Player Me API configuration
    private let baseURL = "https://models.readyplayer.me"
    private let imageSize = 1024 // Pixel size (e.g., 256, 512, 1024)
    private let imageFormat = "png" // Can be "png" or "jpg"
    
    // Path to avatar image cache folder
    private var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar_images", isDirectory: true)
    }
    
    // Path to the specific cached avatar image
    private var cacheURL: URL? {
        guard let avatarId = avatarId else { return nil }
        return cacheDirectory.appendingPathComponent("\(avatarId).\(imageFormat)")
    }
    
    // URLSession with delegate for download handling
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    // MARK: - Public Methods
    
    // Begins loading avatar image. Checks cache first, otherwise downloads.
    func loadAvatar() {
        guard !isLoading else { return }
        
        guard let avatarId = UserDefaults.standard.string(forKey: "avatarId") else {
            handleError("No avatar ID configured")
            return
        }
        
        self.avatarId = avatarId
        resetState()
        
        // Ensure cache directory exists
        do {
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        } catch {
            handleError("Could not create cache directory")
            return
        }
        
        // Check cache first
        if let cachedURL = cacheURL, FileManager.default.fileExists(atPath: cachedURL.path) {
            loadCachedImage(cachedURL)
            return
        }
        
        // Download if not cached
        guard let url = buildRenderURL(avatarId: avatarId) else {
            handleError("Invalid avatar URL")
            return
        }
        
        startDownload(with: url)
    }
    
    // Cancels an active download and resets loading state
    func cancel() {
        downloadTask?.cancel()
        resetLoadingState()
    }
    
    // Clears cached image and resets related state
    func clearCache() {
        guard let cacheURL = cacheURL else { return }
        try? FileManager.default.removeItem(at: cacheURL)
        avatarURL = nil
        avatarImage = nil
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    // Updates download progress as avatar image is downloaded
    func urlSession(_ session: URLSession,
                   downloadTask: URLSessionDownloadTask,
                   didWriteData bytesWritten: Int64,
                   totalBytesWritten: Int64,
                   totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0.0
        
        DispatchQueue.main.async {
            self.downloadProgress = progress
        }
    }
    
    // Handles completion of avatar download and saves to cache
    func urlSession(_ session: URLSession,
                   downloadTask: URLSessionDownloadTask,
                   didFinishDownloadingTo location: URL) {
        do {
            guard let cacheURL = self.cacheURL else {
                throw NSError(domain: "Invalid cache path", code: -1)
            }
            
            // Move downloaded file to cache
            try FileManager.default.moveItem(at: location, to: cacheURL)
            
            // Verify the file
            guard FileManager.default.fileExists(atPath: cacheURL.path),
                  let _ = UIImage(contentsOfFile: cacheURL.path) else {
                throw NSError(domain: "Invalid image file", code: -2)
            }
            
            DispatchQueue.main.async {
                self.avatarURL = cacheURL
                self.loadCachedImage(cacheURL)
                print("✅ Avatar image saved to cache")
            }
        } catch {
            DispatchQueue.main.async {
                self.handleError("Failed to save image: \(error.localizedDescription)")
            }
        }
    }
    
    // Handles any error that occurs during URL session tasks
    func urlSession(_ session: URLSession,
                   task: URLSessionTask,
                   didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.handleError("Download failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    // Builds a Ready Player Me render URL with a random pose
    private func buildRenderURL(avatarId: String) -> URL? {
        // List of supported poses
        let poses = ["power-stance", "relaxed", "standing", "thumbs-up"]
        
        // Pick one at random
        let randomPose = poses.randomElement() ?? "standing"
        
        var components = URLComponents(string: "\(baseURL)/\(avatarId).png")
        components?.queryItems = [
            URLQueryItem(name: "pose", value: randomPose),
            URLQueryItem(name: "camera", value: "fullbody"),
            URLQueryItem(name: "quality", value: "100"),
            URLQueryItem(name: "size", value: "\(imageSize)")
        ]
        
        print("🎲 Using random pose: \(randomPose)") // Optional debug
        return components?.url
    }






    
    private func loadCachedImage(_ url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = UIImage(contentsOfFile: url.path) {
                DispatchQueue.main.async {
                    self.avatarImage = image
                    self.avatarURL = url
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.handleError("Invalid cached image")
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
    }
    
    private func startDownload(with url: URL) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.downloadProgress = 0
        }
        
        downloadTask = urlSession.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    private func resetState() {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.downloadProgress = 0
        }
    }
    
    private func resetLoadingState() {
        DispatchQueue.main.async {
            self.isLoading = false
            self.downloadProgress = 0
        }
    }
    
    private func handleError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.isLoading = false
            print("❌ Error: \(message)")
        }
    }
}
