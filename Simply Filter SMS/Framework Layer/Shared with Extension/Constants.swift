//
//  Constants.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 27/12/2021.
//

import Foundation
import IdentityLookup
import SwiftUI


//MARK: Constants
let kAppWorkingDirectory = "Simply-Filter-SMS"
let kDatabaseFilename = "CoreData.sqlite"
let kAppGroupContainer = "group.com.grizz.apps.dev.simply-filter-sms"
let kNoColorDict: [String: Double] = [:]
let kSupportEmail = "grizz.apps.dev@gmail.com"
let kUpdateFilterListsMinDays = 3
let kFilterListsProcessingTaskIdentifier = "com.grizz.apps.dev.simply-filter-sms.process-automatic-filters"
let kInactivityReminderNotificationIdentifier = "com.grizz.apps.dev.simply-filter-sms.inactivity-reminder"
let kInactivityReminderHour = 19
let kInactivityReminderLatestDay = 28
let kInactivityNotificationMaxAsks = 3
let kInactivityNotificationMinSessionsBetweenAsks = 3
let kStayReachableToastMaxShows = 2
let kMinimumFilterLength = 1
let kFilterExportFileExtension = "sfsfilters"
let kFilterExportTypeIdentifier = "com.grizz.apps.dev.simply-filter-sms.filters"
let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "#ERROR#"
let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "#ERROR#"
let currentWhatsNewVersion = 7


// URLs
extension URL {
    static let appBaseURL = URL(string: "https://grizz-apps-dev.s3.us-east-2.amazonaws.com")!
    static let filterListCatalogURL: URL = {
        #if DEBUG
        guard !ProcessInfo.processInfo.isUsingUITestData else {
            return URL.appBaseURL.appendingPathComponent("simply-filter-sms/ui-tests/catalog.json")
        }
        #endif // DEBUG
        return URL.appBaseURL.appendingPathComponent("simply-filter-sms/4.0.0/catalog.json")
    }()
    static let pagesBaseURL = URL(string: "https://adibendahan.github.io")!
    static let communityListGuideURL = URL.pagesBaseURL.appendingPathComponent("SimplyFilterSMS-iOS/", isDirectory: true)
    static let communityListProposalURL = URL.pagesBaseURL.appendingPathComponent("SimplyFilterSMS-iOS/submit/", isDirectory: true)
    static let reportMessageURL = URL(string: "https://api.ben-dahan.com")!
    static let appReviewURL = URL(string: "https://apps.apple.com/app/id1603222959?action=write-review")!
    static let appTwitterURL = URL(string: "https://twitter.com/a_bd")!
    static let appGithubURL = URL(string: "https://github.com/adibendahan/SimplyFilterSMS-iOS")!
}

//MARK: Enums
enum FilterType: Int64, CaseIterable, Identifiable {
    var id: Int64 { return self.rawValue }
    
    case deny=0, allow, denyLanguage
    
    var sortIndex: Int {
        switch self {
        case .allow:
            return 0
        case .deny:
            return 1
        case .denyLanguage:
            return 2
        }
    }
    
    var name: String {
        switch self {
        case .deny:
            return "filterList_denied"~
        case .allow:
            return "filterList_allowed"~
        case .denyLanguage:
            return "filterList_deniedLanguage"~
        }
    }

    var addFilterTitle: String {
        switch self {
        case .deny:
            return "addFilter_addFilter_deny"~
        case .allow:
            return "addFilter_addFilter_allow"~
        case .denyLanguage:
            return "addFilter_addLanguage"~
        }
    }

    var addFilterIconName: String {
        switch self {
        case .deny, .allow:
            return "plus.message"
        case .denyLanguage:
            return "globe"
        }
    }

    var supportsFolders: Bool {
        switch self {
        case .allow:
            return false
        default:
            return true
        }
    }

    var isTransferable: Bool {
        switch self {
        case .denyLanguage:
            return false
        default:
            return true
        }
    }

    var supportsAdvancedOptions: Bool {
        switch self {
        case .deny, .allow:
            return true
        case .denyLanguage:
            return false
        }
    }
    
    var allowedWhenAllSendersBlocked: Bool {
        return self == .allow
    }
    
    var iconName: String {
        switch self {
        case .deny:
            return "person.crop.circle.badge.xmark"
        case .allow:
            return "person.crop.circle.badge.checkmark"
        case .denyLanguage:
            return "globe"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .deny:
            return .red
        case .allow:
            return .green
        case .denyLanguage:
            return .cyan
        }
    }
    
