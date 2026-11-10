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


class NetworkSyncManager: NetworkSyncManagerProtocol {
    var networkStatus: NetworkStatus = .unknown
    var syncStatus: SyncStatus = .unknown
    
    init(persistenceManager: PersistenceManagerProtocol = AppManager.shared.persistenceManager) {
        let kNone = self.kNone
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "MonitorNetwork")
        
        self.persistenceManager = persistenceManager
        self.preSyncFingerprint = persistenceManager.fingerprint
        self.networkMonitor = monitor

        monitor.pathUpdateHandler = self.onNetworkChange
        networkMonitor.start(queue: queue)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, !self.firstStatusHandlers.isEmpty else { return }
            Log.debug("first network status timed out, handlers: \(self.firstStatusHandlers.count) → drained")
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
                        Log.debug("CloudKit setup succeeded, syncStatus: \(self.syncStatus.name)")
                    }
                    else {
                        self.syncStatus = .failed
                        Log.error("CloudKit setup failed, syncStatus: \(self.syncStatus.name)", error: cloudEvent.error)
                    }
                case .import:
                    if cloudEvent.endDate == nil {
                        self.preSyncFingerprint = self.persistenceManager?.fingerprint ?? kNone
                        Log.debug("CloudKit import started, fingerprintLength: \(self.preSyncFingerprint.count)")
                    }
                    else if !cloudEvent.succeeded {
                        Log.error("CloudKit import failed", error: cloudEvent.error)
                    }
                    else {
                        let currentFingerprint = self.persistenceManager?.fingerprint ?? kNone
                        if self.preSyncFingerprint != currentFingerprint {
                            Log.debug("CloudKit import succeeded, dataChanged: \(true) → posting cloudSyncOperationComplete")
                            NotificationCenter.default.post(name: .cloudSyncOperationComplete, object: nil)
                        }
                        else {
                            Log.debug("CloudKit import succeeded, dataChanged: \(false)")
                        }
                    }
                case .export:
                    guard let endDate = cloudEvent.endDate else { return }
                    let eventID = cloudEvent.identifier
                    let duration = endDate.timeIntervalSince(cloudEvent.startDate)
                    guard cloudEvent.succeeded else {
                        Log.error("CloudKit export failed, id: \(eventID), duration: \(duration: duration)", error: cloudEvent.error)
                        return
                    }
                    Log.debug("CloudKit export succeeded, id: \(eventID), duration: \(duration: duration)")
                @unknown default:
                    Log.debug("unknown CloudKit event, type: \(cloudEvent.type.rawValue) → ignored")
                }
            })
            .store(in: &disposables)
    }
    
    private let kNone = "none"
    private weak var persistenceManager: PersistenceManagerProtocol?
    private var networkMonitor: NWPathMonitor
    private var preSyncFingerprint: String
    private var disposables = Set<AnyCancellable>()
    private var firstStatusHandlers: [() -> Void] = []

    func onFirstStatusKnown(_ handler: @escaping () -> Void) {
        if networkStatus != .unknown {
            handler()
        }
        else {
            firstStatusHandlers.append(handler)
        }
    }

    private func onNetworkChange(_ newPath: NWPath) {
        let newStatus = newPath.status.networkStatus
        DispatchQueue.main.async {
            guard self.networkStatus != newStatus else { return }
            Log.debug("network changed, status: \(self.networkStatus.name) → \(newStatus.name)")
            if newStatus.isReconnection(from: self.networkStatus) {
                if self.syncStatus == .failed {
                    Log.debug("reconnected, syncStatus: \(self.syncStatus.name) → reloading the container")
                    self.persistenceManager?.reloadContainer()
                }
                else {
                    Log.debug("reconnected, syncStatus: \(self.syncStatus.name) → no reload")
                }
            }
            self.networkStatus = newStatus
            NotificationCenter.default.post(name: .networkStatusChange, object: newStatus)
            let handlers = self.firstStatusHandlers
            self.firstStatusHandlers = []
            handlers.forEach { $0() }
        }
    }
}
