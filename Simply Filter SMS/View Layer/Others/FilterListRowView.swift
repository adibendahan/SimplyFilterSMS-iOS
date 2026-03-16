//
//  FilterListRowView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/02/2022.
//

import SwiftUI
import CoreData
import NaturalLanguage


//MARK: - View -
struct FilterListRowView: View {

    var filterObjectID: NSManagedObjectID
    var dotFilterID: NSManagedObjectID?
    @ObservedObject var model: ViewModel
    @State private var isEditingText = false
    @State private var showDuplicateError = false
    @State private var dotOpacity: Double = 0

    @ScaledMetric(relativeTo: .caption2) private var badgeFontSize: CGFloat = 8
    @ScaledMetric(relativeTo: .caption2) private var badgeWidth: CGFloat = 60
    @ScaledMetric(relativeTo: .caption2) private var badgeHeight: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var matchingIconSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var caseIconSize: CGFloat = 20
    @ScaledMetric(relativeTo: .caption) private var folderIconSize: CGFloat = 16

    var body: some View {
        HStack (alignment: .center) {

            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .opacity(dotOpacity)
                .onAppear {
                    guard dotFilterID == filterObjectID, dotOpacity == 0 else { return }
                    dotOpacity = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation(.easeOut(duration: 1.0)) {
                            dotOpacity = 0.0
                        }
                    }
                }
                .onChange(of: dotFilterID) { newID in
                    guard newID == filterObjectID, dotOpacity == 0 else { return }
                    dotOpacity = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation(.easeOut(duration: 1.0)) {
                            dotOpacity = 0.0
                        }
                    }
                }

            if self.model.filter.filterType == .denyLanguage,
               let filterText = self.model.filter.text {
                let blockedLanguage = NLLanguage(filterText: filterText)
                if blockedLanguage != .undetermined,
                   let localizedName = blockedLanguage.localizedName {
                    Text(localizedName)
                }
            }
            else {
                EditableText(
                    $model.text,
                    minimumCharacters: 3,
                    onCommit: {
                        self.model.updateFilter(filterText: self.model.text)
                        self.showDuplicateError = false
                        self.isEditingText = false
                    },
                    onEditingChanged: { isEditing in
                        withAnimation {
                            self.isEditingText = isEditing
                            if !isEditing { self.showDuplicateError = false }
                        }
                    },
                    onTextChange: { text in
                        self.showDuplicateError = self.model.isLiveDuplicate(text: text)
                    })

                if self.isEditingText && self.showDuplicateError {
                    HStack {
                        Image(systemName: "xmark.octagon")
                            .foregroundColor(.red.opacity(0.8))
                        Text("addFilter_duplicate"~)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    .background(Color.red.opacity(0.1))
                    .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
            
            Spacer()
            
            if !self.isEditingText && self.model.filter.filterType.supportsAdvancedOptions {
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
                        .frame(width: badgeWidth, height: badgeHeight, alignment: .center)
                        .font(.system(size: badgeFontSize, weight: .semibold, design: .default))
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
                        .background(Color.secondary.opacity(0.1))
                        .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .foregroundColor(.secondary)
                        .truncationMode(.middle)
                } // Menu
                .accessibilityLabel(String(format: "a11y_filterRow_targetLabel"~, self.model.filter.filterTarget.name))

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
                            .frame(width: matchingIconSize, height: matchingIconSize, alignment: .center)
                            .padding(EdgeInsets(top: 7, leading: 7, bottom: 7, trailing: 7))
                            .background(color.opacity(0.1))
                            .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                } // Menu
                .accessibilityLabel(String(format: "a11y_filterRow_matchLabel"~, self.model.filter.filterMatching.name))

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
                            .frame(width: caseIconSize, height: caseIconSize, alignment: .center)
                            .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                            .background(color.opacity(0.1))
                            .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                } // Menu
                .accessibilityLabel(String(format: "a11y_filterRow_caseLabel"~, self.model.filter.filterCase.name))
            }

            if !self.isEditingText && self.model.filter.filterType.supportsFolders {
                
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
                        .frame(width: folderIconSize, height: folderIconSize, alignment: .center)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        .background(Color.secondary.opacity(0.1))
                        .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                } // Menu
                .accessibilityLabel(String(format: "a11y_filterRow_folderLabel"~, self.model.filter.denyFolderType.name))
            }
        }  // HStack
        .accessibilityElement(children: .contain)
    }
}

//MARK: - View Model -
extension FilterListRowView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var filter: Filter
        @Published private(set) var onUpdate: ((Bool) -> ())?
        @Published var text: String

        init(filter: Filter,
             onUpdate: ((Bool) -> ())? = nil,
             appManager: AppManagerProtocol = AppManager.shared) {

            self.filter = filter
            self.onUpdate = onUpdate
            self.text = filter.text ?? "general_null"~
            super.init(appManager: appManager)
        }
        
        func updateFilter(denyFolder: DenyFolderType) {
            self.appManager.persistanceManager.updateFilter(self.filter, denyFolder: denyFolder)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterMatching: FilterMatching) {
            self.appManager.persistanceManager.updateFilter(self.filter, filterMatching: filterMatching)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterCase: FilterCase) {
            self.appManager.persistanceManager.updateFilter(self.filter, filterCase: filterCase)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterTarget: FilterTarget) {
            self.appManager.persistanceManager.updateFilter(self.filter, filterTarget: filterTarget)
            self.onUpdate?(true)
        }
        
        func isLiveDuplicate(text: String) -> Bool {
            guard text != (self.filter.text ?? "") else { return false }
            return self.appManager.persistanceManager.isDuplicateFilter(
                text: text,
                filterTarget: self.filter.filterTarget,
                filterMatching: self.filter.filterMatching,
                filterCase: self.filter.filterCase)
        }

        @discardableResult
        func updateFilter(filterText: String) -> Bool {
            guard filterText != self.filter.text else { return false }

            guard !self.appManager.persistanceManager.isDuplicateFilter(
                text: filterText,
                filterTarget: self.filter.filterTarget,
                filterMatching: self.filter.filterMatching,
                filterCase: self.filter.filterCase) else {
                self.text = self.filter.text ?? ""
                return true
            }

            self.appManager.persistanceManager.updateFilter(self.filter, filterText: filterText)
            self.onUpdate?(false)
            return false
        }
    }
}


//MARK: - Preview -
struct FilterListRowView_Previews: PreviewProvider {
    static var previews: some View {
        let appManager = AppManager.previews
        let filter = appManager.persistanceManager.fetchFilterRecords(for: .deny).first!
        
        FilterListRowView(filterObjectID: filter.objectID, dotFilterID: nil, model: FilterListRowView.ViewModel(filter: filter, appManager: appManager))
            .padding()
    }
}
