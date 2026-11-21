//
//  FilterListLanguagesView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 11/01/2022.
//

import SwiftUI
import NaturalLanguage


//MARK: - View -
struct FilterListLanguagesView: View, ViewWithPersistentStoreReload {

    @ObservedObject var model: ViewModel

    @State private var headerCollapse: CGFloat = 0

    var body: some View {
        List {
            Section {
                FeatureStatusHeader(feature: .aiFiltering,
                                    isOn: self.model.activeLanguagesCount > 0,
                                    badgeTitle: self.model.badgeTitle,
                                    badgeOnWidthSamples: self.model.badgeOnWidthSamples,
                                    badgeOffTitle: self.model.badgeOffTitle,
                                    collapseProgress: self.headerCollapse)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))

            Section {
                ForEach (self.model.languages.indices, id: \.self) { index in
                    let language = model.languages[index].item

                    if let localizedName = language.localizedName {
                        let nativeName = self.model.nativeNames[language]
                        let ruleCountText = self.model.ruleCountTexts[language]
                        let spokenParts = [localizedName, nativeName, ruleCountText].compactMap { $0 }

                        AdaptiveToggle(isOn: $model.languages[index].state) {
                            self.languageLabel(name: localizedName, nativeName: nativeName, ruleCountText: ruleCountText)
                                .accessibilityLabel(spokenParts.joined(separator: ", "))
                        }
                        .accessibilityIdentifier("\(TestIdentifier.filterListLanguageToggle.rawValue)-\(language.rawValue)")
                        .settle(delay: LanguagesMotion.rowDelay(for: index))
                    }
                }

                if self.model.languages.isEmpty {
                    if !self.model.isLoading {
                        if self.model.isOnline {
                            ContentUnavailableView("autoFilter_errorTitle"~,
                                                   systemImage: "wifi.exclamationmark",
                                                   description: Text("autoFilter_error"~))
                        } else {
                            ContentUnavailableView("autoFilter_offlineTitle"~,
                                                   systemImage: "wifi.slash",
                                                   description: Text("autoFilter_empty"~))
                        }
                    }
                    else {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }

            } header: {
                if !self.model.languages.isEmpty {
                    Text("lang_supported"~)
                }
            } footer: {
                Text(self.model.footer)
                    .multilineTextAlignment(.leading)
                    .settle(delay: LanguagesMotion.footerDelay)
            } // Section

            Section {
                Button {
                    self.model.sheetScreen = .enableReportingExtension
                } label: {
                    HStack {
                        Label {
                            Text("autoFilter_improveAIFiltering"~)
                        } icon: {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(.indigo)
                        }

                        Spacer()

                        Image(systemName: "chevron.forward")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(.primary)
                .settle(delay: LanguagesMotion.footerDelay)
            } footer: {
                Text("autoFilter_improveFooter"~)
                    .multilineTextAlignment(.leading)
                    .settle(delay: LanguagesMotion.footerDelay)
            } // Section
        } // List
        .modifier(FeatureStatusHeader.CollapseTracker(progress: self.$headerCollapse))
        .contentMargins(.top, 8, for: .scrollContent)
        .listStyle(.insetGrouped)
        .navigationTitle("autoFilter_title"~)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        self.model.sheetScreen = .enableReportingExtension
                    } label: {
                        Label("autoFilter_improveAIFiltering"~, systemImage: "wand.and.stars")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .tint(.primary)
                .accessibilityLabel("a11y_home_menuButton"~)
            }
        }
        .sheet(item: $model.sheetScreen) { $0.build() }
        .refreshable(action: self.model.updateFilters)
        .onAppear {
            self.model.startMonitoring()
        }
        .modifier(persistentStoreReload)
    }


    //MARK: - Private -
    private func languageLabel(name: String, nativeName: String?, ruleCountText: String?) -> Text {
        var label = Text(name)
        if let nativeName {
            let separator = Text(" / ")
                .font(.footnote)
                .foregroundStyle(.primary)
            let nativeNameText = Text(nativeName)
                .font(.footnote)
                .foregroundStyle(.primary)
            label = label + separator + nativeNameText
        }
        if let ruleCountText {
            let countText = Text(" (\(ruleCountText))")
                .font(.footnote)
                .foregroundStyle(.secondary)
            label = label + countText
        }
        return label
    }
}


//MARK: - Motion -
private enum LanguagesMotion {
    static let footerDelay: Double = 0.5
    static let rise: CGFloat = 10
    static let blur: CGFloat = 6
    static let settleAnimation = Animation.spring(response: 0.6, dampingFraction: 0.85)

    static func rowDelay(for index: Int) -> Double {
        return Stagger.delay(for: index, step: 0.04, base: 0.3, limit: 5)
    }
}

private extension View {
    func settle(delay: Double) -> some View {
        return self.entranceOnAppear(delay: delay, rise: LanguagesMotion.rise, blur: LanguagesMotion.blur, animation: LanguagesMotion.settleAnimation)
    }
}


//MARK: - ViewModel -
extension FilterListLanguagesView {

    class ViewModel: BaseViewModel, @unchecked Sendable, ObservableObject, PersistentStoreReloadRefreshing {
        @Published private(set) var lastUpdated: String
        private var ruleCounts: [NLLanguage: Int]
        @Published private(set) var nativeNames: [NLLanguage: String] = [:]
        @Published private(set) var ruleCountTexts: [NLLanguage: String] = [:]
        @Published private(set) var isLoading: Bool
        @Published private(set) var isOnline: Bool
        @Published var languages: [StatefulItem<NLLanguage>] = []
        @Published var sheetScreen: Screen? = nil {
            didSet {
                guard oldValue != self.sheetScreen else { return }
                Log.debug("sheet changed, screen: \(oldValue) → \(self.sheetScreen)")
            }
        }
        private var didAddObservers = false

