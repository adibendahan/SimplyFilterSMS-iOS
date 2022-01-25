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
    
    @StateObject var model: EnableExtensionViewModel
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

struct EnableExtensionView_Previews: PreviewProvider {
    static var previews: some View {
        let model = EnableExtensionViewModel(showWelcome: false)
        EnableExtensionView(model: model)
    }
}
