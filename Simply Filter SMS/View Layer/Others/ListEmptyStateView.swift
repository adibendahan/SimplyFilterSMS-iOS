//
//  ListEmptyStateView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 18/11/2026.
//

import SwiftUI


//MARK: - View -
struct ListEmptyStateView: View {

    enum Kind: Hashable, CaseIterable {
        case filterList(FilterType)
        case communityLists

        static var allCases: [Kind] {
            return FilterType.allCases.map { .filterList($0) } + [.communityLists]
        }

        var title: String {
            switch self {
            case .filterList(.deny):
                return "filterList_empty_denied"~
            case .filterList(.allow):
                return "filterList_empty_allowed"~
            case .filterList(.denyLanguage):
                return "filterList_empty_deniedLanguage"~
            case .communityLists:
                return "communityLists_empty"~
            }
        }

        var caption: String {
            switch self {
            case .filterList(.deny):
                return "filterList_empty_denied_caption"~
            case .filterList(.allow):
                return "filterList_empty_allowed_caption"~
            case .filterList(.denyLanguage):
                return "filterList_empty_deniedLanguage_caption"~
            case .communityLists:
                return "communityLists_empty_caption"~
            }
        }

        var illustration: Illustration {
            switch self {
            case .filterList(.deny):
                return .message("filterList_empty_denied_sample"~)
            case .filterList(.allow):
                return .message("filterList_empty_allowed_sample"~)
            case .filterList(.denyLanguage):
                return .message("filterList_empty_deniedLanguage_sample"~)
            case .communityLists:
                return .lists
            }
        }

        var badgeIconName: String {
            switch self {
            case .filterList(.deny):
                return "xmark"
            case .filterList(.allow):
                return "checkmark"
            case .filterList(.denyLanguage):
                return "globe"
            case .communityLists:
                return "person.2.fill"
            }
        }

        var color: Color {
            switch self {
            case .filterList(let filterType):
                return filterType.iconColor
            case .communityLists:
                return .indigo
            }
        }

        var style: Style {
            switch self {
            case .filterList:
                return .regular
            case .communityLists:
                return .compact
            }
        }
    }

    enum Style {
        case regular
        case compact

        var spacing: CGFloat {
            switch self {
            case .regular:
                return 10
            case .compact:
                return 6
            }
        }

        var illustrationSpacing: CGFloat {
            switch self {
            case .regular:
                return 14
            case .compact:
                return 6
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .regular:
                return 22
            case .compact:
                return 8
            }
        }

        var titleFont: Font {
            switch self {
            case .regular:
                return .title2.bold()
            case .compact:
                return .title3.bold()
            }
        }
    }

    enum Illustration {
        case message(String)
        case lists
    }

    struct Action {
        let title: String
        let iconName: String
        let testIdentifier: TestIdentifier
        let perform: () -> Void
    }

    struct Presence: Equatable {
        var isShown = false
        var appearance = UUID()
        var pendingArrival: UUID? = nil

        var isActive: Bool {
            return self.isShown || self.pendingArrival != nil
        }
    }

    struct PresenceTracker: ViewModifier {
        let isEmpty: Bool
        @Binding var presence: Presence

        func body(content: Content) -> some View {
            content
                .onAppear {
                    guard self.presence.isActive != self.isEmpty else { return }
                    self.presence = Presence(isShown: self.isEmpty)
                }
                .onChange(of: self.isEmpty) { _, isEmpty in
                    self.update(isEmpty: isEmpty)
                }
        }

        private func update(isEmpty: Bool) {
            if isEmpty {
                self.arrive()
            } else {
                self.leave()
            }
        }

        private func arrive() {
            let arrival = UUID()
            withAnimation(.easeOut(duration: Motion.footerFadeDuration)) {
                self.presence = Presence(isShown: false, pendingArrival: arrival)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Motion.arrivalDelay) {
                guard self.presence.pendingArrival == arrival else { return }
                withAnimation {
                    self.presence = Presence(isShown: true)
                }
            }
        }

