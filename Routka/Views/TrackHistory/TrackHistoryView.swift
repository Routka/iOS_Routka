//
//  TrackHistoryView.swift
//  Routka
//
//  Created by vladukha on 16.02.2026.
//

import SwiftUI
import Combine
import SimpleRouter

extension Route where Self == TrackHistoryView.RouteBuilder {
    /// View of a detailed measured track view
    static func trackHistory(vm: any TrackHistoryViewModelProtocol,
                            dependencies: DependencyManager) -> TrackHistoryView.RouteBuilder {
        TrackHistoryView.RouteBuilder(vm: vm, dependencies: dependencies)
    }
}
  

/// Root view for displaying the user's track history with date-based navigation and detail view links.
struct TrackHistoryView: View {
    
    struct RouteBuilder: Route {
        let id: String = UUID.init().uuidString
        static func == (lhs: TrackHistoryView.RouteBuilder, rhs: TrackHistoryView.RouteBuilder) -> Bool {
            lhs.id == rhs.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        let vm: any TrackHistoryViewModelProtocol
        let dependencies: DependencyManager

        func build() -> AnyView {
            AnyView(TrackHistoryView(vm: vm, dependencies: dependencies))
        }
    }
    
    /// The view model managing and providing track history data and selection.
    @State private var vm: any TrackHistoryViewModelProtocol
    /// User's preferred unit for speed display, persisted locally.
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    
    private let dependencies: DependencyManager
    
    /// Initializes the history view with the given view model.
    init(vm: any TrackHistoryViewModelProtocol,
         dependencies: DependencyManager) {
        self._vm = .init(wrappedValue: vm)
        self.dependencies = dependencies
    }
    
    /// The main UI displaying history list, navigation links, and date selector.
    var body: some View {
        ScrollView {
            VStack {
                dateSelector
                Divider()
                LazyVStack(spacing: 15) {
                    if case .list(let array) = vm.state {
                        ForEach(array, id: \.id) { track in
                            Button {
#warning("Fix navigation")
//                                dependencies.routers[dependencies.tabRouter.selectedTab]?.push(
//                                    .trackDetail(track: track, dependencies: dependencies))
                            } label: {
                                TrackHistoryCellView(track: track,
                                                     unit: UnitSpeed.byName(speedUnit),
                                                     dependencies: dependencies)
                                .containerRelativeFrame([.horizontal, .vertical]) { size, axis in
                                    if axis == .vertical {
                                        return size * 0.4
                                    } else {
                                        return size
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .animation(.default, value: vm.state)
        .navigationTitle("History")
        .background {
            if case .list(let array) = vm.state,
               array.isEmpty {
                emptyTag
            }
        }
        .defaultBackground()
    }
    
    private var emptyTag: some View {
        Text("Empty history by day")
            .font(.largeTitle)
            .opacity(0.6)
            .transition(.opacity)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
    
    /// UI component for selecting the date whose tracks are shown.
    private var dateSelector: some View {
        DatePicker("Date",
                   selection: $vm.selectedDate,
                   displayedComponents: [.date])
        .datePickerStyle(.compact)
            
    }
}

@Observable
fileprivate final class PreviewModel: TrackHistoryViewModelProtocol {
    var state: ListState<Track> = .list([
        .newFilledTrack(),
        .newFilledTrack(),
        .newFilledTrack(),
        .newFilledTrack(),
        .newFilledTrack()
    ])
    
    var selectedDate: Date = .now
    
    
    func deleteDestinations(_ indexSet: IndexSet) {
        
    }
    init() {
    }
    
}




#Preview {
    TrackHistoryView(vm: PreviewModel(),
                     dependencies: .mock()
    )
}
