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

class AppManager: AppManagerProtocol {
    static let shared: AppManagerProtocol = AppManager()
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
    var schedulingManager: SchedulingManagerProtocol
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
        self.schedulingManager = SchedulingManager(automaticFilterManager: automaticFilterManager,
                                                   defaultsManager: defaultsManager)
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
        self.schedulingManager.scheduleAutomaticFiltersProcessing()
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
        self.schedulingManager.cancelInactivityReminder()
    }
    #endif // DEBUG

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
