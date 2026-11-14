//
//  ToastView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 08/02/2022.
//

import SwiftUI
import UIKit
import Foundation

struct ToastView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.needsStackedLayout) private var needsStackedLayout
    @ObservedObject var model: ViewModel
    @State private var offset: CGFloat = -200
    @State private var isVisible = false

    private let kHideOffset: CGFloat = -200
    private let kShowOffset: CGFloat = 25

    var body: some View {
        Group {
            if needsStackedLayout {
                accessibilityLayout
            } else {
                compactLayout
            }
        }
        .limitedDynamicTypeSize(.accessibility1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(self.model.onTap == nil ? [] : .isButton)
        .accessibilityAction {
            self.performTap()
        }
        .accessibilityActions {
            if self.model.hasSeparateButtonAction {
                Button(self.model.buttonTitle) {
                    self.model.onButtonTap?()
                }
            }
        }
        .modifier(ToastGlassBackground())
        .gesture(dismissDragGesture)
        .onGeometryChange(for: CGRect.self) { geometry in
            geometry.frame(in: .global)
        } action: { frame in
            self.model.visibleFrame = frame
        }
        .offset(y: self.offset)
        .opacity(self.isVisible ? 1 : 0)
        .accessibilityHidden(offset != kShowOffset)
        .onTapGesture {
            self.performTap()
        }
        .onReceive(model.$show) { show in
            withAnimation {
                self.setShow(show)
            }
        }
    }

    private func announce() {
        let announcement = NSAttributedString(
            string: "\(self.model.title). \(self.model.subtitle)",
            attributes: [.accessibilitySpeechAnnouncementPriority: UIAccessibilityPriority.high]
        )
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    private func slideAnimation(initialVelocity: CGFloat) -> Animation? {
        guard !self.reduceMotion else { return nil }
        return .interpolatingSpring(mass: 1, stiffness: 200, damping: 30, initialVelocity: initialVelocity)
    }

    private func hideAfterSlideOut() {
        guard self.offset == kHideOffset else { return }
        self.setVisible(false)
    }

    private func setVisible(_ visible: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            self.isVisible = visible
        }
    }

    private func performTap() {
        if let onTap = self.model.onTap {
            onTap()
        } else {
            self.model.onButtonTap?()
        }
    }

    private func setShow(_ show: Bool) {
        if show && self.offset == kHideOffset {
            self.setVisible(true)
            withAnimation(self.slideAnimation(initialVelocity: 25)) {
                self.offset = kShowOffset
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if UIAccessibility.isVoiceOverRunning {
                self.announce()
            }
        }
        else if !show && self.offset == kShowOffset {
            withAnimation(self.slideAnimation(initialVelocity: 0), completionCriteria: .removed) {
                self.offset = kHideOffset
            } completion: {
                self.hideAfterSlideOut()
            }
            let callback = self.model.onHide
            self.model.onHide = nil
            callback?()
        }
    }

    private var compactLayout: some View {
        HStack(alignment: .center, spacing: 8) {
            toastIcon
            textColumn
            actionButton
        }
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                toastIcon
                textColumn
            }
            actionButton
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var toastIcon: some View {
        Image(systemName: self.model.icon)
            .font(.body)
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 0))
            .foregroundStyle(self.model.iconColor)
    }

    private var textColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(self.model.title)
                .font(.caption.bold())
                .foregroundColor(.primary)

            Text(self.model.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 4))
        .if(needsStackedLayout) { content in
            content
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionButton: some View {
        Button {
            self.model.onButtonTap?()
        } label: {
            Text(self.model.buttonTitle)
                .font(.caption.bold())
                .foregroundColor(.primary)
                .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                .modifier(ToastActionChipBackground())
        }
        .modifier(ToastActionButtonStyle())
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onChanged { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height

                if abs(horizontalAmount) < abs(verticalAmount) && verticalAmount < -20 {
                    self.model.onButtonTap?()
                }
            }
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height

                if abs(horizontalAmount) < abs(verticalAmount) && verticalAmount < 0 {
                    self.model.onButtonTap?()
                }
            }
    }

    class ViewModel: ObservableObject {
        @Published var icon: String
        @Published var iconColor: Color
        @Published var title: String
        @Published var subtitle: String
        @Published var buttonTitle: String
        @Published var onButtonTap: (() -> ())?
        var onTap: (() -> Void)?
        private(set) var hasSeparateButtonAction: Bool
        @Published var show: Bool {
            didSet {
                if show {
                    scheduleAutoHide()
                } else {
                    autoHideWork?.cancel()
                    autoHideWork = nil
                }
            }
        }
        var onHide: (() -> Void)?
        var visibleFrame: CGRect = .zero

        private var currentTimeout: TimeInterval?
        private var autoHideWork: DispatchWorkItem?

        init(toast: Toast) {
            self.icon = toast.icon
            self.iconColor = toast.iconColor
            self.title = toast.title
            self.subtitle = toast.subtitle
            self.buttonTitle = toast.buttonTitle
            self.currentTimeout = toast.timeout
            self.hasSeparateButtonAction = toast.hasSeparateButtonAction
            self.show = false
            self.onButtonTap = { [weak self] in
                withAnimation {
                    self?.show = false
                }
            }
        }

        func setToast(_ toast: Toast) {
            self.icon = toast.icon
            self.iconColor = toast.iconColor
            self.title = toast.title
            self.subtitle = toast.subtitle
            self.buttonTitle = toast.buttonTitle
            self.currentTimeout = toast.timeout
            self.hasSeparateButtonAction = toast.hasSeparateButtonAction
        }

        func setOnButtonTap(_ newOnButtonTap: (() -> ())?) {
            self.onButtonTap = {
                guard self.show else { return }
                newOnButtonTap?()
                withAnimation {
                    self.show = false
                }
            }
        }

        private func scheduleAutoHide() {
            autoHideWork?.cancel()
            guard let timeout = currentTimeout else { return }
            let work = DispatchWorkItem { [weak self] in
                Log.debug("toast timed out, timeout: \(duration: timeout) → hiding")
                withAnimation {
                    self?.show = false
                }
            }
            autoHideWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: work)
        }
    }

    enum Toast: Equatable {
        case offline, cloudSyncOperationComplete, filterListsUpdated(FilterListCatalogEntryType), onClipboardSet(String), tipSuccessful(TipTier), tipPromotion, enableReportingExtension, filtersImported(added: Int, skipped: Int), filterImportFailed, filterExportFailed, saveFailed

        var logName: String {
            let mirror = Mirror(reflecting: self)
            guard let caseName = mirror.children.first?.label else { return "\(self)" }
            return caseName
        }

        var icon: String {
            switch self {
            case .offline:
                return "icloud.slash.fill"
            case .cloudSyncOperationComplete:
                return "icloud.and.arrow.down.fill"
            case .filterListsUpdated:
                return "bolt.shield.fill"
            case .onClipboardSet:
                return "doc.on.clipboard.fill"
            case .tipSuccessful:
                return "heart.fill"
            case .tipPromotion:
                return "heart.fill"
            case .enableReportingExtension:
                return "exclamationmark.message.fill"
            case .filtersImported:
                return "square.and.arrow.down.fill"
            case .filterImportFailed, .filterExportFailed, .saveFailed:
                return "exclamationmark.triangle.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .offline:
                return .red.opacity(0.4)
            case .cloudSyncOperationComplete:
                return .green.opacity(0.6)
            case .filterListsUpdated:
                return .indigo.opacity(0.6)
            case .onClipboardSet:
                return .primary.opacity(0.6)
            case .tipSuccessful:
                return .pink.opacity(0.8)
            case .tipPromotion:
                return .pink.opacity(0.8)
            case .enableReportingExtension:
                return .green.opacity(0.8)
            case .filtersImported:
                return .green.opacity(0.6)
            case .filterImportFailed, .filterExportFailed, .saveFailed:
                return .red.opacity(0.6)
            }
        }


        var title: String {
            switch self {
            case .offline:
                return "notification_offline_title"~
            case .cloudSyncOperationComplete:
                return "notification_sync_title"~
            case .filterListsUpdated(let entryType):
                switch entryType {
                case .aiFilteringLanguage:
                    return "notification_automatic_title"~
                case .curatedCommunityList:
                    return "communityLists_title"~
                }
            case .onClipboardSet(let contentDescription):
                return contentDescription
            case .tipSuccessful:
                return "tipJar_toast_title"~
            case .tipPromotion:
                return "notification_tipPromotion_title"~
            case .enableReportingExtension:
                return "notification_reportingExtension_title"~
            case .filtersImported:
                return "notification_import_title"~
            case .filterImportFailed:
                return "notification_importFailed_title"~
            case .filterExportFailed:
                return "notification_exportFailed_title"~
            case .saveFailed:
                return "notification_saveFailed_title"~
            }
        }

        var subtitle: String {
            switch self {
            case .offline:
                return "notification_offline_subtitle"~
            case .cloudSyncOperationComplete:
                return "notification_sync_subtitle"~
            case .filterListsUpdated:
                return "notification_automatic_subtitle"~
            case .onClipboardSet:
                return "notification_clipboard_subtitle"~
            case .tipSuccessful:
                return "tipJar_toast_subtitle"~
            case .tipPromotion:
                return "notification_tipPromotion_subtitle"~
            case .enableReportingExtension:
                return "notification_reportingExtension_subtitle"~
            case .filtersImported(let added, let skipped):
                return String(format: "notification_import_subtitle"~, added, skipped)
            case .filterImportFailed:
                return "notification_importFailed_subtitle"~
            case .filterExportFailed:
                return "notification_exportFailed_subtitle"~
            case .saveFailed:
                return "notification_saveFailed_subtitle"~
            }
        }

        var buttonTitle: String {
            switch self {
            case .enableReportingExtension:
                return "notification_reportingExtension_button"~
            default:
                return "notification_hide"~
            }
        }

        var timeout: TimeInterval? {
            switch self {
            case .offline:
                return nil
            case .cloudSyncOperationComplete, .filterListsUpdated:
                return 6
            case .onClipboardSet:
                return 3
            case .tipSuccessful:
                return 6
            case .tipPromotion, .enableReportingExtension:
                guard !UIAccessibility.isVoiceOverRunning else { return 30 }
                return 10
            case .filtersImported, .filterImportFailed, .filterExportFailed, .saveFailed:
                return 6
            }
        }

        var showDelay: TimeInterval {
            switch self {
            case .onClipboardSet, .tipSuccessful, .filtersImported, .filterImportFailed, .filterExportFailed, .saveFailed:
                return 0
            case .offline, .cloudSyncOperationComplete, .filterListsUpdated, .tipPromotion, .enableReportingExtension:
                return 1
            }
        }

        var snoozeAfterHide: TimeInterval? {
            switch self {
            case .offline:
                return 60 * 60
            default:
                return nil
            }
        }

        var isTappable: Bool {
            switch self {
            case .tipPromotion, .enableReportingExtension:
                return true
            default:
                return false
            }
        }

        var buttonActsAsTap: Bool {
            switch self {
            case .enableReportingExtension:
                return true
            default:
                return false
            }
        }

        var hasSeparateButtonAction: Bool {
            return self.isTappable && !self.buttonActsAsTap
        }

        var confettiTier: TipTier? {
            switch self {
            case .tipSuccessful(let tier):
                return tier
            default:
                return nil
            }
        }

        static let allNudges: [Toast] = [.tipPromotion, .enableReportingExtension]

        var isNudge: Bool {
            return Self.allNudges.contains(self)
        }

        var nudgeKey: String? {
            switch self {
            case .tipPromotion:
                return "tipPromotion"
            case .enableReportingExtension:
                return "enableReportingExtension"
            default:
                return nil
            }
        }

        var nudgeSessionInterval: Int? {
            switch self {
            case .tipPromotion:
                return 5
            case .enableReportingExtension:
                return 3
            default:
                return nil
            }
        }


        func isOutranked(by otherToasts: Toast?...) -> Bool {
            let competingToasts = otherToasts.compactMap { $0 }
            return competingToasts.contains { $0.priority < self.priority }
        }

        var priority: Int {
            switch self {
            case .filterImportFailed, .filterExportFailed, .saveFailed:
                return 0
            case .filtersImported, .onClipboardSet, .tipSuccessful:
                return 1
            case .offline:
                return 2
            case .cloudSyncOperationComplete:
                return 3
            case .filterListsUpdated:
                return 4
            case .tipPromotion:
                return 5
            case .enableReportingExtension:
                return 6
            }
        }

        #if DEBUG
        static let debugSamples: [Toast] = [
            .offline,
            .cloudSyncOperationComplete,
            .filterListsUpdated(.aiFilteringLanguage),
            .filterListsUpdated(.curatedCommunityList),
            .onClipboardSet("support@example.com"),
            .tipSuccessful(.large),
            .tipPromotion,
            .enableReportingExtension,
            .filtersImported(added: 3, skipped: 1),
            .filterImportFailed,
            .filterExportFailed,
            .saveFailed
        ]
        #endif // DEBUG
    }
}

private struct ToastGlassBackground: ViewModifier {
    private let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
                .containerShape(shape)
        } else {
            content
                .background(.ultraThinMaterial)
                .containerShape(shape)
        }
    }
}

private struct ToastActionChipBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .contentShape(Capsule())
        } else {
            content
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .background(Color.secondary.opacity(0.2))
        }
    }
}

private struct ToastActionButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.plain)
                .glassEffect(.clear.interactive(), in: Capsule())
        } else {
            content.buttonStyle(.plain)
        }
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        let model = ToastView.ViewModel(toast: .filterListsUpdated(.aiFilteringLanguage))
        NavigationView {
            List {
                Button("Tap me") {
                    model.show = true
                }
            }
            .navigationTitle("Preview")
        }
        .preferredColorScheme(.dark)
        .overlay(alignment: .top) {
            ToastView(model: model)
        }
    }
}


