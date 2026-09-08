//
//  Simply_Filter_SMSApp.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI
import BackgroundTasks

@main
struct Simply_Filter_SMSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var homeModel = AppHomeView.ViewModel(appManager: AppManager.shared)

    @Environment(\.scenePhase)
    private var scenePhase

    init() {
        UIScrollView.appearance().delaysContentTouches = false
    }

    var body: some Scene {
        WindowGroup {
            AppHomeView(model: homeModel)
                .adaptiveLayoutEnvironment()
        }
        .onChange(of: scenePhase) { phase in
            // Coming to the front is the only thing that counts as opening the app, so it is the
            // only thing that pushes the reminder out another month. iOS also runs
            // didFinishLaunching for background task wakes, which must not move that clock.
            guard phase == .active else { return }
            AppManager.shared.schedulingManager.refreshInactivityReminder()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var didRegisterForRemoteNotifications = false
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // iOS only accepts background task handlers registered before launch returns.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: kAutomaticFiltersProcessingTaskIdentifier,
                                        using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            AppManager.shared.schedulingManager.handleAutomaticFiltersProcessing(task: processingTask)
        }

        if !self.didRegisterForRemoteNotifications {
            application.registerForRemoteNotifications()
            self.didRegisterForRemoteNotifications = true
        }
        
        AppManager.shared.onAppLaunch()
        return true
    }
}
