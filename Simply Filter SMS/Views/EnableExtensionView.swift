//
//  EnableExtensionView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/12/2021.
//

import SwiftUI

struct EnableExtensionView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                TabView {
                    StepView(title: "enableExtension_step1"~,
                             text: "enableExtension_step1_desc"~,
                             image: "enableExtension_screenshot1",
                             geometry: geometry)
                    StepView(title: "enableExtension_step2"~,
                             text: "enableExtension_step2_desc"~,
                             image: "enableExtension_screenshot2",
                             geometry: geometry)
                    StepView(title: "enableExtension_step3"~,
                             text: "enableExtension_step3_desc"~,
                             image: "enableExtension_screenshot3",
                             geometry: geometry)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .toolbar {
                    ToolbarItem {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    func StepView(title: String,
                  text: String,
                  image: String,
                  geometry: GeometryProxy) -> some View {
        
        ScrollView {
            VStack (alignment: .center, spacing: 8) {
                Spacer()
                Text(text)
                    .frame(width: geometry.size.width*0.9, alignment: .leading)
                    .font(.title2)
                Spacer()
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 50*0.9, style: .continuous))
                    .frame(width: geometry.size.width*0.9, alignment: .center)
                Spacer(minLength: 50)
            }
            
        }
        .navigationTitle(title)
    }
}

struct EnableExtensionView_Previews: PreviewProvider {
    static var previews: some View {
        EnableExtensionView()
    }
}
