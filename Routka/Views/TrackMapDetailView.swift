//
//  TrackMapDetailView.swift
//  Routka
//
//  Created by vladukha on 04.04.2026.
//

import SwiftUI
import MapKit
import SimpleRouter

extension Route where Self == MeasuredTrackDetailView.RouteBuilder {
    /// View of a detailed measured track view
    static func mapTrackDetail(track: Track,
                            dependencies: DependencyManager) -> TrackMapDetailView.RouteBuilder {
        TrackMapDetailView.RouteBuilder(track: track, dependencies: dependencies)
    }
}

struct TrackMapDetailView: View {
    struct RouteBuilder: Route {
        static func == (lhs: TrackMapDetailView.RouteBuilder, rhs: TrackMapDetailView.RouteBuilder) -> Bool {
            lhs.track == rhs.track
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(track)
        }
        
        let track: Track
        let dependencies: DependencyManager

        func build() -> AnyView {
            AnyView(TrackMapDetailView(track: track,
                                    dependencies: dependencies))
        }
    }
    
    @State private var undoableList: UndoService<TrackPoint> = .init()
    @State private var trackBounds: MKMapRect?
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    let track: Track
    let dependencies: DependencyManager
    var body: some View {
        MapReader { proxy in
            MapView(mode: .free(track), dependencies: dependencies) {
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
            }
            .onTapGesture { tapPoint in
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

#Preview {
    TrackMapDetailView(track: .filledTrack, dependencies: .mock())
}
