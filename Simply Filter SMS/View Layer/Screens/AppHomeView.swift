//
//  AppHomeView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 31/01/2022.
//

import SwiftUI
import StoreKit


//MARK: - View -
struct AppHomeView: View {
    
    @Environment(\.isDebug)
    var isDebug
    
    @Environment(\.isPreview)
    var isPreview
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    
    @ObservedObject var model: ViewModel

    @ScaledMetric(relativeTo: .title) private var shieldIconSize: CGFloat = 34
    @ScaledMetric(relativeTo: .title3) private var autoFilterTitleSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var badgeFontSize: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var emojiIconSize: CGFloat = 16

    @State private var dynamicEmojis: [String: String] = [:]
    @State private var shieldGlintTrigger = false
    
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
                                Group {
                                    if #available(iOS 17, *) {
                                        if self.model.isAutomaticFilteringOn && !self.model.isAllUnknownFilteringOn && !reduceMotion {
                                            Image(systemName: "bolt.shield.fill")
                                                .phaseAnimator([0, 1, 2, 1, 0], trigger: shieldGlintTrigger) { view, phase in
                                                    view
                                                        .symbolRenderingMode(.palette)
                                                        .foregroundStyle(
                                                            { switch phase {
                                                                case 1:  Color.yellow
                                                                case 2:  Color.white.opacity(0.3)
                                                                default: Color.white.opacity(0.9)
                                                            }}(),
                                                            Color.indigo
                                                        )
                                                } animation: { phase in
                                                    phase == 0 ? .linear(duration: 0.3) : .easeInOut(duration: 0.08)
                                                }
                                                .task {
                                                    while !Task.isCancelled {
                                                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                                                        shieldGlintTrigger.toggle()
                                                    }
                                                }
                                        } else {
                                            Image(systemName: "bolt.shield.fill")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(Color.white.opacity(0.9), Color.indigo)
                                        }
                                    } else {
                                        Image(systemName: "bolt.shield.fill")
                                            .foregroundColor(.indigo)
                                    }
                                }
                                .font(.system(size: shieldIconSize))
                                .padding(.trailing, 1)
                                .accessibilityHidden(true)
                                
                                VStack (alignment: .leading) {
                                    Text("autoFilter_title"~)
                                        .font(.system(size: autoFilterTitleSize, weight: .bold, design: .rounded))
                                    
                                    if !self.model.subtitle.isEmpty {
                                        Text(self.model.subtitle)
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
                                        .font(.system(size: badgeFontSize, weight: .heavy, design: .default))
                                }
                                else {
                                    Text("autoFilter_OFF"~)
                                        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                        .font(.system(size: badgeFontSize, weight: .heavy, design: .default))
                                }
                            }
                            .padding(.vertical, 12)
                        } // Navigation Link
                        .listRowInsets(EdgeInsets(top: 0, leading: 11, bottom: 0, trailing: 20))
                        .accessibility(identifier: TestIdentifier.automaticFilterLink.rawValue)
                        .accentColor(Color.primary.opacity(0.35))
                } header: {
                    Spacer()
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                } // Section
                .disabled(self.model.isAllUnknownFilteringOn)
                
                
                //MARK: Smart Filters
                Section {
                    ForEach($model.rules.indices, id: \.self) { index in
                        let rule = model.rules[index].item
                        let isDisabled = self.model.isAllUnknownFilteringOn && rule != .allUnknown
                        
                        Toggle(isOn: $model.rules[index].state) {
                            HStack {
                                if rule.isTextIcon {
                                    let ruleKey: String = rule.title
                                    let baseEmoji = rule.icon
                                    let currentEmoji = dynamicEmojis[ruleKey] ?? baseEmoji
                                    Button {
                                        dynamicEmojis[ruleKey] = EmojiGenerator.randomEmoji()
                                    } label: {
                                        Text(currentEmoji)
                                            .opacity(isDisabled ? 0.5 : 1)
                                            .frame(maxWidth: 20, maxHeight: .infinity, alignment: .center)
                                            .font(.system(size: emojiIconSize))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isDisabled)
                                }
                                else {
                                    Image(systemName: rule.icon)
                                        .foregroundColor(rule.iconColor.opacity(isDisabled ? 0.5 : 1))
                                        .frame(maxWidth: 20, maxHeight: .infinity, alignment: .center)
                                        .font(rule.isDestructive ? Font.body.bold() : .body)
                                }
                                
                                VStack (alignment: .leading, spacing: 0) {
                                    let color = rule.isDestructive && model.rules[index].state ? Color.red : .primary
                                    Text(rule.title)
                                        .foregroundColor(color.opacity(isDisabled ? 0.5 : 1))
                                    
                                    if let subtitle = rule.subtitle,
                                       let action = rule.action,
                                       let actionTitle = rule.actionTitle {
                                        
                                        HStack (alignment: .center, spacing: 4) {
                                            Text(String(format: subtitle, self.model.shortSenderChoice))
                                                .font(.caption2)
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
                                                    .font(.caption2)
                                            }
                                        }
                                    }
                                }
                                .padding(.leading, 8)
                            }
                        } // Toggle
                        .tint(rule.toggleBackgroundColor)
                        .disabled(isDisabled)
                        .if(rule.subtitle != nil) {
                            $0.accessibilityHint(String(format: "a11y_home_shortSenderHint"~, self.model.shortSenderChoice))
                                .accessibilityAction(named: "a11y_home_shortSenderAction"~) {
                                    let next = self.model.shortSenderChoice >= 6 ? 3 : self.model.shortSenderChoice + 1
                                    self.model.setSelectedChoice(for: rule, choice: next)
                                }
                        }
                    } // ForEach
                    
                } header: {
                    Text("autoFilter_smartFilters"~)
                        .accessibilityAddTraits(.isHeader)
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
                                
                                Text(String.localizedStringWithFormat("general_active_count"~, self.model.activeCount(for: filterType)))
                                    .textCase(.uppercase)
                                    .foregroundColor(.secondary)
                                    .font(Font.caption2)
                            }
                        }
                        .disabled(self.model.isAllUnknownFilteringOn && filterType != .allow)
                        .accessibilityIdentifier(filterType.testIdentifier.rawValue)
                        .accentColor(Color.primary.opacity(0.35))
                    }
                } header: {
                    Text("autoFilter_yourFilters"~)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Section {} header: {
                    Text("")
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
                            self.model.sheetScreen = .enableExtension
                        }
                        else if !isPreview && self.model.shouldShowWhatsNew {
                            self.model.sheetScreen = .whatsNew
                        }
                    }
                }
            }
            
            CustomPlaceholderView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.listBackgroundColor(for: colorScheme))
        } // NavigationView
        .phoneOnlyStackNavigationView()
        .modifier(EmbeddedFooterView {
            guard horizontalSizeClass == .regular || self.model.navigationScreen == nil else { return }
            self.model.sheetScreen = .about
        })
        .modifier(EmbeddedNotificationView(model: self.model.notification))
        .sheet(item: $model.sheetScreen) {
            self.model.refresh()
            if self.model.pendingScreenAfterDismiss != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.model.sheetScreen = self.model.pendingScreenAfterDismiss
                    self.model.pendingScreenAfterDismiss = nil
                }
            }
        } content: { sheetScreen in
            if sheetScreen == .whatsNew {
                WhatsNewView(model: WhatsNewView.ViewModel(onActionnableEntryTapped: { entry in
                    if entry == .tipJar {
                        self.model.pendingScreenAfterDismiss = .tipJar
                    }
                }))
            } else {
                sheetScreen.build()
            }
        }
        .fullScreenCover(item: $model.modalFullScreen) {
            self.model.refresh()
        } content: { modalFullScreen in
            modalFullScreen.build()
        }
        .onAppear {
            self.model.startMonitoring()
        }
        .onOpenURL { url in
            self.model.handleDeepLink(url: url)
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
                .accessibilityIdentifier(TestIdentifier.loadDebugDataMenuButton.rawValue)
            }
            
            Button {
                self.model.sheetScreen = .testFilters
            } label: {
                Label("testFilters_title"~, systemImage: "arrow.up.message")
            }
            .accessibilityIdentifier(TestIdentifier.testYourFiltersMenuButton.rawValue)
            
            Button {
                self.model.sheetScreen = .reportMessage
            } label: {
                Label("reportMessage_title"~, systemImage: "exclamationmark.bubble")
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

            Button {
                self.model.sheetScreen = .tipJar
            } label: {
                Label("tipJar_menuItem"~, systemImage: "heart.fill")
            }

            if !WhatsNewEntry.allCases.isEmpty {
                Button {
                    self.model.sheetScreen = .whatsNew
                } label: {
                    Label("whatsNew_menuItem"~, systemImage: "sparkles")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("a11y_home_menuButton"~)
        .accessibilityIdentifier(TestIdentifier.appMenuButton.rawValue)
    }
}


//MARK: - ViewModel -
extension AppHomeView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var filters: [Filter]
        @Published private(set) var title: String
        @Published private(set) var isAppFirstRun: Bool
        @Published private(set) var isAutomaticFilteringOn: Bool
        @Published private(set) var isAllUnknownFilteringOn: Bool
        @Published private(set) var shortSenderChoice: Int
        @Published private(set) var subtitle: String
        @Published var rules: [StatefulItem<RuleType>]
        @Published var notification: NotificationView.ViewModel
        @Published var navigationScreen: Screen? = nil {
            didSet {
                if oldValue != nil,
                   self.navigationScreen == nil {
                    self.tryRequestReview()
                }
            }
        }
        @Published var modalFullScreen: Screen? = nil {
            didSet {
                if self.modalFullScreen == nil,
                   let pendingNotification = self.pendingNotification {
                    self.showNotification(pendingNotification)
                    self.pendingNotification = nil
                }
            }
        }
        @Published var sheetScreen: Screen? = nil {
            didSet {
                if self.sheetScreen == nil,
                   let pendingNotification = self.pendingNotification {
                    self.showNotification(pendingNotification)
                    self.pendingNotification = nil
                }
            }
        }
        var pendingScreenAfterDismiss: Screen?
        
        override init(appManager: AppManagerProtocol = AppManager.shared) {
            
            let isAutomaticFilteringOn = appManager.automaticFilterManager.isAutomaticFilteringOn
            
            self.title = "filterList_filters"~
            self.subtitle = isAutomaticFilteringOn ? appManager.automaticFilterManager.activeAutomaticFiltersTitle ?? "" : ""
            self.isAppFirstRun = appManager.defaultsManager.isAppFirstRun
            self.wasFirstRunOnInit = appManager.defaultsManager.isAppFirstRun
            self.isAutomaticFilteringOn = isAutomaticFilteringOn
            self.isAllUnknownFilteringOn = appManager.automaticFilterManager.automaticRuleState(for: .allUnknown)
            self.shortSenderChoice = appManager.automaticFilterManager.selectedChoice(for: .shortSender)
            self.filters = appManager.persistanceManager.fetchFilterRecords()
            self.rules = []
            self.notification = NotificationView.ViewModel(notification: .offline)
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
        }
        
        func setSelectedChoice(for rule: RuleType, choice: Int) {
            self.appManager.automaticFilterManager.setSelectedChoice(for: rule, choice: choice)
            self.refresh()
        }
        
        func activeCount(for filterType: FilterType) -> Int {
            return self.filters.filter({ $0.filterType == filterType }).count
        }
        
        func showNotification(_ notification: NotificationView.Notification) {
            guard self.modalFullScreen == nil && self.sheetScreen == nil else {
                self.pendingNotification = notification
                return
            }
            
            if !self.notification.show {
                self.notification.setNotification(notification)
                self.notification.setOnButtonTap {
                    self.appManager.defaultsManager.lastOfflineNotificationDismiss = Date()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        self.notification.show = true
                    }
                }
            }
            else {
                withAnimation {
                    self.notification.setNotification(notification)
                }
            }
            
        }
        
        func startMonitoring() {
            if self.appManager.networkSyncManager.networkStatus == .offline,
               !self.userIgnoresNetworkStatus {
                self.showNotification(.offline)
            }
            
            if !didAddObservers {
                self.didAddObservers = true
                NotificationCenter.default.addObserver(forName: .cloudSyncOperationComplete, object: nil, queue: .main) { _ in
                    self.refresh()
                    self.showNotification(.cloudSyncOperationComplete)
                }
                
                NotificationCenter.default.addObserver(forName: .networkStatusChange, object: nil, queue: .main) { notification in
                    guard let networkStatus = notification.object as? NetworkStatus else { return }
                    
                    if networkStatus == .online {
                        self.notification.show = false
                    }
                    else {
                        if !self.userIgnoresNetworkStatus {
                            self.showNotification(.offline)
                        }
                    }
                }
                
                NotificationCenter.default.addObserver(forName: .filtersStateChanged, object: nil, queue: .main) { _ in
                    withAnimation {
                        self.refresh()
                    }
                }

                NotificationCenter.default.addObserver(forName: .automaticFiltersUpdated, object: nil, queue: .main) { _ in
                    self.refresh()
                    guard self.isAutomaticFilteringOn else { return }
                    self.showNotification(.automaticFiltersUpdated)
                }
            }

            self.tryShowTipPromotion()
        }
        
        func tryShowTipPromotion() {
            let defaultsManager = self.appManager.defaultsManager
            guard defaultsManager.sessionCounter % 5 == 0,
                  defaultsManager.sessionCounter > 0,
                  !defaultsManager.didTip,
                  !self.notification.show,
                  self.sheetScreen == nil,
                  self.modalFullScreen == nil else { return }

            self.notification.setNotification(.tipPromotion)
            self.notification.onTap = {
                withAnimation { self.notification.show = false }
                self.sheetScreen = .tipJar
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    self.notification.show = true
                }
            }
        }

        func tryRequestReview() {
            var defaultsManager = self.appManager.defaultsManager
            if !defaultsManager.didPromptForReview,
               defaultsManager.appAge.daysBetween(date: Date()) > 7,
               defaultsManager.sessionCounter > 5,
               let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                
                SKStoreReviewController.requestReview(in: scene)
                defaultsManager.didPromptForReview = true
            }
        }
        
        func loadDebugData() {
            #if DEBUG
            self.appManager.persistanceManager.loadDebugData()
            #endif
            self.refresh()
        }
        
        func handleDeepLink(url: URL) {
            guard url.scheme == "simplyfiltersms",
                  let host = url.host,
                  let screen = Screen.fromDeepLink(host: host) else { return }

            if self.sheetScreen != nil || self.modalFullScreen != nil {
                self.sheetScreen = nil
                self.modalFullScreen = nil

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.sheetScreen = screen
                }
            } else {
                self.sheetScreen = screen
            }
        }

        var shouldShowWhatsNew: Bool {
            !self.wasFirstRunOnInit
            && !self.isAppFirstRun
            && !WhatsNewEntry.allCases.isEmpty
            && currentWhatsNewVersion > self.appManager.defaultsManager.lastSeenWhatsNewVersion
        }

        private let wasFirstRunOnInit: Bool
        private var didAddObservers = false
        private var pendingNotification: NotificationView.Notification?
        private var userIgnoresNetworkStatus: Bool {
            guard let lastOfflineNotificationDismiss = self.appManager.defaultsManager.lastOfflineNotificationDismiss else { return false }
            return Date().minutesBetween(date: lastOfflineNotificationDismiss) < kHideiClouldStatusMemory
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


