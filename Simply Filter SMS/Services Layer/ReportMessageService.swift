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
            Log.debug("offline, type: \(reportMessageRequestBody.type), sender: \(reportMessageRequestBody.sender), body: \(reportMessageRequestBody.body) → skipped")
            return false
        }
        Log.debug("sending, type: \(reportMessageRequestBody.type), sender: \(reportMessageRequestBody.sender), body: \(reportMessageRequestBody.body)")
        do {
            let response = try await self.httpService.execute(type: ReportMessageResponse.self,
                                                              request: ReportMessageRequest(body: reportMessageRequestBody))
            Log.debug("response received, statusCode: \(response.statusCode)")
            return response.statusCode == 200
        } catch (let error) {
            Log.error("report failed, type: \(reportMessageRequestBody.type), sender: \(private: reportMessageRequestBody.sender)", error: error)
        }
        return false
    }
}
