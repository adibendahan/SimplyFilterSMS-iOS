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
            return try? FilterExportPayload(data: data)
        })
    }

    //MARK: - Private -
    private func fetch<T>(request: URLRequestProtocol, decode: (Data) -> T?) async -> FetchResult<T>? {
        let url = request.url
        guard self.networkSyncManager?.networkStatus == .online else {
            AppManager.logger.debug("fetch — skipped (offline): \(url.lastPathComponent, privacy: .public)")
            return nil
        }
        do {
            let response = try await self.httpService.fetchIfModified(request: request)

            switch response {
            case .notModified:
                AppManager.logger.debug("fetch — not modified: \(url.lastPathComponent, privacy: .public)")
                return .notModified

            case .modified(let data, let newETag):
                guard let decoded = decode(data) else {
                    AppManager.logger.error("ERROR! While decoding \(url.absoluteString, privacy: .public)")
                    return nil
                }
                AppManager.logger.debug("fetch — modified: \(url.lastPathComponent, privacy: .public)")
                return .modified(decoded, etag: newETag)
            }
        } catch (let error) {
            let nsError = error as NSError
            AppManager.logger.error("ERROR! While fetching \(url.absoluteString, privacy: .public): \(nsError), \(nsError.userInfo)")
            return nil
        }
    }
}
