//
//  SafariView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/11/2026.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: self.url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}

struct SafariLink: Identifiable {
    let id = UUID()
    let url: URL
}

struct InAppBrowserModifier: ViewModifier {
    @State private var safariLink: SafariLink?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                guard url.opensInAppBrowser else {
                    Log.debug("link opened, url: \(url) → system")
                    return .systemAction
                }
                Log.debug("link opened, url: \(url) → in-app browser")
                self.safariLink = SafariLink(url: url)
                return .handled
            })
            .sheet(item: self.$safariLink) { safariLink in
                SafariView(url: safariLink.url)
                    .ignoresSafeArea()
            }
    }
}
