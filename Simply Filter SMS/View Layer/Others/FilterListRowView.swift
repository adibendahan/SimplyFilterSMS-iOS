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
        HStack (alignment: .center) {
            
            if self.model.filter.filterType == .denyLanguage,
               let filterText = self.model.filter.text,
               let blockedLanguage = NLLanguage(filterText: filterText),
               blockedLanguage != .undetermined,
               let localizedName = blockedLanguage.localizedName {
                
                Text(localizedName)
            }
            else {
                Text(self.model.filter.text ?? "general_null"~)
            }
            
            Spacer()
            
            if self.model.filter.filterType.supportsAdvancedOptions {
                Menu {
                    ForEach(FilterTarget.allCases) { filterTarget in
                        Button {
                            self.model.updateFilter(filterTarget: filterTarget)
                        } label: {
                            Text(filterTarget.name)
                        }
                    }
                } label: {
                    Text(self.model.filter.filterTarget.multilineName.uppercased())
                        .frame(width: 44, height: 20, alignment: .center)
                        .font(.system(size: 8, weight: .semibold, design: .default))
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
                        .background(Color.secondary.opacity(0.1))
                        .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .foregroundColor(.secondary)
                        .truncationMode(.middle)
                } // Menu

                Menu {
                    ForEach(FilterMatching.allCases) { filterMatching in
                        Button {
                            self.model.updateFilter(filterMatching: filterMatching)
                        } label: {
                            Label(filterMatching.name, systemImage: filterMatching.icon)
                        }
                    }
                } label: {
                    Button {
                        self.model.updateFilter(filterMatching: self.model.filter.filterMatching.other)
                    } label: {
                        let color = self.model.filter.filterMatching == .exact ? Color.green : .secondary
                        
                        Image(systemName: self.model.filter.filterMatching.icon)
                            .resizable()
                            .foregroundColor(color)
                            .frame(width: 18, height: 18, alignment: .center)
                            .padding(EdgeInsets(top: 7, leading: 7, bottom: 7, trailing: 7))
                            .background(color.opacity(0.1))
                            .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    .buttonStyle(BorderlessButtonStyle())
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
                    Button {
                        self.model.updateFilter(filterCase: self.model.filter.filterCase.other)
                    } label: {
                        let color = self.model.filter.filterCase == .caseSensitive ? Color.green : .secondary
                        
                        Image("caseSensitive")
                            .resizable()
                            .foregroundColor(color)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                            .background(color.opacity(0.1))
                            .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                } // Menu
            }
            
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
                    Image(systemName: self.model.filter.denyFolderType.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16, alignment: .center)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        .background(Color.secondary.opacity(0.1))
                        .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                } // Menu
            }
        }  // HStack
    }
}

//MARK: - View Model -
extension FilterListRowView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var filter: Filter
        @Published private(set) var onUpdate: (() -> ())?
        
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
