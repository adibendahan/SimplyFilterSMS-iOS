//
//  URLRequestExecutor.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation

protocol HTTPServiceProtocol {
    func execute<T>(type: T.Type,
                    baseURL: URL,
                    request: URLRequestProtocol) async throws -> T where T: Decodable
}

class HTTPService: HTTPServiceProtocol {
    func execute<T>(type: T.Type,
                    baseURL: URL,
                    request: URLRequestProtocol) async throws -> T where T: Decodable {
        
        let request = URLRequest(baseURL: baseURL, request: request)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return decodedData
        } catch {
            throw RequestError.noData
        }
    }
}

class HTTPServiceBase {
    var httpService: HTTPServiceProtocol
    weak var networkSyncManager: NetworkSyncManagerProtocol?
    
    init(httpService: HTTPServiceProtocol,
         networkSyncManager: NetworkSyncManagerProtocol = AppManager.shared.networkSyncManager) {
        
        self.networkSyncManager = networkSyncManager
        self.httpService = httpService
    }
    
    init(networkSyncManager: NetworkSyncManagerProtocol = AppManager.shared.networkSyncManager) {
        self.networkSyncManager = networkSyncManager
        self.httpService = HTTPService()
    }
}
