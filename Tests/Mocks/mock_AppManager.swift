//
//  mock_AppManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 03/02/2022.
//

import Foundation
import XCTest
import OSLog
@testable import Simply_Filter_SMS

class mock_AppManager: AppManagerProtocol {

    static var logger: Logger = Logger(subsystem: "com.grizz.apps.dev.Simply-Filter-SMS", category: "tests")

    var persistanceManager: PersistanceManagerProtocol = mock_PersistanceManager()
    var defaultsManager: DefaultsManagerProtocol = mock_DefaultsManager()
    var automaticFilterManager: AutomaticFilterManagerProtocol = mock_AutomaticFilterManager()
    var messageEvaluationManager: MessageEvaluationManagerProtocol = mock_MessageEvaluationManager()
    var networkSyncManager: NetworkSyncManagerProtocol = mock_NetworkSyncManager()
    var amazonS3Service: AmazonS3ServiceProtocol = mock_AmazonS3Service()
    var reportMessageService: ReportMessageServiceProtocol = mock_ReportMessageService()
    var tipJarManager: TipJarManagerProtocol = mock_TipJarManager()
    var filterTransferManager: FilterTransferManagerProtocol = mock_FilterTransferManager()
    var flowManager: FlowManagerProtocol = mock_FlowManager()
    var userNotificationScheduling: UserNotificationSchedulingProtocol = mock_UserNotificationScheduling()
    var debugDataManager: DebugDataManagerProtocol = mock_DebugDataManager()

    var onAppLaunchCounter = 0
    var onNewUserSessionCounter = 0
    var scheduleAutomaticFiltersProcessingCounter = 0
    var syncInactivityReminderCounter = 0
    var cancelInactivityReminderCounter = 0
    var requestNotificationAuthorizationFromExplainerCounter = 0

    var onAppLaunchClosuer: (() -> ())?
    var onNewUserSessionClosuer: (() -> ())?
    var requestNotificationAuthorizationFromExplainerGranted = false

    func onAppLaunch() {
        self.onAppLaunchCounter += 1
        self.onAppLaunchClosuer?()
    }
    
    func onNewUserSession() {
        self.onNewUserSessionCounter += 1
        self.onNewUserSessionClosuer?()
    }

    func scheduleAutomaticFiltersProcessing() {
        self.scheduleAutomaticFiltersProcessingCounter += 1
    }

    func syncInactivityReminder() {
        self.syncInactivityReminderCounter += 1
    }

    func cancelInactivityReminder() {
        self.cancelInactivityReminderCounter += 1
    }

    func requestNotificationAuthorizationFromExplainer(completion: @escaping (Bool) -> Void) {
        self.requestNotificationAuthorizationFromExplainerCounter += 1
        completion(self.requestNotificationAuthorizationFromExplainerGranted)
    }
    
    func resetCounters() {
        self.onAppLaunchCounter = 0
        self.onNewUserSessionCounter = 0
        self.scheduleAutomaticFiltersProcessingCounter = 0
        self.syncInactivityReminderCounter = 0
        self.cancelInactivityReminderCounter = 0
        self.requestNotificationAuthorizationFromExplainerCounter = 0
    }

    func loadDebugData() { }
    func reset() { }
}
