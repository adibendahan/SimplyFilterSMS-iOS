//
//  ReportMessageService.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 25/06/2022.
//

import Foundation


protocol ReportMessageServiceProtocol: AnyObject {
    @discardableResult
    func reportMessage(reportMessageRequestBody: ReportMessageRequestBody) async -> Bool
}

class ReportMessageService: HTTPServiceBase, ReportMessageServiceProtocol {

    @discardableResult
    func reportMessage(reportMessageRequestBody: ReportMessageRequestBody) async -> Bool {
        guard self.networkSyncManager?.networkStatus == .online else {
            AppManager.logger.debug("reportMessage — skipped (offline) | type: \(reportMessageRequestBody.type, privacy: .public) | sender: '\(reportMessageRequestBody.sender, privacy: .public)'")
            return false
        }
        AppManager.logger.debug("reportMessage — sending | type: \(reportMessageRequestBody.type, privacy: .public) | sender: '\(reportMessageRequestBody.sender, privacy: .public)'")
        do {
            let response = try await self.httpService.execute(type: ReportMessageResponse.self,
                                                              baseURL: .reportMessageURL,
                                                              request: ReportMessageRequest(body: reportMessageRequestBody))
            AppManager.logger.debug("reportMessage — response statusCode: \(response.statusCode ?? -1, privacy: .public)")
            return response.statusCode == 200
        } catch (let error) {
            let nsError = error as NSError
            AppManager.logger.error("ERROR! While reporting message: \(nsError), \(nsError.userInfo)")
        }
        return false
    }
}
