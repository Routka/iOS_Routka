//
//  TrackHistoryView.swift
//  Routka
//
//  Created by vladukha on 16.02.2026.
//

import SwiftUI
import Combine

/// Root view for displaying the user's track history with date-based navigation and detail view links.
struct TrackHistoryView: View {
    
    
    /// The view model managing and providing track history data and selection.
    @State private var vm: any TrackHistoryViewModelProtocol
    /// User's preferred unit for speed display, persisted locally.
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    
    
    /// Initializes the history view with the given view model.
    init(vm: any TrackHistoryViewModelProtocol) {
        self._vm = .init(wrappedValue: vm)
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
                                vm.openTrack(track)
                            } label: {
                                vm.trackCell(track, unitSpeed: .byName(speedUnit))
                                    .view
                                .containerRelativeFrame([.horizontal, .vertical]) { size, axis in
                                    if axis == .vertical {
                                        return size * 0.4
                                    } else {
                                        return size * 0.95
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
    func openTrack(_ track: Track) {
    }

    func trackCell(_ track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        TrackHistoryCellMockComponentProvider().trackCell(track: track, unit: unitSpeed)
    }
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
    TrackHistoryView(vm: PreviewModel())
}
