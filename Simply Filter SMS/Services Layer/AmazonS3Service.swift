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
    var isFetching = false
    
    func fetchAutomaticFilters() async -> AutomaticFilterListsResponse? {
        guard self.networkSyncManager?.networkStatus == .online, !self.isFetching else { return nil }
        
        do {
            self.isFetching = true
            let response = try await self.httpService.execute(type: AutomaticFilterListsResponse.self, baseURL: .appBaseURL, request: AutomaticFilterListsRequest())
            self.isFetching = false
            return response
        } catch (let error) {
            self.isFetching = false
            let nsError = error as NSError
            AppManager.logger.error("ERROR! While fetching Automatic Filter List: \(nsError), \(nsError.userInfo)")
        }
        
        return nil
    }
}
