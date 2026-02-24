//
//  TrackHistoryView.swift
//  DuckRunner
//
//  Created by vladukha on 16.02.2026.
//

import SwiftUI
import Combine

extension TrackHistoryView where ViewModel == TrackHistoryViewModel {
    init(dependencies: DependencyManager) {
        self.init(vm: .init(dependencies: dependencies),
                  dependencies: dependencies)
    }
}

/// Root view for displaying the user's track history with date-based navigation and detail view links.
struct TrackHistoryView<ViewModel: TrackHistoryViewModelProtocol>: View {
    /// The view model managing and providing track history data and selection.
    @StateObject private var vm: ViewModel
    /// User's preferred unit for speed display, persisted locally.
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    
    private let dependencies: DependencyManager
    
    /// Initializes the history view with the given view model.
    init(vm: ViewModel,
         dependencies: DependencyManager) {
        self._vm = .init(wrappedValue: vm)
        self.dependencies = dependencies
    }
    
    /// The main UI displaying history list, navigation links, and date selector.
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    dateSelector
                    Divider()
                    LazyVStack(spacing: 5) {
                        if vm.tracks.isEmpty {
                            Text("Empty history")
                                .font(.largeTitle)
                                .opacity(0.6)
                                .transition(.opacity)
                        }
                        ForEach(vm.tracks, id: \.id) { track in
                            Button {
                                dependencies.routers[dependencies.tabRouter.selectedTab]?.push(
                                    .trackDetail(track: track, dependencies: dependencies))
                            } label: {
                                TrackHistoryCellView(track: track,
                                                     unit: UnitSpeed.byName(speedUnit),
                                                     dependencies: dependencies)
                            }
                        }
                    }
                    
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .animation(.default, value: vm.tracks.isEmpty)
            .navigationTitle("History")
            .background(Color.cyan.gradient.opacity(0.05))
        }
        
    }
    
    /// UI component for selecting the date whose tracks are shown.
    private var dateSelector: some View {
        DatePicker("Date",
                   selection: $vm.selectedDate,
                   displayedComponents: [.date])
        .datePickerStyle(.compact)
            
    }
}

fileprivate final class PreviewModel: TrackHistoryViewModelProtocol {
    @Published var selectedDate: Date = .now
    
    @Published var tracks: [Track] = []
    
    func deleteDestinations(_ indexSet: IndexSet) {
        
    }
    init() {
        self.tracks.append(.filledTrack)
    }
    
}




#Preview {
    TrackHistoryView(vm: PreviewModel(),
                     dependencies: .mock()
    )
}
