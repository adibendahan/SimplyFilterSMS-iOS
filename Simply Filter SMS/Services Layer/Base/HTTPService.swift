//
//  URLRequestExecutor.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation

enum FetchResult<T> {
    case notModified
    case modified(T, etag: String?)
}

extension FetchResult: Equatable where T: Equatable { }

protocol HTTPServiceProtocol {
    func execute<T>(type: T.Type,
                    request: URLRequestProtocol) async throws -> T where T: Decodable

    func fetchIfModified(request: URLRequestProtocol) async throws -> FetchResult<Data>
}

class HTTPService: HTTPServiceProtocol {
    func execute<T>(type: T.Type,
                    request: URLRequestProtocol) async throws -> T where T: Decodable {
        
        let request = URLRequest(request: request)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return decodedData
        } catch {
            throw RequestError.noData
        }
    }

    func fetchIfModified(request: URLRequestProtocol) async throws -> FetchResult<Data> {
        var request = URLRequest(request: request)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw RequestError.unknown }

        switch httpResponse.statusCode {
        case 304:
            return .notModified
        case 200..<300:
            let etag = httpResponse.value(forHTTPHeaderField: "ETag")
            return .modified(data, etag: etag)
        default:
            throw RequestError.badStatus(httpResponse.statusCode)
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
