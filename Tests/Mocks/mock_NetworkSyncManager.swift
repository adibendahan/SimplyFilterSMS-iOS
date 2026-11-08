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
    var onFirstStatusKnownCounter = 0
    
    var syncStatusClosure: (() -> (SyncStatus))?
    var networkStatusClosure: (() -> (NetworkStatus))?
    var onFirstStatusKnownClosure: ((@escaping () -> Void) -> ())?
    
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

    func onFirstStatusKnown(_ handler: @escaping () -> Void) {
        self.onFirstStatusKnownCounter += 1
        guard let onFirstStatusKnownClosure = self.onFirstStatusKnownClosure else {
            handler()
            return
        }
        onFirstStatusKnownClosure(handler)
    }

    func resetCounters() {
        self.syncStatusGetCounter = 0
        self.syncStatusSetCounter = 0
        self.networkStatusGetCounter = 0
        self.networkStatusSetCounter = 0
        self.onFirstStatusKnownCounter = 0
    }
}
