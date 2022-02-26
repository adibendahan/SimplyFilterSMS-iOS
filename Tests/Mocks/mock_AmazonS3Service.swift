//
//  mock_AmazonS3Service.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation
@testable import Simply_Filter_SMS

class mock_AmazonS3Service: AmazonS3ServiceProtocol {
    
    var fetchAutomaticFiltersCounter = 0

    var fetchAutomaticFiltersClosure: (() -> (AutomaticFilterListsResponse?))?

    
    func fetchAutomaticFilters() async -> AutomaticFilterListsResponse? {
        self.fetchAutomaticFiltersCounter += 1
        return self.fetchAutomaticFiltersClosure?()
    }
    
    func resetCounters() {
        self.fetchAutomaticFiltersCounter = 0
    }
}