    var testIdentifier: TestIdentifier {
        switch self {
        case .deny:
            return .denyFiltersLink
        case .allow:
            return .allowFiltersLink
        case .denyLanguage:
            return .denyLanguageLink
        }
    }
}

enum MessageFolder: Int64, CaseIterable, Identifiable, TestIdentifiable {
    var id: Int64 { return self.rawValue }
    
    case junk=0, transaction, promotion
    
    var iconName: String {
        switch self {
        case .junk:
            return "xmark.bin"
        case .transaction:
            return "arrow.left.arrow.right"
        case .promotion:
            return "megaphone"
        }
    }
    
    var name: String {
        switch self {
        case .junk:
            return "addFilter_folder_junk"~
        case .transaction:
            return "addFilter_folder_transactions"~
        case .promotion:
            return "addFilter_folder_promotions"~
        }
    }
    
    var action: ILMessageFilterAction {
        switch self {
        case .junk:
            return .junk
        case .transaction:
            return .transaction
        case .promotion:
            return .promotion
        }
    }
    
    static var title: String {
        return "addFilter_folder_caption"~
    }

    var testIdentifier: TestIdentifier {
        switch self {
        case .junk:
            return .folderJunkOption
        case .transaction:
            return .folderTransactionsOption
        case .promotion:
            return .folderPromotionsOption
        }
    }
}

enum FilterTarget: Int64, CaseIterable, Identifiable, TestIdentifiable {
    var id: Int64 { return self.rawValue }
    
    case all=0, sender, body
    
    var name: String {
        switch self {
        case .all:
            return "addFilter_target_all"~
        case .sender:
            return "addFilter_target_sender"~
        case .body:
            return "addFilter_target_body"~
        }
    }
    
    var multilineName: String {
        switch self {
        case .all:
            return "addFilter_target_all_multiline"~
        default:
            return self.name
        }
    }

    var icon: String {
        switch self {
        case .all:
            return "asterisk"
        case .sender:
            return "person"
        case .body:
            return "text.bubble"
        }
    }

    static var title: String {
        return "addFilter_target_title"~
    }

    var testIdentifier: TestIdentifier {
        switch self {
        case .all:
            return .targetAllOption
        case .sender:
            return .targetSenderOption
        case .body:
            return .targetBodyOption
        }
    }
}

enum FilterMatching: Int64, CaseIterable, Identifiable, TestIdentifiable {
    var id: Int64 { return self.rawValue }

    case contains=0, exact, regex=2

    var name: String {
        switch self {
        case .contains:
            return "addFilter_match_contains"~
        case .exact:
            return "addFilter_match_exact"~
        case .regex:
            return "addFilter_match_regex"~
        }
    }

    var icon: String {
        switch self {
        case .contains:
            return "equal.circle"
        case .exact:
            return "equal.circle.fill"
        case .regex:
            return "chevron.left.forwardslash.chevron.right"
        }
    }

    var other: FilterMatching {
        switch self {
        case .contains:
            return .exact
        case .exact:
            return .contains
        case .regex:
            return .contains
        }
    }

    var definesOwnCase: Bool {
        switch self {
        case .regex:
            return true
        default:
            return false
        }
    }

    static var title: String {
        return "addFilter_match_title"~
    }

    var testIdentifier: TestIdentifier {
        switch self {
        case .contains:
            return .matchingContainsOption
        case .exact:
            return .matchingExactOption
        case .regex:
            return .matchingRegexOption
        }
    }
}

enum FilterCase: Int64, CaseIterable, Identifiable, TestIdentifiable {
    var id: Int64 { return self.rawValue }
    
    case caseInsensitive=0, caseSensitive
    
    var name: String {
        switch self {
        case .caseInsensitive:
            return "addFilter_case_insensitive"~
        case .caseSensitive:
            return "addFilter_case_sensitive"~
        }
    }
    
    var compareOption: NSString.CompareOptions {
        switch self {
        case .caseInsensitive:
            return .caseInsensitive
        case .caseSensitive:
            return .literal
        }
    }
    
    var icon: String {
        switch self {
        case .caseInsensitive:
            return "characters.lowercase"
        case .caseSensitive:
            return "textformat.characters"
        }
    }

    var other: FilterCase {
        switch self {
        case .caseInsensitive:
            return .caseSensitive
        case .caseSensitive:
            return .caseInsensitive
        }
    }
    
