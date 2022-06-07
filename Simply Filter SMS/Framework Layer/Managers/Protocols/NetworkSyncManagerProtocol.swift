//
//  NetworkSyncManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 09/02/2022.
//

import Foundation
import CoreData
import Network


protocol NetworkSyncManagerProtocol: AnyObject {
    var syncStatus: SyncStatus { get }
    var networkStatus: NetworkStatus { get }
}


extension NSNotification.Name {
    static let networkStatusChange: NSNotification.Name = NSNotification.Name("NetworkStatusChange")
    static let cloudSyncOperationComplete: NSNotification.Name = NSNotification.Name("CloudSyncOperationComplete")
    static let automaticFiltersUpdated: NSNotification.Name = NSNotification.Name("AutomaticFiltersUpdated")
    static let onClipboardSet: NSNotification.Name = NSNotification.Name("OnClipboardSet")
}


enum NetworkStatus {
    case unknown, online, offline
    
    var name: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        }
    }
}

enum SyncStatus {
    case unknown, active, failed
    
    var name: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .active:
            return "Active"
        case .failed:
            return "Failed"
        }
    }
}

extension NWPath.Status {
    var networkStatus: NetworkStatus {
        switch self {
        case .requiresConnection, .unsatisfied:
            return .offline
        case .satisfied:
            return .online
        @unknown default:
            return .unknown
        }
    }
}

