//
//  FilterListCatalogRequest.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 29/10/2026.
//

import Foundation

class FilterListCatalogRequest: URLRequestProtocol {
    var url: URL = .filterListCatalogURL
    var method: HTTPMethod = .get
    var task: HTTPTask = .requestPlain
    var headers: [String: String] = [:]
    var errorDomain: String = "com.grizz.apps.dev.Simply-Filter-SMS.FilterListCatalogRequest"

    init(etag: String?) {
        if let etag = etag {
            self.headers["If-None-Match"] = etag
        }
    }
}
