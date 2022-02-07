//
//  FilterListRowView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/02/2022.
//

import SwiftUI
import NaturalLanguage


//MARK: - View -
struct FilterListRowView: View {
    
    @ObservedObject var model: ViewModel
    
    var body: some View {
        HStack (alignment: .bottom) {
            
            if self.model.filter.filterType == .denyLanguage,
               let filterText = self.model.filter.text,
               let blockedLanguage = NLLanguage(filterText: filterText),
               blockedLanguage != .undetermined,
               let localizedName = blockedLanguage.localizedName {
                
                Text(localizedName)
            }
            else {
                Text(self.model.filter.text ?? "general_null"~)
                    .font(.system(size: 14, weight: .regular, design: .default))
            }
            
            Spacer()
            
            Menu {
                ForEach(FilterTarget.allCases) { filterTarget in
                    Button {
                        self.model.updateFilter(filterTarget: filterTarget)
                    } label: {
                        Text(filterTarget.name)
                    }
                }
            } label: {
                Text(self.model.filter.filterTarget.name.uppercased())
                    .font(.system(size: 7, weight: .light, design: .default))
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    .background(Color.secondary.opacity(0.1))
                    .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .foregroundColor(.primary)
                    .truncationMode(.middle)
            } // Menu
            
            
            Menu {
                ForEach(FilterMatching.allCases) { filterMatching in
                    Button {
                        self.model.updateFilter(filterMatching: filterMatching)
                    } label: {
                        Text(filterMatching.name)
                    }
                }
            } label: {
                Text(self.model.filter.filterMatching.name.uppercased())
                    .font(.system(size: 7, weight: .light, design: .default))
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    .background(Color.secondary.opacity(0.1))
                    .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .foregroundColor(.primary)
                    .truncationMode(.middle)
            } // Menu
            
            Menu {
                ForEach(FilterCase.allCases) { filterCase in
                    Button {
                        self.model.updateFilter(filterCase: filterCase)
                    } label: {
                        Text(filterCase.name)
                    }
                }
            } label: {
                Text(self.model.filter.filterCase.name.uppercased())
                    .font(.system(size: 7, weight: .light, design: .default))
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    .background(Color.secondary.opacity(0.1))
                    .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .foregroundColor(.primary)
                    .truncationMode(.middle)
            } // Menu
            
            if self.model.filter.filterType.supportsFolders {
                
                Menu {
                    ForEach(DenyFolderType.allCases) { folder in
                        Button {
                            self.model.updateFilter(denyFolder: folder)
                        } label: {
                            Label {
                                Text(folder.name)
                            } icon: {
                                Image(systemName: folder.iconName)
                            }
                        }
                    }
                } label: {
                    Text(self.model.filter.denyFolderType.name.uppercased())
                        .font(.system(size: 7, weight: .light, design: .default))
                        .multilineTextAlignment(.leading)
                        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                        .background(Color.secondary.opacity(0.1))
                        .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .foregroundColor(.primary)
                        .truncationMode(.middle)
                } // Menu
            }
        }  // HStack
    }
}

//MARK: - View Model -
extension FilterListRowView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published var filter: Filter
        @Published var onUpdate: (() -> ())?
        
        init(filter: Filter,
             onUpdate: (() -> ())? = nil,
             appManager: AppManagerProtocol = AppManager.shared) {
            
            self.filter = filter
            self.onUpdate = onUpdate
            
            super.init(appManager: appManager)
        }
        
        func updateFilter(denyFolder: DenyFolderType) {
            self.appManager.persistanceManager.updateFilter(self.filter, denyFolder: denyFolder)
            self.onUpdate?()
        }
        
        func updateFilter(filterMatching: FilterMatching) {
            self.appManager.persistanceManager.updateFilter(self.filter, filterMatching: filterMatching)
            self.onUpdate?()
        }
        
        func updateFilter(filterCase: FilterCase) {
            self.appManager.persistanceManager.updateFilter(self.filter, filterCase: filterCase)
            self.onUpdate?()
        }
        
        func updateFilter(filterTarget: FilterTarget) {
            self.appManager.persistanceManager.updateFilter(self.filter, filterTarget: filterTarget)
            self.onUpdate?()
        }
    }
}


//MARK: - Preview -
struct FilterListRowView_Previews: PreviewProvider {
    static var previews: some View {
        let appManager = AppManager.previews
        let filter = appManager.persistanceManager.fetchFilterRecords(for: .deny).first!
        
        FilterListRowView(model: FilterListRowView.ViewModel(filter: filter, appManager: appManager))
            .padding()
    }
}
