//
//  AboutView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/12/2021.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    private var backgroundColor: Color {
        if colorScheme == .light {
            return Color(uiColor: UIColor.secondarySystemBackground)
        }
        else {
            return Color(uiColor: UIColor.systemBackground)
        }
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 55, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .trailing) {
                    Text("Simply Filter SMS")
                        .font(.system(size: 32, weight: .bold, design: .default))
                    Text("v1.0.0")
                        .font(.footnote)
                        .italic()
                }
            }
            .padding()
            List {
                Section {
                    Text("aboutView_aboutText"~)
                        .font(.subheadline)
                } header: {
                    Text("aboutView_aboutSection"~)
                }
                Section {
                    Link(destination: URL(string: "https://github.com/adibendahan/SimplyFilterSMS-iOS")!) {
                        HStack {
                            Image("GitHub")
                                .resizable()
                                .frame(width: 26, height: 26, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                            Text("aboutView_github"~)
                                .foregroundColor(.primary)
                        }
                    }
                    Link(destination: URL(string: "https://twitter.com/a_bd")!) {
                        HStack {
                            Image("Twitter")
                                .resizable()
                                .frame(width: 26, height: 21, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                            Text("aboutView_twitter"~)
                                .foregroundColor(.primary)
                        }
                    }
                    Link(destination: URL(string: "https://www.linkedin.com/in/adi-ben-dahan-8b213343")!) {
                        HStack {
                            Image("LinkedIn")
                                .resizable()
                                .frame(width: 26, height: 22, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                            Text("aboutView_linkedin"~)
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("aboutView_linksSection"~)
                } footer: {
                    Text("general_copyright"~)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(.grouped)
        }
        .background(backgroundColor)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
.previewInterfaceOrientation(.portrait)
    }
}
