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

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @ObservedObject var model: ViewModel

    @ScaledMetric(relativeTo: .subheadline) private var iconWidth: CGFloat = 36
    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = 30
    @ScaledMetric(relativeTo: .subheadline) private var titleCapHeight: CGFloat = 10.57
    @ScaledMetric(relativeTo: .largeTitle) private var heroCollapseDistance: CGFloat = 200

    @State private var hasAppeared = false
    @State private var heroCollapse: CGFloat = 0

    private let rowEntranceDelay: Double = 0.35
    private let rowEntranceStagger: Double = 0.08
    private let staggeredRowLimit = 6

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    OrbitHeroView(entries: self.model.orbitEntries, hasAppeared: self.hasAppeared, collapse: self.heroCollapse)
                        .padding(.top, 8)

                    if !self.showsVersionAsSubtitle {
                        Text(self.model.versionText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }

                    self.entryList(self.model.currentEntries, startIndex: 0)
                        .padding(.top, 24)

                    if !self.model.earlierSections.isEmpty {
                        Divider()
                            .padding(.top, 28)
                            .padding(.horizontal, 28)
                            .modifier(EntranceModifier(isVisible: self.hasAppeared, delay: self.entranceDelay(for: self.model.currentEntries.count), reduceMotion: self.reduceMotion))

                        Text("whatsNew_earlierUpdates"~)
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 20)
                            .padding(.horizontal, 32)
                            .accessibilityAddTraits(.isHeader)
                            .modifier(EntranceModifier(isVisible: self.hasAppeared, delay: self.entranceDelay(for: self.model.currentEntries.count), reduceMotion: self.reduceMotion))

                        ForEach(Array(self.model.earlierSections.enumerated()), id: \.element.id) { offset, section in
                            self.releaseSection(section, startIndex: self.model.currentEntries.count + 1 + offset)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            .modifier(ScrollCollapseReader(distance: self.heroCollapseDistance, progress: self.$heroCollapse))
            .modifier(BottomActionBar(bar: self.continueButton))
            .background(Color(.systemBackground))
            .navigationTitle("whatsNew_title"~)
            .modifier(VersionSubtitle(text: self.model.versionText))
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
    private var showsVersionAsSubtitle: Bool {
        let result: Bool
        if #available(iOS 26.0, *) {
            result = true
        } else {
            result = false
        }
        return result
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

    private func entranceDelay(for index: Int) -> Double {
        let staggerIndex = min(index, self.staggeredRowLimit)
        return self.rowEntranceDelay + self.rowEntranceStagger * Double(staggerIndex)
    }

    private func releaseSection(_ section: ViewModel.ReleaseSection, startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 32)
                .accessibilityAddTraits(.isHeader)
                .modifier(EntranceModifier(isVisible: self.hasAppeared, delay: self.entranceDelay(for: startIndex), reduceMotion: self.reduceMotion))

            self.entryList(section.entries, startIndex: startIndex)
        }
        .padding(.top, 20)
    }

    private func entryList(_ entries: [WhatsNewEntry], startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(entries.enumerated()), id: \.element) { offset, entry in
                self.entryRow(entry, delay: self.entranceDelay(for: startIndex + offset))
            }
        }
        .padding(.horizontal, 32)
    }

    private func entryRow(_ entry: WhatsNewEntry, delay: Double) -> some View {
        AdaptiveRow(compactAlignment: .firstTextBaseline, compactSpacing: 14) {
            EntryIconView(entry: entry, size: self.iconSize * entry.iconScale, hasAppeared: self.hasAppeared, delay: delay + 0.2)
                .frame(width: self.iconWidth)
                .alignmentGuide(.firstTextBaseline) { dimensions in
                    dimensions[.top] + self.titleCapHeight
                }
        } content: {
            VStack(alignment: .leading, spacing: 3) {
                VStack(alignment: .leading, spacing: 3) {
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
        .modifier(EntranceModifier(isVisible: self.hasAppeared, delay: delay, reduceMotion: self.reduceMotion))
        .modifier(ScrollFocusModifier(reduceMotion: self.reduceMotion))
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

private struct OrbitHeroView: View {
    let entries: [WhatsNewEntry]
    let hasAppeared: Bool
    let collapse: CGFloat

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var logoSize: CGFloat = 92
    @ScaledMetric(relativeTo: .largeTitle) private var orbitRadius: CGFloat = 104
    @ScaledMetric(relativeTo: .largeTitle) private var satelliteSize: CGFloat = 44

    @State private var spinBoost: Double = 0
    @State private var logoBounce = false

    private let secondsPerRevolution: Double = 48
    private let secondsPerPulse: Double = 2.4

    var body: some View {
        TimelineView(.animation(paused: self.reduceMotion)) { context in
            let drift = self.driftAngle(at: context.date)
            let pulse = self.pulsePhase(at: context.date)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
                    .frame(width: self.orbitRadius * 2, height: self.orbitRadius * 2)
                    .scaleEffect((self.hasAppeared ? 1 : 0.4) * (1 - 0.75 * self.motionCollapse))
                    .opacity(self.hasAppeared ? 1 - self.motionCollapse : 0)
                    .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.1), value: self.hasAppeared)

                ForEach(Array(self.entries.enumerated()), id: \.element) { index, entry in
                    self.satellite(entry, index: index, drift: drift, pulse: pulse)
                }

                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.logoSize, height: self.logoSize)
                    .clipShape(RoundedRectangle(cornerRadius: self.logoSize * 0.225, style: .continuous))
                    .shadow(color: Color.green.opacity(0.35 * (1 - self.motionCollapse)), radius: self.hasAppeared ? 24 : 0, y: 8)
                    .scaleEffect(self.logoScale)
                    .rotationEffect(.degrees(self.hasAppeared ? 0 : -12))
                    .animation(.spring(response: 0.55, dampingFraction: 0.55), value: self.hasAppeared)
                    .animation(.spring(response: 0.35, dampingFraction: 0.45), value: self.logoBounce)
                    .scaleEffect(1 - 0.45 * self.logoCollapse)
                    .opacity(1 - self.logoCollapse)
                    .blur(radius: 8 * self.logoCollapse)
                    .onTapGesture {
                        self.logoTapped()
                    }
            }
            .offset(y: self.orbitRadius * 0.7 * self.motionCollapse)
            .opacity(self.reduceMotion ? 1 - self.collapse : 1)
            .frame(height: self.orbitRadius * 2 + self.satelliteSize)
            .frame(maxWidth: .infinity)
        }
        .accessibilityHidden(true)
    }

    private var motionCollapse: CGFloat {
        let result: CGFloat
        if self.reduceMotion {
            result = 0
        } else {
            result = self.collapse
        }
        return result
    }

    private var logoCollapse: CGFloat {
        return self.collapseStage(start: 0.45, length: 0.55)
    }

    private func collapseStage(start: CGFloat, length: CGFloat) -> CGFloat {
        let raw = (self.motionCollapse - start) / length
        return min(max(raw, 0), 1)
    }

    private var logoScale: CGFloat {
        let result: CGFloat
        if !self.hasAppeared {
            result = 0.5
        } else if self.logoBounce {
            result = 1.08
        } else {
            result = 1
        }
        return result
    }

    private func driftAngle(at date: Date) -> Double {
        guard !self.reduceMotion else { return 0 }
        let seconds = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: self.secondsPerRevolution)
        return seconds / self.secondsPerRevolution * 2 * .pi
    }

    private func pulsePhase(at date: Date) -> Double {
        guard !self.reduceMotion else { return 0 }
        let seconds = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: self.secondsPerPulse)
        return seconds / self.secondsPerPulse
    }

    private func satellite(_ entry: WhatsNewEntry, index: Int, drift: Double, pulse: Double) -> some View {
        let count = Double(max(self.entries.count, 1))
        let baseAngle = Double(index) / count * 2 * .pi - .pi / 2
        let pull = self.collapseStage(start: 0.05 * CGFloat(index), length: 0.55)
        let swirl = Double(pull) * .pi * 0.75
        let angle = baseAngle + drift + self.spinBoost + swirl
        let radius = self.hasAppeared ? self.orbitRadius * (1 - pull) : 0
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        let delay = 0.15 + 0.06 * Double(index)
        let emphasis: CGFloat = entry.isCurrent ? 1.18 : 0.92
        let haloOpacity = entry.isCurrent && !self.reduceMotion ? (1 - pulse) * 0.6 : 0

        return ZStack {
            Circle()
                .stroke(entry.color, lineWidth: 1.5)
                .scaleEffect(1 + pulse * 0.6)
                .opacity(haloOpacity)

            Circle()
                .fill(entry.color.opacity(entry.isCurrent ? 0.24 : 0.14))

            Image(systemName: entry.imageName)
                .resizable()
                .scaledToFit()
                .foregroundColor(entry.color)
                .frame(width: self.satelliteSize * 0.48 * entry.iconScale, height: self.satelliteSize * 0.48 * entry.iconScale)
        }
        .frame(width: self.satelliteSize, height: self.satelliteSize)
        .scaleEffect(self.hasAppeared ? emphasis * (1 - 0.7 * pull) : 0.2)
        .opacity(self.hasAppeared ? 1 - pull : 0)
        .offset(x: x, y: y)
        .animation(.spring(response: 0.75, dampingFraction: 0.62).delay(delay), value: self.hasAppeared)
    }

    private func logoTapped() {
        guard !self.reduceMotion else { return }
        withAnimation(.spring(response: 1.1, dampingFraction: 0.75)) {
            self.spinBoost += 2 * .pi
        }
        self.logoBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            self.logoBounce = false
        }
    }
}

