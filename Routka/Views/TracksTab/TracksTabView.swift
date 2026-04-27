//
//  TracksTabView.swift
//  Routka
//
//  Created by vladukha on 08.03.2026.
//

import SwiftUI
import NeedleFoundation

struct TracksTabView: View {
    private enum SectionID: Hashable {
        case history
        case measurements
        case imported
    }

    @AppStorage("speedunit") var speedUnit: String = "km/h"
    @State private var vm: any TracksTabViewModelProtocol

    init(vm: any TracksTabViewModelProtocol) {
        self._vm = .init(wrappedValue: vm)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroHeader(proxy: proxy)
                    historyTimeLine
                        .id(SectionID.history)
                    measuredTimeLine
                        .id(SectionID.measurements)
                    importedTimeLine
                        .id(SectionID.imported)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .defaultBackground()
            .frame(maxWidth: .infinity)
        }
    }
    
    private func heroHeader(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "book.pages.fill")
                    Text("Your journal")
                }
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Browse recorded runs, compare measurements, and jump back into imported sessions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !vm.historyTracks.isEmpty ||
               !vm.measuredTracks.isEmpty ||
               !vm.importedTracks.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()),
                                    GridItem(.flexible())]) {
                    if !vm.historyTracks.isEmpty {
                        statCard(title: "History",
                                 value: vm.historyTracks.count.formatted(),
                                 icon: "road.lanes",
                                 tint: .blue) {
                            scroll(to: .history, proxy: proxy)
                        }
                    }
                    if !vm.measuredTracks.isEmpty {
                        statCard(title: "Measurements",
                                 value: vm.measuredTracks.count.formatted(),
                                 icon: "gauge.with.dots.needle.50percent",
                                 tint: .orange) {
                            scroll(to: .measurements, proxy: proxy)
                        }
                    }
                    if !vm.importedTracks.isEmpty {
                        statCard(title: "Imported",
                                 value: vm.importedTracks.count.formatted(),
                                 icon: "square.and.arrow.down.on.square",
                                 tint: .green) {
                            scroll(to: .imported, proxy: proxy)
                        }
                    }
                }
            }

