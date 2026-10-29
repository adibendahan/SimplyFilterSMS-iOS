//
//  mock_FilterListService.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation
@testable import Simply_Filter_SMS

class mock_FilterListService: FilterListServiceProtocol {
    
    var fetchFilterListCatalogCounter = 0
    var fetchFilterListCounter = 0

    var fetchFilterListCatalogClosure: ((String?) -> (FetchResult<FilterListCatalogResponse>?))?
    var fetchFilterListClosure: ((URL, String?) -> (FetchResult<FilterExportPayload>?))?

    
    func fetchFilterListCatalog(etag: String?) async -> FetchResult<FilterListCatalogResponse>? {
        self.fetchFilterListCatalogCounter += 1
        return self.fetchFilterListCatalogClosure?(etag)
    }

    func fetchFilterList(at url: URL, etag: String?) async -> FetchResult<FilterExportPayload>? {
        self.fetchFilterListCounter += 1
        return self.fetchFilterListClosure?(url, etag)
    }
    
    func resetCounters() {
        self.fetchFilterListCatalogCounter = 0
        self.fetchFilterListCounter = 0
    }
}
