//
//  FilterListManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/01/2022.
//

import Foundation
import NaturalLanguage

protocol FilterListManagerProtocol {
    var hasActiveFilterLists: Bool { get }
    var activeFilterListsTitle: String? { get }
    var filterListsLastUpdated: Date? { get }
    var filterListLanguages: [NLLanguage] { get }
    var communityLists: [CommunityListItem] { get }
    var activeCommunityListsCount: Int { get }
    
    func isFilterListActive(for language: NLLanguage) -> Bool
    func setFilterListActive(for language: NLLanguage, value: Bool)
    func setCommunityListActive(_ communityList: CommunityListItem, value: Bool)
    func removeCommunityList(_ communityList: CommunityListItem)
    func previewCommunityList(at url: URL) async -> Result<CommunityListItem, CommunityListPreviewError>
    @MainActor func subscribeCommunityList(_ communityList: CommunityListItem) async -> Bool
    @MainActor func refreshFilterLists() async
    @MainActor func updateFilterListsWhenOnline()
    func onFilterListsUpdateFinished(_ handler: @escaping () -> Void)
}

struct CommunityListItem: Identifiable, Equatable {
    var id: String { return self.url }
    let url: String
    let name: String
    let description: String?
    let author: String?
    let homepage: URL?
    let locale: Locale?
    let cacheSection: FilterListsCacheSection?
    let isActive: Bool
    let isCurated: Bool
}

enum CommunityListPreviewError: Error, Equatable, CaseIterable {
    case invalidURL, alreadySubscribed, offline, notAList, missingName, missingDescription, missingAuthor, invalidHomepage, invalidLocale
}

extension CommunityListItem {
    init(url: String, catalogEntry: FilterListCatalogEntry?, cacheSection: FilterListsCacheSection?, isActive: Bool) {
        let payload = cacheSection?.payload
        self.url = url
        if let catalogEntry {
            self.name = catalogEntry.name
            self.description = catalogEntry.description
            self.author = catalogEntry.author
            self.homepage = Self.homepageURL(from: catalogEntry.homepage)
            self.locale = Locale.listLocale(from: catalogEntry.locale)
        }
        else {
            self.name = FilterExportPayload.displayName(name: payload?.name, url: url)
            self.description = payload?.description
            self.author = payload?.author
            self.homepage = Self.homepageURL(from: payload?.homepage)
            self.locale = Locale.listLocale(from: payload?.locale)
        }
        self.cacheSection = cacheSection
        self.isActive = isActive
        self.isCurated = catalogEntry != nil
    }

    static func homepageURL(from homepage: String?) -> URL? {
        guard let homepage, let homepageURL = URL(string: homepage) else { return nil }
        guard homepageURL.scheme?.lowercased() == "https" else { return nil }
        guard homepageURL.host != nil else { return nil }
        return homepageURL
    }
}


extension NSNotification.Name {
    static let filterListsUpdated: NSNotification.Name = NSNotification.Name("FilterListsUpdated")
}
