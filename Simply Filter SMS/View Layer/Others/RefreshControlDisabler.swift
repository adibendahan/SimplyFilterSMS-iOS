//
//  RefreshControlDisabler.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/03/2026.
//

import SwiftUI
import UIKit

struct RefreshControlDisabler: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            var current: UIView? = uiView
            while let view = current {
                if let scrollView = view as? UIScrollView {
                    scrollView.refreshControl = nil
                    return
                }
                current = view.superview
            }
        }
    }
}
