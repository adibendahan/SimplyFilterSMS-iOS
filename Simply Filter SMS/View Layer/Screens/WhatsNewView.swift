//
//  WhatsNewView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 04/11/2022.
//

import SwiftUI

struct WhatsNewView: View {
    
    @Environment(\.dismiss)
    var dismiss
    
    @ObservedObject var model: ViewModel
    
    var body: some View {
        NavigationView {
            VStack (alignment: .leading, spacing: 40) {
                VStack (alignment: .leading, spacing: 4) {
                    VersionView(text: self.model.mainVersionTitle)
                    
                    ForEach(self.model.mainVersionUpdates, id: \.self) { update in
                        DetailView(text: update)
                    }
                }
                VStack (alignment: .leading, spacing: 4) {
                    VersionView(text: self.model.secondaryVersionTitle)
                    ForEach(self.model.secondaryVersionUpdates, id: \.self) { update in
                        DetailView(text: update)
                    }
                }
                Spacer()
                Link(destination: .appReviewURL) {
                    Text("whatsNew_rateUs"~)
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .frame(width: 50, height: 50)
                        .font(.system(size: 30))
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("whatsNew_title"~)
            .background(.ultraThinMaterial)
        }
        .modifier(EmbeddedCloseButton(onTap: { dismiss() }))
        .onAppear {
            self.model.appManager.defaultsManager.whatsNewVersion = kCurrentWhatsNewVersion
        }
    }
    
    struct DetailView: View {
        var text: String
        
        var body: some View {
            HStack (alignment: .top, spacing: 4) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .padding(.top, 4)
                Text(.init(self.text))
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    struct VersionView: View {
        var text: String
        
        var body: some View {
            Text(self.text)
                .font(.title2.bold())
                .foregroundColor(.secondary)
        }
    }
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published var mainVersionTitle: String = "whatsNew_mainVersionTitle"~
        @Published var mainVersionUpdates: [String] = ["whatsNew_mainVersionUpdates_1"~, "whatsNew_mainVersionUpdates_2"~]
        @Published var secondaryVersionTitle: String = "whatsNew_secondaryVersionTitle"~
        @Published var secondaryVersionUpdates: [String] = ["whatsNew_secondaryVersionUpdates_1"~, "whatsNew_secondaryVersionUpdates_2"~, "whatsNew_secondaryVersionUpdates_3"~]
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(model: WhatsNewView.ViewModel(appManager: AppManager.previews))
    }
}

extension String: @retroactive Identifiable {
    public var id: Int {
        return self.hashValue
    }
}
