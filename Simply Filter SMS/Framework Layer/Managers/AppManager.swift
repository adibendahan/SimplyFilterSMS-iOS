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
    var filterListService: FilterListServiceProtocol
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
        let filterListService = FilterListService(networkSyncManager: networkSyncManager)
        let reportMessageService = ReportMessageService(networkSyncManager: networkSyncManager)
        
        messageEvaluationManager.setLogger(AppManager.logger)
        
        let automaticFilterManager = AutomaticFilterManager(persistanceManager: persistanceManager,
                                                             filterListService: filterListService)
        self.persistanceManager = persistanceManager
        self.defaultsManager = defaultsManager
        self.automaticFilterManager = automaticFilterManager
        self.messageEvaluationManager = messageEvaluationManager
        self.networkSyncManager = networkSyncManager
        self.filterListService = filterListService
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
            let languages = ["en", "he", "ar", "es", "fr", "pt", "de", "ja", "ko", "it"]
            var entries: [FilterListCatalogEntry] = []
            var lists: [FilterListsCacheSection] = []

            for language in languages {
                let fileName = "\(language).sfsfilters"
                let entry = FilterListCatalogEntry(id: "ai-\(language)",
                                                   name: language,
                                                   url: fileName,
                                                   language: language)
                guard let listURL = entry.resolvedURL else { continue }
                let payload = FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                                  version: FilterExportPayload.currentVersion,
                                                  exportedAt: Date(),
                                                  appVersion: appVersion,
                                                  name: language,
                                                  revision: nil,
                                                  filters: [],
                                                  forceClearBeforeImport: nil)
                let section = FilterListsCacheSection(url: listURL.absoluteString,
                                                      etag: nil,
                                                      payload: payload)
                entries.append(entry)
                lists.append(section)
            }

            let catalog = FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                                    version: FilterListCatalogResponse.currentVersion,
                                                    lists: entries)
            let cache = FilterListsCache(catalogETag: nil, catalog: catalog, lists: lists)
            _ = persistanceManager.saveCache(cache)
            defaultsManager.inactivityNotificationDeclineCount = kInactivityNotificationMaxAsks
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
                Task(priority: .background) {
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
        self.schedulingManager.reset()
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
