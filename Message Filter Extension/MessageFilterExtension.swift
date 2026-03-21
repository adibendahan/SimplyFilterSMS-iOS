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

    override init() {
        super.init()
        logger.debug("Extension loaded")
    }

    lazy var extensionManager: MessageEvaluationManagerProtocol = {
        let messageEvaluationManager = MessageEvaluationManager()
        messageEvaluationManager.setLogger(self.logger)
        return messageEvaluationManager
    }()
}

@available(iOS 16.0, *)
extension MessageFilterExtension: ILMessageFilterCapabilitiesQueryHandling {
    func handle(_ capabilitiesQueryRequest: ILMessageFilterCapabilitiesQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterCapabilitiesQueryResponse) -> Void) {
        completion(ILMessageFilterCapabilitiesQueryResponse())
    }
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
        let body = queryRequest.messageBody ?? ""
        let sender = queryRequest.sender ?? ""
        logger.debug("▶▶▶ Query received | sender: '\(sender, privacy: .public)' | body: '\(body, privacy: .public)'")
        let result = self.extensionManager.evaluateMessage(body: body, sender: sender)
        logger.debug("◀◀◀ Extension response: \(result.action.logName, privacy: .public) | reason: '\(result.reason ?? "none", privacy: .public)'")
        return result.action
    }
}
