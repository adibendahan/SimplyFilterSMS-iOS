//
//  UITestsHelpers.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 18/06/2022.
//

import XCTest
import NaturalLanguage


//MARK: Localization
postfix operator ~
postfix func ~ (string: String) -> String {
    let bundle = Bundle(for: SnapshotsTestCase.self)
    var candidates: [String] = []

    let localeId = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    candidates.append(localeId)

    let language = Locale.current.language
    if let langCode = language.languageCode?.identifier {
        candidates.append(langCode)
        if let script = language.script?.identifier {
            candidates.append("\(langCode)-\(script)")
        }
    }

    for preferred in Locale.preferredLanguages {
        let normalized = preferred.replacingOccurrences(of: "_", with: "-")
        candidates.append(normalized)
        let parts = normalized.split(separator: "-").map(String.init)
        if parts.count >= 2 {
            candidates.append("\(parts[0])-\(parts[1])")
        }
        if let first = parts.first {
            candidates.append(first)
        }
    }

    if let fastlaneLanguage = ProcessInfo.processInfo.environment["FASTLANE_LANGUAGE"] {
        candidates.append(fastlaneLanguage.replacingOccurrences(of: "_", with: "-"))
    }

    var seen = Set<String>()
    for candidate in candidates where seen.insert(candidate).inserted {
        if let path = bundle.path(forResource: candidate, ofType: "lproj"),
           let localizationBundle = Bundle(path: path) {
            return NSLocalizedString(string, tableName: nil, bundle: localizationBundle, value: "", comment: "")
        }
    }
    return "?"
}

postfix func ~ (lang: NLLanguage) -> String {
    return Locale.current.localizedString(forIdentifier: lang.rawValue) ?? "ERROR"
}


//MARK: Extensions
extension XCUIElement {
    func forceTap() {
        if isHittable {
            coordinate(withNormalizedOffset: CGVector(dx:0.5, dy:0.5)).tap()
        }
        else {
            XCTContext.runActivity(named: "Tap \(self) by coordinate") { _ in
                coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
        }
    }
}

