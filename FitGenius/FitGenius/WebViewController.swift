//
//  WebViewController.swift
//  FitGenius
//
//  Created by Isai Flores on 4/4/25.
//

import UIKit
import WebKit

// MARK: - WKWebViewConfiguration Extension
extension WKWebViewConfiguration {
    
    // // Configures the WKWebView with JavaScript, media playback, cookie policies, and the Ready Player Me message handler.
    static func avatarCreatorConfiguration(messageHandler: WKScriptMessageHandler) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Enable JavaScript
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            config.preferences.javaScriptEnabled = true
        }

        // Enable cookies and storage
        config.websiteDataStore = WKWebsiteDataStore.default()
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always

        // Inject message handler script
        let script = WKUserScript(
            source: WebViewController.messageHandlerScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(script)
        config.userContentController.add(messageHandler, name: "iosListener")
        
        return config
    }
}

class WebViewController: UIViewController {
    // MARK: - Properties
    weak var webViewDelegate: WebViewDelegate?
    weak var errorDelegate: WebViewErrorDelegate?
    var webView: WKWebView!
    private var subscriptionCreated = false
    private let cookieName = "rpm-uid"
    var authToken: String?
    var subdomain = "fitgenius"
    
    // MARK: - View Lifecycle
    
    // Initializes and configures the WKWebView instance.
    override func loadView() {
        let config = WKWebViewConfiguration.avatarCreatorConfiguration(messageHandler: self)
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true  // Added from demo
        view = webView
    }
    
    // Loads the Ready Player Me creator/editor view when the controller appears.
    override func viewDidLoad() {
        super.viewDidLoad()
        loadWebView(editMode: UserDefaults.standard.string(forKey: "avatarId") != nil)
    }
    
    // Ensures cleanup when the view controller is deallocated.
    deinit {
        cleanUp()
    }
    
    // MARK: - Script Handling
    
    // // JavaScript snippet that listens for messages from Ready Player Me and posts them to the native iOS app.
    static let messageHandlerScript = """
        window.addEventListener('message', function(event){
            const json = parse(event)

            if (json?.source !== 'readyplayerme') {
              return;
            }

            // Subscribe to all events sent from Ready Player Me once frame is ready
            if (json.eventName === 'v1.frame.ready') {
              window.postMessage(
                JSON.stringify({
                  target: 'readyplayerme',
                  type: 'subscribe',
                  eventName: 'v1.**'
                }),
                '*'
              );
            }

            window.webkit.messageHandlers.iosListener.postMessage(event.data);

            function parse(event) {
                try {
                    return JSON.parse(event.data)
                } catch (error) {
                    return null
                }
            };
        });
    """
    
    // MARK: - WebView Operations
    
    // Loads either the avatar editor or creator URL into the WebView, with optional cache clearing.
    func loadWebView(editMode: Bool, clearCache: Bool = false) {
        let url: URL?
        
        if editMode {
            guard let avatarId = UserDefaults.standard.string(forKey: "avatarId") else { return }
            url = AvatarEditURLBuilder(avatarId: avatarId).build()
        } else {
            url = AvatarCreatorSettings().generateUrl()
        }
        
        if clearCache {
            WebCacheCleaner.clean()
        }
        
        if let url = url {
            webView.load(URLRequest(url: url))
        }
    }
    
    // Constructs the avatar creation or editing URL manually (e.g., with token).
    func generateAvatarURL(editMode: Bool) -> URL? {
        if editMode {
            guard let avatarId = UserDefaults.standard.string(forKey: "avatarId") else { return nil }
            var components = URLComponents(string: "https://\(subdomain).readyplayer.me/avatar")!
            components.queryItems = [
                URLQueryItem(name: "id", value: avatarId),
                URLQueryItem(name: "token", value: authToken)
            ]
            return components.url
        } else {
            var components = URLComponents(string: "https://\(subdomain).readyplayer.me/avatar")!
            components.queryItems = [
                URLQueryItem(name: "token", value: authToken)
            ]
            return components.url
        }
    }
    
    // Reloads the WebView, deciding whether to clear cache first.
    func reload(clearCache: Bool = false) {
        loadWebView(
            editMode: UserDefaults.standard.string(forKey: "avatarId") != nil,
            clearCache: clearCache
        )
    }
    
    // Removes message handlers and stops loading to prevent memory leaks.
    func cleanUp() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "iosListener")
        webView?.navigationDelegate = nil
        webView?.stopLoading()
    }
    
    // MARK: - Cookie Handling (Improved from demo)
    // Checks if Ready Player Me-related cookies are present in the WebView.
    func hasCookies() -> Bool {
        var hasRpmCookies = false
        let semaphore = DispatchSemaphore(value: 0)
        
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            hasRpmCookies = cookies.contains { $0.name.contains(self.cookieName) }
            semaphore.signal()
        }
        
        semaphore.wait()
        return hasRpmCookies
    }
    
    // Passes error to an optional delegate for UI feedback.
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorDelegate?.webViewDidFail(with: error)
        }
    }
}

// MARK: - WKScriptMessageHandler
extension WebViewController: WKScriptMessageHandler {
    
    // Receives and decodes messages from the embedded WebView via the WKScriptMessageHandler protocol.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("📩 Received message: \(message.body)")

        var jsonData: Data?

        if let body = message.body as? String {
            jsonData = body.data(using: .utf8)
        } else if let bodyDict = message.body as? [String: Any] {
            jsonData = try? JSONSerialization.data(withJSONObject: bodyDict)
        }

        guard let data = jsonData else {
            errorDelegate?.webViewDidFailToLoadAvatar()
            return
        }

