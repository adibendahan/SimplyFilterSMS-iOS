//
//  FilterListService.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation

protocol FilterListServiceProtocol: AnyObject {
    func fetchFilterListCatalog(etag: String?) async -> FetchResult<FilterListCatalogResponse>?
    func fetchFilterList(at url: URL, etag: String?) async -> FetchResult<FilterExportPayload>?
}

class FilterListService: HTTPServiceBase, FilterListServiceProtocol {

    func fetchFilterListCatalog(etag: String?) async -> FetchResult<FilterListCatalogResponse>? {
        let request = FilterListCatalogRequest(etag: etag)

        return await self.fetch(request: request, decode: { data in
            return FilterListCatalogResponse(data: data)
        })
    }

    func fetchFilterList(at url: URL, etag: String?) async -> FetchResult<FilterExportPayload>? {
        let request = FilterListRequest(url: url, etag: etag)

        return await self.fetch(request: request, decode: { data in
            return try FilterExportPayload(data: data)
        })
    }

    //MARK: - Private -
    private func fetch<T>(request: URLRequestProtocol, decode: (Data) throws -> T?) async -> FetchResult<T>? {
        let requestURL = request.url
        guard self.networkSyncManager?.networkStatus == .online else {
            Log.debug("offline, url: \(requestURL.absoluteString) → skipped")
            return nil
        }
        do {
            let fetchResult = try await self.httpService.fetchIfModified(request: request)

            switch fetchResult {
            case .notModified:
                return .notModified

            case .modified(let responseData, let newETag):
                guard let decodedResponse = try decode(responseData) else {
                    Log.error("response doesn't decode, url: \(requestURL.absoluteString), bytes: \(responseData.count)")
                    return nil
                }
                return .modified(decodedResponse, etag: newETag)
            }
        } catch {
            Log.error("fetch failed, url: \(requestURL.absoluteString)", error: error)
            return nil
        }
    }
}
