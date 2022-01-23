//
//  EnableExtensionView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/12/2021.
//

import SwiftUI

struct EnableExtensionView: View {
    
    @Environment(\.dismiss)
    var dismiss
    
    @State var appManager: AppManagerProtocol = AppManager.shared
    @State var isFromMenu: Bool
    @State private var tabSelection = 1
    
    var body: some View {
        NavigationView {
            TabView (selection: $tabSelection) {
                let shouldShowWelcomePages = !self.isFromMenu && self.appManager.defaultsManager.isAppFirstRun
                let welcomeIndex = shouldShowWelcomePages ? 1 : 0
                
                if shouldShowWelcomePages {
                    let welcomePageModel = TwoButtonPageViewModel(
                        title: "enableExtension_welcome"~,
                        text: "enableExtension_welcome_desc"~,
                        confirmText: "enableExtension_welcome_callToAction"~,
                        cancelText: "enableExtension_welcome_cancel"~,
                        onConfirm: {
                            tabSelection = 2
                        },
                        onCancel: {
                            self.appManager.defaultsManager.isAppFirstRun = false
                            dismiss()
                        })
                    
                    TwoButtonPageView(model: welcomePageModel)
                        .tag(1)
                }
                
                ForEach(1...3, id: \.self) { index in
                    let model = ScreenshotPageViewModel(
                        title: "enableExtension_step\(index)"~,
                        text: "enableExtension_step\(index)_desc"~,
                        image: "enableExtension_screenshot\(index)",
                        confirmText: "enableExtension_next"~,
                        onConfirm: {
                            tabSelection = tabSelection + 1
                        })
                    
                    ScreenshotPageView(model: model)
                        .tag(welcomeIndex + index)
                }
                
                let readyPageModel = TwoButtonPageViewModel(
                    title: "enableExtension_welcome"~,
                    text: String(format: "enableExtension_ready_desc"~, "enableExtension_ready_callToAction"~, "enableExtension_ready_cancel"~),
                    confirmText: "enableExtension_ready_callToAction"~,
                    cancelText: "enableExtension_ready_cancel"~,
                    onConfirm: {
                        self.appManager.defaultsManager.isAppFirstRun = false
                        dismiss()
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    },
                    onCancel: {
                        self.appManager.defaultsManager.isAppFirstRun = false
                        dismiss()
                    },
                    image: "enableExtension_screenshot4")
                
                TwoButtonPageView(model: readyPageModel)
                    .tag(welcomeIndex + 4)
            } // TabView
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
            }
        } // NavigationView
    }
}

struct EnableExtensionView_Previews: PreviewProvider {
    static var previews: some View {
        EnableExtensionView(isFromMenu: false)
    }
}