        private func leave() {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                self.presence = Presence()
            }
        }
    }

    let kind: Kind
    var action: Action? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isPreview) private var isPreview

    @ScaledMetric(relativeTo: .body) private var regularIllustrationHeight: CGFloat = 124
    @ScaledMetric(relativeTo: .body) private var compactIllustrationHeight: CGFloat = 76
    @ScaledMetric(relativeTo: .subheadline) private var twoCaptionLinesHeight: CGFloat = 40

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: self.kind.style.spacing) {
            self.illustrationContent
                .frame(minHeight: self.illustrationHeight)
                .padding(.bottom, self.kind.style.illustrationSpacing)
                .entrance(isShown: self.isRevealed, rise: Motion.illustrationRise, scale: Motion.illustrationStartScale)
                .accessibilityHidden(true)

            Text(self.kind.title)
                .font(self.kind.style.titleFont)
                .multilineTextAlignment(.center)
                .entrance(isShown: self.isRevealed, delay: Motion.titleDelay)

            Text(self.kind.caption)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: self.captionMinHeight, alignment: .top)
                .entrance(isShown: self.isRevealed, delay: Motion.captionDelay)

            if let action = self.action {
                Button {
                    action.perform()
                } label: {
                    HStack {
                        Image(systemName: action.iconName)
                        Text(action.title)
                    }
                    .fontWeight(.semibold)
                }
                .buttonStyle(FilledButton())
                .padding(.top, 10)
                .accessibilityIdentifier(action.testIdentifier.rawValue)
                .entrance(isShown: self.isRevealed, delay: Motion.buttonDelay)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, self.kind.style.verticalPadding)
        .onAppear {
            self.playEntrance()
        }
    }

    @ViewBuilder
    private var illustrationContent: some View {
        let badge = IllustrationBadge(iconName: self.kind.badgeIconName,
                                      color: self.kind.color,
                                      isShown: self.isRevealed || self.reduceMotion)

        switch self.kind.illustration {
        case .message(let sample):
            MessageIllustration(sample: sample, badge: badge)
        case .lists:
            ListsIllustration(badge: badge)
        }
    }

    private var illustrationHeight: CGFloat {
        switch self.kind.style {
        case .regular:
            return self.regularIllustrationHeight
        case .compact:
            return self.compactIllustrationHeight
        }
    }

    private var captionMinHeight: CGFloat? {
        switch self.kind.style {
        case .regular:
            return self.twoCaptionLinesHeight
        case .compact:
            return nil
        }
    }

    private var isRevealed: Bool {
        return self.hasAppeared || self.isPreview
    }

    private func playEntrance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Motion.entranceDelay) {
            self.hasAppeared = true
        }
    }
}


//MARK: - Motion -
private enum Motion {
    static let entranceDelay: TimeInterval = 0.25
    static let arrivalDelay: TimeInterval = 0.35
    static let footerFadeDuration: TimeInterval = 0.15
    static let titleDelay: TimeInterval = 0.3
    static let captionDelay: TimeInterval = 0.36
    static let buttonDelay: TimeInterval = 0.42
    static let badgePopDelay: TimeInterval = 0.22
    static let badgeBounceDelay: TimeInterval = 0.45
    static let illustrationRise: CGFloat = 28
    static let illustrationStartScale: CGFloat = 0.6
    static let badgeSpring = Animation.spring(response: 0.42, dampingFraction: 0.45)
}


//MARK: - Illustrations -
private enum IllustrationColor {
    static let rowBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let shape = Color.gray.opacity(0.18)
    static let fadedShape = Color.gray.opacity(0.1)
    static let line = Color.gray.opacity(0.25)
}

private struct IllustrationBadge: ViewModifier {
    let iconName: String
    let color: Color
    let isShown: Bool

    @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = 30
    private let ringWidth: CGFloat = 3
    private let overlap: CGFloat = 10

    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content
                .padding(.top, self.outerSize / 2)
                .padding(.trailing, self.outerSize - self.overlap)

            Image(systemName: self.iconName)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .bounceOnAppear(isShown: self.isShown, delay: Motion.badgeBounceDelay)
                .frame(width: self.badgeSize, height: self.badgeSize)
                .background(self.color, in: Circle())
                .padding(self.ringWidth)
                .background(IllustrationColor.rowBackground, in: Circle())
                .scaleEffect(self.isShown ? 1 : 0.01)
                .animation(Motion.badgeSpring.delay(Motion.badgePopDelay), value: self.isShown)
        }
    }

    private var outerSize: CGFloat {
        return self.badgeSize + self.ringWidth * 2
    }
}

private struct MessageIllustration: View {
    let sample: String
    let badge: IllustrationBadge

    @ScaledMetric(relativeTo: .subheadline) private var width: CGFloat = 250

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(self.sample)
                .font(.subheadline)
                .lineLimit(3)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(IllustrationColor.shape, in: Self.bubbleShape)
                .modifier(self.badge)

            PlaceholderLines(widths: [124, 74])
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(IllustrationColor.fadedShape, in: Self.bubbleShape)
        }
        .frame(width: self.width, alignment: .leading)
    }

    private static let bubbleShape = UnevenRoundedRectangle(
        topLeadingRadius: 18,
        bottomLeadingRadius: 6,
        bottomTrailingRadius: 18,
        topTrailingRadius: 18,
        style: .continuous)
}

private struct ListsIllustration: View {
    let badge: IllustrationBadge

    var body: some View {
        ZStack(alignment: .topLeading) {
            Self.cardShape
                .fill(IllustrationColor.fadedShape)
                .frame(width: 156, height: 52)
                .padding(.leading, 22)

            HStack {
                PlaceholderLines(widths: [110, 70])
                Spacer(minLength: 10)
                Capsule()
                    .fill(IllustrationColor.line)
                    .frame(width: 30, height: 18)
            }
            .padding(.horizontal, 14)
            .frame(width: 200, height: 58)
            .background(IllustrationColor.shape, in: Self.cardShape)
            .background(IllustrationColor.rowBackground, in: Self.cardShape)
            .modifier(self.badge)
        }
    }

    private static let cardShape = RoundedRectangle(cornerRadius: 14, style: .continuous)
}

private struct PlaceholderLines: View {
    let widths: [CGFloat]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(self.widths, id: \.self) { width in
                Capsule()
                    .fill(IllustrationColor.line)
                    .frame(width: width, height: 8)
            }
        }
    }
}


//MARK: - Preview -
struct ListEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ForEach(ListEmptyStateView.Kind.allCases, id: \.self) { kind in
                Section {
                    ListEmptyStateView(kind: kind)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
