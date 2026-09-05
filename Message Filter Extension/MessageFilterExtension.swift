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
        extensionManager.setLogger(logger)
        logger.debug("Extension loaded")
    }

    let extensionManager = MessageEvaluationManager()

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
        let queryID = UUID().uuidString
        let started = Date()
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        logger.info("Query received: id=\(queryID, privacy: .public) version=\(version, privacy: .public) build=\(build, privacy: .public)")
        extensionManager.evaluateMessage(body: queryRequest.messageBody ?? "", sender: queryRequest.sender ?? "") { result in
            let response = result.makeResponse()
            self.logger.info("Query completed: id=\(queryID, privacy: .public) match=\(result.match.logKind, privacy: .public) status=\(result.status.rawValue, privacy: .public) action=\(result.action.logName, privacy: .public) elapsed=\(Date().timeIntervalSince(started), privacy: .public)")
            completion(response)
        }
    }
}
