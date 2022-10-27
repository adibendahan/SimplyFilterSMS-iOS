//
//  mock_MessageEvaluationManager.swift
//  Simply Filter SMS Tests
//
//  Created by Adi Ben-Dahan on 02/02/2022.
//

import Foundation
import XCTest
import IdentityLookup
import CoreData
import OSLog
@testable import Simply_Filter_SMS

class mock_MessageEvaluationManager: MessageEvaluationManagerProtocol {

    var evaluateMessageCounter = 0
    var setLoggerCounter = 0
    var fetchChosenSubActionsCounter = 0
    
    var evaluateMessageClosure: ((String, String) -> (MessageEvaluationResult))?
    var setLoggerClosure: ((Logger) -> ())?
    var fetchChosenSubActionsClosure: (() -> ())?
    
    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult {
        self.evaluateMessageCounter += 1
        return self.evaluateMessageClosure?(body, sender) ?? MessageEvaluationResult(action: .none)
    }
    
    func setLogger(_ logger: Logger) {
        self.setLoggerCounter += 1
        self.setLoggerClosure?(logger)
    }
    
    func resetCounters() {
        self.evaluateMessageCounter = 0
        self.setLoggerCounter = 0
    }
    
    @available(iOS 16.0, *)
    func fetchChosenSubActions() -> ILMessageFilterCapabilitiesQueryResponse {
        self.fetchChosenSubActionsCounter += 1
        self.fetchChosenSubActionsClosure?()
        return ILMessageFilterCapabilitiesQueryResponse()
    }
    
    //MARK: Helpers
    private var persistance = MessageEvaluationManager(inMemory: true)
    var context: NSManagedObjectContext
    
    init() {
        self.context = persistance.context
    }
}
