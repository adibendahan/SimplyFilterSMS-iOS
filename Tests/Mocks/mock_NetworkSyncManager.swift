//
//  mock_NetworkSyncManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 09/02/2022.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class mock_NetworkSyncManager: NetworkSyncManagerProtocol {
    
    var syncStatusGetCounter = 0
    var syncStatusSetCounter = 0
    var networkStatusGetCounter = 0
    var networkStatusSetCounter = 0
    
    var syncStatusClosure: (() -> (SyncStatus))?
    var networkStatusClosure: (() -> (NetworkStatus))?
    
    var syncStatus: SyncStatus {
        get {
            self.syncStatusGetCounter += 1
            return self.syncStatusClosure?() ?? .unknown
        }
        set {
            self.syncStatusSetCounter += 1
        }
    }
    
    var networkStatus: NetworkStatus {
        get {
            self.networkStatusGetCounter += 1
            return self.networkStatusClosure?() ?? .unknown
        }
        set {
            self.networkStatusSetCounter += 1
        }
    }
}
