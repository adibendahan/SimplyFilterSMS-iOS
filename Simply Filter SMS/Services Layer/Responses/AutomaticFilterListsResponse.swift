//
//  AutomaticFilterListResponse.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation


struct AutomaticFilterListsResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case filterLists = "filter_lists"
    }
    
    let filterLists: [String : LanguageFilterListResponse]
}

struct LanguageFilterListResponse: Codable {
    
    enum CodingKeys: String, CodingKey {
        case allowSenders = "allow_sender"
        case allowBody = "allow_body"
        case denySender = "deny_sender"
        case denyBody = "deny_body"
    }
    
    let allowSenders: [String]
    let allowBody: [String]
    let denySender: [String]
    let denyBody: [String]
}

extension AutomaticFilterListsResponse {
    var hashed: String {
        return "" // Not in use
    }
    
    var encoded: String? {
        guard let encodedData = try? JSONEncoder().encode(self) else { return nil }
        return encodedData.base64EncodedString()
    }
    
    init?(base64String: String) {
        guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters),
                let filterList = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        
        self = filterList
    }
}
