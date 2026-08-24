//
//  PersistentStoreReload.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 24/08/2026.
//

import SwiftUI


protocol PersistentStoreReloadRefreshing: AnyObject {
    func refresh()
}

protocol ViewWithPersistentStoreReload: View {
    associatedtype RefreshModel: PersistentStoreReloadRefreshing
    var model: RefreshModel { get }
}

struct PersistentStoreReloadModifier<Model: PersistentStoreReloadRefreshing>: ViewModifier {
    let model: Model

    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: .persistentStoreReloaded)) { _ in
            model.refresh()
        }
    }
}

extension ViewWithPersistentStoreReload {
    var persistentStoreReload: PersistentStoreReloadModifier<RefreshModel> {
        PersistentStoreReloadModifier(model: model)
    }
}
