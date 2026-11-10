//
//  MessageFilterExtension.swift
//  Simply Filter SMS Extension
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import IdentityLookup
import CoreData
import NaturalLanguage

final class MessageFilterExtension: ILMessageFilterExtension {
    override init() {
        super.init()
        Log.debug("loaded")
    }

    lazy var extensionManager: MessageEvaluationManagerProtocol = MessageEvaluationManager()
}

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
        Log.debug("query received from iOS")
        let result = self.extensionManager.evaluateMessage(body: body, sender: sender)
        return result.action
    }
}