private struct EntryIconView: View {
    let entry: WhatsNewEntry
    let size: CGFloat
    let hasAppeared: Bool
    let delay: Double

    @State private var bounceTrigger = 0

    var body: some View {
        Image(systemName: self.entry.imageName)
            .resizable()
            .scaledToFit()
            .foregroundColor(self.entry.color)
            .frame(maxWidth: self.size, maxHeight: self.size)
            .symbolEffect(.bounce, value: self.bounceTrigger)
            .accessibilityHidden(true)
            .onChange(of: self.hasAppeared) { _, isVisible in
                guard isVisible else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                    self.bounceTrigger += 1
                }
            }
            .onTapGesture {
                self.bounceTrigger += 1
            }
    }
}

private struct EntranceModifier: ViewModifier {
    let isVisible: Bool
    let delay: Double
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(self.isVisible ? 1 : 0)
            .offset(y: self.isVisible || self.reduceMotion ? 0 : 28)
            .blur(radius: self.isVisible || self.reduceMotion ? 0 : 6)
            .animation(.spring(response: 0.6, dampingFraction: 0.82).delay(self.delay), value: self.isVisible)
    }
}

private struct ScrollFocusModifier: ViewModifier {
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .scrollTransition(.animated(.smooth)) { view, phase in
                view
                    .opacity(phase.isIdentity ? 1 : 0.35)
                    .scaleEffect(phase.isIdentity || self.reduceMotion ? 1 : 0.94)
                    .blur(radius: phase.isIdentity || self.reduceMotion ? 0 : 1.5)
            }
    }
}

private struct ScrollCollapseReader: ViewModifier {
    let distance: CGFloat
    @Binding var progress: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, offset in
                    self.progress = min(max(offset / self.distance, 0), 1)
                }
        } else {
            content
        }
    }
}

private struct VersionSubtitle: ViewModifier {
    let text: String

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .navigationSubtitle(self.text)
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
                        .background(Color(.systemBackground).ignoresSafeArea())
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
        let currentEntries: [WhatsNewEntry]
        let earlierSections: [ReleaseSection]
        let versionText: String
        var onActionableEntryTapped: ((WhatsNewEntry) -> Void)?

        private static let orbitCapacity = 6

        init(appManager: AppManagerProtocol = AppManager.shared, onActionableEntryTapped: ((WhatsNewEntry) -> Void)? = nil) {
            let entries = WhatsNewEntry.allCases.sorted { $0.order < $1.order }
            let earlierEntries = entries.filter { !$0.isCurrent }
            self.orbitEntries = Array(entries.prefix(ViewModel.orbitCapacity))
            self.currentEntries = entries.filter { $0.isCurrent }
            self.earlierSections = ViewModel.releaseSections(for: earlierEntries)
            self.versionText = String(format: "whatsNew_version"~, appVersion)
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
