//
//  StayReachableView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 18/11/2026.
//

import SwiftUI


//MARK: - View -
struct StayReachableView: View {

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.layoutDirection)
    private var layoutDirection

    @Environment(\.needsStackedLayout)
    private var needsStackedLayout

    @ScaledMetric(relativeTo: .body)
    private var labelWidth: CGFloat = 104

    @ScaledMetric(relativeTo: .title)
    private var iconSize: CGFloat = 60

    @StateObject private var model: ViewModel
    @FocusState private var focusedField: FieldFocus?

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
            List {
                Section {} header: {
                    self.header
                }

                ForEach($model.sections) { $section in
                    Section {
                        ForEach(Field.allCases, id: \.self) { field in
                            self.fieldRow(field, text: $section[dynamicMember: field.keyPath], in: section)
                        }
                    } header: {
                        self.sectionHeader(for: section)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } footer: {
                        let skippedNote = self.model.skippedNote(for: section)
                        if !skippedNote.isEmpty {
                            Text(skippedNote)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .accessibilityIdentifier(TestIdentifier.stayReachableSkippedNote.rawValue)
                        }
                    }
                    .environment(\.layoutDirection, self.model.layoutDirection(for: section) ?? self.layoutDirection)
                }

                Section {
                    self.addLanguageMenu
                }
            }
            .listStyle(.insetGrouped)
            .safeAreaInset(edge: .bottom) {
                Button {
                    self.hideKeyboard()
                    withAnimation {
                        self.model.addFilters()
                        self.dismiss()
                    }
                } label: {
                    Text(self.model.addButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButton())
                .disabled(self.model.changeCount == 0)
                .accessibilityIdentifier(TestIdentifier.stayReachableAddButton.rawValue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
            .navigationTitle("stayReachable_title"~)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.hideKeyboard()
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .tint(.primary)
                    .accessibilityLabel("general_close"~)
                    .accessibilityIdentifier(TestIdentifier.closeButton.rawValue)
                    .contentShape(Rectangle())
                }
            }
        } // NavigationView
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                guard let firstSection = self.model.sections.first, firstSection.trimmedText(.firstName).isEmpty else { return }
                self.focusedField = FieldFocus(sectionID: firstSection.id, field: .firstName)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.shield.checkmark.fill")
                .font(.system(size: self.iconSize * 0.55))
                .foregroundStyle(.white)
                .frame(width: self.iconSize, height: self.iconSize)
                .background(.green, in: RoundedRectangle(cornerRadius: self.iconSize * 0.25, style: .continuous))
                .accessibilityHidden(true)

            if let description = self.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .textCase(nil)
        .padding(.bottom, 8)
    }

    private var description: AttributedString? {
        guard var description = try? AttributedString(markdown: "stayReachable_description"~, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) else { return nil }
        for run in description.runs {
            let isBold = run.inlinePresentationIntent?.contains(.stronglyEmphasized) ?? false
            guard isBold else { continue }
            description[run.range].foregroundColor = Color(.label)
        }
        return description
    }

    @ViewBuilder
    private func sectionHeader(for section: LanguageSection) -> some View {
        if section.language == self.model.appLanguage {
            Text(self.model.title(for: section))
        } else {
            Menu {
                Picker(selection: Binding(
                    get: { section.language },
                    set: { self.model.setLanguage($0, for: section) }
                )) {
                    Section("stayReachable_phoneLanguages"~) {
                        ForEach(self.model.languageChoices(in: self.model.phoneLanguages, for: section), id: \.self) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    }
                    Section("stayReachable_allLanguages"~) {
                        ForEach(self.model.languageChoices(in: self.model.otherLanguages, for: section), id: \.self) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    }
                } label: {
                    EmptyView()
                }

                Divider()

                Button(role: .destructive) {
                    withAnimation {
                        self.model.removeSection(section)
                    }
                } label: {
                    Label("stayReachable_removeLanguage"~, systemImage: "trash")
                }
            } label: {
                HStack(spacing: 4) {
                    Text(self.model.title(for: section))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(.tint)
            }
            .accessibilityHint("a11y_stayReachable_languageHint"~)
        }
    }

    private var addLanguageMenu: some View {
        Menu {
            Section("stayReachable_phoneLanguages"~) {
                ForEach(self.model.unusedLanguages(in: self.model.phoneLanguages), id: \.self) { language in
                    Button(language.displayName) {
                        withAnimation {
                            self.model.addSection(language: language)
                        }
                    }
                }
            }
            Section("stayReachable_allLanguages"~) {
                ForEach(self.model.unusedLanguages(in: self.model.otherLanguages), id: \.self) { language in
                    Button(language.displayName) {
                        withAnimation {
                            self.model.addSection(language: language)
                        }
                    }
                }
            }
        } label: {
            Label("stayReachable_addLanguage"~, systemImage: "plus.circle.fill")
                .foregroundStyle(.tint)
        }
    }

    private func fieldRow(_ field: Field, text: Binding<String>, in section: LanguageSection) -> some View {
        let language = section.language
        let title = self.model.title(for: field, in: section)
        let prompt = self.model.prompt(for: field, in: section)
        let focus = FieldFocus(sectionID: section.id, field: field)
        let isSkipped = self.model.isSkipped(field, in: section)
        let layout = self.needsStackedLayout ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            Text(title)
                .frame(width: self.needsStackedLayout ? nil : self.labelWidth, alignment: .leading)

            TextField(title, text: text, prompt: Text(prompt))
                .focused($focusedField, equals: focus)
                .accessibilityIdentifier(field.testIdentifier.rawValue)
                .textContentType(field.contentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .multilineTextAlignment(self.textAlignment(for: language))
                .environment(\.layoutDirection, self.layoutDirection)
                .opacity(isSkipped ? 0.5 : 1)
        }
    }

    private func textAlignment(for language: Locale.LanguageCode) -> TextAlignment {
        let isLayoutRightToLeft = self.layoutDirection == .rightToLeft
        let alignment: TextAlignment
        if language.isRightToLeft == isLayoutRightToLeft {
            alignment = .leading
        } else {
            alignment = .trailing
        }
        return alignment
    }

    struct FieldFocus: Hashable {
        let sectionID: UUID
        let field: Field
    }
}


