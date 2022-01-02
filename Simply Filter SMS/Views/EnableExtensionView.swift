//
//  EnableExtensionView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/12/2021.
//

import SwiftUI

struct EnableExtensionView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var tabSelection = 1
    
    var isFromMenu: Bool
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                TabView (selection: $tabSelection) {
                    let shouldShowWelcomePages = !isFromMenu && UserDefaults.isAppFirstRun
                    let ctaString = "enableExtension_ready_callToAction"~
                    let cancelString = "enableExtension_ready_cancel"~
                    
                    if shouldShowWelcomePages {
                        VStack (alignment: .center, spacing: 8) {
                            Spacer().frame(height: 12, alignment: .top)
                            Text("enableExtension_welcome_desc"~)
                                .frame(width: geometry.size.width*0.9, alignment: .leading)
                                .font(.title2)
                            Spacer()
                            Button {
                                withAnimation {
                                    tabSelection = 2
                                }
                            } label: {
                                Text("enableExtension_welcome_callToAction"~).frame(maxWidth: .infinity)
                            }.buttonStyle(FilledButton())
                                .frame(width: geometry.size.width*0.9, alignment: .center)
                            Button {
                                UserDefaults.isAppFirstRun = false
                                withAnimation {
                                   dismiss()
                                }
                            } label: {
                                Text("enableExtension_welcome_cancel"~).frame(maxWidth: .infinity)
                            }.buttonStyle(OutlineButton())
                                .frame(width: geometry.size.width*0.9, alignment: .center)
                            Spacer().frame(height: 50, alignment: .bottom)
                        }
                        .navigationTitle("enableExtension_welcome"~)
                        .tag(1)
                    }
                    
                    StepView(title: "enableExtension_step1"~,
                             text: "enableExtension_step1_desc"~,
                             image: "enableExtension_screenshot1",
                             geometry: geometry).tag(2)
                    StepView(title: "enableExtension_step2"~,
                             text: "enableExtension_step2_desc"~,
                             image: "enableExtension_screenshot2",
                             geometry: geometry).tag(3)
                    StepView(title: "enableExtension_step3"~,
                             text: "enableExtension_step3_desc"~,
                             image: "enableExtension_screenshot3",
                             geometry: geometry).tag(4)
                    
                    VStack (alignment: .center, spacing: 8) {
                        Spacer().frame(height: 12, alignment: .top)
                        Text(String(format: "enableExtension_ready_desc"~, ctaString, cancelString))
                            .frame(width: geometry.size.width*0.9, alignment: .leading)
                            .font(.title2)
                        Spacer()
                        Button {
                            UserDefaults.isAppFirstRun = false
                            dismiss()
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        } label: {
                            Text(ctaString).frame(maxWidth: .infinity)
                        }.buttonStyle(FilledButton())
                            .frame(width: geometry.size.width*0.9, alignment: .center)
                        Button {
                            UserDefaults.isAppFirstRun = false
                            withAnimation {
                                dismiss()
                            }
                        } label: {
                            Text(cancelString).frame(maxWidth: .infinity)
                        }.buttonStyle(OutlineButton())
                            .frame(width: geometry.size.width*0.9, alignment: .center)
                        Spacer().frame(height: 50, alignment: .bottom)
                    }
                    .navigationTitle("enableExtension_ready"~)
                    .tag(5)
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
        EnableExtensionView(isFromMenu: false)
    }
}