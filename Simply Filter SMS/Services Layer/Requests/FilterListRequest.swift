//
//  FilterListRequest.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 29/10/2026.
//

import Foundation

class FilterListRequest: URLRequestProtocol {
    var url: URL
    var method: HTTPMethod = .get
    var task: HTTPTask = .requestPlain
    var headers: [String: String]
    var errorDomain: String = "com.grizz.apps.dev.Simply-Filter-SMS.FilterListRequest"

    init(url: URL, etag: String?) {
        self.url = url
        self.headers = .ifNoneMatch(etag)
    }
}
