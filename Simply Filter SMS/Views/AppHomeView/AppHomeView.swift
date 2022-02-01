//
//  AppHomeView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 31/01/2022.
//

import SwiftUI

struct AppHomeView: View {
    
    @Environment(\.isDebug)
    var isDebug
    
    @Environment(\.isPreview)
    var isPreview
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    enum SheetView: Int, Identifiable {
        var id: Self { self }
        case about=0, help
    }
    
    @StateObject var model: AppHomeViewModel
    
    @State private var presentedSheet: SheetView? = nil
    @State private var isPresentingFullScreenWelcome = false
    @State private var viewDidAppear = false
    @State private var activeLanguagesModel = FadingTextView.Model()
    
    var body: some View {
        NavigationView {
            List {
                
                //MARK: Automatic Filtering
                Section {
                    NavigationLink(
                        destination: LanguageListView(model: LanguageListViewModel(mode: .automaticBlocking)),
                        tag: "AutomaticFilteringLanguageView",
                        selection: $model.activeNavigationTag) {
                            
                            HStack {
                                Image(systemName: "bolt.shield.fill")
                                    .foregroundColor(.indigo)
                                    .font(.system(size: 30))
                                    .padding(.trailing, 1)

                                VStack (alignment: .leading) {
                                    Text("autoFilter_title"~)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                    
                                    if !self.model.activeLanguages.isEmpty {
                                        FadingTextView(model: self.activeLanguagesModel)
                                            .font(.caption2)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                                
                                if self.model.isAutomaticFilteringOn {
                                    Text("autoFilter_ON"~)
                                        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                                        .background(Color.green.opacity(0.1))
                                        .foregroundColor(.green)
                                        .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                        .font(.system(size: 16, weight: .heavy, design: .default))
                                }
                                else {
                                    Text("autoFilter_OFF"~)
                                        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                        .font(.system(size: 16, weight: .heavy, design: .default))
                                }
                            }
                            .padding(.vertical, 12)
                        } // Navigation Link
                        .listRowInsets(EdgeInsets(top: 0, leading: 11, bottom: 0, trailing: 20))
                } header: {
                    Spacer()
                } // Section
                .disabled(self.model.isAllUnknownFilteringOn)
                
                
                //MARK: Smart Filters
                Section {
                    ForEach($model.rules.indices) { index in
                        Button { } label: {
                            let rule = model.rules[index].item
                            
                            Toggle(isOn: $model.rules[index].state) {
                                HStack {
                                    Image(systemName: rule.icon)
                                        .accentColor(rule.iconColor)
                                        .frame(maxWidth: 20, maxHeight: .infinity, alignment: .center)
                                        .font(rule.isDestructive ? Font.body.bold() : .body)
                                    
                                    VStack (alignment: .leading, spacing: 0) {
                                        Text(rule.title)
                                            .accentColor(rule.isDestructive && model.rules[index].state ? Color.red : .primary)
                                        
                                        if let subtitle = rule.subtitle,
                                           let action = rule.action,
                                           let actionTitle = rule.actionTitle {
                                            
                                            HStack (alignment: .center, spacing: 4) {
                                                Text(String(format: subtitle, self.model.shortSenderChoice))
                                                    .font(.caption2)
                                                    .accentColor(.secondary)
                                                
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
                                                        .font(.caption2)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                            } // Toggle
                            .tint(.accentColor)
                            .disabled(self.model.isAllUnknownFilteringOn && rule != .allUnknown)
                        } // Button
                    } // ForEach
                    
                } header: {
                    Text("autoFilter_smartFilters"~)
                } // Section
                
                
                //MARK: User Filters
                Section {
                    ForEach(FilterType.allCases.sorted(by: { $0.sortIndex < $1.sortIndex }), id: \.self) { filterType in
                        NavigationLink (tag: "\(filterType.rawValue)", selection: $model.activeNavigationTag) {
                            FilterListView(model: FilterListViewModel(filterType: filterType))
                        } label: {
                            HStack {
                                Image(systemName: filterType.iconName)
                                    .foregroundColor(filterType.iconColor)
                                    .frame(maxWidth: 20, maxHeight: .infinity, alignment: .center)
                                
                                Text(filterType.name)
                                    .padding(.leading, 8)
                                
                                Spacer()
                                
                                Text(String(format: "general_active_count"~, self.model.activeCount(for: filterType)))
                                    .textCase(.uppercase)
                                    .foregroundColor(.secondary)
                                    .font(Font.caption2)
                            }
                        }
                        .disabled(self.model.isAllUnknownFilteringOn && filterType != .allow)
                    }
                } header: {
                    Text("autoFilter_yourFilters"~)
                }
            } // List
            .navigationTitle(self.model.title)
            .listStyle(.insetGrouped)
            .navigationBarItems(trailing: NavigationBarTrailingItem())
        } // NavigationView
        .navigationViewStyle(StackNavigationViewStyle())
        .modifier(EmbeddedFooterView(onTap: { presentedSheet = .about }))
        .onAppear() {
            self.model.refresh()
            self.viewDidAppear = true
            
            if !isPreview && self.model.isAppFirstRun {
                self.isPresentingFullScreenWelcome = true
            }
            else {
                self.animateLastUpdatedIfNeeded()
            }
        }
        .onReceive(self.model.$activeNavigationTag) { activeNavigationTag in
            guard self.viewDidAppear else { return }
            DispatchQueue.main.async {
                if activeNavigationTag == nil {
                    withAnimation {
                        self.model.refresh()
                    }
                }
            }
        }
        .onReceive(self.model.$activeLanguages) { activeLanguages in
            guard self.viewDidAppear else { return }
            self.activeLanguagesModel.text = activeLanguages
        }
        .sheet(item: $presentedSheet) { // onDismiss:
            self.presentedSheet = nil
            guard self.viewDidAppear else { return }
            withAnimation {
                self.model.refresh()
            }
        } content: { presentedSheet in
            switch (presentedSheet) {
            case .about:
                AboutView()
                
            case .help:
                HelpView(model: HelpViewModel())
            }
        }
        .fullScreenCover(
            isPresented: $isPresentingFullScreenWelcome,
            onDismiss: {
                self.isPresentingFullScreenWelcome = false
                self.model.refresh()
            },
            content: {
                EnableExtensionView(model: EnableExtensionViewModel(showWelcome: true))
            })
    }
    
    private func animateLastUpdatedIfNeeded() {
        guard !self.model.activeLanguages.isEmpty else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let activeLanguages = self.model.activeLanguages
            self.model.activeLanguages = self.model.automaticFilteringFooter
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.model.activeLanguages = activeLanguages
            }
        }
    }
    
    @ViewBuilder
    private func NavigationBarTrailingItem() -> some View {
        Menu {
            
            if isDebug {
                Button {
                    self.model.loadDebugData()
                } label: {
                    Label("filterList_menu_debug"~, systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
            
            Button {
                presentedSheet = .help
            } label: {
                Label("filterList_menu_enableExtension"~, systemImage: "questionmark.circle")
            }
            
            Button {
                presentedSheet = .about
            } label: {
                Label("filterList_menu_about"~, systemImage: "info.circle")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

struct AppHomeView_Previews: PreviewProvider {
    static var previews: some View {
        AppHomeView(model: AppHomeViewModel(persistanceManager: AppManager.shared.previewsPersistanceManager))
    }
}
