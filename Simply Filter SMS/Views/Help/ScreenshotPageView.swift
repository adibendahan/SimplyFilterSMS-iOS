//
//  ScreenshotPageView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import SwiftUI

struct ScreenshotPageView: View {
    
    @StateObject var model: ScreenshotPageViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                VStack (alignment: .leading, spacing: 8) {
                    Spacer()
                    
                    Text(self.model.text)
                        .font(.title2)
                        .frame(width: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    Image(self.model.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 45, style: .continuous))
                    
                    Spacer(minLength: 50)
                }
            }
            .padding(.horizontal, 16)
            
            Spacer(minLength: 20)
            
            Button {
                withAnimation {
                    self.model.onConfirm?()
                }
            } label: {
                Text(self.model.confirmText)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(FilledButton())
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            
            Spacer()
                .frame(height: 50, alignment: .bottom)
        }
        .navigationTitle(self.model.title)
    }
}

struct ScreenshotPageView_Previews: PreviewProvider {
    static var previews: some View {
        let model = ScreenshotPageViewModel(title: "enableExtension_step2"~,
                                            text: "enableExtension_step2_desc"~,
                                            image: "enableExtension_screenshot2",
                                            confirmText: "enableExtension_next"~)
        ScreenshotPageView(model: model)
    }
}
