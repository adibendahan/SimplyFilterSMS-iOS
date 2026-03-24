//
//  EnableExtensionView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 22/11/2025.
//

import SwiftUI

private let kEnableExtensionCycleStartDelay: UInt64  = 600_000_000   // pause before first step and after reset
private let kEnableExtensionStepDuration: UInt64     = 1_100_000_000 // time each step stays highlighted
private let kEnableExtensionResetPause: UInt64       = 800_000_000   // pause before resetting to step 0

struct EnableExtensionView: View {

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.accessibilityVoiceOverEnabled)
    private var voiceOverEnabled

    @ObservedObject var model: ViewModel
    @State private var activeStep = 0
    @State private var isPressing = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(model.description)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(model.steps.indices, id: \.self) { index in
                            EnableExtensionStepView(step: model.steps[index], isActive: activeStep >= model.steps[index].stepNumber)
                        }
                    }
                    .background(
                        PressDetector { isPressing = $0 }
                    )
                    .task {
                        guard !voiceOverEnabled else {
                            activeStep = model.steps.last?.stepNumber ?? 0
                            return
                        }

                        @MainActor func pauseableSleep(_ nanoseconds: UInt64) async {
                            let chunk: UInt64 = 50_000_000
                            var remaining = nanoseconds
                            while remaining > 0 && !Task.isCancelled {
                                if isPressing {
                                    try? await Task.sleep(nanoseconds: chunk)
                                } else {
                                    let slice = min(chunk, remaining)
                                    try? await Task.sleep(nanoseconds: slice)
                                    remaining -= slice
                                }
                            }
                        }

                        while !Task.isCancelled {
                            await pauseableSleep(kEnableExtensionCycleStartDelay)
                            for step in model.steps {
                                withAnimation(reduceMotion ? nil : .default) {
                                    activeStep = step.stepNumber
                                }
                                await pauseableSleep(kEnableExtensionStepDuration)
                            }
                            await pauseableSleep(kEnableExtensionResetPause)
                            withAnimation(reduceMotion ? nil : .default) {
                                activeStep = 0
                            }
                            await pauseableSleep(kEnableExtensionCycleStartDelay)
                        }
                    }
                }
                .padding()
                .background(RefreshControlDisabler())
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                Button(action: openSettings) {
                    Text("enableExtension_ready_callToAction"~)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButton())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .accessibilityIdentifier(TestIdentifier.callToActionButton.rawValue)
                .accessibilityHint("a11y_enableExtension_ctaHint"~)
            }
            .navigationTitle(model.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: dismissView) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier(TestIdentifier.cancelButton.rawValue)
                }
            }
        }
        .interactiveDismissDisabled(model.isInteractiveDismissDisabled)
    }

    private func dismissView() {
        withAnimation {
            model.onDismiss()
            dismiss()
        }
    }

    private func openSettings() {
        withAnimation {
            model.onCTA()
            dismiss()
        }
    }
}

// MARK: - ViewModel -
extension EnableExtensionView {

    class ViewModel: BaseViewModel, ObservableObject {
        let steps: [any EnableExtensionStepProtocol]
        let title: String
        let description: String
        let isInteractiveDismissDisabled: Bool
        let onDismiss: () -> Void
        let onCTA: () -> Void

        init(steps: [any EnableExtensionStepProtocol],
             title: String = "enableExtension_welcome"~,
             description: String = "enableExtension_welcome_desc"~,
             isInteractiveDismissDisabled: Bool,
             onDismiss: @escaping () -> Void,
             onCTA: @escaping () -> Void,
             appManager: AppManagerProtocol = AppManager.shared) {
            self.steps = steps
            self.title = title
            self.description = description
            self.isInteractiveDismissDisabled = isInteractiveDismissDisabled
            self.onDismiss = onDismiss
            self.onCTA = onCTA
            super.init(appManager: appManager)
        }
    }
}

// MARK: - Preview -
#Preview {
    EnableExtensionView(
        model: EnableExtensionView.ViewModel(
            steps: Array(EnableExtensionStep.allCases),
            isInteractiveDismissDisabled: false,
            onDismiss: {},
            onCTA: {},
            appManager: AppManager.previews
        )
    )
}
