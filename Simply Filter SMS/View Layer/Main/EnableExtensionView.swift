//
//  EnableExtensionView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/12/2021.
//

import SwiftUI


//MARK: - View -
struct EnableExtensionView: View {
    
    @Environment(\.dismiss)
    var dismiss
    
    @StateObject var model: Model
    @State var coordinator: PageCoordinator?
    @State var appManager: AppManagerProtocol = AppManager.shared
    @State private var tabSelection = 0
    
    var body: some View {
        NavigationView {
            TabView (selection: $tabSelection) {
                if let welcomeModel = self.model.welcomePage {
                    TwoButtonPageView(model: welcomeModel, coordinator: self.coordinator)
                        .tag(0)
                }
                
                ForEach(self.model.screenshotPages.indices) { index in
                    if let screenshotModel = self.model.screenshotPages[index] {
                        ScreenshotPageView(model: screenshotModel, coordinator: self.coordinator)
                            .tag(self.model.welcomeTagOffset + index)
                    }
                }
                
                TwoButtonPageView(model: self.model.readyPage, coordinator: self.coordinator)
                    .tag(self.model.welcomeTagOffset + self.model.screenshotPages.count)

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
        .onAppear {
            self.coordinator = PageCoordinator(presenter: self)
        }
    }

    private func nextTab() {
        withAnimation {
            tabSelection = tabSelection + 1
        }
    }
    
    private func dismissView() {
        withAnimation {
            self.model.isAppFirstRun = false
            dismiss()
        }
    }
    
    private func openSettings() {
        withAnimation {
            self.model.isAppFirstRun = false
            dismiss()
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
}


//MARK: - Page Coordinator -
extension EnableExtensionView {
    
    class PageCoordinator {
        enum Action {
            case nextPage, dismiss, openSettings
        }
        
        private var presenter: EnableExtensionView
        
        init(presenter: EnableExtensionView) {
            self.presenter = presenter
        }
        
        func onPerform(action: Action) {
            switch action {
            case .nextPage:
                self.presenter.nextTab()
            case .dismiss:
                self.presenter.dismissView()
            case .openSettings:
                self.presenter.openSettings()
            }
        }
    }
}


//MARK: - Model -
extension EnableExtensionView {
    
    class Model: ObservableObject {
        @Published var welcomePage: TwoButtonPageView.Model? = nil
        @Published var screenshotPages: [ScreenshotPageView.Model]
        @Published var readyPage: TwoButtonPageView.Model
        
        var isAppFirstRun: Bool {
            get {
                self.defaultsManager.isAppFirstRun
            }
            set {
                self.defaultsManager.isAppFirstRun = newValue
            }
        }
        
        var welcomeTagOffset: Int {
            return self.welcomePage == nil ? 0 : 1
        }
        
        private var defaultsManager: DefaultsManagerProtocol
        
        init(showWelcome: Bool,
             defaultsManager: DefaultsManagerProtocol = AppManager.shared.defaultsManager) {
            
            self.defaultsManager = defaultsManager
            
            // welcomePage:
            if showWelcome {
                self.welcomePage = TwoButtonPageView.Model(
                    title: "enableExtension_welcome"~,
                    text: "enableExtension_welcome_desc"~,
                    confirmText: "enableExtension_welcome_callToAction"~,
                    confirmAction: .nextPage,
                    cancelText: "enableExtension_welcome_cancel"~,
                    cancelAction: .dismiss)
            }
            
            // screenshotPages:
            var pages: [ScreenshotPageView.Model] = []
            for index in 1...3 {
                let model = ScreenshotPageView.Model(
                    title: "enableExtension_step\(index)"~,
                    text: "enableExtension_step\(index)_desc"~,
                    image: "enableExtension_screenshot\(index)",
                    confirmText: "enableExtension_next"~,
                    confirmAction: .nextPage)
                
                pages.append(model)
            }
            
            self.screenshotPages = pages
            
            // readyPage:
            self.readyPage = TwoButtonPageView.Model(
                title: "enableExtension_ready"~,
                text: String(format: "enableExtension_ready_desc"~, "enableExtension_ready_callToAction"~, "enableExtension_ready_cancel"~),
                confirmText: "enableExtension_ready_callToAction"~,
                confirmAction: .openSettings,
                cancelText: "enableExtension_ready_cancel"~,
                cancelAction: .dismiss,
                image: "enableExtension_screenshot4")
        }
    }
}


//MARK: - Preview -
struct EnableExtensionView_Previews: PreviewProvider {
    static var previews: some View {
        let model = EnableExtensionView.Model(showWelcome: false)
        EnableExtensionView(model: model)
    }
}
