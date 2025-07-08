//
//  KeyboardResponder.swift
//  FitGenius
//
//  Created by Sergio Garcia on 5/2/25.
//

import SwiftUI
import Combine

// Observes keyboard show/hide notifications and publishes the current keyboard height
final class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Subscribes to keyboard appearance/disappearance and updates `currentHeight`
    init() {
        let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }

        let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        Publishers.Merge(keyboardWillShow, keyboardWillHide)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] height in
                print("🔽 Keyboard height =", height)
                self?.currentHeight = height
            }
            .store(in: &cancellableSet)
    }
}