//MARK: - ViewModel -
extension StayReachableView {

    typealias LanguageSection = StayReachableSection
    typealias Field = StayReachableField

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var sections: [LanguageSection]
        let appLanguage: Locale.LanguageCode
        let phoneLanguages: [Locale.LanguageCode]
        let otherLanguages: [Locale.LanguageCode]
        private let existingFilters: [Filter]

        private static let extraLocalizations: [String: [String: String]] = {
            guard let url = Bundle.main.url(forResource: "StayReachableLocalizations", withExtension: "json") else {
                Log.error("stay reachable localizations missing → extra languages use the app language")
                return [:]
            }
            let localizations: [String: [String: String]]
            do {
                let data = try Data(contentsOf: url)
                localizations = try JSONDecoder().decode([String: [String: String]].self, from: data)
            } catch {
                Log.error("stay reachable localizations unreadable → extra languages use the app language", error: error)
                localizations = [:]
            }
            return localizations
        }()

        init(appManager: AppManagerProtocol = AppManager.shared,
             appLanguage: Locale.LanguageCode = .appLanguage,
             phoneLanguages allPhoneLanguages: [Locale.LanguageCode] = Locale.LanguageCode.phoneLanguages) {
            let phoneLanguages = allPhoneLanguages.filter { $0 != appLanguage }
            let otherLanguages = Locale.LanguageCode.namedLanguages.filter { $0 != appLanguage && !phoneLanguages.contains($0) }
            let secondLanguage: Locale.LanguageCode?
            if appLanguage == .english {
                secondLanguage = phoneLanguages.first
            } else {
                secondLanguage = .english
            }
            let filters = appManager.persistenceManager.fetchFilterRecords()
            let rememberedSections = appManager.stayReachableManager.rememberedSections(in: filters)
            var sections = [LanguageSection(language: appLanguage)]
            if rememberedSections.isEmpty, let secondLanguage {
                sections.append(LanguageSection(language: secondLanguage))
            }
            for rememberedSection in rememberedSections {
                if rememberedSection.language == appLanguage {
                    sections[0] = rememberedSection
                } else {
                    sections.append(rememberedSection)
                }
            }

            self.appLanguage = appLanguage
            self.phoneLanguages = phoneLanguages
            self.otherLanguages = otherLanguages
            self.sections = sections
            self.existingFilters = filters

            super.init(appManager: appManager)
            Log.debug("opened, appLanguage: \(appLanguage.identifier), phoneLanguages: \(phoneLanguages.map(\.identifier)), sections: \(sections.map(\.language.identifier)), rememberedSections: \(rememberedSections.count), existingFilters: \(self.existingFilters.count)")
        }

