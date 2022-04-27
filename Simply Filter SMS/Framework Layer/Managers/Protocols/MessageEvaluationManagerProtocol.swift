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


struct MessageEvaluationResult {
    var action: ILMessageFilterAction
    var reason: String?
}

protocol MessageEvaluationManagerProtocol {
    var context: NSManagedObjectContext { get }
    
    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult
    func setLogger(_ logger: Logger)
}
