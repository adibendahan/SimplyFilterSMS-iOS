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
    
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager) {
        let kNone = self.kNone
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "MonitorNetwork")
        
        self.persistanceManager = persistanceManager
        self.preSyncFingerprint = persistanceManager.fingerprint
        self.networkMonitor = monitor
        
        monitor.pathUpdateHandler = self.onNetworkChange
        networkMonitor.start(queue: queue)
        
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .sink(receiveValue: { notification in
                guard let cloudEvent = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                        as? NSPersistentCloudKitContainer.Event else { return }

                switch cloudEvent.type {
                case .setup:
                    if cloudEvent.endDate != nil {
                        self.syncStatus = cloudEvent.succeeded ? .active : .failed
                    }

                case .import:
                    if cloudEvent.endDate == nil {
                        self.preSyncFingerprint = self.persistanceManager?.fingerprint ?? kNone
                    }
                    else if cloudEvent.succeeded &&
                                self.preSyncFingerprint != kNone &&
                                self.preSyncFingerprint != self.persistanceManager?.fingerprint ?? self.preSyncFingerprint {
                        
                        NotificationCenter.default.post(name: .cloudSyncOperationComplete, object: nil)
                    }
                    
                case .export:
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
    
    private func onNetworkChange(_ newPath: NWPath) {
        if self.networkStatus != newPath.status.networkStatus {
            
            let newStatus = newPath.status.networkStatus
            
            if newStatus == .online && self.syncStatus == .failed {
                self.persistanceManager?.reloadContainer()
            }
            
            self.networkStatus = newStatus
            NotificationCenter.default.post(name: .networkStatusChange, object: newPath.status.networkStatus)
        }
    }
}
