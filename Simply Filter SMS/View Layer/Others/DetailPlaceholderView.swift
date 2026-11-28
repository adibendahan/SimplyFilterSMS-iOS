//
//  DetailPlaceholderView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/01/2025.
//
import SwiftUI


struct DetailPlaceholderView: View {

    @ScaledMetric(relativeTo: .largeTitle) private var placeholderIconSize: CGFloat = IconSize.header

    var body: some View {
        var symbol: String {
            let languageCode = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
            switch languageCode {
                case "he": return "sidebar.right"
                default: return "sidebar.left"
            }
        }
        
        VStack(spacing: Spacing.rowMargin) {
            Spacer()
            
            Image(systemName: "square.text.square")
                .font(.system(size: placeholderIconSize))
                .foregroundColor(.text)
                .accessibilityHidden(true)
            
            Text("placeholder_choose_title"~)
                .font(.heading)
                .foregroundColor(.text)
            
            VStack (spacing: Spacing.tight) {
                Text("placeholder_choose_detail"~)
                    .font(.body)
                    .foregroundColor(.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                AdaptiveStack(spacing: Spacing.tight) {
                    Text("placeholder_choose_sub_detail1"~)
                        .font(.body)
                        .foregroundColor(.text)
                        .multilineTextAlignment(.center)

                    Image(systemName: symbol)
                        .font(.body)
                        .foregroundStyle(.tint)

                    Text("placeholder_choose_sub_detail2"~)
                        .font(.body)
                        .foregroundColor(.text)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}



//MARK: - Preview -
struct DetailPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        DetailPlaceholderView()
    }
}
