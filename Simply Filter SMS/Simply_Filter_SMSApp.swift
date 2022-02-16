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
    
    var body: some Scene {
        WindowGroup {
            AppHomeView(model: AppHomeView.ViewModel(appManager: AppManager.shared))
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var didRegisterForRemoteNotifications = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if !self.didRegisterForRemoteNotifications {
            application.registerForRemoteNotifications()
            self.didRegisterForRemoteNotifications = true
        }
        
        var defaultsManager = AppManager.shared.defaultsManager
        let _ = defaultsManager.appAge // make sure it's initialized
        
        if let sessionAge = defaultsManager.sessionAge {
            if sessionAge.daysBetween(date: Date()) != 0 {
                defaultsManager.sessionCounter += 1
                defaultsManager.sessionAge = Date()
            }
        }
        else {
            defaultsManager.sessionCounter += 1
            defaultsManager.sessionAge = Date()
        }

        return true
    }
}