        var newFilterTexts: [String] {
            var newTexts: [String] = []
            for section in self.sections {
                for field in Field.allCases {
                    let trimmedText = section.trimmedText(field)
                    guard trimmedText.count >= kMinimumFilterLength,
                          !section.hasRestoredFilter(field),
                          !self.isSkipped(field, in: section) else { continue }
                    newTexts.append(trimmedText)
                }
            }
            return newTexts
        }

        var editedTexts: [String] {
            var editedTexts: [String] = []
            for section in self.sections {
                for field in Field.allCases {
                    let trimmedText = section.trimmedText(field)
                    guard trimmedText.count >= kMinimumFilterLength,
                          section.hasRestoredFilter(field),
                          !section.isUnchanged(field),
                          !self.isSkipped(field, in: section) else { continue }
                    editedTexts.append(trimmedText)
                }
            }
            return editedTexts
        }

        var clearedFieldCount: Int {
            var clearedFieldCount = 0
            for section in self.sections {
                for field in Field.allCases {
                    guard section.hasRestoredFilter(field), section.trimmedText(field).isEmpty else { continue }
                    clearedFieldCount += 1
                }
            }
            return clearedFieldCount
        }

        var changeCount: Int {
            return self.newFilterTexts.count + self.editedTexts.count + self.clearedFieldCount
        }

        var addButtonTitle: String {
            let newTextCount = self.newFilterTexts.count
            let isSavingChangesOnly = newTextCount == 0 && self.changeCount > 0
            let title: String
            if isSavingChangesOnly {
                title = "stayReachable_saveChanges"~
            } else {
                title = String.localizedStringWithFormat("stayReachable_addFilters"~, newTextCount)
            }
            return title
        }

        func isAlreadyAllowed(_ text: String, excluding ownFilter: Filter? = nil) -> Bool {
            return self.appManager.stayReachableManager.isAlreadyAllowed(text, excluding: ownFilter, in: self.existingFilters)
        }

        func isSkipped(_ field: Field, in section: LanguageSection) -> Bool {
            guard !section.isUnchanged(field) else { return false }
            let text = section[keyPath: field.keyPath]
            let ownFilter = section.restoredFilters[field]
            return self.isAlreadyAllowed(text, excluding: ownFilter) || self.isRepeated(field, in: section)
        }

        func skippedNote(for section: LanguageSection) -> String {
            var sentences: [String] = []
            var namedTexts: [String] = []
            for field in Field.allCases {
                guard !section.isUnchanged(field) else { continue }
                let trimmedText = section.trimmedText(field)
                let isolatedText = "\u{2068}" + trimmedText + "\u{2069}"
                let sentence: String?
                if self.isAlreadyAllowed(trimmedText, excluding: section.restoredFilters[field]) {
                    sentence = String(format: self.localizedString("stayReachable_alreadyAllowed", in: section.language), isolatedText)
                } else if self.isRepeated(field, in: section) {
                    sentence = String(format: self.localizedString("stayReachable_enteredTwice", in: section.language), isolatedText)
                } else {
                    sentence = nil
                }
                let isNamed = namedTexts.contains { $0.caseInsensitiveCompare(trimmedText) == .orderedSame }
                guard let sentence, !isNamed else { continue }
                sentences.append(sentence)
                namedTexts.append(trimmedText)
            }
            return sentences.joined(separator: " ")
        }

        func title(for section: LanguageSection) -> String {
            let title: String
            if self.hasLabels(for: section.language) {
                title = section.language.nativeName
            } else {
                title = section.language.displayName
            }
            return title
        }

        func title(for field: Field, in section: LanguageSection) -> String {
            return self.localizedString(field.titleKey, in: section.language)
        }

        func prompt(for field: Field, in section: LanguageSection) -> String {
            return self.localizedString(field.promptKey, in: section.language)
        }

