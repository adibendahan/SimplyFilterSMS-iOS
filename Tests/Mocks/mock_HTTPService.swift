//
//  mock_HTTPService.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 15/02/2022.
//

import Foundation
@testable import Simply_Filter_SMS

class mock_HTTPService: HTTPServiceProtocol {
    
    var executeCounter = 0
    
    var executeClosure: ((AnyClass.Type?, URL, URLRequestProtocol) -> ())?
    
    func execute<T>(type: T.Type, baseURL: URL, request: URLRequestProtocol) async throws -> T where T : Decodable {
        
        self.executeCounter += 1
        self.executeClosure?(type as? AnyClass.Type, baseURL, request)
        
        switch type {
        case is AutomaticFilterListsResponse.Type:
            let mock: T = AutomaticFilterListsResponse(filterLists: [:]) as! T
            return mock
        default:
            break
        }
        fatalError("Unsupported mock object?")
    }
}
