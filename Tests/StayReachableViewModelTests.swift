//
//  StayReachableViewModelTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 18/11/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class StayReachableViewModelTests: XCTestCase {

    private var appManager: mock_AppManager!
    private var persistenceManager: mock_PersistenceManager!
    private var testSubject: StayReachableView.ViewModel!

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.appManager = mock_AppManager()
        self.persistenceManager = mock_PersistenceManager()
        self.appManager.persistenceManager = self.persistenceManager
        self.testSubject = StayReachableView.ViewModel(appManager: self.appManager)
    }

    override func tearDown() {
        self.testSubject = nil
        self.persistenceManager = nil
        self.appManager = nil
        super.tearDown()
    }

    //MARK: Tests
    func test_init_inEnglish_startsWithEnglishThenTheFirstOtherPhoneLanguage() {
        // Prepare
        let hebrew = Locale.LanguageCode("he")
        let french = Locale.LanguageCode("fr")

        // Act
        self.testSubject = StayReachableView.ViewModel(appManager: self.appManager,
                                                       appLanguage: .english,
                                                       phoneLanguages: [.english, hebrew, french])

        // Verify
        XCTAssertEqual(self.testSubject.sections.map(\.language), [.english, hebrew])
        XCTAssertEqual(self.testSubject.appLanguage, .english)
        XCTAssertEqual(self.testSubject.phoneLanguages, [hebrew, french])
        XCTAssertFalse(self.testSubject.otherLanguages.contains(.english))
        XCTAssertFalse(self.testSubject.otherLanguages.contains(hebrew))
        XCTAssertFalse(self.testSubject.otherLanguages.contains(french))
    }

    func test_init_inEnglishWithNoOtherPhoneLanguage_startsWithEnglishOnly() {
        // Act
        self.testSubject = StayReachableView.ViewModel(appManager: self.appManager,
                                                       appLanguage: .english,
                                                       phoneLanguages: [.english])

        // Verify
        XCTAssertEqual(self.testSubject.sections.map(\.language), [.english])
        XCTAssertTrue(self.testSubject.phoneLanguages.isEmpty)
    }

    func test_init_inAnotherAppLanguage_startsWithItThenEnglish() {
        // Prepare
        let hebrew = Locale.LanguageCode("he")
        let arabic = Locale.LanguageCode("ar")

        // Act
        self.testSubject = StayReachableView.ViewModel(appManager: self.appManager,
                                                       appLanguage: hebrew,
                                                       phoneLanguages: [hebrew, arabic])

        // Verify
        XCTAssertEqual(self.testSubject.sections.map(\.language), [hebrew, .english])
        XCTAssertEqual(self.testSubject.appLanguage, hebrew)
        XCTAssertEqual(self.testSubject.phoneLanguages, [arabic])
        XCTAssertTrue(self.testSubject.otherLanguages.contains(.english))
        XCTAssertFalse(self.testSubject.otherLanguages.contains(hebrew))
        XCTAssertFalse(self.testSubject.otherLanguages.contains(arabic))
    }

    func test_newFilterTexts_skipsBlankRepeatedAndAllowed() {
        // Prepare
        var english = StayReachableView.LanguageSection(language: .english)
        english.firstName = " Adi "
        english.surname = "Ben-Dahan"
        var hebrew = StayReachableView.LanguageSection(language: Locale.LanguageCode("he"))
        hebrew.firstName = "adi"
        hebrew.surname = "בן דהן"
        hebrew.street = "הרצל"
        self.persistenceManager.filterTextsClosure = { _, _, _ in
            return ["Ben-Dahan"]
        }
        self.testSubject = StayReachableView.ViewModel(appManager: self.appManager)

        // Act
        self.testSubject.sections = [english, hebrew]

        // Verify
        XCTAssertEqual(self.testSubject.newFilterTexts, ["Adi", "בן דהן", "הרצל"])
        XCTAssertTrue(self.testSubject.isAlreadyAllowed("Ben-Dahan"))
        XCTAssertFalse(self.testSubject.isAlreadyAllowed("  "))
    }

    func test_isSkipped_marksOnlyTheLaterRepeat() {
        // Prepare
        var english = StayReachableView.LanguageSection(language: .english)
        english.firstName = "Adi"
        english.surname = "Herzl"
        english.street = " herzl "
        var hebrew = StayReachableView.LanguageSection(language: Locale.LanguageCode("he"))
        hebrew.firstName = "ADI"

        // Act
        self.testSubject.sections = [english, hebrew]

        // Verify
        XCTAssertFalse(self.testSubject.isSkipped(.firstName, in: english))
        XCTAssertFalse(self.testSubject.isSkipped(.surname, in: english))
        XCTAssertTrue(self.testSubject.isSkipped(.street, in: english))
        XCTAssertTrue(self.testSubject.isSkipped(.firstName, in: hebrew))
        XCTAssertEqual(self.testSubject.newFilterTexts, ["Adi", "Herzl"])
    }

    func test_skippedNote_namesAllowedAndRepeatedTexts() {
        // Prepare
        var english = StayReachableView.LanguageSection(language: .english)
        english.firstName = "Adi"
        english.surname = "Cohen"
        english.street = "Cohen"
        self.persistenceManager.filterTextsClosure = { _, _, _ in
            return ["Adi"]
        }
        self.testSubject = StayReachableView.ViewModel(appManager: self.appManager)

        // Act
        self.testSubject.sections = [english]

        // Verify
        XCTAssertEqual(self.testSubject.skippedNote(for: english), "\u{2068}Adi\u{2069} is already allowed. \u{2068}Cohen\u{2069} is entered twice.")
        XCTAssertEqual(self.testSubject.skippedNote(for: StayReachableView.LanguageSection(language: .english)), "")
    }

    func test_skippedNote_namesEachTextOnce() {
        // Prepare
        var english = StayReachableView.LanguageSection(language: .english)
        english.firstName = "Aaa"
        english.surname = "aaa"
        english.street = "Aaa"
        self.persistenceManager.filterTextsClosure = { _, _, _ in
            return ["Aaa", "aaa"]
        }
        self.testSubject = StayReachableView.ViewModel(appManager: self.appManager)

        // Act
        self.testSubject.sections = [english]

        // Verify
        XCTAssertEqual(self.testSubject.skippedNote(for: english), "\u{2068}Aaa\u{2069} is already allowed.")
    }

    func test_sectionLabels_followTheSectionLanguage() {
        // Prepare
        let polish = StayReachableView.LanguageSection(language: Locale.LanguageCode("pl"))
        let persian = StayReachableView.LanguageSection(language: Locale.LanguageCode("fa"))
        let hebrew = StayReachableView.LanguageSection(language: Locale.LanguageCode("he"))
        let klingon = StayReachableView.LanguageSection(language: Locale.LanguageCode("tlh"))

        // Verify
        XCTAssertEqual(self.testSubject.title(for: .firstName, in: polish), "Imię")
        XCTAssertEqual(self.testSubject.title(for: polish), Locale.LanguageCode("pl").nativeName)
        XCTAssertEqual(self.testSubject.layoutDirection(for: polish), .leftToRight)
        XCTAssertEqual(self.testSubject.prompt(for: .street, in: persian), "فقط نام، بدون پلاک")
        XCTAssertEqual(self.testSubject.layoutDirection(for: persian), .rightToLeft)
        XCTAssertEqual(self.testSubject.title(for: .street, in: hebrew), "רחוב")
        XCTAssertEqual(self.testSubject.title(for: .street, in: klingon), "stayReachable_street"~)
        XCTAssertEqual(self.testSubject.title(for: klingon), Locale.LanguageCode("tlh").displayName)
        XCTAssertNil(self.testSubject.layoutDirection(for: klingon))
    }

    func test_init_loadsAllowedTextsOnce() {
        // Prepare
        var english = StayReachableView.LanguageSection(language: .english)
        english.firstName = "Adi"
        english.surname = "Cohen"
        var requestedRule: (FilterTarget, FilterMatching, FilterCase)?
        self.persistenceManager.filterTextsClosure = { target, matching, filterCase in
            requestedRule = (target, matching, filterCase)
            return ["Adi"]
        }
        self.persistenceManager.resetCounters()

        // Act
        self.testSubject = StayReachableView.ViewModel(appManager: self.appManager)
        self.testSubject.sections = [english]
        let newFilterTexts = self.testSubject.newFilterTexts
        let skippedNote = self.testSubject.skippedNote(for: english)

        // Verify
        XCTAssertEqual(newFilterTexts, ["Cohen"])
        XCTAssertFalse(skippedNote.isEmpty)
        XCTAssertEqual(self.persistenceManager.filterTextsCounter, 1)
        XCTAssertEqual(self.persistenceManager.isDuplicateFilterCounter, 0)
        XCTAssertEqual(requestedRule?.0, .all)
        XCTAssertEqual(requestedRule?.1, .exact)
        XCTAssertEqual(requestedRule?.2, .caseInsensitive)
    }

    func test_addFilters_addsExactCaseInsensitiveAllowFilters() {
        // Prepare
        var english = StayReachableView.LanguageSection(language: .english)
        english.firstName = "Adi"
        english.street = "Herzl"
        self.testSubject.sections = [english]
        var addedTexts: [String] = []
        self.persistenceManager.addFilterClosure = { text, type, _, target, matching, filterCase in
            XCTAssertEqual(type, .allow)
            XCTAssertEqual(target, .all)
            XCTAssertEqual(matching, .exact)
            XCTAssertEqual(filterCase, .caseInsensitive)
            addedTexts.append(text)
        }

        // Act
        self.testSubject.addFilters()

        // Verify
        XCTAssertEqual(addedTexts, ["Adi", "Herzl"])
    }

    func test_addAndRemoveSection_updatesUnusedLanguages() {
        // Prepare
        let french = Locale.LanguageCode("fr")
        self.testSubject.sections = [StayReachableView.LanguageSection(language: .english)]

        // Act
        self.testSubject.addSection(language: french)
        let unusedAfterAdd = self.testSubject.unusedLanguages(in: [french])
        let frenchSection = self.testSubject.sections[1]
        self.testSubject.removeSection(frenchSection)

        // Verify
        XCTAssertFalse(unusedAfterAdd.contains(french))
        XCTAssertEqual(self.testSubject.unusedLanguages(in: [french]), [french])
    }

    func test_languageChoices_keepOwnLanguageAndSkipOthers() {
        // Prepare
        let french = Locale.LanguageCode("fr")
        let german = Locale.LanguageCode("de")
        let frenchSection = StayReachableView.LanguageSection(language: french)
        let germanSection = StayReachableView.LanguageSection(language: german)
        self.testSubject.sections = [frenchSection, germanSection]

        // Act
        let choices = self.testSubject.languageChoices(in: [french, german], for: frenchSection)

        // Verify
        XCTAssertEqual(choices, [french])
    }

    func test_setLanguage_changesOnlyThatSection() {
        // Prepare
        let french = Locale.LanguageCode("fr")
        let german = Locale.LanguageCode("de")
        let frenchSection = StayReachableView.LanguageSection(language: french)
        self.testSubject.sections = [StayReachableView.LanguageSection(language: .english), frenchSection]

        // Act
        self.testSubject.setLanguage(german, for: frenchSection)

        // Verify
        XCTAssertEqual(self.testSubject.sections.map(\.language), [.english, german])
    }
}
