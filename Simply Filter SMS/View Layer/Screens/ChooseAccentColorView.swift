//
//  ChooseAccentColorView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/08/2026.
//

import SwiftUI
import UIKit


//MARK: - View -
struct ChooseAccentColorView: View {

    @Environment(\.dismiss)
    var dismiss

    @StateObject var model: ViewModel

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                AccentUIColorPicker(
                    color: Binding(
                        get: { model.pickerColor },
                        set: { model.applyPickedColor($0) }
                    )
                )
                .ignoresSafeArea(edges: .bottom)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("accentColor_picker"~)

                Button {
                    model.reset()
                } label: {
                    Text("accentColor_reset"~)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!model.hasCustomColor)
                .accessibilityHint("a11y_accentColor_resetHint"~)
                .padding()
            }
            .navigationTitle("accentColor_title"~)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.primary)
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .optionalTint(model.hasCustomColor ? Color(uiColor: model.pickerColor) : nil)
    }
}


private struct AccentUIColorPicker: UIViewControllerRepresentable {
    @Binding var color: UIColor

    func makeCoordinator() -> Coordinator {
        Coordinator(color: $color)
    }

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.selectedColor = color
        picker.delegate = context.coordinator
        picker.view.backgroundColor = .clear
        return picker
    }

    func updateUIViewController(_ uiViewController: UIColorPickerViewController, context: Context) {
        context.coordinator.color = $color
        var desiredRed: CGFloat = 0, desiredGreen: CGFloat = 0, desiredBlue: CGFloat = 0, desiredAlpha: CGFloat = 0
        var currentRed: CGFloat = 0, currentGreen: CGFloat = 0, currentBlue: CGFloat = 0, currentAlpha: CGFloat = 0
        guard color.getRed(&desiredRed, green: &desiredGreen, blue: &desiredBlue, alpha: &desiredAlpha),
              uiViewController.selectedColor.getRed(&currentRed, green: &currentGreen, blue: &currentBlue, alpha: &currentAlpha) else {
            return
        }
        let delta = max(
            abs(desiredRed - currentRed),
            abs(desiredGreen - currentGreen),
            abs(desiredBlue - currentBlue)
        )
        if delta > 0.02 {
            uiViewController.selectedColor = color
        }
    }

    class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var color: Binding<UIColor>

        init(color: Binding<UIColor>) {
            self.color = color
        }

        func colorPickerViewController(_ viewController: UIColorPickerViewController,
                                       didSelect color: UIColor,
                                       continuously: Bool) {
            self.color.wrappedValue = color
        }
    }
}


//MARK: - View Model -
extension ChooseAccentColorView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var pickerColor: UIColor
        @Published var hasCustomColor: Bool

        private var defaultsManager: DefaultsManagerProtocol
        private var onAccentChanged: ((Color?) -> Void)?

        init(appManager: AppManagerProtocol = AppManager.shared,
             defaultsManager: DefaultsManagerProtocol? = nil,
             onAccentChanged: ((Color?) -> Void)? = nil) {
            let defaults = defaultsManager ?? appManager.defaultsManager
            self.defaultsManager = defaults
            self.onAccentChanged = onAccentChanged

            if let color = Color(accentRGB: defaults.accentColorRGB) {
                if #available(iOS 17.0, *) {
                    self.pickerColor = UIColor(color)
                } else {
                    let rgb = defaults.accentColorRGB
                    self.pickerColor = UIColor(red: rgb["red"] ?? 0, green: rgb["green"] ?? 0, blue: rgb["blue"] ?? 0, alpha: 1)
                }
                self.hasCustomColor = true
            } else {
                self.pickerColor = .systemBlue
                self.hasCustomColor = false
            }
            super.init(appManager: appManager)
        }

        func applyPickedColor(_ color: UIColor) {
            self.pickerColor = color
            self.hasCustomColor = true
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                self.defaultsManager.accentColorRGB = ["red": Double(red), "green": Double(green), "blue": Double(blue)]
            }
            self.onAccentChanged?(Color(uiColor: color))
        }

        func reset() {
            self.pickerColor = .systemBlue
            self.hasCustomColor = false
            self.defaultsManager.accentColorRGB = kNoColorDict
            self.onAccentChanged?(nil)
        }
    }
}


//MARK: - Preview -
#Preview {
    ChooseAccentColorView(model: ChooseAccentColorView.ViewModel(appManager: AppManager.previews))
}
