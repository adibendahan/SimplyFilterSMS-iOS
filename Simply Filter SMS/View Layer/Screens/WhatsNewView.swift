//
//  WhatsNewView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 16/02/2026.
//

import SwiftUI


//MARK: - View -
struct WhatsNewView: View {

    @Environment(\.dismiss)
    var dismiss

    @ObservedObject var model: ViewModel

    @ScaledMetric(relativeTo: .subheadline) private var iconWidth: CGFloat = 36
    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = 30
    @ScaledMetric(relativeTo: .subheadline) private var titleCapHeight: CGFloat = 10.57
    @ScaledMetric(relativeTo: .largeTitle) private var heroCollapseDistance: CGFloat = 200

    @State private var hasAppeared = false
    @State private var heroCollapse: CGFloat = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    WhatsNewOrbitView(entries: self.model.orbitEntries, hasAppeared: self.hasAppeared, collapse: self.heroCollapse)
                        .padding(.top, 8)

                    if let currentSection = self.model.currentSection {
                        self.releaseSection(currentSection, startIndex: 0)
                    }

                    if !self.model.earlierSections.isEmpty {
                        Divider()
                            .padding(.top, 28)
                            .padding(.horizontal, 28)
                            .rowEntrance(isShown: self.hasAppeared, index: self.currentEntryCount)

                        Text("whatsNew_earlierUpdates"~)
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 20)
                            .padding(.horizontal, 32)
                            .accessibilityAddTraits(.isHeader)
                            .rowEntrance(isShown: self.hasAppeared, index: self.currentEntryCount)

                        ForEach(Array(self.model.earlierSections.enumerated()), id: \.element.id) { offset, section in
                            self.releaseSection(section, startIndex: self.currentEntryCount + 1 + offset)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            .onScrollProgress(distance: self.heroCollapseDistance, progress: self.$heroCollapse)
            .modifier(BottomActionBar(bar: self.continueButton))
            .background(Color(.systemGroupedBackground))
            .navigationTitle("whatsNew_title"~)
            .modifier(AppNameSubtitle())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.model.markAsSeen()
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.primary)
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier(TestIdentifier.cancelButton.rawValue)
                }
            }
            .onAppear {
                self.hasAppeared = true
            }
        }
    }


    //MARK: - Private -
    private var currentEntryCount: Int {
        return self.model.currentSection?.entries.count ?? 0
    }

    private var continueButton: some View {
        Button {
            self.model.markAsSeen()
            self.dismiss()
        } label: {
            Text("whatsNew_continue"~)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(FilledButton())
        .accessibilityIdentifier(TestIdentifier.callToActionButton.rawValue)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func releaseSection(_ section: ViewModel.ReleaseSection, startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 32)
                .accessibilityAddTraits(.isHeader)
                .rowEntrance(isShown: self.hasAppeared, index: startIndex)

            self.entryList(section.entries, startIndex: startIndex)
        }
        .padding(.top, 20)
    }

    private func entryList(_ entries: [WhatsNewEntry], startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(entries.enumerated()), id: \.element) { offset, entry in
                self.entryRow(entry, index: startIndex + offset)
            }
        }
        .padding(.horizontal, 32)
    }

    private func entryRow(_ entry: WhatsNewEntry, index: Int) -> some View {
        AdaptiveRow(compactAlignment: .firstTextBaseline, compactSpacing: 14) {
            Image(systemName: entry.imageName)
                .resizable()
                .scaledToFit()
                .foregroundColor(entry.color)
                .frame(maxWidth: self.iconSize * entry.iconScale, maxHeight: self.iconSize * entry.iconScale)
                .bounceOnAppear(isShown: self.hasAppeared, delay: RowMotion.delay(for: index) + RowMotion.iconBounceLag, bouncesOnTap: true)
                .accessibilityHidden(true)
                .frame(width: self.iconWidth)
                .alignmentGuide(.firstTextBaseline) { dimensions in
                    dimensions[.top] + self.titleCapHeight
                }
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    self.descriptionText(entry.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)

                if let actionTitle = entry.actionTitle, self.model.onActionableEntryTapped != nil {
                    Button {
                        self.model.markAsSeen()
                        self.model.onActionableEntryTapped?(entry)
                        self.dismiss()
                    } label: {
                        Text(actionTitle)
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 4)
                }
            }
        }
        .rowEntrance(isShown: self.hasAppeared, index: index)
        .scrollFocus()
    }

    private func descriptionText(_ description: String) -> Text {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let result: Text
        if let attributed = try? AttributedString(markdown: description, options: options) {
            result = Text(attributed)
        } else {
            result = Text(description)
        }
        return result
    }
}


