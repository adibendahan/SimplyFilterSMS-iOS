//
//  mock_AppManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 03/02/2022.
//

import Foundation
import XCTest
import OSLog
@testable import Simply_Filter_SMS

class mock_AppManager: AppManagerProtocol {

    static var logger: Logger = Logger(subsystem: "com.grizz.apps.dev.Simply-Filter-SMS", category: "tests")

    var persistenceManager: PersistenceManagerProtocol = mock_PersistenceManager()
    var defaultsManager: DefaultsManagerProtocol = mock_DefaultsManager()
    var filterListManager: FilterListManagerProtocol = mock_FilterListManager()
    var smartFilterManager: SmartFilterManagerProtocol = mock_SmartFilterManager()
    var messageEvaluationManager: MessageEvaluationManagerProtocol = mock_MessageEvaluationManager()
    var networkSyncManager: NetworkSyncManagerProtocol = mock_NetworkSyncManager()
    var filterListService: FilterListServiceProtocol = mock_FilterListService()
    var reportMessageService: ReportMessageServiceProtocol = mock_ReportMessageService()
    var tipJarManager: TipJarManagerProtocol = mock_TipJarManager()
    var filterTransferManager: FilterTransferManagerProtocol = mock_FilterTransferManager()
    var flowManager: FlowManagerProtocol = mock_FlowManager()
    var schedulingManager: SchedulingManagerProtocol = mock_SchedulingManager()
    var debugDataManager: DebugDataManagerProtocol = mock_DebugDataManager()

    var onAppLaunchCounter = 0
    var onAppBecameActiveCounter = 0
    var onNewUserSessionCounter = 0

    var onAppLaunchClosure: (() -> ())?
    var onAppBecameActiveClosure: (() -> (Bool))?
    var onNewUserSessionClosure: (() -> ())?

    @MainActor
    func onAppLaunch() {
        self.onAppLaunchCounter += 1
        self.onAppLaunchClosure?()
    }

    @MainActor
    func onAppBecameActive() -> Bool {
        self.onAppBecameActiveCounter += 1
        return self.onAppBecameActiveClosure?() ?? false
    }

    @MainActor
    func onNewUserSession() {
        self.onNewUserSessionCounter += 1
        self.onNewUserSessionClosure?()
    }
    
    func resetCounters() {
        self.onAppLaunchCounter = 0
        self.onAppBecameActiveCounter = 0
        self.onNewUserSessionCounter = 0
    }

    func loadDebugData() { }
    func reset() { }
}
