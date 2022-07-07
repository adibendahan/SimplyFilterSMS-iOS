//
//  ReportMessageResponse.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 25/06/2022.
//

import Foundation

struct ReportMessageResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case statusCode = "statusCode"
        case message = "message"
    }
    
    let statusCode: Int?
    let message: String?
}
