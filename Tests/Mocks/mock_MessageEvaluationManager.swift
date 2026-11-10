//
//  mock_MessageEvaluationManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 02/02/2022.
//

import Foundation
import XCTest
import IdentityLookup
import CoreData
@testable import Simply_Filter_SMS

class mock_MessageEvaluationManager: MessageEvaluationManagerProtocol {

    var evaluateMessageCounter = 0
    var evaluateMessageClosure: ((String, String) -> (MessageEvaluationResult))?

    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult {
        self.evaluateMessageCounter += 1
        return self.evaluateMessageClosure?(body, sender) ?? MessageEvaluationResult(action: .none)
    }

    func resetCounters() {
        self.evaluateMessageCounter = 0
    }

    //MARK: Helpers
    private var persistence = MessageEvaluationManager(inMemory: true)
    var context: NSManagedObjectContext

    init() {
        self.context = persistence.context
    }
}
