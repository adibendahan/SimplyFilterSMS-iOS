//
//  BlockLanguageView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/11/2026.
//

import SwiftUI
import NaturalLanguage


//MARK: - View -
struct BlockLanguageView: View, ViewWithPersistentStoreReload {

    @Environment(\.dismiss)
    var dismiss

    @ObservedObject var model: ViewModel

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(self.model.languages) { language in
                        if let localizedName = language.localizedName {
                            Button {
                                self.model.addFilter(language: language)
                                dismiss()
                            } label: {
                                Text(localizedName)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                } header: {
                    if !self.model.languages.isEmpty {
                        Text("lang_supported"~)
                    }
                } // Section
            } // List
            .listStyle(.insetGrouped)
            .navigationTitle("filterList_menu_filterLanguage"~)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .tint(.primary)
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier(TestIdentifier.closeButton.rawValue)
                }
            }
            .modifier(persistentStoreReload)
        } // NavigationView
    }
}


//MARK: - ViewModel -
extension BlockLanguageView {

    class ViewModel: BaseViewModel, ObservableObject, Identifiable, PersistentStoreReloadRefreshing {
        let id = UUID()
        @Published private(set) var languages: [NLLanguage]
        private let onAdded: ((Filter) -> Void)?

        init(onAdded: ((Filter) -> Void)? = nil,
             appManager: AppManagerProtocol = AppManager.shared) {
            self.onAdded = onAdded
            self.languages = appManager.persistenceManager.blockableLanguages()

            super.init(appManager: appManager)
        }

        func refresh() {
            self.languages = self.appManager.persistenceManager.blockableLanguages()
        }

        func addFilter(language: NLLanguage) {
            let filter = self.appManager.persistenceManager.addFilter(text: language.filterText,
                                                                      type: .denyLanguage,
                                                                      denyFolder: .junk,
                                                                      filterTarget: .body,
                                                                      filterMatching: .contains,
                                                                      filterCase: .caseInsensitive)
            if let filter {
                self.onAdded?(filter)
            }
        }
    }
}


//MARK: - Preview -
struct BlockLanguageView_Previews: PreviewProvider {
    static var previews: some View {
        BlockLanguageView(model: BlockLanguageView.ViewModel(appManager: AppManager.previews))
    }
}
