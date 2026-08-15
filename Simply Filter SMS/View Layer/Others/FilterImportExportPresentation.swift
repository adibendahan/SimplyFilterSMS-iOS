//
//  FilterImportExportPresentation.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import SwiftUI
import UniformTypeIdentifiers


struct FilterImportExportPresentation: ViewModifier {
    @ObservedObject var model: ViewModel

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: self.$model.previewViewModel) { viewModel in
                FilterImportPreviewView(model: viewModel)
            }
            .sheet(item: self.$model.exportFile) { file in
                ShareSheet(items: [file.url])
            }
            .alert("importFilters_title"~, isPresented: self.$model.showNothingToImportAlert) {
                Button("general_close"~, role: .cancel) {
                    self.model.didDismissNothingToImportAlert()
                }
            } message: {
                Text("importFilters_nothingToAdd"~)
            }
            .background {
                Color.clear
                    .frame(width: 0, height: 0)
                    .fileImporter(isPresented: self.$model.isImportingFile,
                                  allowedContentTypes: [.sfsFilters, .json],
                                  allowsMultipleSelection: false) { result in
                        self.model.handlePickedFiles(result)
                    }
                    .id(self.model.fileImporterID)
            }
    }
}


//MARK: - ViewModel -
extension FilterImportExportPresentation {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var previewViewModel: FilterImportPreviewView.ViewModel? {
            didSet {
                if self.previewViewModel == nil {
                    if let notification = self.pendingNotification {
                        self.pendingNotification = nil
                        self.onNotification?(notification)
                    }
                    self.presentPendingIfPossible()
                }
            }
        }
        @Published var isImportingFile = false
        @Published var exportFile: ExportFile?
        @Published var showNothingToImportAlert = false
        @Published var fileImporterID = UUID()
        var exportFileURL: URL? { return self.exportFile?.url }

        var isPresenting: Bool {
            return self.previewViewModel != nil || self.exportFile != nil || self.showNothingToImportAlert
        }

        private let isPresentationBlocked: () -> (Bool)
        private let onImported: (() -> ())?
        private let onNotification: ((NotificationView.Notification) -> ())?
        private var pendingImportData: Data?
        private var pendingNotification: NotificationView.Notification?

        init(appManager: AppManagerProtocol = AppManager.shared,
             isPresentationBlocked: @escaping () -> (Bool) = { return false },
             onImported: (() -> ())? = nil,
             onNotification: ((NotificationView.Notification) -> ())? = nil) {
            self.isPresentationBlocked = isPresentationBlocked
            self.onImported = onImported
            self.onNotification = onNotification
            super.init(appManager: appManager)
        }

        func export() {
            do {
                let url = try self.appManager.filterImportExportManager.writeExportFile()
                self.exportFile = ExportFile(url: url)
            } catch {
                AppManager.logger.error("exportFilters — failed: \(error.localizedDescription, privacy: .public)")
                self.onNotification?(.filterExportFailed)
            }
        }

        func beginFileImport() {
            self.isImportingFile = false
            DispatchQueue.main.async {
                self.isImportingFile = true
            }
        }

        func handlePickedFiles(_ result: Result<[URL], Error>) {
            self.isImportingFile = false
            self.fileImporterID = UUID()

            switch result {
            case .failure(let error):
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError {
                    return
                }
                AppManager.logger.error("importFilters — picker failed: \(error.localizedDescription, privacy: .public)")
                self.onNotification?(.filterImportFailed)

            case .success(let urls):
                guard let url = urls.first else {
                    self.onNotification?(.filterImportFailed)
                    return
                }
                self.importFromFileURL(url)
            }
        }

        func handleIncomingURL(_ url: URL) -> Bool {
            guard self.appManager.filterImportExportManager.isExportFile(url) else { return false }
            self.importFromFileURL(url)
            return true
        }

        func didDismissNothingToImportAlert() {
            self.showNothingToImportAlert = false
            self.presentPendingIfPossible()
        }

        func presentPendingIfPossible() {
            guard let data = self.pendingImportData,
                  self.canPresent else { return }
            self.pendingImportData = nil
            self.presentPreview(data: data)
        }

        private var canPresent: Bool {
            return self.isPresentationBlocked() == false &&
                self.previewViewModel == nil &&
                self.exportFile == nil &&
                self.showNothingToImportAlert == false
        }

        private func importFromFileURL(_ url: URL) {
            do {
                let data = try self.appManager.filterImportExportManager.readFile(at: url)
                if self.canPresent {
                    self.presentPreview(data: data)
                }
                else {
                    self.pendingImportData = data
                }
            } catch {
                AppManager.logger.error("importFilters — could not read file: \(url.lastPathComponent, privacy: .public)")
                self.onNotification?(.filterImportFailed)
            }
        }

        private func presentPreview(data: Data) {
            do {
                let preview = try self.appManager.filterImportExportManager.previewImport(data: data)
                guard preview.addedCount > 0 else {
                    self.showNothingToImportAlert = true
                    return
                }

                self.previewViewModel = FilterImportPreviewView.ViewModel(
                    preview: preview,
                    appManager: self.appManager,
                    onImported: { [weak self] result in
                        self?.onImported?()
                        self?.pendingNotification = .filtersImported(added: result.added, skipped: result.skippedCount)
                    })
            } catch {
                AppManager.logger.error("importFilters — failed: \(error.localizedDescription, privacy: .public)")
                self.onNotification?(.filterImportFailed)
            }
        }
    }
}