        func layoutDirection(for section: LanguageSection) -> LayoutDirection? {
            let direction: LayoutDirection?
            if self.hasLabels(for: section.language) {
                direction = section.language.isRightToLeft ? .rightToLeft : .leftToRight
            } else {
                direction = nil
            }
            return direction
        }

        func languageChoices(in languages: [Locale.LanguageCode], for section: LanguageSection) -> [Locale.LanguageCode] {
            let otherSections = self.sections.filter { $0.id != section.id }
            let takenLanguages = otherSections.map(\.language)
            return languages.filter { !takenLanguages.contains($0) }
        }

        func unusedLanguages(in languages: [Locale.LanguageCode]) -> [Locale.LanguageCode] {
            let takenLanguages = self.sections.map(\.language)
            return languages.filter { !takenLanguages.contains($0) }
        }

        func setLanguage(_ language: Locale.LanguageCode, for section: LanguageSection) {
            guard let index = self.sections.firstIndex(where: { $0.id == section.id }) else { return }
            Log.debug("language changed, language: \(self.sections[index].language.identifier) → \(language.identifier)")
            self.sections[index].language = language
        }

        func addSection(language: Locale.LanguageCode) {
            Log.debug("language added, language: \(language.identifier), sections: \(self.sections.count + 1)")
            self.sections.append(LanguageSection(language: language))
        }

        func removeSection(_ section: LanguageSection) {
            Log.debug("language removed, language: \(section.language.identifier), sections: \(self.sections.count - 1)")
            self.sections.removeAll { $0.id == section.id }
        }

        func addFilters() {
            Log.debug("saving, new: \(self.newFilterTexts), edited: \(self.editedTexts), cleared: \(self.clearedFieldCount), languages: \(self.sections.map(\.language.identifier))")
            self.appManager.stayReachableManager.save(self.sections)
        }


        //MARK: Private
        private func hasLabels(for language: Locale.LanguageCode) -> Bool {
            return language.appLocalization != nil || Self.extraLocalizations[language.identifier] != nil
        }

        private func localizedString(_ key: String, in language: Locale.LanguageCode) -> String {
            let localizedString: String
            if let localization = language.appLocalization,
               let path = Bundle.main.path(forResource: localization, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)
            } else if let extraString = Self.extraLocalizations[language.identifier]?[key] {
                localizedString = extraString
            } else {
                localizedString = key~
            }
            return localizedString
        }

        private func isRepeated(_ field: Field, in section: LanguageSection) -> Bool {
            let trimmedText = section.trimmedText(field)
            guard trimmedText.count >= kMinimumFilterLength,
                  let sectionIndex = self.sections.firstIndex(where: { $0.id == section.id }) else { return false }
            let earlierSections = self.sections.prefix(upTo: sectionIndex)
            let earlierFields = Field.allCases.prefix { $0 != field }
            var earlierTexts = earlierSections.flatMap(\.texts)
            earlierTexts.append(contentsOf: earlierFields.map { section[keyPath: $0.keyPath] })
            let trimmedEarlierTexts = earlierTexts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            return trimmedEarlierTexts.contains { $0.caseInsensitiveCompare(trimmedText) == .orderedSame }
        }
    }
}


//MARK: - Field -
extension StayReachableField: TestIdentifiable {
    var titleKey: String {
        switch self {
        case .firstName: return "stayReachable_firstName"
        case .surname: return "stayReachable_surname"
        case .street: return "stayReachable_street"
        }
    }

    var promptKey: String {
        switch self {
        case .firstName, .surname: return "stayReachable_optional"
        case .street: return "stayReachable_streetPrompt"
        }
    }

    var contentType: UITextContentType? {
        switch self {
        case .firstName: return .givenName
        case .surname: return .familyName
        case .street: return nil
        }
    }

    var testIdentifier: TestIdentifier {
        switch self {
        case .firstName: return .stayReachableFirstNameField
        case .surname: return .stayReachableSurnameField
        case .street: return .stayReachableStreetField
        }
    }
}


//MARK: - Preview -
struct StayReachableView_Previews: PreviewProvider {
    static var previews: some View {
        let model = StayReachableView.ViewModel(appManager: AppManager.previews)
        let english = StayReachableView.LanguageSection(language: .english)
        let hebrew = StayReachableView.LanguageSection(language: Locale.LanguageCode("he"))
        model.sections = [english, hebrew]
        return StayReachableView(model: model)
    }
}
