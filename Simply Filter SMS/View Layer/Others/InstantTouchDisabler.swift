//
//  InstantTouchDisabler.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 28/03/2026.
//

import SwiftUI
import UIKit

/// Sets delaysContentTouches on parent UIScrollViews.
/// Used to override UIScrollView.appearance() for specific scroll views.
struct InstantTouchDisabler: UIViewRepresentable {
    var delaysContentTouches: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard uiView.window != nil else { return }
        var current: UIView? = uiView
        while let view = current, !(view is UIWindow) {
            if let scrollView = view as? UIScrollView {
                scrollView.delaysContentTouches = self.delaysContentTouches
            }
            current = view.superview
        }
    }
}
