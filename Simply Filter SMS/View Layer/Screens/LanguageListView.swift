//
//  LanguageListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 11/01/2022.
//

import SwiftUI
import NaturalLanguage
import CoreData
import CryptoKit


//MARK: - View -
struct LanguageListView: View {
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @Environment(\.dismiss)
    var dismiss
    
    @ObservedObject var model: ViewModel
    
    var body: some View {
        switch self.model.mode {
        case .blockLanguage:
            NavigationView {
                self.makeBody()
            }
            .modifier(EmbeddedFooterView(onTap: { self.model.sheetScreen = .about }))
        case .automaticBlocking:
            self.makeBody()
        }
    }
    
    @ViewBuilder
    func makeBody() -> some View {
        List {
            Section {
                ForEach (self.model.languages.indices, id: \.self) { index in
                    let language = model.languages[index].item
                    
                    if let localizedName = language.localizedName {
                        switch self.model.mode {
                        case .blockLanguage:
                            Button {
                                self.model.addFilter(language: language)
                                dismiss()
                            } label: {
                                Text(localizedName)
                                    .foregroundColor(.primary)
                            }
                            
                        case .automaticBlocking:
                            Toggle(localizedName, isOn: $model.languages[index].state)
                                .tint(.accentColor)
                        }
                    }
                }
                
                if self.model.mode == .automaticBlocking &&
                    self.model.languages.count == 0 {
                    
                    if !self.model.isLoading {
                        HStack (spacing: 12) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 30))
                                .foregroundColor(.red)

                            if self.model.isOnline {
                                Text(.init("autoFilter_error"~))
                                    .padding(.vertical, 16)
                            }
                            else {
                                Text(.init("autoFilter_empty"~))
                                    .padding(.vertical, 16)
                            }
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
                VStack {
                    Text(.init(self.model.footer))
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    if let helpText = self.model.footerSecondLine {
                        Spacer(minLength: 20)
                        
                        Text(helpText)
                            .multilineTextAlignment(.leading)
                    }
                }
            } // Section
        } // List
        .listStyle(.insetGrouped)
        .navigationTitle(self.model.title)
        .navigationBarTitleDisplayMode(self.model.mode == .blockLanguage ? .large : .inline)
        .toolbar {
            ToolbarItem {
                Button {
                    dismiss()
                } label: {
                    switch self.model.mode {
                    case .blockLanguage:
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                        
                    case .automaticBlocking:
                        EmptyView()
                    }
                }
                .contentShape(Rectangle())
                .accessibilityIdentifier(TestIdentifier.closeButton.rawValue)
            }
        }
        .sheet(item: $model.sheetScreen) { } content: { sheetScreen in
            sheetScreen.build()
        }
        .if(self.model.shouldAllowRefresh) {
            $0.refreshable(action: self.model.forceUpdateFilters)
        }
    }
}


//MARK: - ViewModel -
extension LanguageListView {
    
    enum Mode {
        case blockLanguage, automaticBlocking
    }
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var mode: LanguageListView.Mode
        @Published private(set) var title: String
        @Published private(set) var footer: String
        @Published private(set) var lastUpdate: Date?
        @Published private(set) var footerSecondLine: String?
        @Published private(set) var autoFilterErrorText: String
        @Published private(set) var isLoading: Bool
        @Published private(set) var isOnline: Bool
        @Published private(set) var shouldAllowRefresh: Bool
        @Published var languages: [StatefulItem<NLLanguage>] = []
        @Published var sheetScreen: Screen? = nil
        
