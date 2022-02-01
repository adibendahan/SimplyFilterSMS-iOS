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
    
    var debugName: String {
        switch self {
        case .none:
            return "None"
        case .allow:
            return "Allow"
        case .junk:
            return "Junk"
        case .filter:
            return "Filter"
        case .promotion:
            return "Promotion"
        case .transaction:
            return "Transaction"
        @unknown default:
            return "Unknown"
        }
    }
    
    var testResult: String {
        switch self {
        case .none, .allow:
            return "testFilters_resultAllowed"~
            
        case .junk, .filter:
            return "testFilters_resultJunk"~
            
        case .promotion:
            return "testFilters_resultPromotion"~
            
        case .transaction:
            return "testFilters_resultTransaction"~
            
        @unknown default:
            return "🧐"
        }
    }
}
