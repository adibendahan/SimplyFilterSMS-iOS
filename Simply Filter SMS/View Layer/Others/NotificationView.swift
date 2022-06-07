//
//  NotificationView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 08/02/2022.
//

import SwiftUI
import Foundation

struct NotificationView: View {
    
    @ObservedObject var model: ViewModel
    @State private var offset: CGFloat = -200
    
    private let kHideOffset: CGFloat = -200
    private let kShowOffset: CGFloat = 25
    
    var body: some View {
        HStack (alignment: .center, spacing: 8) {
            Image(systemName: self.model.icon)
                .font(.body)
                .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 0))
                .foregroundColor(self.model.iconColor)
            
            VStack (alignment: .leading, spacing: 0) {
                Text(self.model.title)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                
                Text(self.model.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 4))
           
            Button {
                self.model.onButtonTap?()
            } label: {
                Text(self.model.buttonTitle)
                    .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                    .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .background(Color.secondary.opacity(0.2))
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
        .background(.ultraThinMaterial)
        .containerShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onChanged({ value in
                    let horizontalAmount = value.translation.width as CGFloat
                    let verticalAmount = value.translation.height as CGFloat
                    
                    if abs(horizontalAmount) < abs(verticalAmount) && verticalAmount < -20  {
                        self.model.onButtonTap?()
                    }
                })
                .onEnded { value in
                    let horizontalAmount = value.translation.width as CGFloat
                    let verticalAmount = value.translation.height as CGFloat
                    
                    if abs(horizontalAmount) < abs(verticalAmount) && verticalAmount < 0  {
                        self.model.onButtonTap?()
                    }
                })
        .offset(y: self.offset)
        .animation(.interpolatingSpring(mass: 1, stiffness: 200, damping: 30, initialVelocity: offset == kShowOffset ? 25 : 0), value: offset)
        .onTapGesture {
            withAnimation {
                self.model.show = false
            }
        }
        .onReceive(model.$show) { show in
            withAnimation {
                self.setShow(show)
            }
        }
    }
    
    private func setShow(_ show: Bool) {
        if show && self.offset == kHideOffset {
            self.offset = kShowOffset
        }
        else if !show && self.offset == kShowOffset {
            self.offset = kHideOffset
        }
    }
    
    class ViewModel: ObservableObject {
        @Published var icon: String
        @Published var iconColor: Color
        @Published var title: String
        @Published var subtitle: String
        @Published var buttonTitle: String
        @Published var onButtonTap: (() -> ())?
        @Published var show: Bool
        
        init(notification: Notification) {
            
            self.icon = notification.icon
            self.iconColor = notification.iconColor
            self.title = notification.title
            self.subtitle = notification.subtitle
            self.buttonTitle = notification.buttonTitle
            self.show = false
            self.onButtonTap = {
                withAnimation {
                    self.show = false
                }
            }
        }
        
        func setNotification(_ notification: Notification) {
            self.icon = notification.icon
            self.iconColor = notification.iconColor
            self.title = notification.title
            self.subtitle = notification.subtitle
            self.buttonTitle = notification.buttonTitle
        }
        
        func setOnButtonTap(_ newOnButtonTap: (() -> ())?) {
            self.onButtonTap = {
                newOnButtonTap?()
                withAnimation {
                    self.show = false
                }
            }
        }
    }
    
    enum Notification {
        case offline, cloudSyncOperationComplete, automaticFiltersUpdated, onClipboardSet(String)
        
        var icon: String {
            switch self {
            case .offline:
                return "icloud.slash.fill"
            case .cloudSyncOperationComplete:
                return "icloud.and.arrow.down.fill"
            case .automaticFiltersUpdated:
                return "bolt.shield.fill"
            case .onClipboardSet:
                return "doc.on.clipboard.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .offline:
                return .red.opacity(0.4)
            case .cloudSyncOperationComplete:
                return .green.opacity(0.6)
            case .automaticFiltersUpdated:
                return .indigo.opacity(0.6)
            case .onClipboardSet:
                return .accentColor.opacity(0.6)
            }
        }
        
        
        var title: String {
            switch self {
            case .offline:
                return "notification_offline_title"~
            case .cloudSyncOperationComplete:
                return "notification_sync_title"~
            case .automaticFiltersUpdated:
                return "notification_automatic_title"~
            case .onClipboardSet(let contentDescription):
                return contentDescription
            }
        }
        
        var subtitle: String {
            switch self {
            case .offline:
                return "notification_offline_subtitle"~
            case .cloudSyncOperationComplete:
                return "notification_sync_subtitle"~
            case .automaticFiltersUpdated:
                return "notification_automatic_subtitle"~
            case .onClipboardSet:
                return "notification_clipboard_subtitle"~
            }
        }
        
        var buttonTitle: String {
            return "notification_hide"~
        }
        
        var timeout: TimeInterval? {
            switch self {
            case .offline:
                return nil
            case .cloudSyncOperationComplete, .automaticFiltersUpdated:
                return 6
            case .onClipboardSet:
                return 3
            }
        }
    }
}

struct NotificationToastView_Previews: PreviewProvider {
    static var previews: some View {
        let model = NotificationView.ViewModel(notification: .automaticFiltersUpdated)
        NavigationView {
            List {
                Button("Tap me") {
                    model.show = true
                }
            }
            .navigationTitle("Preview")
        }
        .preferredColorScheme(.dark)
        .modifier(EmbeddedNotificationView(model: model))
    }
}


