//
//  MessageEvaluationManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 01/02/2022.
//

import Foundation
import CoreData
import IdentityLookup

protocol MessageEvaluationManagerProtocol {
    var context: NSManagedObjectContext { get }
    
    func evaluateMessage(body: String, sender: String) -> ILMessageFilterAction
}

extension ILMessageFilterAction {
    var isFiltered: Bool {
        switch self {
        case .none, .allow:
            return false
        case .junk, .filter, .promotion, .transaction:
            return true
        @unknown default:
            return false
        }
    }
}
