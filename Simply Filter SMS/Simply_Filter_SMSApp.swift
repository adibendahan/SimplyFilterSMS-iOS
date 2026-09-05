//
//  Simply_Filter_SMSApp.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI

@main
struct Simply_Filter_SMSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var homeModel = AppHomeView.ViewModel(appManager: AppManager.shared)

    @StateObject private var saveState = RulesSaveState.shared

    init() {
        UIScrollView.appearance().delaysContentTouches = false
    }

    var body: some Scene {
        WindowGroup {
            AppHomeView(model: homeModel)
                .adaptiveLayoutEnvironment()
                .alert(saveState.titleKey~, isPresented: $saveState.failed) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(saveState.messageKey~)
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var didRegisterForRemoteNotifications = false
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        if !self.didRegisterForRemoteNotifications {
            application.registerForRemoteNotifications()
            self.didRegisterForRemoteNotifications = true
        }
        
        AppManager.shared.onAppLaunch()
        return true
    }
}
