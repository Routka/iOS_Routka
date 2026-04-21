//
//  TrackMapDetailView.swift
//  Routka
//
//  Created by vladukha on 04.04.2026.
//

import SwiftUI
import MapKit
import SimpleRouter
import NeedleFoundation

protocol TrackMapDependency: Dependency {
    var locationService: any LocationServiceProtocol { get }
}

nonisolated
final class TrackMapComponent: Component<TrackMapDependency> {
    private let track: Track
    init(parent: Scope,
         track: Track) {
        self.track = track
        super.init(parent: parent)
    }
    
    @MainActor
    var view: TrackMapDetailView {
        TrackMapDetailView(track: track, mapViewModel: mapViewModel)
    }
    
    @MainActor
    var mapViewModel: MapViewModel {
        MapViewModel(mode: .free(track),
                     locationService: dependency.locationService)
    }
    
    @MainActor
    var route: any Route {
        RouteBuilder(component: self)
    }
    
    @MainActor
    struct RouteBuilder: Route {
        static func == (lhs: RouteBuilder, rhs: RouteBuilder) -> Bool {
            lhs.component.track == rhs.component.track
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(component.track)
        }
        
        let component: TrackMapComponent

        func build() -> AnyView {
            AnyView(component.view)
        }
    }
}

struct TrackMapDetailView: View {
    @State private var undoableList: UndoService<TrackPoint> = .init()
    @State private var trackBounds: MKMapRect?
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    let track: Track
    @State private var coordinate: CGPoint = .zero
    
    let mapViewModel: MapViewModel
    
    var body: some View {
        ZStack {
            MapReader { proxy in
                MapView(vm: mapViewModel) {
                    MapContents.speedTrack(track)
                    if let start = track.points.first {
                        MapContents.startPoint(start)
                    }
                    if let last = track.points.last {
                        MapContents.stopPoint(last)
                    }
                    
                    ForEach(undoableList.state, id: \.position) { point in
                        
                        Annotation(coordinate: point.position,
                                   anchor: .bottom) {
                            SpeedPointView(point)
                                .transition(.opacity)
                            .onTapGesture {
                                undoableList.removeElement(point)
                            }
                        } label: {
                            EmptyView()
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing, content: {
                    controls
                })
                .animation(.bouncy, value: undoableList.state)
                .onAppear {
                    guard self.trackBounds == nil else { return }
                    let region = self.track.points.regionOfATrack()
                    self.trackBounds = .init(region: region)
                    if ProcessInfo.processInfo.arguments.contains("CreateSpeedCheckpointsForUITest") {
                        let totalCount = self.track.points.count
                        let step = totalCount / 4
                        let stride: StrideTo<Int> = stride(from: step, to: totalCount - step, by: step)
                        for index in stride {
                            let point = self.track.points[index]
                            self.undoableList.addElement(point)
                        }
                    }
                }
                .onTapGesture { tapPoint in
                    print("TappedPoint", tapPoint)
                    Task.detached {
                        guard let tapPointCoordinate = proxy.convert(tapPoint, from: .local) else { return }
                        let tapAsMapPoint = MKMapPoint(tapPointCoordinate)
                        // Skip finding closest speed point if the tap is outside the track bounds, helps with optimization
                        guard let trackBounds = await trackBounds,
                              trackBounds.contains(tapAsMapPoint) else { return }
                        guard let closestPoint = closestTrackPoint(to: tapAsMapPoint) else { return }
                        guard let pointOnScreen = proxy.convert(closestPoint.position, to: .local) else { return }
                        // limiting tap to some are around the found point
                        guard abs(tapPoint.x - pointOnScreen.x) < 18,
                              abs(tapPoint.y - tapPoint.y) < 18 else { return }
                        await MainActor.run {
                            withAnimation {
                                undoableList.addElement(closestPoint)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @Namespace var glassSpace
    
    
    
    
    private var controls: some View {
        GlassEffectContainer() {
            HStack(spacing: 20) {
                HStack {
                        Button {
                            undoableList.removeAllElements()
                        } label: {
                            Image(systemName: "eraser")
                                .padding(8)
                                .opacity(undoableList.state.isEmpty ? 0.3 : 1)
                        }
                        .glassEffect(.clear.interactive(), in: Circle())
                        .disabled(undoableList.state.isEmpty)
                }
                HStack {
                        Button {
                            withAnimation {
                                undoableList.undo()
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .padding(8)
                                .opacity(undoableList.doneActions.isEmpty ? 0.3 : 1)
                        }
                        .glassEffect(.clear.interactive(), in: Circle())
                        .disabled(undoableList.doneActions.isEmpty)
                        Button {
                            withAnimation {
                                undoableList.forward()
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.forward")
                                .padding(8)
                                .opacity(undoableList.undoneActions.isEmpty ? 0.3 : 1)
                        }
                        .glassEffect(.clear.interactive(), in: Circle())
                        .disabled(undoableList.undoneActions.isEmpty)
                    
                }
                
            }
            
        }
        .foregroundStyle(Color.primary)
        .font(.title)
        .padding(8)
        .animation(.bouncy, value: undoableList.state)
    }
    
    nonisolated
    private func closestTrackPoint(to point: MKMapPoint) -> TrackPoint? {
        
        let closest = track.points.min { left, right in
            let leftDistance = MKMapPoint(left.position).distance(to: point)
            let rightDistance = MKMapPoint(right.position).distance(to: point)
            return leftDistance < rightDistance
        }
        return closest
    }
    
    
}

nonisolated
class MockTrackMapDetailParentComponent: BootstrapComponent {
    
    @MainActor
    public var locationService: any LocationServiceProtocol {
        DependencyManager.MockLocationService()
    }
    
    @MainActor
    var trackMapComponent: TrackMapComponent {
        TrackMapComponent(parent: self,
                          track: .filledTrack)
    }
}

#Preview {
    Group {
        let component = MockTrackMapDetailParentComponent()
        return component.trackMapComponent.view
    }
}
