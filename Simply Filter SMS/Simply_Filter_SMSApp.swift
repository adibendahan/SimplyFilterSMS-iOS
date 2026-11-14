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
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UIScrollView.appearance().delaysContentTouches = false
    }

    var body: some Scene {
        WindowGroup {
            AppHomeView(model: homeModel)
                .adaptiveLayoutEnvironment()
                .inAppBrowser()
                .onChange(of: scenePhase) { oldPhase, phase in
                    Log.debug("scene phase changed, phase: \(oldPhase.logName) → \(phase.logName)")
                    guard phase == .active else { return }
                    homeModel.appBecameActive()
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var didRegisterForRemoteNotifications = false
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        BGTaskScheduler.shared.register(forTaskWithIdentifier: kFilterListsProcessingTaskIdentifier,
                                        using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                Log.fault("unexpected background task type, identifier: \(task.identifier)")
                task.setTaskCompleted(success: false)
                return
            }
            AppManager.shared.schedulingManager.handleFilterListsProcessing(task: processingTask)
        }

        if !self.didRegisterForRemoteNotifications {
            application.registerForRemoteNotifications()
            self.didRegisterForRemoteNotifications = true
        }
        
        AppManager.shared.onAppLaunch()
        return true
    }
}


private extension ScenePhase {
    var logName: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
}
