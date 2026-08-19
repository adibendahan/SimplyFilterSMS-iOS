//
//  MessageEvaluationManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 01/02/2022.
//

import Foundation
import CoreData
import IdentityLookup
import OSLog

enum MessageEvaluationMatch: Equatable {
    case none
    case noMatch
    case storeUnavailable
    case userFilter(String)
    case smartFilter(String)
    case automaticFilter(String)

    var label: String? {
        switch self {
        case .none, .storeUnavailable:
            return nil
        case .noMatch:
            return "testFilters_resultReason_noMatch"~
        case .userFilter:
            return "testFilters_resultMatchedFilter"~
        case .smartFilter:
            return "testFilters_resultMatchedSmartFilter"~
        case .automaticFilter:
            return "testFilters_resultMatchedAutomaticFilter"~
        }
    }

    var value: String? {
        switch self {
        case .userFilter(let text), .smartFilter(let text), .automaticFilter(let text):
            return text
        case .none, .noMatch, .storeUnavailable:
            return nil
        }
    }

    var caption: String? {
        switch self {
        case .none:
            return nil
        case .storeUnavailable:
            return "storeUnavailable"
        default:
            guard let label else { return nil }
            if let value {
                return "\(label) \"\(value)\""
            }
            return label
        }
    }
}

struct MessageEvaluationResult: Equatable {
    var action: ILMessageFilterAction
    var match: MessageEvaluationMatch = .none

    var reason: String? { match.caption }
}

protocol MessageEvaluationManagerProtocol {
    var context: NSManagedObjectContext { get }
    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult
    func setLogger(_ logger: Logger)
}
