//
//  AppHomeView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 31/01/2022.
//

import SwiftUI


//MARK: - View -
struct AppHomeView: View {
    
    @Environment(\.isDebug)
    var isDebug
    
    @Environment(\.isPreview)
    var isPreview
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @ObservedObject var model: ViewModel
    @StateObject private var subtitleModel = FadingTextView.ViewModel()
    
    var body: some View {
        NavigationView {
            List {
                
                //MARK: Automatic Filtering
                Section {
                    let screen: Screen = .automaticBlocking
                    
                    NavigationLink(
                        destination: screen.build(),
                        tag: screen,
                        selection: $model.navigationScreen) {
                            
                            HStack {
                                Image(systemName: "bolt.shield.fill")
                                    .foregroundColor(.indigo)
                                    .font(.system(size: 30))
                                    .padding(.trailing, 1)
                                
                                VStack (alignment: .leading) {
                                    Text("autoFilter_title"~)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                    
                                    if !self.model.subtitle.isEmpty {
                                        FadingTextView(model: self.subtitleModel)
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
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
                            .tint(rule == .allUnknown && model.rules[index].state ? .red : .accentColor)
                            .disabled(self.model.isAllUnknownFilteringOn && rule != .allUnknown)
                        } // Button
                    } // ForEach
                    
                } header: {
                    Text("autoFilter_smartFilters"~)
                } // Section
                
                
                //MARK: User Filters
                Section {
                    ForEach(FilterType.allCases.sorted(by: { $0.sortIndex < $1.sortIndex }), id: \.self) { filterType in
                        NavigationLink (tag: filterType.screen,
                                        selection: $model.navigationScreen) {
                            filterType.screen.build()
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
            .onReceive(self.model.$navigationScreen) { navigationScreen in
                if navigationScreen == nil {
                    withAnimation {
                        self.model.refresh()
                        
                        if !isPreview && self.model.isAppFirstRun {
                            self.model.modalFullScreen = .enableExtension
                        }
                    }
                }
            }
            .onReceive(self.model.$subtitle) { subtitle in
                self.subtitleModel.text = subtitle
            }
        } // NavigationView
        .navigationViewStyle(StackNavigationViewStyle())
        .modifier(EmbeddedFooterView {
            guard self.model.navigationScreen == nil else { return }
            self.model.sheetScreen = .about
        })
        .sheet(item: $model.sheetScreen) { } content: { sheetScreen in
            sheetScreen.build()
        }
        .fullScreenCover(item: $model.modalFullScreen) { } content: { modalFullScreen in
            modalFullScreen.build()
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
                self.model.sheetScreen = .testFilters
            } label: {
                Label("testFilters_title"~, systemImage: "arrow.up.message")
            }
            
            Button {
                self.model.sheetScreen = .help
            } label: {
                Label("filterList_menu_enableExtension"~, systemImage: "questionmark.circle")
            }
            
            Button {
                self.model.sheetScreen = .about
            } label: {
                Label("filterList_menu_about"~, systemImage: "info.circle")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}


//MARK: - ViewModel -
extension AppHomeView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published var filters: [Filter]
        @Published var rules: [StatefulItem<RuleType>]
        @Published var title: String
        @Published var isAppFirstRun: Bool
        @Published var isAutomaticFilteringOn: Bool
        @Published var isAllUnknownFilteringOn: Bool
        @Published var shortSenderChoice: Int
        @Published var activeNavigationTag: String?
        @Published var subtitle: String
        @Published var navigationScreen: Screen? = nil
        @Published var modalFullScreen: Screen? = nil
        @Published var sheetScreen: Screen? = nil
        
        override init(appManager: AppManagerProtocol = AppManager.shared) {
            
            let isAutomaticFilteringOn = appManager.automaticFilterManager.isAutomaticFilteringOn
            
            self.title = "filterList_filters"~
            self.subtitle = isAutomaticFilteringOn ? appManager.automaticFilterManager.activeAutomaticFiltersTitle ?? "" : ""
            self.isAppFirstRun = appManager.defaultsManager.isAppFirstRun
            self.isAutomaticFilteringOn = isAutomaticFilteringOn
            self.isAllUnknownFilteringOn = appManager.automaticFilterManager.automaticRuleState(for: .allUnknown)
            self.shortSenderChoice = appManager.automaticFilterManager.selectedChoice(for: .shortSender)
            self.activeNavigationTag = nil
            self.filters = appManager.persistanceManager.fetchFilterRecords()
            self.rules = []
            
            super.init(appManager: appManager)
            
            self.rules = appManager.automaticFilterManager.rules
                .map({
                    StatefulItem<RuleType>(item: $0,
                                           getter: appManager.automaticFilterManager.automaticRuleState,
                                           setter: self.setAutomaticRuleState) })
                .sorted(by: { $0.id.sortIndex < $1.id.sortIndex })
        }
        
        func refresh() {
            let isAutomaticFilteringOn = self.appManager.automaticFilterManager.isAutomaticFilteringOn
            
            self.title = "filterList_filters"~
            self.subtitle = isAutomaticFilteringOn ? self.appManager.automaticFilterManager.activeAutomaticFiltersTitle ?? "" : ""
            self.isAppFirstRun = self.appManager.defaultsManager.isAppFirstRun
            self.isAutomaticFilteringOn = isAutomaticFilteringOn
            self.isAllUnknownFilteringOn = self.appManager.automaticFilterManager.automaticRuleState(for: .allUnknown)
            self.shortSenderChoice = self.appManager.automaticFilterManager.selectedChoice(for: .shortSender)
            self.filters = self.appManager.persistanceManager.fetchFilterRecords()
            self.rules = self.appManager.automaticFilterManager.rules.map({ StatefulItem<RuleType>(item: $0,
                                                                                                   getter: self.appManager.automaticFilterManager.automaticRuleState,
                                                                                                   setter: self.setAutomaticRuleState) }).sorted(by: { $0.id.sortIndex < $1.id.sortIndex })
            self.animationTimer?.invalidate()
            self.animateLastUpdatedIfNeeded()
        }
        
        func setSelectedChoice(for rule: RuleType, choice: Int) {
            self.appManager.automaticFilterManager.setSelectedChoice(for: rule, choice: choice)
            self.refresh()
        }
        
        func activeCount(for filterType: FilterType) -> Int {
            return self.filters.filter({ $0.filterType == filterType }).count
        }
        
        func forceUpdateFilters() {
            self.appManager.automaticFilterManager.forceUpdateAutomaticFilters { [weak self] in
                DispatchQueue.main.async {
                    self?.refresh()
                }
            }
        }
        
        func loadDebugData() {
            self.appManager.persistanceManager.loadDebugData()
            self.refresh()
        }
        
        private var didAnimateSubtitle = false
        private var animationTimer: Timer?
        
        private func animateLastUpdatedIfNeeded() {
            guard self.animationTimer == nil,
                  !self.didAnimateSubtitle,
                  self.isAutomaticFilteringOn,
                  let lastUpdate = self.appManager.automaticFilterManager.automaticFiltersCacheAge else { return }
            
            var runCount = 0

            let timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { timer in
                guard timer.isValid,
                      self.navigationScreen == nil,
                      self.sheetScreen == nil,
                      self.modalFullScreen == nil else { return }
                                
                if runCount == 0 {
                    let formatter = DateFormatter()
                    formatter.locale = Locale.current
                    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "ddMMyyyy", options: 0, locale: Locale.current)
                    let text = String(format: "autoFilter_lastUpdated"~, formatter.string(from: lastUpdate))
                    self.subtitle = text
                    runCount += 1
                }
                else if runCount == 1 {
                    let text = self.appManager.automaticFilterManager.activeAutomaticFiltersTitle ?? ""
                    self.subtitle = text
                    runCount += 1
                    self.didAnimateSubtitle = true
                    timer.invalidate()
                }
            }
            
            self.animationTimer = timer
        }
        
        private func setAutomaticRuleState(for rule: RuleType, value: Bool) {
            self.appManager.automaticFilterManager.setAutomaticRuleState(for: rule, value: value)
            self.refresh()
        }
    }
}


//MARK: - Preview -
struct AppHomeView_Previews: PreviewProvider {
    static var previews: some View {
        AppHomeView(model: AppHomeView.ViewModel(appManager: AppManager.previews))
    }
}
