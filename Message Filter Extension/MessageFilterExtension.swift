//
//  MessageFilterExtension.swift
//  Simply Filter SMS Extension
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import IdentityLookup
import CoreData
import NaturalLanguage
import OSLog

final class MessageFilterExtension: ILMessageFilterExtension {
    lazy var logger: Logger = {
        return Logger(subsystem: "com.grizz.apps.dev.Simply-Filter-SMS", category: "extension")
    }()
    
    lazy var extensionManager: MessageEvaluationManagerProtocol = {
        let messageEvaluationManager = MessageEvaluationManager()
        messageEvaluationManager.setLogger(self.logger)
        return messageEvaluationManager
    }()
}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    
    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        
        let offlineAction = self.offlineAction(for: queryRequest)
        let response = ILMessageFilterQueryResponse()
        
        response.action = offlineAction
        completion(response)
    }
    
    private func offlineAction(for queryRequest: ILMessageFilterQueryRequest) -> ILMessageFilterAction {
        let body = queryRequest.messageBody?.lowercased() ?? ""
        let sender = queryRequest.sender?.lowercased() ?? ""
        
        return self.extensionManager.evaluateMessage(body: body, sender: sender)
    }
}