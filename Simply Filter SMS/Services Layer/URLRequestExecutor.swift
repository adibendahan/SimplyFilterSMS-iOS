//
//  URLRequestExecutor.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation


class URLRequestExecutor: URLRequestExecutorProtocol {
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
