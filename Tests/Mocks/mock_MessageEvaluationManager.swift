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
    var setHitCounterServiceCounter = 0

    var evaluateMessageClosure: ((String, String) -> (MessageEvaluationResult))?
    var setLoggerClosure: ((Logger) -> ())?
    var setHitCounterServiceClosure: ((FilterHitCounterServiceProtocol) -> ())?

    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult {
        self.evaluateMessageCounter += 1
        return self.evaluateMessageClosure?(body, sender) ?? MessageEvaluationResult(action: .none)
    }

    func setLogger(_ logger: Logger) {
        self.setLoggerCounter += 1
        self.setLoggerClosure?(logger)
    }

    func setHitCounterService(_ service: FilterHitCounterServiceProtocol) {
        self.setHitCounterServiceCounter += 1
        self.setHitCounterServiceClosure?(service)
    }

    func resetCounters() {
        self.evaluateMessageCounter = 0
        self.setLoggerCounter = 0
        self.setHitCounterServiceCounter = 0
    }
    
    //MARK: Helpers
    private var persistance = MessageEvaluationManager(inMemory: true)
    var context: NSManagedObjectContext
    
    init() {
        self.context = persistance.context
    }
}
