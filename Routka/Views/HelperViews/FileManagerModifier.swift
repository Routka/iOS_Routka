//
//  FileManagerModifier.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import vladukhaAlerts

extension View {
    
    func fileManager(managedBy dependencies: DependencyManager) -> some View {
        self.modifier(FileServiceViewWrapper(dependencies: dependencies))
           
    }
}


private struct FileServiceViewWrapper: ViewModifier {
    @State var service: any TrackFileServiceProtocol
    let dependencies: DependencyManager
    init(dependencies: DependencyManager) {
        self._service = .init(wrappedValue: dependencies.trackFileService)
        self.dependencies = dependencies
    }
    
    func importFromURL(url: URL) {
        
    }
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                guard url.isFileURL, url.pathExtension.lowercased() == "routka" else {
                    return
                }
                Task { @MainActor in
                    guard let track = try? await service.importFromFile(url: url) else { return }
                    dependencies.tabRouter.selectedTab = "Tracks"
                    dependencies.routers[dependencies.tabRouter.selectedTab]?.popToRoot()
                    dependencies.routers[dependencies.tabRouter.selectedTab]?.push(.trackDetail(track: track, dependencies: dependencies))
                }
            }
            .fileImporter(
                isPresented: $service.isImporterPresented,
                allowedContentTypes: [UTType(filenameExtension: "routka")!],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    Task {
                        do {
                            let importedTrack = try await service.importFromFile(url: url)
                            dependencies.routers[dependencies.tabRouter.selectedTab]?
                                .push(.trackDetail(track: importedTrack, dependencies: dependencies))
                        } catch {
                            await AlertController.shared.showAlert(String(localized: "importing track error alert",
                                                                          table: "ExportImportAlerts"),
                                                                   icon: .angryFail,
                                                                   timeout: 5,
                                                                   closable: true,
                                                                   feedback: .error)
                        }
                    }
                case .failure(let error):
                    Task {
                        await AlertController.shared.showAlert(String(localized: "importing track error alert",
                                                                      table: "ExportImportAlerts"),
                                                               icon: .angryFail,
                                                               timeout: 5,
                                                               closable: true,
                                                               feedback: .error)
                    }
//                TODO: Record the error to metric
                    print(error)
                }
            }
            .fileMover(isPresented: $service.isExporterPresented,
                       file: service.fileToExport) { result in
                switch result {
                case .success(let newURL):
                    print("Success moving file", newURL)
                    Task {
                        await AlertController.shared.showAlert(String(localized: "export track success",
                                                                      table: "ExportImportAlerts"),
                                                               icon: .done,
                                                               timeout: 5,
                                                               closable: true,
                                                               feedback: .success)
                    }
                case .failure(let failure):
                    print("Failure moving file", failure)
//                TODO: Record error to metric
                    Task {
                        await AlertController.shared.showAlert(String(localized: "exporting track error alert",
                                                                      table: "ExportImportAlerts"),
                                                               icon: .angryFail,
                                                               timeout: 5,
                                                               closable: true,
                                                               feedback: .error)
                    }
                }
            }
                       
    }
}