        init(mode: LanguageListView.Mode,
             appManager: AppManagerProtocol = AppManager.shared) {
            
            let cacheAge = appManager.automaticFilterManager.automaticFiltersCacheAge ?? nil
            let isOnline = appManager.networkSyncManager.networkStatus == .online
            
            self.mode = mode
            self.lastUpdate = cacheAge
            self.footer = ViewModel.updatedFooter(for: mode, cacheAge: cacheAge)
            self.isLoading = false
            self.isOnline = isOnline
            
            switch mode {
            case .automaticBlocking:
                self.title = "autoFilter_title"~
                self.footerSecondLine = "help_automaticFiltering"~
            case .blockLanguage:
                self.title = "filterList_menu_filterLanguage"~
                self.footerSecondLine = nil
            }

            self.languages = appManager.automaticFilterManager.languages(for: mode)
                .map({ StatefulItem<NLLanguage>(item: $0,
                                                getter: appManager.automaticFilterManager.languageAutomaticState,
                                                setter: appManager.automaticFilterManager.setLanguageAutmaticState) })
            

            if isOnline {
                self.autoFilterErrorText = "autoFilter_error"~
            }
            else {
                self.autoFilterErrorText = "autoFilter_empty"~
            }
            
            if mode == .automaticBlocking,
               let lastUpdate = cacheAge,
               lastUpdate.daysBetween(date: Date()) > 0 {
                
                self.shouldAllowRefresh = true
            }
            else {
                self.shouldAllowRefresh = false
            }
            
            super.init(appManager: appManager)
            
            if mode == .automaticBlocking {
                
                if !isOnline && self.languages.isEmpty {
                    NotificationCenter.default.addObserver(forName: .networkStatusChange, object: nil, queue: .main) { [weak self] notification in
                        guard let networkStatus = notification.object as? NetworkStatus else { return }
                        
                        if networkStatus == .online {
                            appManager.automaticFilterManager.updateAutomaticFiltersIfNeeded()
                            self?.isLoading = true
                        }
                        else {
                            self?.autoFilterErrorText = "autoFilter_empty"~
                            self?.isLoading = false
                        }
                    }
                }
                
                NotificationCenter.default.addObserver(forName: .automaticFiltersUpdated, object: nil, queue: .main) { [weak self] _ in
                    withAnimation {
                        guard let self = self else { return }
                        self.refresh()
                        self.isLoading = false
                    }
                }
            }
        }
        
        private static func updatedFooter(for mode: LanguageListView.Mode, cacheAge: Date?) -> String {
            switch mode {
            case .blockLanguage:
                return "lang_how"~
                
            case .automaticBlocking:
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "ddMMyyyy HHmm", options: 0, locale: Locale.current)
                
                
                if let date = cacheAge {
                    return String(format: "autoFilter_lastUpdated"~, formatter.string(from: date))
                }
                else
                {
                    return ""
                }
            }
        }
        
        func refresh() {
            let cacheAge = self.appManager.automaticFilterManager.automaticFiltersCacheAge ?? nil
            
            self.lastUpdate = cacheAge
            self.footer = ViewModel.updatedFooter(for: self.mode, cacheAge: cacheAge)
            self.languages = self.appManager.automaticFilterManager.languages(for: self.mode)
                .map({ StatefulItem<NLLanguage>(item: $0,
                                                getter: self.appManager.automaticFilterManager.languageAutomaticState,
                                                setter: self.appManager.automaticFilterManager.setLanguageAutmaticState) })
            
            if self.mode == .automaticBlocking,
               let lastUpdate = self.lastUpdate,
               lastUpdate.daysBetween(date: Date()) > 0 {
                
                self.shouldAllowRefresh = true
            }
            else {
                self.shouldAllowRefresh = false
            }
        }
        
        func addFilter(language: NLLanguage) {
            self.appManager.persistanceManager.addFilter(text: language.filterText,
                                                         type: .denyLanguage,
                                                         denyFolder: .junk,
                                                         filterTarget: .body,
                                                         filterMatching: .contains,
                                                         filterCase: .caseInsensitive)
        }
        
        @Sendable func forceUpdateFilters() async {
            try? await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
            await self.appManager.automaticFilterManager.forceUpdateAutomaticFilters()
            
            DispatchQueue.main.async {
                self.refresh()
            }
        }
    }
}


//MARK: - Preview -
struct LanguageListView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageListView(model: LanguageListView.ViewModel(mode: .blockLanguage, appManager: AppManager.previews))
        
        NavigationView {
            LanguageListView(model: LanguageListView.ViewModel(mode: .automaticBlocking, appManager: AppManager.previews))
        }
    }
}