    static var title: String {
        return "addFilter_case_title"~
    }

    var testIdentifier: TestIdentifier {
        switch self {
        case .caseInsensitive:
            return .caseInsensitiveOption
        case .caseSensitive:
            return .caseSensitiveOption
        }
    }
}

struct FilterSignature: Equatable {
    let text: String
    let filterTarget: FilterTarget
    let filterMatching: FilterMatching
    let filterCase: FilterCase

    func isDuplicate(of other: FilterSignature) -> Bool {
        guard self.filterTarget == other.filterTarget, self.filterMatching == other.filterMatching else { return false }
        let isEitherCaseInsensitive = self.filterCase == .caseInsensitive || other.filterCase == .caseInsensitive
        let isDuplicate: Bool
        if self.filterMatching != .regex && isEitherCaseInsensitive {
            isDuplicate = self.text.lowercased() == other.text.lowercased()
        } else {
            isDuplicate = self.text == other.text
        }
        return isDuplicate
    }
}

enum ReportType: Int64, CaseIterable, Identifiable {
    var id: Int64 { return self.rawValue }

    case junk=0, notJunk, junkAndBlockSender=2

    var name: String {
        switch self {
        case .junk:
            return "reportMessage_junk"~
        case .notJunk:
            return "reportMessage_notJunk"~
        case .junkAndBlockSender:
            return "reportMessage_junkAndBlockSender"~
        }
    }

    var type: String {
        switch self {
        case .junk, .junkAndBlockSender:
            return "deny"
        case .notJunk:
            return "allow"
        }
    }

    var icon: String {
        switch self {
        case .junk:
            return "trash.fill"
        case .notJunk:
            return "checkmark.circle.fill"
        case .junkAndBlockSender:
            return "hand.raised.fill"
        }
    }

    var color: Color {
        switch self {
        case .junk:
            return .red
        case .notJunk:
            return .green
        case .junkAndBlockSender:
            return .orange
        }
    }
}

enum SmartFilterType: Int64, CaseIterable, Equatable, Identifiable {
    case allUnknown=0, links, numbersOnly, shortSender, email, emojis, countryAllowlist=6
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .allUnknown:
            return "autoFilter_allUnknown"~
        case .links:
            return "autoFilter_links"~
        case .numbersOnly:
            return "autoFilter_numbersOnly"~
        case .shortSender:
            return "autoFilter_shortSender"~
        case .email:
            return "autoFilter_email"~
        case .emojis:
            return "autoFilter_emojis"~
        case .countryAllowlist:
            return "autoFilter_countryAllowlist"~
        }
    }

    var sortIndex: Int {
        switch self {
        case .allUnknown:
            return 0
        case .links:
            return 1
        case .shortSender:
            return 2
        case .email:
            return 3
        case .numbersOnly:
            return 4
        case .emojis:
            return 6
        case .countryAllowlist:
            return 5
        }
    }

    var icon: String {
        switch self {
        case .allUnknown:
            return "nosign"
        case .links:
            return "link"
        case .numbersOnly:
            return "number.circle.fill"
        case .shortSender:
            return "textformat.123"
        case .email:
            return "envelope.fill"
        case .emojis:
            return "🙄"
        case .countryAllowlist:
            return "globe.americas.fill"
        }
    }
    
    var isTextIcon: Bool {
        return self == .emojis
    }

    var iconColor: Color {
        switch self {
        case .allUnknown:
            return .red
        case .links:
            return .blue
        case .numbersOnly:
            return .purple.opacity(0.8)
        case .shortSender:
            return .orange
        case .email:
            return .brown
        case .emojis:
            return .orange
        case .countryAllowlist:
            return .teal
        }
    }
    
    var subtitle: String? {
        switch self {
        case .shortSender:
            return "autoFilter_shortSender_desc"~
        default:
            return nil
        }
    }

    var action: String? {
        switch self {
        case .shortSender:
            return "autoFilter_shortSender_change"~
        default:
            return nil
        }
    }

    var actionTitle: String? {
        switch self {
        case .shortSender:
            return "autoFilter_shortSender_action"~
        default:
            return nil
        }
    }

    var shortTitle: String {
        switch self {
        case .allUnknown:
            return "autoFilter_allUnknown_shortTitle"~
        case .links:
            return "autoFilter_links_shortTitle"~
        case .numbersOnly:
            return "autoFilter_numbersOnly_shortTitle"~
        case .shortSender:
            return "autoFilter_shortSender_shortTitle"~
        case .email:
            return "autoFilter_email_shortTitle"~
        case .emojis:
            return "autoFilter_emojis_shortTitle"~
        case .countryAllowlist:
            return "autoFilter_countryAllowlist_shortTitle"~
        }
    }

    var isDestructive: Bool {
        return self == .allUnknown
    }

    var testIdentifier: TestIdentifier {
        switch self {
        case .allUnknown:
            return .allUnknownToggle
        case .links:
            return .linksToggle
        case .numbersOnly:
            return .numbersOnlyToggle
        case .shortSender:
            return .shortSenderToggle
        case .email:
            return .emailToggle
        case .emojis:
            return .emojisToggle
        case .countryAllowlist:
            return .countryAllowlistToggle
        }
    }
}

