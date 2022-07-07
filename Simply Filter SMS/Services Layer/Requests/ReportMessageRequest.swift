//
//  ReportMessageRequest.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 25/06/2022.
//

import Foundation

class ReportMessageRequest: URLRequestProtocol {
    var path: String = "/ReportMessage"
    var method: HTTPMethod = .post
    var task: HTTPTask
    var errorDomain: String = "com.grizz.apps.dev.Simply-Filter-SMS.ReportMessageRequest"
    var auth : Bool = true
    
    init(body: ReportMessageRequestBody) {
        let jsonDict: [String : Any] = [ "sender" : body.sender,
                                         "body" : body.body,
                                         "type" : body.type ]
        
        self.task = .requestParameters(bodyParameters: jsonDict, urlParameters: nil)
    }
}

struct ReportMessageRequestBody: Codable {
    let sender: String
    let body: String
    let type: String
}