        override init(appManager: AppManagerProtocol = AppManager.shared) {
            let lastUpdated = appManager.filterListManager.filterListsLastUpdated

            self.lastUpdated = lastUpdated?.lastUpdatedText ?? ""
            self.ruleCounts = appManager.filterListManager.filterListRuleCounts
            self.isLoading = false
            self.isOnline = appManager.networkSyncManager.networkStatus == .online

            super.init(appManager: appManager)
            self.languages = self.makeLanguages()
            self.nativeNames = self.makeNativeNames()
            self.ruleCountTexts = self.makeRuleCountTexts()
        }

        var activeLanguagesCount: Int {
            return self.languages.filter(\.state).count
        }

        var headline: String {
            return String.localizedStringWithFormat("autoFilter_languagesOn"~, self.activeLanguagesCount)
        }

        var badgeTitle: StatusBadge.Title {
            return StatusBadge.Title(text: self.headline, count: self.activeLanguagesCount)
        }

        var badgeOnWidthSamples: [String] {
            let sampleCounts = [1, max(self.languages.count, 1)]
            let samples = sampleCounts.map { String.localizedStringWithFormat("autoFilter_languagesOn"~, $0) }
            return samples.uniqued()
        }

        var badgeOffTitle: String {
            return String.localizedStringWithFormat("autoFilter_languagesOn"~, 0)
        }

        var footer: String {
            let activeLanguagesCount = self.activeLanguagesCount
            var activeRuleCount = 0
            for statefulLanguage in self.languages where statefulLanguage.state {
                activeRuleCount += self.ruleCounts[statefulLanguage.item] ?? 0
            }

            let summary: String
            if activeLanguagesCount == 0 {
                summary = "autoFilter_turnOnHint"~
            }
            else if activeRuleCount > 0 {
                summary = String.localizedStringWithFormat("autoFilter_rulesFromLanguages"~, activeRuleCount, activeLanguagesCount)
            }
            else {
                summary = ""
            }

            let parts = [summary, self.lastUpdated].filter { !$0.isEmpty }
            return parts.joined(separator: ". ")
        }

        func startMonitoring() {
            guard !didAddObservers else { return }
            didAddObservers = true

            if !isOnline && self.languages.isEmpty {
                Log.debug("offline with no languages → refresh when back online")
                NotificationCenter.default.addObserver(forName: .networkStatusChange, object: nil, queue: .main) { [weak self] notification in
                    guard let networkStatus = notification.object as? NetworkStatus else { return }

                    if networkStatus == .online {
                        Log.debug("back online → refreshing")
                        Task(priority: .background) {
                            await self?.appManager.filterListManager.refreshFilterLists()
                        }
                        self?.isLoading = true
                    }
                    else {
                        self?.isLoading = false
                    }
                }
            }

            NotificationCenter.default.addObserver(forName: .filterListsUpdated, object: nil, queue: .main) { [weak self] _ in
                withAnimation {
                    guard let self = self else { return }
                    self.refresh()
                    self.isLoading = false
                }
            }
        }

        func refresh() {
            let lastUpdated = self.appManager.filterListManager.filterListsLastUpdated

            self.lastUpdated = lastUpdated?.lastUpdatedText ?? ""
            self.ruleCounts = self.appManager.filterListManager.filterListRuleCounts
            self.languages = self.makeLanguages()
            self.nativeNames = self.makeNativeNames()
            self.ruleCountTexts = self.makeRuleCountTexts()
        }

        @Sendable func updateFilters() async {
            Log.debug("pull to refresh")
            try? await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
            await self.appManager.filterListManager.refreshFilterLists()

            Task {
                DispatchQueue.main.async {
                    self.refresh()
                }
            }

        }

        private func makeLanguages() -> [StatefulItem<NLLanguage>] {
            let filterListManager = self.appManager.filterListManager
            return filterListManager.filterListLanguages
                .map({ StatefulItem<NLLanguage>(item: $0,
                                                getter: filterListManager.isFilterListActive,
                                                setter: self.setFilterListActive) })
        }

        private func makeNativeNames() -> [NLLanguage: String] {
            var nativeNames: [NLLanguage: String] = [:]

            for statefulLanguage in self.languages {
                let language = statefulLanguage.item
                guard let nativeName = language.nativeName, nativeName != language.localizedName else { continue }
                nativeNames[language] = nativeName
            }

            return nativeNames
        }

        private func makeRuleCountTexts() -> [NLLanguage: String] {
            var ruleCountTexts: [NLLanguage: String] = [:]

            for statefulLanguage in self.languages {
                let language = statefulLanguage.item
                guard let ruleCount = self.ruleCounts[language], ruleCount > 0 else { continue }
                ruleCountTexts[language] = String.localizedStringWithFormat("autoFilter_ruleCount"~, ruleCount)
            }

            return ruleCountTexts
        }

        private func setFilterListActive(for language: NLLanguage, value: Bool) {
            self.appManager.filterListManager.setFilterListActive(for: language, value: value)
            if value {
                self.appManager.flowManager.offerStayReachable()
            }
        }
    }
}


//MARK: - Preview -
struct FilterListLanguagesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FilterListLanguagesView(model: FilterListLanguagesView.ViewModel(appManager: AppManager.previews))
        }
    }
}
