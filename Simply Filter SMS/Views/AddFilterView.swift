//
//  AddFilterView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/12/2021.
//

import SwiftUI

struct AddFilterView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var focusedField: Field?
    
    @State private var filterText = ""
    @State private var selectedFilterType = FilterType.deny.rawValue
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(alignment: .trailing, spacing: 8) {
                    Spacer()
                    TextField("addFilter_text"~, text: $filterText)
                        .focused($focusedField, equals: .text)
                    Spacer()
                    Picker("addFilter_type"~, selection: $selectedFilterType) {
                        Text("general_deny"~).tag(FilterType.deny.rawValue)
                        Text("general_allow"~).tag(FilterType.allow.rawValue)
                    }.pickerStyle(.segmented)
                    Spacer()
                    Button {
                        addFilter()
                        dismiss()
                    } label: {
                        Text("addFilter_add"~).frame(maxWidth: .infinity)
                    }.buttonStyle(FilledButton()).disabled(filterText.isEmpty)
                    Spacer().padding()
                }
                .frame(width: geometry.size.width-32, alignment: .center)
                .navigationTitle("addFilter_addFilter"~)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                focusedField = .text
            }
        }
    }
    
    private func addFilter() {
        withAnimation {
            let newFilter = Filter(context: viewContext)
            newFilter.uuid = UUID()
            newFilter.type = Int64(self.selectedFilterType)
            newFilter.text = self.filterText

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private enum Field: Int, Hashable {
    case text
}

struct FilledButton: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(configuration.isPressed ? .gray : .white)
            .padding()
            .background(isEnabled ? Color.accentColor : .gray)
            .cornerRadius(8)
    }
}

struct AddFilterView_Previews: PreviewProvider {
    static var previews: some View {
        AddFilterView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
