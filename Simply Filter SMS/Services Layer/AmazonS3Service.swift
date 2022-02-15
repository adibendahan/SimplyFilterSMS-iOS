//
//  AmazonS3Service.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation

protocol AmazonS3ServiceProtocol: AnyObject {
    func fetchAutomaticFilters() async -> AutomaticFilterListsResponse?
}

class AmazonS3Service: HTTPServiceBase, AmazonS3ServiceProtocol {
    func fetchAutomaticFilters() async -> AutomaticFilterListsResponse? {
        do {
            let response = try await self.httpService.execute(type: AutomaticFilterListsResponse.self, baseURL: .appBaseURL, request: AutomaticFilterListsRequest())
            return response
        } catch (let error) {
            let nsError = error as NSError
            AppManager.logger.error("ERROR! While fetching Automatic Filter List: \(nsError), \(nsError.userInfo)")
        }
        
        return nil
    }
}
