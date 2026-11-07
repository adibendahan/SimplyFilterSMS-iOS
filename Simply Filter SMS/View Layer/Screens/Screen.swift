//
//  Screen.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 05/02/2022.
//

import SwiftUI

enum Screen: Int, Identifiable, Hashable {
    var id: Self { self }

    case appHome, onboarding, help, about, enableExtension, filterTester,
         addLanguageFilter, addAllowFilter, addDenyFilter, filterLists,
         denyFilters, allowFilters, denyLanguageFilters, reportMessage,
         whatsNew, tipJar, countryList, enableReportingExtension, filterImport,
         chooseAccentColor, filterExport

    @ViewBuilder func build() -> some View {
        Group {
            switch self {
            case .appHome:
                AppHomeView(model: AppHomeView.ViewModel())

            case .onboarding, .enableExtension:
                EnableExtensionView(model: EnableExtensionView.ViewModel(
                    steps: Array(EnableFilterExtensionStep.allCases),
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

            case .filterTester:
                FilterTesterView(model: FilterTesterView.ViewModel())

            case .addLanguageFilter:
                BlockLanguageView(model: BlockLanguageView.ViewModel())

            case .addAllowFilter:
                AddFilterView(model: AddFilterView.ViewModel(filterType: .allow))

            case .addDenyFilter:
                AddFilterView(model: AddFilterView.ViewModel(filterType: .deny))

            case .filterLists:
                FilterListLanguagesView(model: FilterListLanguagesView.ViewModel())

            case .denyFilters:
                FiltersView(model: FiltersView.ViewModel(filterType: .deny))

            case .allowFilters:
                FiltersView(model: FiltersView.ViewModel(filterType: .allow))

            case .denyLanguageFilters:
                FiltersView(model: FiltersView.ViewModel(filterType: .denyLanguage))

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

            case .filterImport:
                FilterTransferPreviewView(model: FilterTransferPreviewView.ViewModel())

            case .chooseAccentColor:
                ChooseAccentColorView(model: ChooseAccentColorView.ViewModel())

            case .filterExport:
                FilterTransferPreviewView(model: FilterTransferPreviewView.ViewModel())
            }
        }
        .adaptiveLayoutEnvironment()
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
        case .filterTester:
            return "filterTester"
        case .addLanguageFilter:
            return "addLanguageFilter"
        case .addAllowFilter:
            return "addAllowFilter"
        case .addDenyFilter:
            return "addDenyFilter"
        case .filterLists:
            return "filterLists"
        case .denyFilters:
            return "denyFilters"
        case .allowFilters:
            return "allowFilters"
        case .denyLanguageFilters:
            return "denyLanguageFilters"
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
        case .filterImport:
            return "filterImport"
        case .chooseAccentColor:
            return "chooseAccentColor"
        case .filterExport:
            return "filterExport"
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
            return .filterTester
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
            return .denyFilters
        case .allow:
            return .allowFilters
        case .denyLanguage:
            return .denyLanguageFilters
        }
    }
}
