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
@testable import Simply_Filter_SMS

class mock_MessageEvaluationManager: MessageEvaluationManagerProtocol {

    var evaluateMessageCounter = 0

    var evaluateMessageClosure: ((String, String) -> (ILMessageFilterAction))?
    
    func evaluateMessage(body: String, sender: String) -> ILMessageFilterAction {
        self.evaluateMessageCounter += 1
        return self.evaluateMessageClosure?(body, sender) ?? .none
    }
    
    func resetCounters() {
        self.evaluateMessageCounter = 0
    }
    
    //MARK: Helpers
    private var persistance = MessageEvaluationManager(inMemory: true)
    var context: NSManagedObjectContext
    
    init() {
        self.context = persistance.context
    }
}
