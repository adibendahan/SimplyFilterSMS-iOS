//
//  Screen.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 05/02/2022.
//

import SwiftUI

enum Screen: Int, Identifiable, Hashable {
    var id: Self { self }

    case appHome, onboarding, help, about, enableExtension, testFilters,
         addLanguageFilter, addAllowFilter, addDenyFilter, automaticBlocking,
         denyFilterList, allowFilterList, denyLanguageFilterList, reportMessage,
         whatsNew, tipJar, countryList, enableReportingExtension

    @ViewBuilder func build() -> some View {
        switch self {
        case .appHome:
            AppHomeView(model: AppHomeView.ViewModel())

        case .onboarding:
            EnableExtensionView(model: EnableExtensionView.ViewModel(
                steps: Array(EnableExtensionStep.allCases),
                isInteractiveDismissDisabled: true,
                onDismiss: {
                    var defaultsManager = AppManager.shared.defaultsManager
                    defaultsManager.isAppFirstRun = false
                },
                onCTA: {
                    var defaultsManager = AppManager.shared.defaultsManager
                    defaultsManager.isAppFirstRun = false
                    UIApplication.shared.openSettings()
                }
            ))

        case .help:
            HelpView(model: HelpView.ViewModel())

        case .about:
            AboutView(model: AboutView.ViewModel())

        case .enableExtension:
            EnableExtensionView(model: EnableExtensionView.ViewModel(
                steps: Array(EnableExtensionStep.allCases),
                isInteractiveDismissDisabled: true,
                onDismiss: {
                    var defaultsManager = AppManager.shared.defaultsManager
                    defaultsManager.isAppFirstRun = false
                },
                onCTA: {
                    var defaultsManager = AppManager.shared.defaultsManager
                    defaultsManager.isAppFirstRun = false
                    UIApplication.shared.openSettings()
                }
            ))

        case .testFilters:
            TestFiltersView(model: TestFiltersView.ViewModel())

        case .addLanguageFilter:
            LanguageListView(model: LanguageListView.ViewModel(mode: .blockLanguage))

        case .addAllowFilter:
            AddFilterView(model: AddFilterView.ViewModel(filterType: .allow))

        case .addDenyFilter:
            AddFilterView(model: AddFilterView.ViewModel(filterType: .deny))

        case .automaticBlocking:
            LanguageListView(model: LanguageListView.ViewModel(mode: .automaticBlocking))

        case .denyFilterList:
            FilterListView(model: FilterListView.ViewModel(filterType: .deny))

        case .allowFilterList:
            FilterListView(model: FilterListView.ViewModel(filterType: .allow))

        case .denyLanguageFilterList:
            FilterListView(model: FilterListView.ViewModel(filterType: .denyLanguage))

        case .reportMessage:
            ReportMessageView(model: ReportMessageView.ViewModel())

        case .whatsNew:
            WhatsNewView(model: WhatsNewView.ViewModel())

        case .tipJar:
            TipJarView(model: TipJarView.ViewModel())

        case .countryList:
            CountryListView(model: CountryListView.ViewModel())

        case .enableReportingExtension:
            EnableExtensionView(model: EnableExtensionView.ViewModel(
                steps: Array(EnableReportingExtensionStep.allCases),
                title: "autoFilter_improveAIFiltering"~,
                description: "enableReportingExtension_desc"~,
                isInteractiveDismissDisabled: false,
                onDismiss: {},
                onCTA: UIApplication.shared.openSettings
            ))
        }
    }

    var tag: String {
        switch self {
        case .appHome:
            return "appHome"
        case .onboarding:
            return "onboarding"
        case .help:
            return "help"
        case .about:
            return "about"
        case .enableExtension:
            return "enableExtension"
        case .testFilters:
            return "testFilters"
        case .addLanguageFilter:
            return "addLanguageFilter"
        case .addAllowFilter:
            return "addAllowFilter"
        case .addDenyFilter:
            return "addDenyFilter"
        case .automaticBlocking:
            return "automaticBlocking"
        case .denyFilterList:
            return "denyFilterList"
        case .allowFilterList:
            return "allowFilterList"
        case .denyLanguageFilterList:
            return "denyLanguageFilterList"
        case .reportMessage:
            return "reportMessage"
        case .whatsNew:
            return "whatsNew"
        case .tipJar:
            return "tipJar"
        case .countryList:
            return "countryList"
        case .enableReportingExtension:
            return "enableReportingExtension"
        }
    }
}

extension Screen {
    static func fromDeepLink(host: String) -> Screen? {
        switch host {
        case "enable-extension":
            return .enableExtension
        case "enable-reporting-extension":
            return .enableReportingExtension
        case "test-filters":
            return .testFilters
        case "tip-jar":
            return .tipJar
        default:
            return nil
        }
    }
}

extension FilterType {
    var screen: Screen {
        switch self {
        case .deny:
            return .denyFilterList
        case .allow:
            return .allowFilterList
        case .denyLanguage:
            return .denyLanguageFilterList
        }
    }
}
