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
        guard self.networkSyncManager?.networkStatus == .online else { return false }
        
        do {
            let response = try await self.httpService.execute(type: ReportMessageResponse.self,
                                                              baseURL: .reportMessageURL,
                                                              request: ReportMessageRequest(body: reportMessageRequestBody))
            
            return response.statusCode == 200
        } catch (let error) {
            let nsError = error as NSError
            AppManager.logger.error("ERROR! While fetching Automatic Filter List: \(nsError), \(nsError.userInfo)")
        }

        return false
    }
}
