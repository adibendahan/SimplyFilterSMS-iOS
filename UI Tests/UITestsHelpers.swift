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
    let localeId = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    let langCode = Locale.current.language.languageCode?.identifier ?? "en"
    let path = bundle.path(forResource: localeId, ofType: "lproj")
            ?? bundle.path(forResource: langCode, ofType: "lproj")
    guard let path = path,
          let localizationBundle = Bundle(path: path) else { return "?" }
    return NSLocalizedString(string, tableName: nil, bundle: localizationBundle, value: "", comment: "")
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

