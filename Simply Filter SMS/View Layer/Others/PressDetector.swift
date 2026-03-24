//
//  PressDetector.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/03/2026.
//

import SwiftUI
import UIKit

struct PressDetector: UIViewRepresentable {
    var onPress: (Bool) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let recognizer = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleGesture(_:))
        )
        recognizer.minimumPressDuration = 0
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delegate = context.coordinator
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPress: onPress)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPress: (Bool) -> Void

        init(onPress: @escaping (Bool) -> Void) {
            self.onPress = onPress
        }

        @objc func handleGesture(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                onPress(true)
            case .ended, .cancelled, .failed:
                onPress(false)
            default:
                break
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