//            HStack(spacing: 12) {
//                Button {
//                    pushTrackHistory()
//                } label: {
//                    Label("Open History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity)
//                }
//                .buttonStyle(.borderedProminent)
//                .tint(.blue)
//
//                Button {
//                    dependencies.trackFileService.showImporter()
//                } label: {
//                    Label("Import", systemImage: "square.and.arrow.down")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity)
//                }
//                .buttonStyle(.bordered)
//            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8)
    }

    private var importedTimeLine: some View {
        sectionContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    sectionHeader(title:"Imported Tracks",
                                  subtitle: "Files and external routes you brought into Routka.",
                                  icon: "square.and.arrow.down.on.square",
                                  showLink: vm.importedTracks.count >= vm.showLimit) {
                        vm.openImportedTracks()
                    }
                }

                ZStack {
                    if vm.importedTracks.isEmpty {
                        emptyStateCard(title: "No imported tracks yet",
                                       message: "Bring in .routka saved files.",
                                       buttonTitle: "Import from files",
                                       systemImage: "square.and.arrow.down") {
                            vm.showImporter()
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            vm.showImporter()
                        } label: {
                            Label("Import from files", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.glass)
                        .opacity(vm.importedTracks.isEmpty ? 0 : 1)
                        trackCarousel(vm.importedTracks)
                    }
                    
                }
            }
        }
    }
    
    private var historyTimeLine: some View {
        sectionContainer {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(title: "History",
                              subtitle: "Your latest recorded drives.",
                              icon: "road.lanes",
                              showLink: vm.historyTracks.count >= vm.showLimit) {
                    vm.openTrackHistory()
                }

                ZStack {
                    trackCarousel(vm.historyTracks)
                    if vm.historyTracks.isEmpty {
                        emptyStateCard(title: "No recorded history",
                                       message: "Start a run from the map tab and your sessions will appear here with route snapshots and stats.",
                                       buttonTitle: "Open Map",
                                       systemImage: "map") {
                            vm.openMap()
                        }
                    }
                    
                }
            }
        }
    }
    
    private var measuredTimeLine: some View {
        sectionContainer {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(title: "Measurements",
                              subtitle: "Saved measurements",
                              icon: "gauge.with.dots.needle.50percent",
                              showLink: vm.measuredTracks.count >= vm.showLimit) {
                    vm.openMeasuredTracks()
                }

                ZStack {
                    if vm.measuredTracks.isEmpty {
                        emptyStateCard(title: "No saved measurements",
                                       message: "Use an auto-stop preset while recording to build a library of comparable timed attempts.",
                                       buttonTitle: "Open Map",
                                       systemImage: "dial.high") {
                            vm.openMap()
                        }
                    }
                    measuredCarousel
                }
            }
        }
    }

    private var measuredCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            let batches = vm.measuredTracks.chunks(of: 3)
            HStack(alignment: .top, spacing: 8) {
                ForEach(batches, id: \.hashValue) { batch in
                    VStack(spacing: 10) {
                        ForEach(batch) { measure in
                            Button {
                                vm.openMeasuredTrack(measure)
                            } label: {
                                MeasuredTrackCellView(measured: measure)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .glassEffect(.regular, in: .buttonBorder)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollTargetBehavior(.viewAligned)
        .scrollClipDisabled()
    }

    private func trackCarousel(_ tracks: [Track]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack() {
                ForEach(tracks) { track in
                    Button {
                        vm.openTrack(track)
                    } label: {
                        vm.trackHistoryCellComponent(track: track,
                                                     unitSpeed: UnitSpeed.byName(speedUnit))
                        .view
                    }
                    .accessibilityIdentifier("historyTrackButton_\(track.id)")
                    .frame(height: 250)
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned(anchor: .leading))
        .scrollClipDisabled()
        .contentMargins(.trailing, 15, for: .scrollContent)
    }

    private func sectionHeader(title: LocalizedStringKey,
                               subtitle: LocalizedStringKey,
                               icon: String,
                               showLink: Bool,
                               action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                
                Label(title, systemImage: icon)
                    .font(.title3.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                if showLink {
                    Button("More", action: action)
                        .buttonStyle(.glass)
                }
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
        }
    }

    private func statCard(title: LocalizedStringKey,
                          value: String,
                          icon: String,
                          tint: Color,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(tint	)
                    Text(value)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func sectionContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(18)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8)
    }

    private func emptyStateCard(title: LocalizedStringKey,
                                message: LocalizedStringKey,
                                buttonTitle: LocalizedStringKey,
                                systemImage: String,
                                action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(buttonTitle, action: action)
                .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    private func scroll(to section: SectionID, proxy: ScrollViewProxy) {
        withAnimation(.smooth(duration: 0.35)) {
            proxy.scrollTo(section, anchor: .top)
        }
    }
}
//
//let measureds: [MeasuredTrack] = [
//    .init(id: "1", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//    .init(id: "2", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//    .init(id: "3", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//    .init(id: "4", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//    .init(id: "5", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//    .init(id: "6", measurement: .reachingDistance(30, name: "1/8 mill"), track: .filledTrack),
//]


@Observable
private final class PreviewModel: TracksTabViewModelProtocol {
    func openTrack(_ track: Track) {
    }
    func trackHistoryCellComponent(track: Track, unitSpeed: UnitSpeed) -> TrackHistoryCellComponent {
        TrackHistoryCellMockComponentProvider().trackCell(track: track, unit: unitSpeed)
    }
    
    func showImporter() {
    }
    
    func openMap() {
    }
    
    func openMeasuredTrack(_ measure: MeasuredTrack) {
    }
    
    func openTrackHistory() {
    }
    
    func openMeasuredTracks() {
    }
    
    func openImportedTracks() {
    }
    
    var showLimit: Int = 2
    
    var historyTracks: [Track] = [/*.newFilledTrack(),
                                  .newFilledTrack(),
                                  .newFilledTrack(),
                                  .newFilledTrack(),*/]
//
//    var measuredTracks: [MeasuredTrack] = [
//        .init(id: "", measurement: .reachingDistance(30, name: "1/2 mile"), track: .filledTrack),
//        .init(id: "1", measurement: .reachingDistance(30, name: "1/2 mile"), track: .filledTrack),
//        .init(id: "2", measurement: .reachingDistance(30, name: "1/2 mile"), track: .filledTrack),
//        .init(id: "3", measurement: .reachingDistance(30, name: "1/2 mile"), track: .filledTrack),
//        .init(id: "4", measurement: .reachingDistance(30, name: "1/2 mile"), track: .filledTrack),
//    ]

    var importedTracks: [Track] = [/*.filledTrack,
                                   .newFilledTrack()*/]

//    var historyTracks: [Track] = []
    
    var measuredTracks: [MeasuredTrack] = []
    
//    var importedTracks: [Track] = []
    
    
}

#Preview {
    TracksTabView(vm: PreviewModel())
        .environment(\.locale, .init(identifier: "en"))
}
