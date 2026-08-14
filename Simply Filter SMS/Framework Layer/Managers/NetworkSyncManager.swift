//
//  SyncMonitor.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 09/02/2022.
//

import Foundation
import Combine
import CoreData
import Network
import OSLog


class NetworkSyncManager: NetworkSyncManagerProtocol {
    var networkStatus: NetworkStatus = .unknown
    var syncStatus: SyncStatus = .unknown
    
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager) {
        let kNone = self.kNone
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "MonitorNetwork")
        
        self.persistanceManager = persistanceManager
        self.preSyncFingerprint = persistanceManager.fingerprint
        self.networkMonitor = monitor

        monitor.pathUpdateHandler = self.onNetworkChange
        networkMonitor.start(queue: queue)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, !self.firstStatusHandlers.isEmpty else { return }
            AppManager.logger.debug("NetworkSyncManager — timeout reached, draining \(self.firstStatusHandlers.count, privacy: .public) firstStatusHandlers")
            let handlers = self.firstStatusHandlers
            self.firstStatusHandlers = []
            handlers.forEach { $0() }
        }

        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] notification in
                guard let self else { return }
                guard let cloudEvent = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                        as? NSPersistentCloudKitContainer.Event else { return }

                switch cloudEvent.type {
                case .setup:
                    guard cloudEvent.endDate != nil else { return }
                    if cloudEvent.succeeded {
                        self.syncStatus = .active
                        self.setupRetryCount = 0
                        self.pendingSetupRetry = nil
                        AppManager.logger.debug("CloudKit setup event ended — succeeded: true, syncStatus: \(self.syncStatus.name, privacy: .public)")
                    }
                    else {
                        self.syncStatus = .failed
                        let errorDescription = cloudEvent.error?.localizedDescription ?? "nil"
                        AppManager.logger.debug("CloudKit setup event ended — succeeded: false, syncStatus: \(self.syncStatus.name, privacy: .public), error: \(errorDescription, privacy: .public)")
                        self.scheduleSetupRetryIfNeeded()
                    }
                case .import:
                    if cloudEvent.endDate == nil {
                        self.preSyncFingerprint = self.persistanceManager?.fingerprint ?? kNone
                        AppManager.logger.debug("CloudKit import started — fingerprint: \(self.preSyncFingerprint, privacy: .public)")
                    }
                    else if !cloudEvent.succeeded {
                        let errorDescription = cloudEvent.error?.localizedDescription ?? "nil"
                        AppManager.logger.debug("CloudKit import complete — failed, error: \(errorDescription, privacy: .public)")
                    }
                    else {
                        let currentFingerprint = self.persistanceManager?.fingerprint ?? kNone
                        if self.preSyncFingerprint != currentFingerprint {
                            AppManager.logger.debug("CloudKit import complete — data changed, posting cloudSyncOperationComplete")
                            NotificationCenter.default.post(name: .cloudSyncOperationComplete, object: nil)
                        }
                        else {
                            AppManager.logger.debug("CloudKit import complete — no data change detected")
                        }
                    }
                case .export:
                    AppManager.logger.debug("CloudKit export event — succeeded: \(cloudEvent.succeeded, privacy: .public)")
                    break
                @unknown default:
                    break
                }
            })
            .store(in: &disposables)
    }
    
    private let kNone = "none"
    private weak var persistanceManager: PersistanceManagerProtocol?
    private var networkMonitor: NWPathMonitor
    private var preSyncFingerprint: String
    private var disposables = Set<AnyCancellable>()
    private var firstStatusHandlers: [() -> Void] = []
    private var setupRetryCount = 0
    private let maxSetupRetries = 2
    private var pendingSetupRetry: DispatchWorkItem? {
        didSet { oldValue?.cancel() }
    }

    func onFirstStatusKnown(_ handler: @escaping () -> Void) {
        if networkStatus != .unknown {
            handler()
        }
        else {
            firstStatusHandlers.append(handler)
        }
    }

    private func scheduleSetupRetryIfNeeded() {
        guard self.setupRetryCount < self.maxSetupRetries else {
            AppManager.logger.debug("CloudKit setup retry — exhausted (\(self.maxSetupRetries, privacy: .public) attempts)")
            return
        }
        self.setupRetryCount += 1
        let attempt = self.setupRetryCount
        AppManager.logger.debug("CloudKit setup retry — scheduling attempt \(attempt, privacy: .public) in \(attempt * 5, privacy: .public)s")
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingSetupRetry = nil
            guard self.syncStatus == .failed, self.networkStatus != .offline else { return }
            AppManager.logger.debug("CloudKit setup retry — reloading container (attempt \(attempt, privacy: .public))")
            self.persistanceManager?.reloadContainer()
        }
        self.pendingSetupRetry = work
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(attempt * 5), execute: work)
    }

    private func onNetworkChange(_ newPath: NWPath) {
        let newStatus = newPath.status.networkStatus
        DispatchQueue.main.async {
            guard self.networkStatus != newStatus else { return }
            AppManager.logger.debug("Network status changed — \(self.networkStatus.name, privacy: .public) → \(newStatus.name, privacy: .public)")
            if newStatus == .online && self.syncStatus == .failed {
                AppManager.logger.debug("Network back online with failed sync — reloading CloudKit container")
                self.pendingSetupRetry = nil
                self.persistanceManager?.reloadContainer()
            }
            self.networkStatus = newStatus
            NotificationCenter.default.post(name: .networkStatusChange, object: newStatus)
            let handlers = self.firstStatusHandlers
            self.firstStatusHandlers = []
            handlers.forEach { $0() }
        }
    }
}
