//
//  AboutView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/12/2021.
//

import SwiftUI
import MessageUI
import UniformTypeIdentifiers


//MARK: - View -
struct AboutView: View {

    @Environment(\.dismiss)
    var dismiss

    @ScaledMetric(relativeTo: .largeTitle) private var cardLogoSizeRegular: CGFloat = IconSize.header
    @ScaledMetric(relativeTo: .title2) private var cardLogoSizeCompact: CGFloat = IconSize.headerLandscape
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var notesExpanded = false

    @StateObject var model: ViewModel

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    private var cardLogoSize: CGFloat {
        return self.verticalSizeClass == .compact ? self.cardLogoSizeCompact : self.cardLogoSizeRegular
    }

    var body: some View {
        NavigationView {
            List {
                // Identity
                Section {
                    AdaptiveRow(compactSpacing: Spacing.edge) {
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: cardLogoSize, height: cardLogoSize)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.appIcon(side: cardLogoSize), style: .continuous))
                            .accessibilityHidden(true)
                    } content: {
                        VStack(alignment: .leading, spacing: Spacing.tight) {
                            Text("Simply Filter SMS")
                                .font(.heading)
                                .foregroundColor(.text)
                                .fixedSize(horizontal: false, vertical: true)

                            Button {
                                model.setClipboard(content: "v\(appVersion) (\(appBuild))", displayName: "a11y_about_versionCopied"~)
                            } label: {
                                Text("v\(appVersion) (\(appBuild))")
                                    .font(.label)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, Spacing.item)
                                    .padding(.vertical, Spacing.tight)
                                    .background(.secondary.opacity(Opacity.tintFill))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Version \(appVersion)")
                            .accessibilityHint("a11y_about_versionHint"~)
                        }
                    }
                    .padding(.vertical, Spacing.item)
                }

                // Developer Notes (expandable)
                Section {
                    DisclosureGroup(isExpanded: $notesExpanded) {
                        Group {
                            if let attributed = try? AttributedString(markdown: "aboutView_aboutText"~, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                                Text(attributed)
                            } else {
                                Text("aboutView_aboutText"~)
                            }
                        }
                        .font(.body)
                        .foregroundColor(.text)
                        .padding(.bottom, Spacing.tight)
                        .padding(.leading, LayoutOffset.disclosureFlush)
                    } label: {
                        Label {
                            Text("aboutView_aboutSection"~)
                        } icon: {
                            Image(systemName: "quote.bubble")
                                .foregroundColor(.gray)
                        }
                    }

                    if !notesExpanded {
                        Group {
                            if let attributed = try? AttributedString(markdown: "aboutView_aboutText"~, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                                Text(attributed)
                            } else {
                                Text("aboutView_aboutText"~)
                            }
                        }
                        .font(.body)
                        .foregroundColor(.text)
                        .lineLimit(2)
                        .padding(.bottom, LayoutOffset.collapsedPeek)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }

                // Contact
                Section("aboutView_contactSection"~) {
                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            model.composeMailScreen = true
                        } else {
                            model.setClipboard(content: kSupportEmail, displayName: "aboutView_sendMail"~)
                        }
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: Spacing.tight) {
                                Text("aboutView_sendMail"~)
                                    .foregroundColor(.text)
                                Text(kSupportEmail)
                                    .foregroundColor(.textSecondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }

                // Connect
                Section("aboutView_connectSection"~) {
                    Link(destination: .appGithubURL) {
                        Label {
                            VStack(alignment: .leading, spacing: Spacing.tight) {
                                Text("aboutView_github"~)
                                    .foregroundColor(.text)
                                Text(URL.appGithubURL.lastPathComponent)
                                    .foregroundColor(.textSecondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image("logo.github")
                                .foregroundStyle(Color.text)
                        }
                    }

                    Link(destination: .appTwitterURL) {
                        Label {
                            VStack(alignment: .leading, spacing: Spacing.tight) {
                                Text("X")
                                    .foregroundColor(.text)
                                Text("aboutView_twitter"~)
                                    .foregroundColor(.textSecondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image("logo.x")
                                .foregroundStyle(Color.text)
                        }
                    }
                }

                // Support the App
                Section("aboutView_supportSection"~) {
                    Button {
                        model.showTipJar = true
                    } label: {
                        Label {
                            Text("tipJar_aboutRow"~)
                                .foregroundColor(.text)
                        } icon: {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                        }
                    }

                    Link(destination: .appReviewURL) {
                        Label {
                            Text("aboutView_review"~)
                                .foregroundColor(.text)
                        } icon: {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("general_about"~)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.primary)
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("AboutView.closeButton")
                }
            }
            .sheet(isPresented: $model.composeMailScreen) { } content: {
                MailView(isShowing: $model.composeMailScreen, result: $model.result)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .sheet(isPresented: $model.showTipJar) {
                TipJarView(model: TipJarView.ViewModel())
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}



//MARK: - ViewModel -
extension AboutView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var composeMailScreen: Bool = false {
            didSet {
                guard oldValue != self.composeMailScreen else { return }
                Log.debug("mail compose, shown: \(oldValue) → \(self.composeMailScreen)")
            }
        }
        @Published var showTipJar: Bool = false {
            didSet {
                guard oldValue != self.showTipJar else { return }
                Log.debug("tip jar sheet, shown: \(oldValue) → \(self.showTipJar)")
            }
        }
        @Published var result: Result<MFMailComposeResult, Error>?

        func setClipboard(content: String, displayName: String) {
            UIPasteboard.general.setValue(content, forPasteboardType: UTType.plainText.identifier)
            Log.debug("copied to clipboard, item: \(displayName), content: \(content)")
            self.appManager.flowManager.requestToast(.onClipboardSet(displayName))
        }
    }
}

//MARK: - Preview -
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(model: AboutView.ViewModel(appManager: AppManager.previews))
    }
}
