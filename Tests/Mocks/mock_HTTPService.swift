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
    var fetchIfModifiedCounter = 0
    
    var executeClosure: ((AnyClass.Type?, URLRequestProtocol) -> ())?
    var fetchIfModifiedClosure: ((URLRequestProtocol) throws -> (FetchResult<Data>))?
    
    func execute<T>(type: T.Type, request: URLRequestProtocol) async throws -> T where T : Decodable {
        
        self.executeCounter += 1
        self.executeClosure?(type as? AnyClass.Type, request)
        
        fatalError("Unsupported mock object?")
    }

    func fetchIfModified(request: URLRequestProtocol) async throws -> FetchResult<Data> {
        self.fetchIfModifiedCounter += 1
        return try self.fetchIfModifiedClosure?(request) ?? .notModified
    }
}
