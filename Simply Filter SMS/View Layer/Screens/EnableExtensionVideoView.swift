//
//  EnableExtensionVideoView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 22/11/2025.
//

import SwiftUI
import AVKit
import AVFoundation
import UIKit

struct EnableExtensionVideoView: View {
    
    @Environment(\.dismiss)
    var dismiss
    
    @Environment(\.locale)
    private var locale
    
    @StateObject var model: ViewModel
    
    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
        _player = State(initialValue: AVPlayer())
    }
    
    @State private var player: AVPlayer
    @State private var playerObserver: Any?

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text("enableExtension_welcome_desc"~)
                    .padding(.horizontal)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal)
                    .background(Color.clear)
                    .shadow(radius: 6)
                    .layoutPriority(1)

                VStack(spacing: 12) {
                    Button {
                        openSettings()
                    } label: {
                        Text("enableExtension_ready_callToAction"~)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(Color.white)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("enableExtension_welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button {
                        self.dismissView()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("EnableExtensionView.closeButton")
                }
            }
        }
        .onAppear {
            if let url = model.videoURLForCurrentLocale() {
                player = AVPlayer(url: url)
            } else {
                player = AVPlayer()
            }

            player.play()
            playerObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }
        }
        .onDisappear {
            if let observer = playerObserver {
                NotificationCenter.default.removeObserver(observer)
                playerObserver = nil
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func dismissView() {
        withAnimation {
            self.model.isAppFirstRun = false
            dismiss()
        }
    }
    
    private func openSettings() {
        withAnimation {
            self.model.isAppFirstRun = false
            dismiss()
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
}

//MARK: - ViewModel -
extension EnableExtensionVideoView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published var isAppFirstRun: Bool {
            didSet {
                self.appManager.defaultsManager.isAppFirstRun = self.isAppFirstRun
            }
        }
        
        override init(appManager: AppManagerProtocol = AppManager.shared) {
            self.isAppFirstRun = appManager.defaultsManager.isAppFirstRun
            super.init(appManager: appManager)
        }
        
        func videoURLForCurrentLocale() -> URL? {
            var fileName = "enableExtension"
            
            if #available(iOS 16, *),
               (Locale.current.language.languageCode?.identifier == "he") {
                    fileName = fileName + ".he"
            } else if let code = Locale.current.languageCode,
                      (code == "he"){
                    fileName = fileName + ".he"
            }

            return Bundle.main.url(forResource: fileName, withExtension: "mp4")
        }
    }
}

//MARK: - Preview -
struct EnableExtensionVideoView_Previews: PreviewProvider {
    static var previews: some View {
        EnableExtensionVideoView(
            model: EnableExtensionVideoView.ViewModel(appManager: AppManager.previews)
        )
    }
}
