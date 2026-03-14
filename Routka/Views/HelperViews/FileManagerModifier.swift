//
//  FileManagerModifier.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

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
                        _ = try? await service.importFromFile(url: url)
                    }
                case .failure(let error):
//                    importError = error
                    print(error)
                    break
                }
            }
            .fileMover(isPresented: $service.isExporterPresented,
                       file: service.fileToExport) { result in
                switch result {
                case .success(let newURL):
                    print("SUCCESS MOVE")
                    break
//                    mainLogger.log("SUCCESS transfering video file to new URL", .info)
//                    self.downloadManager.successfullTranfserURL = newURL
//                    self.downloadManager.downloadFileDestination = nil
                case .failure(let failure):
                    print("FAILED MOVE")
                    break
//                    mainLogger.log("FAILURE transfering video file to new URL", message: failure.localizedDescription, .error)
//                    AlertController.showAlert("generic_error".localized())
                }
            }
                       
    }
}
