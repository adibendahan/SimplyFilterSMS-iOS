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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("enableExtension_welcome_desc"~)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(EnableExtensionStep.allCases, id: \.self) { step in
                            EnableExtensionStepView(step: step, isActive: activeStep >= step.stepNumber)
                        }
                    }
                    .task {
                        guard !voiceOverEnabled else {
                            activeStep = EnableExtensionStep.allCases.count
                            return
                        }
                        while !Task.isCancelled {
                            try? await Task.sleep(nanoseconds: kEnableExtensionCycleStartDelay)
                            for step in EnableExtensionStep.allCases {
                                withAnimation(reduceMotion ? nil : .default) {
                                    activeStep = step.stepNumber
                                }
                                try? await Task.sleep(nanoseconds: kEnableExtensionStepDuration)
                            }
                            try? await Task.sleep(nanoseconds: kEnableExtensionResetPause)
                            withAnimation(reduceMotion ? nil : .default) {
                                activeStep = 0
                            }
                            try? await Task.sleep(nanoseconds: kEnableExtensionCycleStartDelay)
                        }
                    }
                }
                .padding()
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
            .navigationTitle("enableExtension_welcome"~)
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
        .interactiveDismissDisabled()
    }

    private func dismissView() {
        withAnimation {
            model.isAppFirstRun = false
            dismiss()
        }
    }

    private func openSettings() {
        withAnimation {
            model.isAppFirstRun = false
            dismiss()
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
}

// MARK: - ViewModel -
extension EnableExtensionView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var isAppFirstRun: Bool {
            didSet {
                appManager.defaultsManager.isAppFirstRun = isAppFirstRun
            }
        }

        override init(appManager: AppManagerProtocol = AppManager.shared) {
            self.isAppFirstRun = appManager.defaultsManager.isAppFirstRun
            super.init(appManager: appManager)
        }
    }
}

// MARK: - Preview -
#Preview {
    EnableExtensionView(
        model: EnableExtensionView.ViewModel(appManager: AppManager.previews)
    )
}
