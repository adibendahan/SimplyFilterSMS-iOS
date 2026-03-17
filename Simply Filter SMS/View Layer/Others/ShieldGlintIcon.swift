//
//  ShieldGlintIcon.swift
//  Simply Filter SMS
//

import SwiftUI


// Isolated in its own view so its internal timer never triggers a re-render
// of the parent view (e.g. AppHomeView), which would cause open Menus to flicker.
@available(iOS 17, *)
struct ShieldGlintIcon: View {
    @StateObject private var glintModel = GlintModel()

    var body: some View {
        Image(systemName: "bolt.shield.fill")
            .phaseAnimator([0, 1, 2, 1, 0], trigger: glintModel.trigger) { view, phase in
                view
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        { switch phase {
                            case 1:  Color.yellow
                            case 2:  Color.white.opacity(0.3)
                            default: Color.white.opacity(0.9)
                        }}(),
                        Color.indigo
                    )
            } animation: { phase in
                phase == 0 ? .linear(duration: 0.3) : .easeInOut(duration: 0.08)
            }
    }

    private class GlintModel: ObservableObject {
        @Published var trigger = false
        private var task: Task<Void, Never>?

        init() {
            task = Task { @MainActor [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    self?.trigger.toggle()
                }
            }
        }

        deinit { task?.cancel() }
    }
}
