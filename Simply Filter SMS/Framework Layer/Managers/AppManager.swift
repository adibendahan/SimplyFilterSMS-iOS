//
//  AppManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import NaturalLanguage
import Network
import OSLog
import UIKit
import BackgroundTasks
import UserNotifications

class AppManager: AppManagerProtocol {
    static let shared = AppManager()
    static let logger: Logger = Logger(subsystem: "com.grizz.apps.dev.Simply-Filter-SMS", category: "main")
    
    var persistanceManager: PersistanceManagerProtocol
    var defaultsManager: DefaultsManagerProtocol
    var automaticFilterManager: AutomaticFilterManagerProtocol
    var messageEvaluationManager: MessageEvaluationManagerProtocol
    var networkSyncManager: NetworkSyncManagerProtocol
    var amazonS3Service: AmazonS3ServiceProtocol
    var reportMessageService: ReportMessageServiceProtocol
    var tipJarManager: TipJarManagerProtocol
    var filterTransferManager: FilterTransferManagerProtocol
    var flowManager: FlowManagerProtocol
    var userNotificationScheduling: UserNotificationSchedulingProtocol
    var debugDataManager: DebugDataManagerProtocol

    init(inMemory: Bool = false) {
        let persistanceManager = PersistanceManager(inMemory: inMemory)
        let defaultsManager = DefaultsManager()
        let messageEvaluationManager = MessageEvaluationManager(persistanceManager: persistanceManager)
        let networkSyncManager = NetworkSyncManager(persistanceManager: persistanceManager)
        let amazonS3Service = AmazonS3Service(networkSyncManager: networkSyncManager)
        let reportMessageService = ReportMessageService(networkSyncManager: networkSyncManager)
        
        messageEvaluationManager.setLogger(AppManager.logger)
        
        let automaticFilterManager = AutomaticFilterManager(persistanceManager: persistanceManager,
                                                             amazonS3Service: amazonS3Service)
        self.persistanceManager = persistanceManager
        self.defaultsManager = defaultsManager
        self.automaticFilterManager = automaticFilterManager
        self.messageEvaluationManager = messageEvaluationManager
        self.networkSyncManager = networkSyncManager
        self.amazonS3Service = amazonS3Service
        self.reportMessageService = reportMessageService
        self.tipJarManager = TipJarManager(defaultsManager: defaultsManager)
        self.filterTransferManager = FilterTransferManager(persistanceManager: persistanceManager)
        self.flowManager = FlowManager(defaultsManager: defaultsManager)
        self.userNotificationScheduling = UserNotificationCenterScheduler()
        self.debugDataManager = DebugDataManager(persistanceManager: persistanceManager,
                                                 defaultsManager: defaultsManager,
                                                 automaticFilterManager: automaticFilterManager)

        #if DEBUG
        if UIApplication.shared.isInTestingMode {
            defaultsManager.reset()
            persistanceManager.resetContainer()
            let emptyList = LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: [])
            let seedCache = AutomaticFilterListsResponse(filterLists: [
                "en": emptyList, "he": emptyList, "ar": emptyList,
                "es": emptyList, "fr": emptyList, "pt": emptyList,
                "de": emptyList, "ja": emptyList, "ko": emptyList, "it": emptyList
            ])
            persistanceManager.saveCache(with: seedCache)
        }
        #endif // DEBUG
    }
    
    func onAppLaunch() {
        let _ = self.defaultsManager.appAge // make sure it's initialized
        AppManager.logger.debug("onAppLaunch — session #\(self.defaultsManager.sessionCounter, privacy: .public), installDate: \(self.defaultsManager.appAge, privacy: .public)")
        self.scheduleAutomaticFiltersProcessing()
        if let sessionAge = self.defaultsManager.sessionAge {
            if sessionAge.daysBetween(date: Date()) != 0 {
                AppManager.logger.debug("onAppLaunch — new day detected, starting new session")
                self.onNewUserSession()
            }
            else {
                AppManager.logger.debug("onAppLaunch — same day, skipping new session")
            }
        }
        else {
            AppManager.logger.debug("onAppLaunch — sessionAge not set, starting new session")
            self.onNewUserSession()
        }
    }

    func onNewUserSession() {
        self.defaultsManager.sessionCounter += 1
        self.defaultsManager.sessionAge = Date()
        AppManager.logger.debug("onNewUserSession — session #\(self.defaultsManager.sessionCounter, privacy: .public), waiting for network status")
        self.networkSyncManager.onFirstStatusKnown { [weak self] in
            guard let self else { return }
            AppManager.logger.debug("onNewUserSession — network: \(self.networkSyncManager.networkStatus.name, privacy: .public)")
            if self.networkSyncManager.networkStatus == .online {
                AppManager.logger.debug("onNewUserSession — online, triggering automatic filter update check")
                Task {
                    await self.automaticFilterManager.updateAutomaticFiltersIfNeeded()
                }
            }
            else {
                AppManager.logger.debug("onNewUserSession — offline, skipping automatic filter update")
            }
        }
    }

    func scheduleAutomaticFiltersProcessing() {
        let request = BGProcessingTaskRequest(identifier: kAutomaticFiltersProcessingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Self.nextAutomaticFiltersProcessingDate()
        do {
            try BGTaskScheduler.shared.submit(request)
            AppManager.logger.debug("scheduleAutomaticFiltersProcessing — submitted for \(request.earliestBeginDate?.description ?? "nil", privacy: .public)")
        } catch {
            AppManager.logger.error("scheduleAutomaticFiltersProcessing — failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func handleAutomaticFiltersProcessing(task: BGProcessingTask) {
        AppManager.logger.debug("handleAutomaticFiltersProcessing — started")
        let work = Task {
            await self.automaticFilterManager.updateAutomaticFiltersIfNeeded()
        }
        task.expirationHandler = {
            work.cancel()
        }
        Task {
            let success: Bool
            switch await work.result {
            case .success:
                success = true
            case .failure:
                success = false
            }
            task.setTaskCompleted(success: success)
            self.scheduleAutomaticFiltersProcessing()
        }
    }

    func syncInactivityReminder() {
        self.cancelInactivityReminder()
        guard self.automaticFilterManager.isAutomaticFilteringOn else { return }
        self.userNotificationScheduling.authorizationStatus { [weak self] status in
            guard let self else { return }
            guard self.automaticFilterManager.isAutomaticFilteringOn, status.allowsAlerts else { return }
            self.scheduleInactivityReminder()
        }
    }

    func cancelInactivityReminder() {
        self.userNotificationScheduling.removePendingNotificationRequests(
            withIdentifiers: [kAutomaticFiltersInactivityNotificationId])
    }

    func requestNotificationAuthorizationFromExplainer(completion: @escaping (Bool) -> Void) {
        self.userNotificationScheduling.requestAlertAuthorization { [weak self] granted in
            if granted {
                self?.syncInactivityReminder()
            }
            completion(granted)
        }
    }

    #if DEBUG
    func loadDebugData() {
        debugDataManager.load()
    }

    func reset() {
        self.defaultsManager.reset()
        self.persistanceManager.clearAllUserData()
        _ = self.filterTransferManager.clearPendingImport()
        self.filterTransferManager.clearPendingExport()
        self.flowManager.resetSession()
        self.cancelInactivityReminder()
    }
    #endif // DEBUG

    //MARK: - Private -
    private func scheduleInactivityReminder() {
        let content = UNMutableNotificationContent()
        content.title = "autoFilter_inactivityNotification_title"~
        content.body = "autoFilter_inactivityNotification_body"~
        guard let trigger = self.monthlyRepeatingTrigger() else { return }
        let request = UNNotificationRequest(identifier: kAutomaticFiltersInactivityNotificationId,
                                            content: content,
                                            trigger: trigger)
        self.userNotificationScheduling.add(request) { error in
            if let error {
                AppManager.logger.error("scheduleInactivityReminder — failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func monthlyRepeatingTrigger() -> UNCalendarNotificationTrigger? {
        guard let fireDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) else { return nil }
        var components = Calendar.current.dateComponents([.day], from: fireDate)
        components.hour = 19
        components.minute = 0
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }

    //MARK: - Previews -
    static private var inMemoryManager = AppManager(inMemory: true)
    static private var didLoadDebugData = false
    static var previews: AppManagerProtocol {
        #if DEBUG
        if !didLoadDebugData {
            inMemoryManager.loadDebugData()
            didLoadDebugData = true
        }
        #endif // DEBUG
        return inMemoryManager
    }
}