//MARK: - Motion -
private enum RowMotion {
    static let rise: CGFloat = 28
    static let blur: CGFloat = 6
    static let animation = Animation.spring(response: 0.6, dampingFraction: 0.82)
    static let iconBounceLag: Double = 0.2

    static func delay(for index: Int) -> Double {
        return Stagger.delay(for: index, step: 0.08, base: 0.35, limit: 6)
    }
}

private extension View {
    func rowEntrance(isShown: Bool, index: Int) -> some View {
        return self.entrance(isShown: isShown, delay: RowMotion.delay(for: index), rise: RowMotion.rise, blur: RowMotion.blur, animation: RowMotion.animation)
    }
}


//MARK: - Layout -
private struct AppNameSubtitle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .navigationSubtitle("Simply Filter SMS")
        } else {
            content
        }
    }
}

private struct BottomActionBar<Bar: View>: ViewModifier {
    let bar: Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .safeAreaBar(edge: .bottom) {
                    self.bar
                }
        } else {
            content
                .safeAreaInset(edge: .bottom) {
                    self.bar
                        .background(Color(.systemGroupedBackground).ignoresSafeArea())
                }
        }
    }
}


//MARK: - ViewModel -
extension WhatsNewView {

    class ViewModel: BaseViewModel, ObservableObject {
        struct ReleaseSection: Identifiable {
            let release: String
            let title: String
            let entries: [WhatsNewEntry]

            var id: String {
                return self.release
            }
        }

        let orbitEntries: [WhatsNewEntry]
        let currentSection: ReleaseSection?
        let earlierSections: [ReleaseSection]
        var onActionableEntryTapped: ((WhatsNewEntry) -> Void)?

        init(appManager: AppManagerProtocol = AppManager.shared, onActionableEntryTapped: ((WhatsNewEntry) -> Void)? = nil) {
            let entries = WhatsNewEntry.allCases.sorted { $0.order < $1.order }
            let sections = ViewModel.releaseSections(for: entries)
            self.orbitEntries = ViewModel.orbitEntries(from: entries)
            self.currentSection = sections.first
            self.earlierSections = Array(sections.dropFirst())
            self.onActionableEntryTapped = onActionableEntryTapped
            super.init(appManager: appManager)
        }

        func markAsSeen() {
            var defaultsManager = self.appManager.defaultsManager
            let lastSeenVersion = defaultsManager.lastSeenWhatsNewVersion
            guard lastSeenVersion < currentWhatsNewVersion else { return }
            defaultsManager.lastSeenWhatsNewVersion = currentWhatsNewVersion
            Log.debug("What's New seen, version: \(lastSeenVersion) → \(currentWhatsNewVersion)")
        }


        //MARK: - Private -
        private static func orbitEntries(from entries: [WhatsNewEntry]) -> [WhatsNewEntry] {
            let orbitEntries = entries.filter(\.isInOrbit)
            let currentEntries = orbitEntries.filter(\.isCurrent).shuffled()
            let earlierEntries = orbitEntries.filter { !$0.isCurrent }.shuffled()
            let startsWithCurrent = Bool.random()
            var leading = startsWithCurrent ? currentEntries : earlierEntries
            var trailing = startsWithCurrent ? earlierEntries : currentEntries
            var result: [WhatsNewEntry] = []
            while !leading.isEmpty || !trailing.isEmpty {
                if !leading.isEmpty {
                    result.append(leading.removeFirst())
                }
                if !trailing.isEmpty {
                    result.append(trailing.removeFirst())
                }
            }
            return result
        }

        private static func releaseSections(for entries: [WhatsNewEntry]) -> [ReleaseSection] {
            var releases: [String] = []
            for entry in entries where !releases.contains(entry.release) {
                releases.append(entry.release)
            }

            var sections: [ReleaseSection] = []
            for release in releases {
                let title = String(format: "whatsNew_version"~, release)
                let releaseEntries = entries.filter { $0.release == release }
                sections.append(ReleaseSection(release: release, title: title, entries: releaseEntries))
            }
            return sections
        }
    }
}


//MARK: - Preview -
struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(model: WhatsNewView.ViewModel(appManager: AppManager.previews, onActionableEntryTapped: { _ in }))
    }
}
