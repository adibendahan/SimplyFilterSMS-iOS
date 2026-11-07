//
//  AppManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import OSLog

protocol AppManagerProtocol {
    static var logger: Logger { get }
    
    var persistenceManager: PersistenceManagerProtocol { get }
    var defaultsManager: DefaultsManagerProtocol { get set }
    var filterListManager: FilterListManagerProtocol { get }
    var smartFilterManager: SmartFilterManagerProtocol { get }
    var messageEvaluationManager: MessageEvaluationManagerProtocol { get }
    var networkSyncManager: NetworkSyncManagerProtocol { get }
    var filterListService: FilterListServiceProtocol { get }
    var reportMessageService: ReportMessageServiceProtocol { get }
    var tipJarManager: TipJarManagerProtocol { get }
    var filterTransferManager: FilterTransferManagerProtocol { get }
    var flowManager: FlowManagerProtocol { get }
    var schedulingManager: SchedulingManagerProtocol { get }

    @MainActor func onAppLaunch()
    @MainActor func onAppBecameActive() -> Bool
    @MainActor func onNewUserSession()

    #if DEBUG
    var debugDataManager: DebugDataManagerProtocol { get }
    func loadDebugData()
    func reset()
    #endif // DEBUG
}
