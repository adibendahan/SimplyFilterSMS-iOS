//
//  AppHomeView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 31/01/2022.
//

import SwiftUI
import StoreKit
import UniformTypeIdentifiers

//MARK: - View -
struct AppHomeView: View, ViewWithPersistentStoreReload {
    
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
    @ScaledMetric(relativeTo: .title3) private var filterListsTitleSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var badgeFontSize: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var emojiIconSize: CGFloat = 16

    @State private var dynamicEmojis: [String: String] = [:]
    @State private var selectedScreen: Screen? = nil

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedScreen) {
                
                //MARK: Automatic Filtering
                Section {
                    let screen: Screen = .filterLists
                    
                    AdaptiveRow {
                        Group {
                            if self.model.hasActiveFilterLists && !self.model.isAllUnknownFilteringOn && !reduceMotion {
                                ShieldGlintIcon()
                            } else {
                                Image(systemName: "bolt.shield.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.white.opacity(0.9), Color.indigo)
                            }
                        }
                        .font(.system(size: shieldIconSize))
                        .frame(width: shieldIconSize + 4, alignment: .center)
                        .accessibilityHidden(true)
                    } content: {
                        filterListsTextColumn
                    } trailing: {
                        filterListsStatusBadge
                    }
                    .padding(.vertical, 12)
                    .sidebarNavigationRow(screen: screen, isRegular: horizontalSizeClass == .regular) {
                        model.navigationScreen = screen
                    }
                        .listRowInsets(EdgeInsets(top: 0, leading: 11, bottom: 0, trailing: 20))
                        .listRowBackground(horizontalSizeClass == .regular ? (model.navigationScreen == screen ? Color.primary.opacity(0.08) : Color(UIColor.secondarySystemGroupedBackground)) : nil)
                        .accessibility(identifier: TestIdentifier.filterListsLink.rawValue)
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

                        smartFilterToggle(index: index, rule: rule, isDisabled: isDisabled)
                        .if(rule.isDestructive) { $0.tint(.red) }
                        .disabled(isDisabled)
                        .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
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
                    communityListsRow
                        .sidebarNavigationRow(screen: .communityLists, isRegular: horizontalSizeClass == .regular) {
                            model.navigationScreen = .communityLists
                        }
                        .listRowBackground(horizontalSizeClass == .regular ? (model.navigationScreen == .communityLists ? Color.primary.opacity(0.08) : Color(UIColor.secondarySystemGroupedBackground)) : nil)
                        .disabled(self.model.isAllUnknownFilteringOn)
                        .accessibilityIdentifier(TestIdentifier.communityListsLink.rawValue)
                        .accentColor(Color.primary.opacity(0.35))

                    ForEach(FilterType.allCases.sorted(by: { $0.sortIndex < $1.sortIndex }), id: \.self) { filterType in
                        userFilterRow(filterType: filterType)
                        .sidebarNavigationRow(screen: filterType.screen, isRegular: horizontalSizeClass == .regular) {
                            model.navigationScreen = filterType.screen
                        }
                        .listRowBackground(horizontalSizeClass == .regular ? (model.navigationScreen == filterType.screen ? Color.primary.opacity(0.08) : Color(UIColor.secondarySystemGroupedBackground)) : nil)
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
            .background(horizontalSizeClass == .regular ? InstantTouchDisabler(delaysContentTouches: true) : nil)
            .navigationTitle(self.model.title)
            .listStyle(.insetGrouped)
            .toolbar {
                if #available(iOS 27.0, *) {
                    ToolbarItem(placement: .topBarPinnedTrailing) {
                        NavigationBarTrailingItem()
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationBarTrailingItem()
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 340, ideal: 380)
            .onChange(of: selectedScreen) { _, newScreen in
                if let screen = newScreen {
                    model.navigationScreen = screen
                    if horizontalSizeClass == .regular {
                        DispatchQueue.main.async {
                            selectedScreen = nil
                        }
                    }
                } else if horizontalSizeClass == .compact {
                    model.navigationScreen = nil
                }
            }
            .onReceive(self.model.$navigationScreen) { navigationScreen in
                if navigationScreen == nil {
                    withAnimation {
                        self.model.refresh()

                        if !isPreview {
                            self.model.presentNextScreen()
                        }
                    }
                }
            }
        } detail: {
            if let screen = selectedScreen ?? model.navigationScreen {
                screen.build()
            } else {
                DetailPlaceholderView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.listBackgroundColor(for: colorScheme))
            }
        } // NavigationSplitView
        .modifier(EmbeddedFooterModifier(isHidden: self.model.sheetScreen != nil) {
            guard horizontalSizeClass == .regular || self.model.navigationScreen == nil else { return }
            self.model.requestSheet(.about)
        })
        .modifier(OverlayWindowModifier(model: self.model.overlayWindow))
        .modifier(persistentStoreReload)
        .sheet(item: $model.sheetScreen) {
            self.model.refresh()
            let pending = self.model.pendingScreenAfterDismiss
            let isPushPending = pending?.opensFromHomeList == true
            if isPushPending {
                Log.debug("push pending → next screen deferred, screen: \(pending)")
            }
            if !self.model.completeInterruptedSheet(), !isPreview, !isPushPending {
                self.model.presentNextScreen()
            }
            if let pending {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard self.model.pendingScreenAfterDismiss == pending else { return }
                    self.model.pendingScreenAfterDismiss = nil
                    if pending.opensFromHomeList {
                        selectedScreen = pending
                    } else {
                        self.model.requestSheet(pending)
                    }
                }
            }
        } content: { sheetScreen in
            if sheetScreen == .whatsNew {
                WhatsNewView(model: WhatsNewView.ViewModel(onActionableEntryTapped: { entry in
                    switch entry {
                    case .tipJar:
                        self.model.pendingScreenAfterDismiss = .tipJar
                    case .communityLists:
                        self.model.pendingScreenAfterDismiss = .communityLists
                    default:
                        break
                    }
                }))
            } else if sheetScreen == .help {
                HelpView(model: HelpView.ViewModel(onRequestScreen: { screen in
                    self.model.pendingScreenAfterDismiss = screen
                }))
            } else if sheetScreen == .chooseAccentColor {
                ChooseAccentColorView(model: ChooseAccentColorView.ViewModel(onAccentChanged: { color in
                    self.model.customAccent = color
                }))
            } else {
                sheetScreen.build()
            }
        }
        .alert("importFilters_title"~, isPresented: self.$model.showNothingToImportAlert) {
            Button("general_close"~, role: .cancel) { }
        } message: {
            Text("importFilters_nothingToAdd"~)
        }
        .alert("inactivityNotification_title"~, isPresented: self.$model.showInactivityNotificationAlert) {
            Button("inactivityNotification_continue"~) {
                self.model.allowInactivityNotification()
            }
            Button(self.model.inactivityNotificationDismissTitle, role: .cancel) {
                self.model.declineInactivityNotification()
            }
        } message: {
            Text("inactivityNotification_message"~)
        }
        .background {
            Color.clear
                .frame(width: 0, height: 0)
                .fileImporter(isPresented: self.$model.isImportingFile,
                              allowedContentTypes: [.sfsFilters],
                              allowsMultipleSelection: false) { result in
                    self.model.handlePickedFiles(result)
                }
                .id(self.model.fileImporterID)
        }
        .onOpenURL { url in
            self.model.handleDeepLink(url: url)
        }
        .optionalTint(model.customAccent)
    }

    @ViewBuilder
    private var filterListsTextColumn: some View {
        VStack(alignment: .leading) {
            Text("autoFilter_title"~)
                .font(.system(size: filterListsTitleSize, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)

            if !self.model.subtitle.isEmpty {
                Text(self.model.subtitle)
                    .font(.caption2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var filterListsStatusBadge: some View {
        if self.model.hasActiveFilterLists {
            let onColor = model.customAccent ?? Color.green
            Text("autoFilter_ON"~)
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .background(onColor.opacity(0.1))
                .foregroundColor(onColor)
                .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .font(.system(size: badgeFontSize, weight: .heavy, design: .default))
                .limitedDynamicTypeSize()
        } else {
            Text("autoFilter_OFF"~)
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .font(.system(size: badgeFontSize, weight: .heavy, design: .default))
                .limitedDynamicTypeSize()
        }
    }
    
    @ViewBuilder
    private func smartFilterToggle(index: Int, rule: SmartFilterType, isDisabled: Bool) -> some View {
        AdaptiveToggle(isOn: $model.rules[index].state) {
            smartFilterLabel(index: index, rule: rule, isDisabled: isDisabled)
        }
    }

    @ViewBuilder
    private func smartFilterLabel(index: Int, rule: SmartFilterType, isDisabled: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            smartFilterIcon(index: index, rule: rule, isDisabled: isDisabled)

            smartFilterTextColumn(index: index, rule: rule, isDisabled: isDisabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func smartFilterIcon(index: Int, rule: SmartFilterType, isDisabled: Bool) -> some View {
        if rule.isTextIcon {
            let ruleKey: String = rule.title
            let baseEmoji = rule.icon
            let currentEmoji = dynamicEmojis[ruleKey] ?? baseEmoji
            Button {
                dynamicEmojis[ruleKey] = EmojiGenerator.randomEmoji()
            } label: {
                Text(currentEmoji)
                    .opacity(isDisabled ? 0.5 : 1)
                    .font(.system(size: emojiIconSize))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .adaptiveIconColumn()
        } else {
            Image(systemName: rule.icon)
                .foregroundColor(rule.iconColor.opacity(isDisabled ? 0.5 : 1))
                .font(rule.isDestructive ? Font.body.bold() : .body)
                .adaptiveIconColumn()
        }
    }

    @ViewBuilder
    private func smartFilterTextColumn(index: Int, rule: SmartFilterType, isDisabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            let color = rule.isDestructive && model.rules[index].state ? Color.red : .primary
            Text(rule.title)
                .foregroundColor(color.opacity(isDisabled ? 0.5 : 1))
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle = rule.subtitle,
               let action = rule.action,
               let actionTitle = rule.actionTitle {
                smartFilterShortSenderControls(
                    subtitle: String(format: subtitle, self.model.shortSenderChoice),
                    action: action,
                    actionTitle: actionTitle,
                    rule: rule)
            } else if rule == .countryAllowlist && model.rules[index].state {
                countryAllowlistControls
            }
        }
    }

    @ViewBuilder
    private func smartFilterShortSenderControls(subtitle: String, action: String, actionTitle: String, rule: SmartFilterType) -> some View {
        AdaptiveFlowRow {
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Menu {
                Text(actionTitle)
                Divider()
                ForEach(3...6, id: \.self) { choice in
                    Button {
                        self.model.setSelectedChoice(for: rule, choice: choice)
                    } label: {
                        Text("\(choice)")
                    }
                }
        } label: {
            Text(action)
                .font(.caption2)
        }
        .buttonStyle(AccessibleTextButtonStyle(compact: true))
    }
    }

    @ViewBuilder
    private var countryAllowlistControls: some View {
        AdaptiveFlowRow {
            Text(self.model.selectedCountriesSummary)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                self.model.requestSheet(.countryList)
            } label: {
                Text("autoFilter_shortSender_change"~)
                    .font(.caption2)
            }
            .buttonStyle(AccessibleTextButtonStyle(compact: true))
            .accessibilityIdentifier(TestIdentifier.countryAllowlistButton.rawValue)
        }
    }

    @ViewBuilder
    private var communityListsRow: some View {
        let activeCount = String.localizedStringWithFormat("communityLists_active_count"~, self.model.activeCommunityListsCount)

        AdaptiveRow {
            Image(systemName: "person.2.circle")
                .foregroundColor(.indigo)
                .adaptiveIconColumn()
        } content: {
            Text("communityLists_title"~)
                .fixedSize(horizontal: false, vertical: true)
        } trailing: {
            Text(activeCount)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
                .font(.caption2)
                .limitedDynamicTypeSize()
        }
    }

    @ViewBuilder
    private func userFilterRow(filterType: FilterType) -> some View {
        let activeCount = String.localizedStringWithFormat("general_active_count"~, self.model.activeCount(for: filterType))

        AdaptiveRow {
            Image(systemName: filterType.iconName)
                .foregroundColor(filterType.iconColor)
                .adaptiveIconColumn()
        } content: {
            Text(filterType.name)
                .fixedSize(horizontal: false, vertical: true)
        } trailing: {
            Text(activeCount)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
                .font(.caption2)
                .limitedDynamicTypeSize()
        }
    }

    @ViewBuilder
    private func NavigationBarTrailingItem() -> some View {
        Menu {

            #if DEBUG
            Menu {
                Button {
                    self.model.loadDebugData()
                } label: {
                    Label("filterList_menu_debug"~, systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .accessibilityIdentifier(TestIdentifier.loadDebugDataMenuButton.rawValue)

                Button {
                    self.model.fireInactivityReminder()
                } label: {
                    Label("Reminder in 30s", systemImage: "bell.badge")
                }

                Button {
                    self.model.refreshFilterListsSoon()
                } label: {
                    Label("AI Refresh in 1m", systemImage: "arrow.clockwise")
                }

                Menu {
                    ForEach(Array(ToastView.Toast.debugSamples.enumerated()), id: \.offset) { _, toast in
                        Button {
                            self.model.showDebugToast(toast)
                        } label: {
                            Label(toast.title, systemImage: toast.icon)
                        }
                    }
                } label: {
                    Label("Show Toast", systemImage: "rectangle.topthird.inset.filled")
                }

                Button(role: .destructive) {
                    self.model.reset()
                } label: {
                    Label("Reset", systemImage: "trash")
                }
            } label: {
                Label("Debug Tools", systemImage: "hammer")
            }
            .accessibilityIdentifier(TestIdentifier.debugToolsButton.rawValue)
            #endif // DEBUG

            Menu {
                Button {
                    self.model.requestSheet(.addAllowFilter)
                } label: {
                    Label("addFilter_addFilter_allow"~, systemImage: "person.crop.circle.badge.checkmark")
                }

                Button {
                    self.model.requestSheet(.addDenyFilter)
                } label: {
                    Label("addFilter_addFilter_deny"~, systemImage: "person.crop.circle.badge.xmark")
                }

                Button {
                    self.model.requestSheet(.addLanguageFilter)
                } label: {
                    Label("addFilter_addLanguage"~, systemImage: "globe")
                }
            } label: {
                Label("menu_addFilter"~, systemImage: "plus.message")
            }

            Menu {
                Button {
                    self.model.requestSheet(.filterTester)
                } label: {
                    Label("testFilters_title"~, systemImage: "arrow.up.message")
                }
                .accessibilityIdentifier(TestIdentifier.testYourFiltersMenuButton.rawValue)

                Button {
                    self.model.requestSheet(.reportMessage)
                } label: {
                    Label("reportMessage_title"~, systemImage: "exclamationmark.bubble")
                }

                Button {
                    self.model.requestSheet(.enableReportingExtension)
                } label: {
                    Label("autoFilter_improveAIFiltering"~, systemImage: "wand.and.stars")
                }

                Divider()

                Button {
                    self.model.exportFilters()
                } label: {
                    Label("menu_exportFilters"~, systemImage: "square.and.arrow.up")
                }
                .disabled(self.model.filters.isEmpty)
                .accessibilityIdentifier(TestIdentifier.exportFiltersMenuButton.rawValue)

                Button {
                    self.model.beginFileImport()
                } label: {
                    Label("menu_importFilters"~, systemImage: "square.and.arrow.down")
                }
                .accessibilityIdentifier(TestIdentifier.importFiltersMenuButton.rawValue)
            } label: {
                Label("menu_filterTools"~, systemImage: "wrench.and.screwdriver.fill")
            }
            .accessibilityIdentifier(TestIdentifier.filterToolsMenuButton.rawValue)

            Divider()

            Button {
                self.model.requestSheet(.help)
            } label: {
                Label("filterList_menu_enableExtension"~, systemImage: "questionmark.circle")
            }

            Button {
                self.model.requestSheet(.about)
            } label: {
                Label("filterList_menu_about"~, systemImage: "info.circle")
            }

            Button {
                self.model.requestSheet(.chooseAccentColor)
            } label: {
                Label("accentColor_menuItem"~, systemImage: "paintpalette")
            }

            Button {
                self.model.requestSheet(.tipJar)
            } label: {
                Label("tipJar_menuItem"~, systemImage: "heart.fill")
            }

            if !WhatsNewEntry.allCases.isEmpty {
                Button {
                    self.model.requestSheet(.whatsNew)
                } label: {
                    Label("whatsNew_menuItem"~, systemImage: "sparkles")
                }
            }

        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .tint(.primary)
        .accessibilityLabel("a11y_home_menuButton"~)
        .accessibilityIdentifier(TestIdentifier.appMenuButton.rawValue)
    }
}


//MARK: - ViewModel -
extension AppHomeView {
    
    class ViewModel: BaseViewModel, ObservableObject, PersistentStoreReloadRefreshing {
        @Published private(set) var filters: [Filter]
        @Published private(set) var title: String
        @Published private(set) var hasActiveFilterLists: Bool
        @Published private(set) var activeCommunityListsCount: Int
        @Published private(set) var isAllUnknownFilteringOn: Bool
        @Published private(set) var shortSenderChoice: Int
        @Published private(set) var subtitle: String
        @Published private(set) var selectedCountriesSummary: String
        @Published var rules: [StatefulItem<SmartFilterType>]
        let overlayWindow: OverlayWindowModifier.ViewModel
        @Published var navigationScreen: Screen? = nil {
            didSet {
                if oldValue != self.navigationScreen {
                    Log.debug("navigation changed, screen: \(oldValue) → \(self.navigationScreen)")
                }
                if oldValue != nil,
                   self.navigationScreen == nil {
                    if !self.tryRequestReview() {
                        self.tryShowInactivityNotification()
                    }
                }
            }
        }
        @Published var sheetScreen: Screen? = nil {
            didSet {
                if self.sheetScreen == nil, let dismissed = oldValue {
                    self.completeDismissedSheet(dismissed)
                    self.appManager.flowManager.showWaitingNudge()
                }
            }
        }
        var pendingScreenAfterDismiss: Screen? {
            didSet {
                guard oldValue != self.pendingScreenAfterDismiss else { return }
                Log.debug("screen after dismiss, screen: \(oldValue) → \(self.pendingScreenAfterDismiss)")
            }
        }
        @Published var showNothingToImportAlert = false {
            didSet {
                if oldValue && !self.showNothingToImportAlert {
                    self.appManager.flowManager.showWaitingNudge()
                }
            }
        }
        @Published var showInactivityNotificationAlert = false {
            didSet {
                if oldValue && !self.showInactivityNotificationAlert {
                    self.appManager.flowManager.showWaitingNudge()
                }
            }
        }
        @Published var isImportingFile = false
        @Published var fileImporterID = UUID()
        @Published var customAccent: Color? = nil

        override init(appManager: AppManagerProtocol = AppManager.shared) {
            let hasActiveFilterLists = appManager.filterListManager.hasActiveFilterLists

            self.title = "filterList_filters"~
            self.subtitle = hasActiveFilterLists ? appManager.filterListManager.activeFilterListsTitle ?? "" : ""
            self.hasActiveFilterLists = hasActiveFilterLists
            self.activeCommunityListsCount = appManager.filterListManager.activeCommunityListsCount
            self.isAllUnknownFilteringOn = appManager.smartFilterManager.isSmartFilterActive(for: .allUnknown)
            self.shortSenderChoice = appManager.smartFilterManager.selectedChoice(for: .shortSender)
            self.filters = appManager.persistenceManager.fetchFilterRecords()
            self.rules = []
            self.overlayWindow = OverlayWindowModifier.ViewModel(appManager: appManager)
            self.selectedCountriesSummary = Self.makeCountrySummary(appManager: appManager)
            super.init(appManager: appManager)
            appManager.flowManager.setHomeIdleCheck { [weak self] in
                return self?.isHomeIdle ?? false
            }
            appManager.flowManager.setScreenPresenter { [weak self] in
                self?.presentNextScreen()
            }
            self.customAccent = Color(accentRGB: appManager.defaultsManager.accentColorRGB)
            self.lastUIFingerprint = appManager.persistenceManager.fingerprint

            self.rules = appManager.smartFilterManager.smartFilterTypes
                .map({
                    StatefulItem<SmartFilterType>(item: $0,
                                           getter: appManager.smartFilterManager.isSmartFilterActive,
                                           setter: self.setSmartFilterActive) })
                .sorted(by: { $0.id.sortIndex < $1.id.sortIndex })

            self.runLaunchFlowIfNeeded()
        }
        
        func refresh() {
            let hasActiveFilterLists = self.appManager.filterListManager.hasActiveFilterLists

            self.title = "filterList_filters"~
            self.subtitle = hasActiveFilterLists ? self.appManager.filterListManager.activeFilterListsTitle ?? "" : ""
            self.hasActiveFilterLists = hasActiveFilterLists
            self.activeCommunityListsCount = self.appManager.filterListManager.activeCommunityListsCount
            self.isAllUnknownFilteringOn = self.appManager.smartFilterManager.isSmartFilterActive(for: .allUnknown)
            self.shortSenderChoice = self.appManager.smartFilterManager.selectedChoice(for: .shortSender)
            self.filters = self.appManager.persistenceManager.fetchFilterRecords()
            self.selectedCountriesSummary = Self.makeCountrySummary(appManager: self.appManager)
            self.rules = self.appManager.smartFilterManager.smartFilterTypes.map({ StatefulItem<SmartFilterType>(item: $0,
                                                                                                   getter: self.appManager.smartFilterManager.isSmartFilterActive,
                                                                                                   setter: self.setSmartFilterActive) }).sorted(by: { $0.id.sortIndex < $1.id.sortIndex })
            self.lastUIFingerprint = self.appManager.persistenceManager.fingerprint
            if self.sheetScreen != .chooseAccentColor {
                self.customAccent = Color(accentRGB: self.appManager.defaultsManager.accentColorRGB)
            }
            self.appManager.flowManager.showWaitingNudge()
        }
        
        func setSelectedChoice(for rule: SmartFilterType, choice: Int) {
            self.appManager.smartFilterManager.setSelectedChoice(for: rule, choice: choice)
            self.refresh()
        }
        
        func activeCount(for filterType: FilterType) -> Int {
            return self.filters.filter({ $0.filterType == filterType }).count
        }

        func handleDeepLink(url: URL) {
            Log.debug("url opened, url: \(url)")
            if self.appManager.filterTransferManager.isExportFile(url) {
                self.importFromFileURL(url)
                return
            }

            guard url.scheme == "simplyfiltersms",
                  let host = url.host,
                  let screen = Screen.fromDeepLink(host: host) else {
                Log.debug("url not recognized, scheme: \(url.scheme), host: \(url.host) → ignored")
                return
            }
            if self.appManager.flowManager.recordLaunch(screen) {
                self.presentLaunch()
            }
        }

        func exportFilters() {
            _ = self.appManager.filterTransferManager.queueExport()
            self.requestSheet(.filterExport)
        }

        func beginFileImport() {
            Log.debug("file picker opened")
            self.isImportingFile = false
            DispatchQueue.main.async {
                self.isImportingFile = true
            }
        }

        func handlePickedFiles(_ result: Result<[URL], Error>) {
            self.isImportingFile = false
            self.fileImporterID = UUID()

            switch result {
            case .failure(let error):
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError {
                    Log.debug("file picker cancelled")
                    return
                }
                Log.error("file picker failed", error: error)
                self.appManager.flowManager.requestToast(.filterImportFailed)

            case .success(let urls):
                guard let url = urls.first else {
                    Log.error("file picker returned no file")
                    self.appManager.flowManager.requestToast(.filterImportFailed)
                    return
                }
                Log.debug("file picked, file: \(url.lastPathComponent)")
                self.importFromFileURL(url)
            }
        }

        func requestSheet(_ screen: Screen) {
            self.appManager.flowManager.requestScreen(screen)
        }

        private func importFromFileURL(_ url: URL) {
            Log.debug("importing, file: \(url.lastPathComponent)")
            do {
                let data = try self.appManager.filterTransferManager.readFile(at: url)
                _ = try self.appManager.filterTransferManager.queueImport(data: data)
                if self.appManager.flowManager.recordLaunch(.filterImport) {
                    self.presentLaunch(preservingImportSession: true)
                }
            } catch {
                Log.error("import failed, file: \(url.lastPathComponent)", error: error)
                self.appManager.flowManager.requestToast(.filterImportFailed)
            }
        }

        private func completeDismissedSheet(_ screen: Screen) {
            self.appManager.flowManager.completeScreen(screen)

            if screen == .whatsNew && !self.isReplacingSheetForLaunch {
                self.markWhatsNewSeen()
            }

            if screen == .filterImport, !self.isReplacingSheetForLaunch {
                if let result = self.appManager.filterTransferManager.clearPendingImport() {
                    self.appManager.flowManager.requestToast(.filtersImported(added: result.added, skipped: result.skippedCount))
                }
            }

            if screen == .filterExport {
                self.appManager.filterTransferManager.clearPendingExport()
            }

            if screen == .chooseAccentColor {
                self.customAccent = Color(accentRGB: self.appManager.defaultsManager.accentColorRGB)
            }
        }

        func presentNextScreen() {
            guard !self.isReplacingSheetForLaunch else {
                Log.debug("sheet being replaced for launch → skipped")
                return
            }
            guard let screen = self.appManager.flowManager.nextScreen() else {
                self.appManager.flowManager.showWaitingNudge()
                return
            }
            if screen == .filterImport,
               self.appManager.filterTransferManager.pendingPreview.count == 0 {
                Log.debug("import has no filters → nothing-to-import alert")
                _ = self.appManager.filterTransferManager.clearPendingImport()
                self.appManager.flowManager.completeScreen(.filterImport)
                self.showNothingToImportAlert = true
                return
            }
            self.sheetScreen = screen
        }

        func enableWhatsNewAndPresent() {
            self.appManager.flowManager.enableWhatsNew()
            self.presentNextScreen()
        }

        @MainActor
        func appBecameActive() {
            self.appManager.schedulingManager.refreshInactivityReminder()
            let didStartNewSession = self.appManager.onAppBecameActive()
            guard didStartNewSession else { return }
            self.appManager.flowManager.showSessionNudges()
        }

        private func runLaunchFlowIfNeeded() {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                return
            }
            #endif
            self.startMonitoring()
            self.enableWhatsNewAndPresent()
        }

        private func markWhatsNewSeen() {
            var defaultsManager = self.appManager.defaultsManager
            let lastSeenVersion = defaultsManager.lastSeenWhatsNewVersion
            guard lastSeenVersion < currentWhatsNewVersion else { return }
            defaultsManager.lastSeenWhatsNewVersion = currentWhatsNewVersion
            Log.debug("What's New seen, version: \(lastSeenVersion) → \(currentWhatsNewVersion)")
        }

        private func presentLaunch(preservingImportSession: Bool = false) {
            if self.sheetScreen == .filterImport && !preservingImportSession {
                _ = self.appManager.filterTransferManager.clearPendingImport()
            }
            if self.sheetScreen == .filterExport {
                self.appManager.filterTransferManager.clearPendingExport()
            }

            self.replacePresentedSheetIfNeeded()
        }

        func completeInterruptedSheet() -> Bool {
            guard self.isReplacingSheetForLaunch else { return false }
            self.isReplacingSheetForLaunch = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.presentNextScreen()
            }
            return true
        }

        private func replacePresentedSheetIfNeeded() {
            self.pendingScreenAfterDismiss = nil
            self.isImportingFile = false

            let isBlockingFirstRun = self.sheetScreen == .enableExtension
                && self.appManager.defaultsManager.isAppFirstRun
            let hasSheet = self.sheetScreen != nil

            guard hasSheet, !isBlockingFirstRun else {
                Log.debug("launch, sheet: \(self.sheetScreen), blockingFirstRun: \(isBlockingFirstRun) → presenting next")
                self.presentNextScreen()
                return
            }

            Log.debug("launch, sheet: \(self.sheetScreen) → replacing the sheet")
            self.isReplacingSheetForLaunch = true
            self.sheetScreen = nil
        }

        private var isHomeIdle: Bool {
            return self.sheetScreen == nil
                && self.pendingScreenAfterDismiss == nil
                && !self.isAlertPresented
                && !self.isReplacingSheetForLaunch
        }

        func startMonitoring() {
            self.appManager.flowManager.startAppEventToasts()

            if !didAddObservers {
                self.didAddObservers = true

                NotificationCenter.default.addObserver(forName: .cloudSyncOperationComplete, object: nil, queue: .main) { _ in
                    self.refresh()
                }

                NotificationCenter.default.addObserver(forName: .filtersSaveFailed, object: nil, queue: .main) { _ in
                    self.refresh()
                }

                NotificationCenter.default.addObserver(forName: .filtersStateChanged, object: nil, queue: .main) { _ in
                    withAnimation {
                        self.refresh()
                    }
                }

                NotificationCenter.default.addObserver(forName: .filterListsUpdated, object: nil, queue: .main) { _ in
                    self.refresh()
                }
            }

            self.catchUpFromStoreIfNeeded()
            self.appManager.flowManager.showWaitingNudge()
        }

        private func catchUpFromStoreIfNeeded() {
            let currentFingerprint = self.appManager.persistenceManager.fingerprint
            guard currentFingerprint != self.lastUIFingerprint else { return }
            Log.debug("store ahead of the UI → refreshing")
            self.refresh()
        }

        var inactivityNotificationDismissTitle: String {
            return self.appManager.schedulingManager.isFinalInactivityNotificationAsk
                ? "inactivityNotification_stopAsking"~
                : "inactivityNotification_notNow"~
        }

        func tryShowInactivityNotification() {
            Task { @MainActor [weak self] in
                guard let self,
                      await self.appManager.schedulingManager.shouldShowInactivityNotificationAlert() else { return }
                guard self.isHomeIdle else {
                    Log.debug("Home busy → inactivity alert skipped")
                    return
                }

                Log.debug("inactivity alert shown")
                self.showInactivityNotificationAlert = true
            }
        }

        func allowInactivityNotification() {
            Task { [weak self] in
                await self?.appManager.schedulingManager.requestInactivityNotificationPermission()
            }
        }

        func declineInactivityNotification() {
            self.appManager.schedulingManager.recordInactivityNotificationDecline()
        }

        func tryRequestReview() -> Bool {
            var defaultsManager = self.appManager.defaultsManager
            let didPrompt = defaultsManager.didPromptForReview
            let daysSinceInstall = defaultsManager.installDate.daysBetween(date: Date())
            let session = defaultsManager.sessionCounter
            guard !didPrompt,
                  daysSinceInstall > 7,
                  session > 5 else {
                Log.debug("not eligible, prompted: \(didPrompt), daysSinceInstall: \(daysSinceInstall), session: \(session) → skipped")
                return false
            }

            guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                Log.debug("no active scene → skipped")
                return false
            }

            SKStoreReviewController.requestReview(in: scene)
            defaultsManager.didPromptForReview = true
            Log.debug("review requested, daysSinceInstall: \(daysSinceInstall), session: \(session)")
            return true
        }
        
        #if DEBUG
        func loadDebugData() {
            self.appManager.loadDebugData()
            self.refresh()
        }

        func reset() {
            self.appManager.reset()
            self.refresh()
            self.presentNextScreen()
        }

        func fireInactivityReminder() {
            self.appManager.schedulingManager.scheduleInactivityReminderSoon()
        }

        func refreshFilterListsSoon() {
            self.appManager.debugDataManager.expireFilterListsCache()
            self.appManager.schedulingManager.scheduleFilterListsProcessingSoon()
        }

        func showDebugToast(_ toast: ToastView.Toast) {
            self.appManager.flowManager.requestToast(toast)
        }
        #endif // DEBUG
        
        private var lastUIFingerprint: String = ""
        private var didAddObservers = false
        private var isReplacingSheetForLaunch = false
        private var isAlertPresented: Bool {
            return self.showNothingToImportAlert || self.showInactivityNotificationAlert
        }
        
        private func setSmartFilterActive(for rule: SmartFilterType, value: Bool) {
            self.appManager.smartFilterManager.setSmartFilterActive(for: rule, value: value)
            self.refresh()
        }

        private static func makeCountrySummary(appManager: AppManagerProtocol) -> String {
            let codes = appManager.smartFilterManager.selectedCountries(for: .countryAllowlist)
            guard !codes.isEmpty else { return "autoFilter_countryAllowlist_empty"~ }
            let names = codes
                .compactMap { CallingCodeEntry.byCallingCode[$0] }
                .sorted { countrySortIndex($0) < countrySortIndex($1) }
                .map { $0.summaryName }
            guard let first = names.first else { return "autoFilter_countryAllowlist_empty"~ }
            if names.count == 1 {
                return first
            } else {
                return "\(first) + \(names.count - 1) \("general_more"~)"
            }
        }

        private static func countrySortIndex(_ entry: CallingCodeEntry) -> Int {
            switch entry.callingCode {
            case "+1":   return -2
            case "+972": return -1
            default:     return Int(entry.callingCode.dropFirst()) ?? Int.max
            }
        }
    }
}



//MARK: - Preview -
struct AppHomeView_Previews: PreviewProvider {
    static var previews: some View {
        AppHomeView(model: AppHomeView.ViewModel(appManager: AppManager.previews))
    }
}


