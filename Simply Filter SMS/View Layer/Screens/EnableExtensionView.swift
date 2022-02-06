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
    
    @ObservedObject var model: ViewModel
    
    var body: some View {
        NavigationView {
            TabView (selection: $model.tabSelection) {
                if let welcomeModel = self.model.welcomePage {
                    TwoButtonPageView(model: welcomeModel, coordinator: self.model.coordinator)
                        .tag(0)
                }
                
                ForEach(self.model.screenshotPages.indices) { index in
                    if let screenshotModel = self.model.screenshotPages[index] {
                        ScreenshotPageView(model: screenshotModel, coordinator: self.model.coordinator)
                            .tag(self.model.welcomeTagOffset + index)
                    }
                }
                
                TwoButtonPageView(model: self.model.readyPage, coordinator: self.model.coordinator)
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
            self.model.coordinator = PageCoordinator(presenter: self)
        }
    }

    private func nextTab() {
        withAnimation {
            self.model.tabSelection = self.model.tabSelection + 1
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


//MARK: - ViewModel -
extension EnableExtensionView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published var welcomePage: TwoButtonPageView.ViewModel? = nil
        @Published var screenshotPages: [ScreenshotPageView.ViewModel]
        @Published var readyPage: TwoButtonPageView.ViewModel
        @Published var tabSelection = 0
        @Published var coordinator: PageCoordinator?
        
        var isAppFirstRun: Bool {
            get {
                self.appManager.defaultsManager.isAppFirstRun
            }
            set {
                self.appManager.defaultsManager.isAppFirstRun = newValue
            }
        }
        
        var welcomeTagOffset: Int {
            return self.welcomePage == nil ? 0 : 1
        }

        init(showWelcome: Bool,
             appManager: AppManagerProtocol = AppManager.shared) {
            
            // welcomePage:
            if showWelcome {
                self.welcomePage = TwoButtonPageView.ViewModel(
                    title: "enableExtension_welcome"~,
                    text: "enableExtension_welcome_desc"~,
                    confirmText: "enableExtension_welcome_callToAction"~,
                    confirmAction: .nextPage,
                    cancelText: "enableExtension_welcome_cancel"~,
                    cancelAction: .dismiss)
            }
            
            // screenshotPages:
            var pages: [ScreenshotPageView.ViewModel] = []
            for index in 1...3 {
                let model = ScreenshotPageView.ViewModel(
                    title: "enableExtension_step\(index)"~,
                    text: "enableExtension_step\(index)_desc"~,
                    image: "enableExtension_screenshot\(index)",
                    confirmText: "enableExtension_next"~,
                    confirmAction: .nextPage)
                
                pages.append(model)
            }
            
            self.screenshotPages = pages
            
            // readyPage:
            self.readyPage = TwoButtonPageView.ViewModel(
                title: "enableExtension_ready"~,
                text: String(format: "enableExtension_ready_desc"~, "enableExtension_ready_callToAction"~, "enableExtension_ready_cancel"~),
                confirmText: "enableExtension_ready_callToAction"~,
                confirmAction: .openSettings,
                cancelText: "enableExtension_ready_cancel"~,
                cancelAction: .dismiss,
                image: "enableExtension_screenshot4")
            
            super.init(appManager: appManager)
        }
    }
}


//MARK: - Preview -
struct EnableExtensionView_Previews: PreviewProvider {
    static var previews: some View {
        EnableExtensionView(model: EnableExtensionView.ViewModel(showWelcome: false, appManager: AppManager.previews))
    }
}
