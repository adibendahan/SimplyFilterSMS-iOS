//
//  AutomaticFilterList.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/01/2022.
//

#warning("Hod - Temp implementation")
import Foundation
import CryptoKit

struct AutomaticFilterList: Codable {
    
    enum CodingKeys: String, CodingKey {
        case filterList = "filteredLists"
    }
    
    let filterList: [String : [String]]
}


extension AutomaticFilterList {
    var hashed: String {
        guard let encodedData = try? JSONEncoder().encode(self) else { return "" }
        let digest = SHA256.hash(data: encodedData)
        let hexString = digest.compactMap { String(format: "%02X", $0) }.joined()
        return hexString
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
