//
//  StatefulItem.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 29/01/2022.
//

import Foundation

struct StatefulItem<T>: Identifiable, Equatable where T: Identifiable & Equatable  {
    var id: T.ID
    var item: T
    var state: Bool {
        didSet {
            if let stateSetter = self.setter {
                stateSetter(self.item, self.state)
            }
        }
    }
    var getter: ((T) -> Bool)?
    var setter: ((T, Bool) -> ())?
    
    init(item: T, getter: ((T) -> Bool)?, setter: ((T, Bool) -> ())?) {
        self.id = item.id
        self.item = item
        self.getter = getter
        self.setter = setter
        self.state = getter?(item) ?? false
    }
    
    static func == (lhs: StatefulItem<T>, rhs: StatefulItem<T>) -> Bool {
        return lhs.item == rhs.item
    }
}
