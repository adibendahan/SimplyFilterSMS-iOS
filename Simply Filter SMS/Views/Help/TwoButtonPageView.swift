//
//  SingleButtonPage.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import SwiftUI

struct TwoButtonPageView: View {
    
    @StateObject var model: TwoButtonPageViewModel
    @State var coordinator: EnableExtensionView.PageCoordinator? = nil
    
    var body: some View {
        VStack (alignment: .center, spacing: 8) {
            
            Spacer()
                .frame(height: 12, alignment: .top)
            
            Text(.init(self.model.text))
                .font(.title2)
                .padding(.horizontal, 16)
            
            if let image = self.model.image {
                Spacer()
                
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 45, style: .continuous))
                    .padding(.horizontal, 16)
            }

            Spacer()
            
            Button {
                withAnimation {
                    self.coordinator?.onPerform(action: model.confirmAction)
                }
            } label: {
                Text(self.model.confirmText)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(FilledButton())
            .padding(.horizontal, 16)
            
            Button {
                withAnimation {
                    self.coordinator?.onPerform(action: model.cancelAction)
                }
            } label: {
                Text(self.model.cancelText)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(OutlineButton())
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            
            Spacer()
                .frame(height: 50, alignment: .bottom)
        } // VStack
        .navigationTitle(self.model.title)
    }
}

struct SingleButtonPage_Previews: PreviewProvider {
    static var previews: some View {
        let model = TwoButtonPageViewModel(title: "enableExtension_welcome"~,
                                           text: "enableExtension_welcome_desc"~,
                                           confirmText: "enableExtension_welcome_callToAction"~,
                                           confirmAction: .nextPage,
                                           cancelText: "enableExtension_welcome_cancel"~,
                                           cancelAction: .dismiss,
                                           image: "enableExtension_screenshot4")
        
        TwoButtonPageView(model: model)
    }
}
