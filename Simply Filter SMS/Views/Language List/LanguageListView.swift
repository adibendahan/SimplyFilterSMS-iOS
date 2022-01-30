//
//  LanguageListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 11/01/2022.
//

import SwiftUI
import NaturalLanguage
import CoreData

struct LanguageListView: View {
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @Environment(\.dismiss)
    var dismiss
    
    enum Mode {
        case blockLanguage, automaticBlocking
    }
    
    @StateObject var model: LanguageListViewModel
    
    var body: some View {
        switch self.model.mode {
        case .blockLanguage:
            NavigationView {
                self.makeBody()
            }
        case .automaticBlocking:
            self.makeBody()
        }
    }
    
    func makeBody() -> some View {
        VStack(alignment: .leading) {
            Spacer()
            
            if !self.model.languages.isEmpty {
                List {
                    
                    if !self.model.rules.isEmpty {
                        Section {
                            ForEach($model.rules.indices) { index in
                                let rule = model.rules[index].item
                                
                                Toggle(isOn: $model.rules[index].state) {
                                    HStack {
                                        Image(systemName: rule.icon)
                                            .foregroundColor(rule.iconColor)
                                            .frame(maxWidth: 20, maxHeight: .infinity, alignment: .center)
                                            .font(rule.isDestructive ? Font.body.bold() : .body)
                                        
                                        VStack (alignment: .leading, spacing: 0) {
                                            Text(rule.title)
                                                .font(rule.isDestructive ? Font.body.bold() : .body)
                                            
                                            if let subtitle = rule.subtitle,
                                               let action = rule.action,
                                               let actionTitle = rule.actionTitle {
                                                
                                                HStack (alignment: .center, spacing: 4) {
                                                    Text(String(format: subtitle, self.model.shortSenderChoice))
                                                        .font(.system(size: 10, weight: .light, design: .default))
                                                        .foregroundColor(.secondary)
                                                    
                                                    Menu {
                                                        Text(actionTitle)
                                                        
                                                        Divider()
                                                        
                                                        ForEach(3...6, id: \.self) { index in
                                                            Button {
                                                                self.model.setSelectedChoice(for: rule, choice: index)
                                                            } label: {
                                                                Text("\(index)")
                                                            }
                                                        }
                                                    } label: {
                                                        Text(action)
                                                            .font(.system(size: 10, weight: .light, design: .default))
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.leading, 8)
                                    }
                                } // Toggle
                                .tint(.accentColor)
                                .disabled(self.model.isAllUnknownFilteringOn && rule != .allUnknown)
                            } // ForEach
                        } // Section
                    }
                    
                    Section {
                        ForEach (self.model.languages.indices) { index in
                            let language = model.languages[index].item
                            
                            if let localizedName = language.localizedName {
                                switch self.model.mode {
                                case .blockLanguage:
                                    Button {
                                        self.model.addFilter(text: language.filterText, type: .denyLanguage)
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
                    } header: {
                        switch self.model.mode {
                        case .automaticBlocking:
                            Text("Smart Filtering")
                        case .blockLanguage:
                            Text("lang_supported"~)
                        }
                        
                    } footer: {
                        HStack {
                            Text(.init(self.model.footer))
                            
                            if self.model.mode == .automaticBlocking,
                               let lastUpdate = self.model.lastUpdate,
                               lastUpdate.daysBetween(date: Date()) > 0 {
                                
                                Button {
                                    self.model.forceUpdateFilters()
                                } label: {
                                    Text("autoFilter_forceUpdate"~)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                    } // Section
                    .disabled(self.model.isAllUnknownFilteringOn)
                } // List
                .listStyle(InsetGroupedListStyle())
            }
            else {
                VStack (alignment: .leading) {
                    Text("lang_allBlocked"~)
                    
                    Spacer(minLength: 24)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("general_close"~)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FilledButton())
                    .contentShape(Rectangle())
                    
                    Spacer().padding()
                }
                .padding()
            }
        } // VStack
        .navigationTitle(self.model.title)
        .navigationBarTitleDisplayMode(self.model.mode == .blockLanguage ? .automatic : .inline)
        .background(Color.listBackgroundColor(for: colorScheme))
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
            }
        }
        .onAppear {
            self.model.refresh()
        }
    }
}

struct LanguageListView_Previews: PreviewProvider {
    static var previews: some View {
        let model = LanguageListViewModel(mode: .automaticBlocking,
                                          persistanceManager: AppManager.shared.previewsPersistanceManager)
        LanguageListView(model: model)
    }
}
