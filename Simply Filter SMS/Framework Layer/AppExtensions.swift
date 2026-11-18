//
//  AppExtensions.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/01/2022.
//

import SwiftUI
import NaturalLanguage
import UniformTypeIdentifiers

extension EnvironmentValues {
    var isPreview: Bool {
#if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#else
        return false
#endif // DEBUG
    }
    
    var isDebug: Bool {
#if DEBUG
        return true
#else
        return false
#endif // DEBUG
    }
}

extension Color {
    static func listBackgroundColor(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .light {
            return Color(uiColor: UIColor.secondarySystemBackground)
        }
        else {
            return Color(uiColor: UIColor.systemBackground)
        }
    }

    init?(accentRGB: [String: Double]) {
        guard accentRGB != kNoColorDict,
              let red = accentRGB["red"],
              let green = accentRGB["green"],
              let blue = accentRGB["blue"] else {
            return nil
        }
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }

    var accentRGB: [String: Double] {
        get {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                return kNoColorDict
            }
            return ["red": Double(red), "green": Double(green), "blue": Double(blue)]
        }
        set {
            if let color = Color(accentRGB: newValue) {
                self = color
            }
        }
    }
}

extension AnyTransition {
    static var opacitySlowInFastOut: AnyTransition {
        .asymmetric(
            insertion: .opacity.animation(.easeIn(duration: 0.35)),
            removal: .opacity.animation(.easeOut(duration: 0.15)).combined(with: .scale)
        )
    }
}

extension Date {
    func daysBetween(date: Date) -> Int {
        return Date.daysBetween(start: self, end: date)
    }
    
    static func daysBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        
        let date1 = calendar.startOfDay(for: start)
        let date2 = calendar.startOfDay(for: end)
        
        let a = calendar.dateComponents([.day], from: date1, to: date2)
        return a.value(for: .day)!
    }

    var lastUpdatedText: String {
        let updatedDate = self.formatted(date: .numeric, time: .shortened)
        return String(format: "autoFilter_lastUpdated"~, updatedDate)
    }
}