        do {
            let event = try JSONDecoder().decode(WebViewEvent.self, from: data)
            handleWebViewEvent(event)
        } catch {
            handleError(error)
        }
    }
    
    // Routes events like frame ready, avatar exported, user set, etc. to the appropriate handlers.
    private func handleWebViewEvent(_ event: WebViewEvent) {
        switch event.eventName {
        case "v1.frame.ready":
            handleFrameReady()
        case "v1.subscription.created":
            subscriptionCreated = true
        case "v1.avatar.exported":
            handleAvatarExported(event.data)
        case "v2.avatar.exported":
            handleAvatarExportedV2(event.data)
        case "v1.user.set":
            handleUserSet(event.data)
        case "v1.user.updated":
            handleUserUpdated(event.data)
        case "v1.user.logout":
            handleUserLoggedOut()
        case "v1.user.authorized":
            handleUserAuthorized(event.data)
        default:
            print("Unhandled event: \(event.eventName)")
        }
    }
    
    // MARK: - Event Handlers
    // Handles frame ready confirmation from Ready Player Me.
    private func handleFrameReady() {
        print("v1.frame.ready event received")
    }
    
    // Handles v1 export events and notifies delegate with a constructed `AvatarExportedEvent`.
    private func handleAvatarExported(_ data: [String: String]?) {
        guard let url = data?["url"], url.hasSuffix(".glb") else {
            errorDelegate?.webViewDidFailToLoadAvatar()
            return
        }
        guard let userId = data?["userId"] else {
            errorDelegate?.webViewDidFail(with: NSError(domain: "WebViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing user data"]))
            return
        }
        
        let event = AvatarExportedEvent(
            url: url,
            userId: userId,
            expression: nil,
            pose: nil,
            blendShapes: nil,
            camera: nil,
            background: nil,
            quality: 100,
            size: 1024,
            uat: nil
        )

        webViewDelegate?.onAvatarExported(event: event)
        storeAvatarId(from: url)
        storeUserId(userId: userId)
    }
    
    // Handles v2 export events with more metadata and flexibility.
    private func handleAvatarExportedV2(_ data: [String: Any]?) {
        guard let url = data?["url"] as? String else {
            errorDelegate?.webViewDidFailToLoadAvatar()
            return
        }
        guard let userId = data?["userId"] else {
            errorDelegate?.webViewDidFail(with: NSError(domain: "WebViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing user data"]))
            return
        }
        
        let event = AvatarExportedEvent(
            url: url,
            userId: userId as! String,
            expression: data?["expression"] as? String,
            pose: data?["pose"] as? String,
            blendShapes: data?["blendShapes"] as? String,
            camera: data?["camera"] as? String,
            background: data?["background"] as? String,
            quality: data?["quality"] as? Int ?? 100,
            size: data?["size"] as? Int ?? 1024,
            uat: data?["uat"] as? String
        )

        webViewDelegate?.onAvatarExported(event: event)
        storeAvatarId(from: url)
        storeUserId(userId: userId as! String)
    }
    
    // Informs delegate when a user is set in the RPM system.
    private func handleUserSet(_ data: [String: String]?) {
        guard let userId = data?["userId"] else {
            errorDelegate?.webViewDidFail(with: NSError(domain: "WebViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing user data"]))
            return
        }
        
        let event = UserSetEvent(id: userId, avatarSettings: nil)
        webViewDelegate?.onUserSet(event: event)
    }
    
    // Informs delegate when a user is authorized.
    private func handleUserAuthorized(_ data: [String: String]?) {
        guard let userId = data?["userId"] else {
            errorDelegate?.webViewDidFail(with: NSError(domain: "WebViewController", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing user authorization data"]))
            return
        }
        
        let event = UserAuthorizedEvent(id: userId)
        webViewDelegate?.onUserAuthorized(event: event)
    }
    
    // Fetches avatar settings and informs delegate when a user is updated.
    private func handleUserUpdated(_ data: [String: String]?) {
        guard let userId = data?["userId"] else {
            errorDelegate?.webViewDidFail(with: NSError(domain: "WebViewController", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing user update data"]))
            return
        }
        
        let avatarSettings: AvatarSettings? = fetchAvatarSettings(for: userId)
        let event = UserUpdatedEvent(id: userId, avatarSettings: avatarSettings)
        webViewDelegate?.onUserUpdated(event: event)
    }
    
    // Informs delegate when the user logs out of the WebView.
    private func handleUserLoggedOut() {
        webViewDelegate?.onUserLoggedOut()
    }
    
    // MARK: - Helper Methods
    
    // Synchronously fetches avatar settings from Ready Player Me models endpoint.
    private func fetchAvatarSettings(for userId: String) -> AvatarSettings? {
        let urlString = "https://models.readyplayer.me/\(userId)"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        var result: AvatarSettings? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    result = try decoder.decode(AvatarSettings.self, from: data)
                } catch {
                    print("Error decoding avatar settings: \(error)")
                }
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        return result
    }
    
    // Extracts and stores avatar ID (from `.glb` URL) in UserDefaults.
    private func storeAvatarId(from url: String) {
        guard let avatarId = url.components(separatedBy: "/").last?.replacingOccurrences(of: ".glb", with: "") else {
            return
        }
        UserDefaults.standard.set(avatarId, forKey: "avatarId")
        print("Avatar saved: \(avatarId)")
    }
    
    // Stores the user ID to UserDefaults.
    private func storeUserId(userId: String) {
        UserDefaults.standard.set(userId, forKey: "userId")
        print("UserId saved: \(userId)")
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    
    // Handles failed navigation events.
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }
    
    // Confirms successful WebView load.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Ready Player Me loaded successfully")
    }
}

// MARK: - Supporting Types
// Codable structure representing incoming events from the WebView.
struct WebViewEvent: Codable {
    let source: String?
    let eventName: String
    let data: [String: String]?
}
