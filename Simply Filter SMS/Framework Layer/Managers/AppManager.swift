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
    
    var persistenceManager: PersistenceManagerProtocol
    var defaultsManager: DefaultsManagerProtocol
    var filterListManager: FilterListManagerProtocol
    var smartFilterManager: SmartFilterManagerProtocol
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
        let persistenceManager = PersistenceManager(inMemory: inMemory)
        let defaultsManager = DefaultsManager()
        let messageEvaluationManager = MessageEvaluationManager(persistenceManager: persistenceManager)
        let networkSyncManager = NetworkSyncManager(persistenceManager: persistenceManager)
        let filterListService = FilterListService(networkSyncManager: networkSyncManager)
        let reportMessageService = ReportMessageService(networkSyncManager: networkSyncManager)
        
        messageEvaluationManager.setLogger(AppManager.logger)
        
        let filterListManager = FilterListManager(persistenceManager: persistenceManager,
                                                  filterListService: filterListService,
                                                  networkSyncManager: networkSyncManager)
        let smartFilterManager = SmartFilterManager(persistenceManager: persistenceManager)
        self.persistenceManager = persistenceManager
        self.defaultsManager = defaultsManager
        self.filterListManager = filterListManager
        self.smartFilterManager = smartFilterManager
        self.messageEvaluationManager = messageEvaluationManager
        self.networkSyncManager = networkSyncManager
        self.filterListService = filterListService
        self.reportMessageService = reportMessageService
        self.tipJarManager = TipJarManager(defaultsManager: defaultsManager)
        self.filterTransferManager = FilterTransferManager(persistenceManager: persistenceManager)
        self.flowManager = FlowManager(defaultsManager: defaultsManager)
        self.schedulingManager = SchedulingManager(filterListManager: filterListManager,
                                                   defaultsManager: defaultsManager)
        self.debugDataManager = DebugDataManager(persistenceManager: persistenceManager,
                                                 defaultsManager: defaultsManager,
                                                 filterListManager: filterListManager,
                                                 smartFilterManager: smartFilterManager)

        #if DEBUG
        if UIApplication.shared.isInTestingMode {
            defaultsManager.reset()
            persistenceManager.resetContainer()
            let testingLanguages = ["en", "he", "ar", "es", "fr", "pt", "de", "ja", "ko", "it"]
            var catalogEntries: [FilterListCatalogEntry] = []
            var cacheSections: [FilterListsCacheSection] = []

            for language in testingLanguages {
                let fileName = "\(language).sfsfilters"
                let catalogEntry = FilterListCatalogEntry(id: "ai-\(language)",
                                                          name: language,
                                                          url: fileName,
                                                          language: language)
                guard let listURL = catalogEntry.resolvedURL else { continue }
                let listPayload = FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                                      version: FilterExportPayload.currentVersion,
                                                      exportedAt: Date(),
                                                      appVersion: appVersion,
                                                      name: language,
                                                      revision: nil,
                                                      filters: [],
                                                      forceClearBeforeImport: nil)
                let cacheSection = FilterListsCacheSection(url: listURL.absoluteString,
                                                           etag: nil,
                                                           payload: listPayload)
                catalogEntries.append(catalogEntry)
                cacheSections.append(cacheSection)
            }

            let catalog = FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                                    version: FilterListCatalogResponse.currentVersion,
                                                    lists: catalogEntries)
            let testingSnapshot = FilterListsSnapshot(catalogETag: nil, catalog: catalog, lists: cacheSections)
            _ = persistenceManager.saveCache(testingSnapshot)
            defaultsManager.inactivityNotificationDeclineCount = kInactivityNotificationMaxAsks
        }
        #endif // DEBUG
    }
    
    @MainActor
    func onAppLaunch() {
        let _ = self.defaultsManager.installDate // make sure it's initialized
        AppManager.logger.debug("onAppLaunch — session #\(self.defaultsManager.sessionCounter, privacy: .public), installDate: \(self.defaultsManager.installDate, privacy: .public)")
        self.schedulingManager.scheduleFilterListsProcessing()
    }

    @MainActor
    func onAppBecameActive() -> Bool {
        if let sessionStartDate = self.defaultsManager.sessionStartDate {
            if sessionStartDate.daysBetween(date: Date()) != 0 {
                AppManager.logger.debug("onAppBecameActive — new day detected, starting new session")
                self.onNewUserSession()
                return true
            }
            else {
                AppManager.logger.debug("onAppBecameActive — same day, skipping new session")
                self.filterListManager.updateFilterListsWhenOnline()
                return false
            }
        }
        else {
            AppManager.logger.debug("onAppBecameActive — sessionStartDate not set, starting new session")
            self.onNewUserSession()
            return true
        }
    }

    @MainActor
    func onNewUserSession() {
        self.defaultsManager.sessionCounter += 1
        self.defaultsManager.sessionStartDate = Date()
        AppManager.logger.debug("onNewUserSession — session #\(self.defaultsManager.sessionCounter, privacy: .public)")
        self.filterListManager.updateFilterListsWhenOnline()
    }
    
    #if DEBUG
    func loadDebugData() {
        debugDataManager.load()
    }

    func reset() {
        self.defaultsManager.reset()
        self.persistenceManager.clearAllUserData()
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