enum TipTier: String, CaseIterable {
    case small = "com.grizz.apps.simplyfiltersms.tip.small"
    case medium = "com.grizz.apps.simplyfiltersms.tip.medium"
    case large = "com.grizz.apps.simplyfiltersms.tip.large"

    var emoji: String {
        switch self {
        case .small: return "☕️"
        case .medium: return "🍕"
        case .large: return "🍸"
        }
    }

    var displayName: String {
        switch self {
        case .small: return "tipJar_tier_small"~
        case .medium: return "tipJar_tier_medium"~
        case .large: return "tipJar_tier_large"~
        }
    }

    var tierDescription: String {
        switch self {
        case .small: return "tipJar_tier_small_desc"~
        case .medium: return "tipJar_tier_medium_desc"~
        case .large: return "tipJar_tier_large_desc"~
        }
    }

    var iconColor: Color {
        switch self {
        case .small: return .orange
        case .medium: return .red
        case .large: return .purple
        }
    }

    var confettiBirthRate: Float {
        switch self {
        case .small: return 15
        case .medium: return 40
        case .large: return 100
        }
    }

    var confettiLifetime: Float {
        switch self {
        case .small: return 1.5
        case .medium: return 2.5
        case .large: return 4.0
        }
    }

    var confettiVelocity: CGFloat {
        switch self {
        case .small: return 200
        case .medium: return 350
        case .large: return 500
        }
    }

    var fallbackPrice: String {
        switch self {
        case .small: return "$1.99"
        case .medium: return "$4.99"
        case .large: return "$9.99"
        }
    }
}

enum WhatsNewEntry: String, CaseIterable {
    case aiFiltering, tipJar, regexFilters, filterTransfer, accentColor, help, communityLists, siriShortcuts, newLanguages, trustedCountries, accessibility, ipad, quickAddFilter, singleChar

    var title: String {
        switch self {
        case .aiFiltering:
            return "whatsNew_aiFiltering_title"~
        case .tipJar:
            return "whatsNew_tipJar_title"~
        case .regexFilters:
            return "whatsNew_regexFilters_title"~
        case .filterTransfer:
            return "whatsNew_filterTransfer_title"~
        case .accentColor:
            return "whatsNew_accentColor_title"~
        case .help:
            return "whatsNew_help_title"~
        case .communityLists:
            return "whatsNew_communityLists_title"~
        case .siriShortcuts:
            return "whatsNew_siriShortcuts_title"~
        case .newLanguages:
            return "whatsNew_newLanguages_title"~
        case .trustedCountries:
            return "whatsNew_trustedCountries_title"~
        case .accessibility:
            return "whatsNew_accessibility_title"~
        case .ipad:
            return "whatsNew_iPad_title"~
        case .quickAddFilter:
            return "whatsNew_quickAddFilter_title"~
        case .singleChar:
            return "whatsNew_singleChar_title"~
        }
    }

    var description: String {
        switch self {
        case .aiFiltering:
            return "whatsNew_aiFiltering_desc"~
        case .tipJar:
            return "whatsNew_tipJar_desc"~
        case .regexFilters:
            return "whatsNew_regexFilters_desc"~
        case .filterTransfer:
            return "whatsNew_filterTransfer_desc"~
        case .accentColor:
            return "whatsNew_accentColor_desc"~
        case .help:
            return "whatsNew_help_desc"~
        case .communityLists:
            return "whatsNew_communityLists_desc"~
        case .siriShortcuts:
            return "whatsNew_siriShortcuts_desc"~
        case .newLanguages:
            return "whatsNew_newLanguages_desc"~
        case .trustedCountries:
            return "whatsNew_trustedCountries_desc"~
        case .accessibility:
            return "whatsNew_accessibility_desc"~
        case .ipad:
            return "whatsNew_iPad_desc"~
        case .quickAddFilter:
            return "whatsNew_quickAddFilter_desc"~
        case .singleChar:
            return "whatsNew_singleChar_desc"~
        }
    }

