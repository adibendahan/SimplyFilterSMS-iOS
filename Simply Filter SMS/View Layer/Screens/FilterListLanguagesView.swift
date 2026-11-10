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

    @ScaledMetric(relativeTo: .title) private var errorIconSize: CGFloat = 30
    @ScaledMetric(relativeTo: .body) private var footerIconSize: CGFloat = 20

    @ObservedObject var model: ViewModel

    var body: some View {
        List {
            Section {
                ForEach (self.model.languages.indices, id: \.self) { index in
                    let language = model.languages[index].item

                    if let localizedName = language.localizedName {
                        AdaptiveToggle(isOn: $model.languages[index].state) {
                            Text(localizedName)
                        }
                    }
                }

                if self.model.languages.isEmpty {
                    if !self.model.isLoading {
                        AdaptiveRow {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: errorIconSize))
                                .foregroundColor(.red)
                                .accessibilityHidden(true)
                                .adaptiveIconColumn()
                        } content: {
                            if self.model.isOnline {
                                Text(.init("autoFilter_error"~))
                            } else {
                                Text(.init("autoFilter_empty"~))
                            }
                        }
                        .padding(.vertical, 16)
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
                VStack(alignment: .leading) {
                    Text((self.model.footer.isEmpty ? "" : self.model.footer + ". ") + "help_automaticFiltering"~)
                        .multilineTextAlignment(.leading)

                    Button {
                        self.model.sheetScreen = .enableReportingExtension
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .imageScale(.large)
                                .font(.system(size: self.footerIconSize, weight: .bold))
                            Text("autoFilter_improveAIFiltering"~)
                                .font(.body)
                        }
                    }
                    .buttonStyle(AccessibleTextButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                    .padding(.bottom, 48)
                }
            } // Section
        } // List
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
                    Image(systemName: "ellipsis.circle")
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
}


//MARK: - ViewModel -
extension FilterListLanguagesView {

    class ViewModel: BaseViewModel, @unchecked Sendable, ObservableObject, PersistentStoreReloadRefreshing {
        @Published private(set) var footer: String
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

            self.footer = ViewModel.makeFooter(lastUpdated: lastUpdated)
            self.isLoading = false
            self.isOnline = appManager.networkSyncManager.networkStatus == .online
            self.languages = ViewModel.makeLanguages(appManager: appManager)

            super.init(appManager: appManager)
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

            self.footer = ViewModel.makeFooter(lastUpdated: lastUpdated)
            self.languages = ViewModel.makeLanguages(appManager: self.appManager)
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

        private static func makeLanguages(appManager: AppManagerProtocol) -> [StatefulItem<NLLanguage>] {
            let filterListManager = appManager.filterListManager
            return filterListManager.filterListLanguages
                .map({ StatefulItem<NLLanguage>(item: $0,
                                                getter: filterListManager.isFilterListActive,
                                                setter: filterListManager.setFilterListActive) })
        }

        private static func makeFooter(lastUpdated: Date?) -> String {
            guard let lastUpdated else { return "" }

            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "ddMMyyyy HHmm", options: 0, locale: Locale.current)
            return String(format: "autoFilter_lastUpdated"~, formatter.string(from: lastUpdated))
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
