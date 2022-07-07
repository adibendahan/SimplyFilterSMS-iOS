//
//  AutomaticFiltersRequest.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation

class AutomaticFilterListsRequest: URLRequestProtocol {
    var path: String = "/simply-filter-sms/1.0.0/automatic_filters.json"
    var method: HTTPMethod = .get
    var task: HTTPTask = .requestPlain
    var errorDomain: String = "com.grizz.apps.dev.Simply-Filter-SMS.AutomaticFiltersRequest"
    var auth : Bool = false
}