    var imageName: String {
        switch self {
        case .aiFiltering:
            return "bolt.shield.fill"
        case .tipJar:
            return "heart.fill"
        case .regexFilters:
            return "chevron.left.forwardslash.chevron.right"
        case .filterTransfer:
            return "square.and.arrow.up.on.square"
        case .accentColor:
            return "paintpalette.fill"
        case .help:
            return "questionmark.circle.fill"
        case .communityLists:
            return "person.2.circle"
        case .siriShortcuts:
            return "mic.fill"
        case .newLanguages:
            return "globe"
        case .trustedCountries:
            return "globe.americas"
        case .accessibility:
            return "accessibility"
        case .ipad:
            return "ipad.and.iphone"
        case .quickAddFilter:
            return "plus.circle"
        case .singleChar:
            return "character.cursor.ibeam"
        }
    }

    var color: Color {
        switch self {
        case .aiFiltering:
            return .indigo
        case .tipJar:
            return .red
        case .regexFilters:
            return .orange
        case .filterTransfer:
            return .blue
        case .accentColor:
            return .pink
        case .help:
            return .green
        case .communityLists:
            return .indigo
        case .siriShortcuts:
            return .purple
        case .newLanguages:
            return .teal
        case .trustedCountries:
            return .green
        case .accessibility:
            return .blue
        case .ipad:
            return .pink
        case .quickAddFilter:
            return .cyan
        case .singleChar:
            return .mint
        }
    }

    var orbitPosition: Int? {
        switch self {
        case .communityLists:
            return 0
        case .siriShortcuts:
            return 1
        case .filterTransfer:
            return 2
        case .accentColor:
            return 3
        case .aiFiltering:
            return 4
        case .regexFilters:
            return 5
        case .help, .newLanguages, .trustedCountries, .accessibility, .tipJar, .ipad, .quickAddFilter, .singleChar:
            return nil
        }
    }

    var order: Int {
        switch self {
        case .communityLists:
            return 0
        case .siriShortcuts:
            return 1
        case .filterTransfer:
            return 2
        case .accentColor:
            return 3
        case .help:
            return 4
        case .regexFilters:
            return 5
        case .aiFiltering:
            return 6
        case .newLanguages:
            return 7
        case .trustedCountries:
            return 8
        case .accessibility:
            return 9
        case .tipJar:
            return 10
        case .ipad:
            return 11
        case .quickAddFilter:
            return 12
        case .singleChar:
            return 13
        }
    }

    var iconScale: CGFloat {
        switch self {
        case .communityLists, .newLanguages, .trustedCountries, .accessibility, .quickAddFilter, .singleChar, .accentColor, .help:
            return 1.0
        case .siriShortcuts:
            return 1.1
        case .filterTransfer:
            return 1.08
        case .tipJar:
            return 1.07
        case .aiFiltering:
            return 1.05
        case .regexFilters:
            return 1.2
        case .ipad:
            return 1.15
        }
    }

    var release: String {
        switch self {
        case .communityLists, .siriShortcuts:
            return "4.0.0"
        case .filterTransfer, .accentColor, .help:
            return "3.1.0"
        case .regexFilters:
            return "3.0.2"
        case .aiFiltering, .newLanguages, .trustedCountries:
            return "3.0.0"
        case .accessibility:
            return "2.3.0"
        case .tipJar:
            return "2.2.1"
        case .ipad, .quickAddFilter, .singleChar:
            return "2.2.0"
        }
    }

    var isCurrent: Bool {
        return self.release == WhatsNewEntry.newestRelease
    }

    private static let newestRelease: String? = {
        let releases = WhatsNewEntry.allCases.map { $0.release }
        return releases.max { $0.compare($1, options: .numeric) == .orderedAscending }
    }()

    var actionTitle: String? {
        switch self {
        case .tipJar:
            return "whatsNew_tipJar_action"~
        case .communityLists:
            return "whatsNew_communityLists_action"~
        default:
            return nil
        }
    }
}
