//
//  HelpViewModelTests.swift
//  Tests
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class HelpViewModelTests: XCTestCase {

    private var appManager = mock_AppManager()
    private var defaultsManager = mock_DefaultsManager()

    override func setUp() {
        super.setUp()
        let appManager = mock_AppManager()
        let defaultsManager = mock_DefaultsManager()
        appManager.defaultsManager = defaultsManager
        self.appManager = appManager
        self.defaultsManager = defaultsManager
    }

    private func makeViewModel() -> HelpView.ViewModel {
        HelpView.ViewModel(appManager: self.appManager)
    }

    func test_siriTips_startOnOneOfTheTips() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.showsSiriTips)
        let slot = try! XCTUnwrap(vm.siriTipSlot)
        XCTAssertTrue((HelpSiriTip.allCases.count..<HelpSiriTip.allCases.count * 2).contains(slot))
    }

    func test_recenterSiriTips_movesOuterCopyToSameTipInMiddle() {
        let vm = makeViewModel()
        let tipCount = HelpSiriTip.allCases.count
        vm.siriTipSlot = tipCount * 2 + 1
        vm.recenterSiriTips()
        XCTAssertEqual(vm.siriTipSlot, tipCount + 1)
        vm.siriTipSlot = tipCount - 1
        vm.recenterSiriTips()
        XCTAssertEqual(vm.siriTipSlot, tipCount * 2 - 1)
        XCTAssertEqual(vm.currentSiriTip, HelpSiriTip.allCases.last)
    }

    func test_siriTipLanguage_isNotTheDeviceLanguage() {
        let deviceLanguage = Locale.preferredLanguages.first ?? ""
        for _ in 0..<20 {
            let language = makeViewModel().siriTipLanguage
            XCTAssertNotNil(language)
            XCTAssertFalse(deviceLanguage.hasPrefix(language?.id ?? ""))
        }
    }

    func test_siriTips_dismissSavesAndHidesNextTime() {
        let vm = makeViewModel()
        vm.showsSiriTips = false
        XCTAssertTrue(self.defaultsManager.didDismissHelpSiriTips)
        XCTAssertFalse(makeViewModel().showsSiriTips)
    }
}
