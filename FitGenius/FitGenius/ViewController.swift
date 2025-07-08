//
//  ViewController.swift
//  FitGenius
//
//  Created by Isai Flores on 4/4/25.
//

import UIKit
import Combine

class AvatarCreatorViewController: UIViewController {
    
    // MARK: - Properties
    private var webViewController: WebViewController?
    private var cancellables = Set<AnyCancellable>()
    private let avatarExportedSubject = PassthroughSubject<AvatarExportedEvent, Never>()
    private let userEventsSubject = PassthroughSubject<String, Never>()
    private let webViewControllerTag = 100
    
    private let apiKey = "sk_live_59ctcjPDVs8bMJz9O_ukz-kodC4yskx6bG5T"
    private let applicationId = "679d89c054e3036f4bc9aed8"
    private let subdomain = "fitgenius"
    
    // MARK: - UI Elements
    private lazy var createAvatarButton: UIButton = {
        let button = UIButton.primaryActionButton(
            title: "Create Avatar",
            target: self,
            action: #selector(createAvatar)
        )
        button.accessibilityIdentifier = "createAvatarButton"
        return button
    }()
    
    private lazy var editAvatarButton: UIButton = {
        let button = UIButton.primaryActionButton(
            title: "Edit Avatar",
            target: self,
            action: #selector(editAvatar)
        )
        button.accessibilityIdentifier = "editAvatarButton"
        button.isHidden = true
        return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Lifecycle
    // Initializes the view, sets up UI and Combine bindings, then either launches avatar creation or editing based on stored user ID.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        if let userId = UserDefaults.standard.string(forKey: "guestUserId") {
            editAvatar()
        } else {
            createAvatar()
        }
        editAvatarButton.isHidden = !hasExistingAvatar()

    }
    // Cleans up Combine subscriptions and removes the WebView on deallocation.
    deinit {
        cleanUp()
    }
    
    // MARK: - UI Setup
    
    // Applies general styling and calls methods to add buttons and activity indicator.
    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupButtons()
        setupActivityIndicator()
    }
    
    // Adds and positions the "Create Avatar" and "Edit Avatar" buttons.
    private func setupButtons() {
        view.addSubview(createAvatarButton)
        view.addSubview(editAvatarButton)
        
        NSLayoutConstraint.activate([
            createAvatarButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createAvatarButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            createAvatarButton.widthAnchor.constraint(equalToConstant: 200),
            createAvatarButton.heightAnchor.constraint(equalToConstant: 50),
            
            editAvatarButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editAvatarButton.topAnchor.constraint(equalTo: createAvatarButton.bottomAnchor, constant: 20),
            editAvatarButton.widthAnchor.constraint(equalToConstant: 200),
            editAvatarButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        editAvatarButton.isHidden = !hasExistingAvatar()
    }
    
    // Adds and centers the loading spinner.
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Bindings
    
    // Subscribes to avatar export and user event publishers. Routes messages to UI and handlers.
    private func setupBindings() {
        avatarExportedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleAvatarExported(event: event)
            }
            .store(in: &cancellables)
        
        userEventsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(message: message)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Action Handlers
    
    // Begins avatar creation flow for new users.
    @objc private func createAvatar() {
        setupAvatarFlow()
    }
    
    // Begins avatar editing flow for returning users (requires stored user ID).
    @objc private func editAvatar() {
        guard let userId = UserDefaults.standard.string(forKey: "guestUserId") else {
            showAlert(message: "No existing avatar found")
            return
        }
        setupAvatarFlow(with: userId)
    }
    
    // MARK: - API Calls
    
    // Coordinates the full flow: gets or creates user, fetches token, and loads the avatar creator WebView.
    private func setupAvatarFlow(with existingUserId: String? = nil) {
        startLoading()
        let publisher = existingUserId != nil ?
            Just(existingUserId!)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher() :
            createGuestAccount()
        
        publisher
            .flatMap { [weak self] userId -> AnyPublisher<(String, String), Error> in
                guard let self = self else {
                    return Fail(error: URLError(.unknown)).eraseToAnyPublisher()
                }
                return self.requestToken(userId: userId)
                    .map { (userId, $0) }
                    .eraseToAnyPublisher()
            }
            .retry(2)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.stopLoading()
                if case .failure(let error) = completion {
                    print("❌ Avatar setup failed: \(error)")
                    self?.showAlert(message: "Failed to setup avatar creator. Please try again.")
                }
            }, receiveValue: { [weak self] (userId, token) in
                UserDefaults.standard.set(userId, forKey: "guestUserId")
                self?.presentAvatarWebView(with: token)
            })
            .store(in: &cancellables)
    }
    
    // Sends a POST request to create a guest Ready Player Me user, returning the user ID.
    private func createGuestAccount() -> AnyPublisher<String, Error> {
        let url = URL(string: "https://api.readyplayer.me/v1/users")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let body: [String: Any] = [
            "data": [
                "applicationId": applicationId
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> String in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let userData = json?["data"] as? [String: Any],
                      let userId = userData["id"] as? String else {
                    throw URLError(.cannotParseResponse)
                }
                return userId
            }
            .eraseToAnyPublisher()
    }
    
    // Fetches an authentication token for a given user ID.
    private func requestToken(userId: String) -> AnyPublisher<String, Error> {
        guard let url = URL(string: "https://api.readyplayer.me/v1/auth/token?userId=\(userId)&partner=\(subdomain)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> String in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let data = json?["data"] as? [String: Any],
                      let token = data["token"] as? String else {
                    throw URLError(.cannotParseResponse)
                }
                return token
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - WebView Management
    
    // Initializes, configures, and displays the WebViewController for Ready Player Me.
    private func presentAvatarWebView(with token: String) {
        destroyWebView()
        
        let webVC = WebViewController()
        webVC.view.tag = webViewControllerTag
        webVC.webViewDelegate = self
        webVC.authToken = token
        
        addChild(webVC)
        view.insertSubview(webVC.view, belowSubview: activityIndicator)
        webVC.view.frame = view.safeAreaLayoutGuide.layoutFrame
        webVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webVC.didMove(toParent: self)
        
        webViewController = webVC
        //MARK: - One Change
        webVC.loadWebView(editMode: hasExistingAvatar(), clearCache: true)
    }
    
    // Properly removes and deinitializes the WebView from the view hierarchy.
    private func destroyWebView() {
        if let webVC = webViewController {
            webVC.willMove(toParent: nil)
            webVC.view.removeFromSuperview()
            webVC.removeFromParent()
            webVC.cleanUp()
            webViewController = nil
        }
    }
    
    // MARK: - Avatar Handling
    
    // Processes the export event, logs, saves the avatar ID, and updates UI.
    private func handleAvatarExported(event: AvatarExportedEvent) {
        stopLoading()
        logAvatarExport(event: event)
        storeAvatarId(from: event.url)
        editAvatarButton.isHidden = false
        dismissWebViewController()
        showAlert(message: "Avatar created successfully!")
    }
    
    // Logs export event data for debugging.
    private func logAvatarExport(event: AvatarExportedEvent) {
        print("✅ Avatar Exported: \(event.url)")
        if let userId = event.userId {
            print("👤 User ID: \(userId)")
        }
    }
    
    // Extracts and saves the avatar ID (from the URL) to UserDefaults.
    private func storeAvatarId(from url: String) {
        guard let avatarId = extractAvatarId(from: url) else {
            print("⚠️ Could not extract avatar ID from URL: \(url)")
            return
        }
        
        UserDefaults.standard.set(avatarId, forKey: UserDefaultsKeys.avatarId)
        print("💾 AvatarId saved: \(avatarId)")
    }
    
    // Returns true if an avatar ID is saved in UserDefaults.
    private func hasExistingAvatar() -> Bool {
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.avatarId) != nil
    }
    
    // Extracts the avatar ID (removes .glb file extension).
    private func extractAvatarId(from url: String) -> String? {
        return URL(string: url)?.lastPathComponent.replacingOccurrences(of: ".glb", with: "")
    }
    
    // Hides and removes the WebView.
    private func dismissWebViewController() {
        //webViewController?.view.isHidden = true
        destroyWebView()
    }
    
    // MARK: - Loading State
    
    // Starts the spinner and disables UI.
    private func startLoading() {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
    }
    
    // Stops the spinner and re-enables UI.
    private func stopLoading() {
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
    }
    
    // MARK: - Cleanup
    
    // Cancels all Combine subscriptions and removes the WebView.
    private func cleanUp() {
        destroyWebView()
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - WebViewDelegate

// Handles events from Ready Player Me's JavaScript bridge:
extension AvatarCreatorViewController: WebViewDelegate {
    func onAvatarExported(event: AvatarExportedEvent) {
        avatarExportedSubject.send(event)
    }
    
    func onAssetUnlocked(event: AssetUnlockedEvent) {
        userEventsSubject.send("Asset unlocked: \(event.assetId)")
    }
    
    func onUserSet(event: UserSetEvent) {
        userEventsSubject.send("User set: \(event.id)")
    }
    
    func onUserAuthorized(event: UserAuthorizedEvent) {
        userEventsSubject.send("User authorized: \(event.id)")
    }
    
    func onUserUpdated(event: UserUpdatedEvent) {
        userEventsSubject.send("User updated: \(event.id)")
    }
    
    func onUserLoggedOut() {
        userEventsSubject.send("User logged out")
        editAvatarButton.isHidden = true
    }
}

// MARK: - Alert Presentation
extension AvatarCreatorViewController {
    
    // Displays a native iOS alert with the given message.
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Ready Player Me",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIButton Extension

// Creates a styled capsule-style UIButton with configurable title and target.
extension UIButton {
    static func primaryActionButton(title: String, target: Any?, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        
        let button = UIButton(configuration: config, primaryAction: nil)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}

// MARK: - Constants

// Stores static key names for avatar and guest user ID storage.
private enum UserDefaultsKeys {
    static let avatarId = "avatarId"
    static let guestUserId = "guestUserId"
}
