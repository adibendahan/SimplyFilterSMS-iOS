//
//  HorizontalDragRecognizer.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 03/04/2026.
//

import SwiftUI
import UIKit

// Installs a UIPanGestureRecognizer on its superview so the recognizer sits on an
// ancestor and receives touches regardless of which child won the hit test —
// buttons tap normally while horizontal drags fire the selection callback.
class HorizontalDragHostView: UIView {
    var panGesture: UIPanGestureRecognizer?
    private weak var installedOn: UIView?

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let pan = panGesture, let old = installedOn {
            old.removeGestureRecognizer(pan)
            installedOn = nil
        }
        if let pan = panGesture, let sup = superview {
            sup.addGestureRecognizer(pan)
            installedOn = sup
        }
    }
}

struct HorizontalDragRecognizer<T>: UIViewRepresentable
where T: CaseIterable & Equatable, T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    let allCases: [T]
    let reduceMotion: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, allCases: allCases, reduceMotion: reduceMotion)
    }

    func makeUIView(context: Context) -> HorizontalDragHostView {
        let view = HorizontalDragHostView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        view.panGesture = pan
        return view
    }

    func updateUIView(_ uiView: HorizontalDragHostView, context: Context) {
        context.coordinator.selection = $selection
        context.coordinator.allCases = allCases
        context.coordinator.reduceMotion = reduceMotion
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var selection: Binding<T>
        var allCases: [T]
        var reduceMotion: Bool

        init(selection: Binding<T>, allCases: [T], reduceMotion: Bool) {
            self.selection = selection
            self.allCases = allCases
            self.reduceMotion = reduceMotion
        }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            guard pan.state == .changed, let view = pan.view else { return }
            let location = pan.location(in: view)
            let segmentWidth = view.bounds.width / CGFloat(allCases.count)
            guard segmentWidth > 0 else { return }
            let index = min(max(Int((location.x - segmentWidth / 3.0) / segmentWidth), 0), allCases.count - 1)
            let option = allCases[index]
            guard selection.wrappedValue != option else { return }
            withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.72)) {
                selection.wrappedValue = option
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
