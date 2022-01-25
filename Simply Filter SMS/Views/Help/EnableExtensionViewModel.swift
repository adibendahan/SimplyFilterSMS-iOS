//
//  EnableExtensionViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 25/01/2022.
//

import Foundation

class EnableExtensionViewModel: ObservableObject {
    @Published var welcomePage: TwoButtonPageViewModel? = nil
    @Published var screenshotPages: [ScreenshotPageViewModel]
    @Published var readyPage: TwoButtonPageViewModel
    
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
            self.welcomePage = TwoButtonPageViewModel(
                title: "enableExtension_welcome"~,
                text: "enableExtension_welcome_desc"~,
                confirmText: "enableExtension_welcome_callToAction"~,
                confirmAction: .nextPage,
                cancelText: "enableExtension_welcome_cancel"~,
                cancelAction: .dismiss)
        }
        
        // screenshotPages:
        var pages: [ScreenshotPageViewModel] = []
        for index in 1...3 {
            let model = ScreenshotPageViewModel(
                title: "enableExtension_step\(index)"~,
                text: "enableExtension_step\(index)_desc"~,
                image: "enableExtension_screenshot\(index)",
                confirmText: "enableExtension_next"~,
                confirmAction: .nextPage)
            
            pages.append(model)
        }
        
        self.screenshotPages = pages
        
        // readyPage:
        self.readyPage = TwoButtonPageViewModel(
            title: "enableExtension_ready"~,
            text: String(format: "enableExtension_ready_desc"~, "enableExtension_ready_callToAction"~, "enableExtension_ready_cancel"~),
            confirmText: "enableExtension_ready_callToAction"~,
            confirmAction: .openSettings,
            cancelText: "enableExtension_ready_cancel"~,
            cancelAction: .dismiss,
            image: "enableExtension_screenshot4")
    }
}