extension FileManager {
    func directoryExistsAtPath(_ path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = self.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

extension String {
    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var listTextWidth: Int {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        var width = 0
        for character in trimmed {
            let isWide = character.unicodeScalars.contains(where: Self.isWideScalar)
            width += isWide ? 2 : 1
        }
        return width
    }

    private static func isWideScalar(_ scalar: Unicode.Scalar) -> Bool {
        return Self.wideScalarRanges.contains(where: { $0.contains(scalar.value) })
    }

    private static let wideScalarRanges: [ClosedRange<UInt32>] = [
        0x1100...0x115F,
        0x2E80...0xA4CF,
        0xAC00...0xD7A3,
        0xF900...0xFAFF,
        0xFE30...0xFE4F,
        0xFF00...0xFF60,
        0xFFE0...0xFFE6,
        0x1F300...0x1FAFF,
        0x20000...0x3FFFD
    ]

    var highlightedAsRegex: AttributedString {
        let nsAttr = NSMutableAttributedString(string: self)
        let nsLen = (self as NSString).length
        let fullRange = NSRange(location: 0, length: nsLen)

        let rules: [(String, UIColor)] = [
            (#"\^|\$"#,                         .systemGreen),    // anchors
            (#"\|"#,                             .secondaryLabel), // alternation
            (#"[*+?]|\{[0-9,]*\}"#,             .systemOrange),   // quantifiers
            (#"[()]"#,                           .systemPurple),   // groups
            (#"\[(?:[^\]\\]|\\.)*\]"#,           .systemBlue),     // character classes
            (#"\\."#,                            .systemTeal),     // escape sequences
        ]

        for (pat, color) in rules {
            guard let re = try? NSRegularExpression(pattern: pat) else { continue }
            for match in re.matches(in: self, range: fullRange) {
                nsAttr.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }

        return (try? AttributedString(nsAttr, including: \.uiKit)) ?? AttributedString(self)
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ conditional: Bool, @ViewBuilder _ content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }
    
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}

extension View {
    @ViewBuilder func sidebarNavigationRow(screen: Screen, isRegular: Bool, onTap: @escaping () -> Void) -> some View {
        if isRegular {
            self.contentShape(Rectangle())
                .highPriorityGesture(TapGesture().onEnded { _ in onTap() })
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
        } else {
            NavigationLink(value: screen) { self }
        }
    }
}

extension View {
    @ViewBuilder func phoneOnlyStackNavigationView() -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.navigationViewStyle(.stack)

        } else {
            self
        }
    }
}


extension UTType {
    static var sfsFilters: UTType {
        UTType(exportedAs: kFilterExportTypeIdentifier)
    }
}

extension UIApplication {
    func openSettings() {
        if #available(iOS 18.3, *) {
            if let url = URL(string: UIApplication.openDefaultApplicationsSettingsURLString) {
                Log.debug("opening Settings, url: \(url)")
                UIApplication.shared.open(url)
            }
        } else {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Log.debug("opening Settings, url: \(url)")
                UIApplication.shared.open(url)
            }
        }
    }
}

extension View {
    func optionalTint(_ color: Color?) -> some View {
        self.tint(color ?? Color.accentColor)
    }
}

extension NLLanguage {
    static func displayOrder(_ a: NLLanguage, _ b: NLLanguage) -> Bool {
        let currentLocale: NLLanguage? = Locale.current.language.languageCode.map { NLLanguage(rawValue: $0.identifier) }
        var priority: [NLLanguage] = [.english, .hebrew]
        if let current = currentLocale, !priority.contains(current) {
            priority.insert(current, at: 0)
        } else if currentLocale == .hebrew {
            priority = [.hebrew, .english]
        }
        let ai = priority.firstIndex(of: a)
        let bi = priority.firstIndex(of: b)
        switch (ai, bi) {
        case let (ai?, bi?):
            return ai < bi
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case (nil, nil):
            let locale = Locale(identifier: "en_US")
            let an = locale.localizedString(forIdentifier: a.rawValue) ?? a.rawValue
            let bn = locale.localizedString(forIdentifier: b.rawValue) ?? b.rawValue
            return an < bn
        }
    }
}

extension CommunityListItem {
    var localeName: String? {
        guard let locale = self.locale else { return nil }
        return Locale.current.localizedString(forIdentifier: locale.identifier)
    }

    var localeLabel: String? {
        guard let languageCode = self.locale?.language.languageCode else { return nil }
        let languageName = Locale.current.localizedString(forLanguageCode: languageCode.identifier) ?? languageCode.identifier
        let capitalizedLanguageName = languageName.localizedCapitalized
        guard let flag = self.locale?.region?.flagEmoji else { return capitalizedLanguageName }
        return "\(flag) \(capitalizedLanguageName)"
    }
}

extension Locale.LanguageCode {
    var displayName: String {
        let currentName = self.currentName
        let nativeName = self.nativeName
        let name: String
        if nativeName == currentName {
            name = currentName
        } else {
            name = "\(currentName) · \(nativeName)"
        }
        return name
    }

    var nativeName: String {
        return Locale(identifier: self.identifier).localizedString(forLanguageCode: self.identifier)?.localizedCapitalized ?? self.currentName
    }

    var isRightToLeft: Bool {
        return Locale.Language(languageCode: self).characterDirection == .rightToLeft
    }

    var appLocalization: String? {
        return Bundle.main.localizations.first { Locale(identifier: $0).language.languageCode == self }
    }

    static var phoneLanguages: [Locale.LanguageCode] {
        return Self.languages(in: Locale.preferredLanguages)
    }

    static var namedLanguages: [Locale.LanguageCode] {
        let languages = Self.languages(in: Locale.availableIdentifiers)
        return languages.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    private var currentName: String {
        return Locale.current.localizedString(forLanguageCode: self.identifier)?.localizedCapitalized ?? self.identifier
    }

    private static func languages(in localeIdentifiers: [String]) -> [Locale.LanguageCode] {
        var languages: [Locale.LanguageCode] = []
        for identifier in localeIdentifiers {
            guard let language = Locale(identifier: identifier).language.languageCode,
                  !languages.contains(language) else { continue }
            languages.append(language)
        }
        return languages
    }
}

extension Locale.Region {
    private static let regionalIndicatorOffset: UInt32 = 0x1F1A5

    var flagEmoji: String? {
        let regionCode = self.identifier.uppercased()
        guard regionCode.count == 2, regionCode.allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }

        var flag = ""
        for scalar in regionCode.unicodeScalars {
            guard let flagScalar = Unicode.Scalar(Self.regionalIndicatorOffset + scalar.value) else { return nil }
            flag.unicodeScalars.append(flagScalar)
        }
        return flag
    }
}

extension URL {
    var displayLink: String {
        var link = self.absoluteString
        if let scheme = self.scheme, link.hasPrefix(scheme + "://") {
            link.removeFirst(scheme.count + 3)
        }
        if link.hasPrefix("www.") {
            link.removeFirst(4)
        }
        if link.hasSuffix("/") {
            link.removeLast()
        }
        return link
    }

    var isGitHubLink: Bool {
        let host = self.host()?.lowercased() ?? ""
        return host == "github.com" || host == "www.github.com" || host.hasSuffix(".github.io")
    }

    var opensInAppBrowser: Bool {
        guard let scheme = self.scheme?.lowercased(), scheme == "https" || scheme == "http" else { return false }
        return self.host() != "apps.apple.com"
    }
}

extension View {
    func inAppBrowser() -> some View {
        self.modifier(InAppBrowserModifier())
    }
}

extension CommunityListPreviewError {
    var message: String {
        switch self {
        case .invalidURL:
            return "communityLists_error_invalidURL"~
        case .alreadySubscribed:
            return "communityLists_error_alreadySubscribed"~
        case .offline:
            return "communityLists_error_offline"~
        case .notAList:
            return "communityLists_error_notAList"~
        case .missingName:
            return "communityLists_error_missingName"~
        case .nameTooLong:
            return String(format: "communityLists_error_nameTooLong"~, CommunityListItem.maxNameWidth)
        case .missingDescription:
            return "communityLists_error_missingDescription"~
        case .missingAuthor:
            return "communityLists_error_missingAuthor"~
        case .authorTooLong:
            return String(format: "communityLists_error_authorTooLong"~, CommunityListItem.maxAuthorWidth)
        case .invalidHomepage:
            return "communityLists_error_invalidHomepage"~
        case .invalidLocale:
            return "communityLists_error_invalidLocale"~
        }
    }
}
