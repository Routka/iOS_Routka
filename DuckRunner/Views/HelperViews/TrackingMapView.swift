//
//  TrackingMapView.swift
//  DuckRunner
//
//  Created by vladukha on 16.02.2026.
//
import MapKit
import SwiftUI
import UIKit

/// UIKit bridged MapView with track rendering and user location following
struct TrackingMapView: UIViewRepresentable {
    
    enum MapViewMode {
        case trackUser
        case bounds(Track)
        /// Like bounds which moves map to the track but you can move it freely
        case free(Track)
    }

    let overlays: [any MKOverlay]
    let markers: [any MKAnnotation]
    let mapMode: MapViewMode
    
    init(overlays: [any MKOverlay],
         markers: [any MKAnnotation] = [],
         mapMode: MapViewMode = .trackUser) {
        self.overlays = overlays
        self.mapMode = mapMode
        self.markers = markers
    }
    
    init(track: Track,
         markers: [any MKAnnotation] = [],
         mapMode: MapViewMode = .trackUser) {
        self.overlays = [SpeedTrackOverlay(track: track.points)]
        self.mapMode = mapMode
        self.markers = markers
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator

        // Interaction restrictions
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        
        mapView.isZoomEnabled = true
        switch mapMode {
        case .trackUser:
            mapView.isScrollEnabled = false
            let camera = MKMapCamera()
            camera.pitch = 80
            camera.altitude = 80
            camera.heading = 0

            mapView.camera = camera
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(.followWithHeading, animated: false)
            for marker in markers {
                mapView.addAnnotation(marker)
            }
            for overlay in overlays {
                mapView.addOverlay(overlay)
            }
        case .bounds(let track):
            mapView.isScrollEnabled = false
            mapView.showsUserLocation = false
            if let region = getRegion(for: track) {
                mapView.setRegion(region, animated: true)
            }
            for marker in markers {
                mapView.addAnnotation(marker)
            }
            for overlay in overlays {
                mapView.addOverlay(overlay)
            }
        case .free(let track):
            mapView.isScrollEnabled = true
            mapView.showsUserLocation = false
            if let region = getRegion(for: track) {
                mapView.setRegion(region, animated: true)
            }
            for marker in markers {
                mapView.addAnnotation(marker)
            }
            for overlay in overlays {
                mapView.addOverlay(overlay)
            }
        }
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Helper for overlays (value equality)
        func overlaysEqual(_ lhs: MKOverlay, _ rhs: MKOverlay) -> Bool {
            if let lhs = lhs as? any TrackOverlayProtocol,
               let rhs = rhs as? (any TrackOverlayProtocol) {
                return lhs.points == rhs.points
            }
            // by default we redraw the overlay
            return false
        }
        // Helper for markers (value equality)
        func markersEqual(_ lhs: MKAnnotation, _ rhs: MKAnnotation) -> Bool {
            // Compare coordinate, title, and type name
            lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude &&
            String(describing: type(of: lhs)) == String(describing: type(of: rhs)) &&
            ((lhs.title ?? "") == (rhs.title ?? ""))
        }
        // --- Overlays (by value) ---
        let currentOverlays = mapView.overlays
        // Remove overlays not present in new set
        for overlay in currentOverlays {
            if !overlays.contains(where: { overlaysEqual($0, overlay) }) {
                mapView.removeOverlay(overlay)
            }
        }
        // Add overlays not present in current set
        for overlay in overlays {
            if !currentOverlays.contains(where: { overlaysEqual($0, overlay) }) {
                mapView.addOverlay(overlay)
            }
        }
        // --- Markers (by value) ---
        let nonUserAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        // Remove markers not present in new set
        for annotation in nonUserAnnotations {
            if !markers.contains(where: { markersEqual($0, annotation) }) {
                mapView.removeAnnotation(annotation)
            }
        }
        // Add markers not present in current set
        for marker in markers {
            if !nonUserAnnotations.contains(where: { markersEqual($0, marker) }) {
                mapView.addAnnotation(marker)
            }
        }
    }
    

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    
    private func getRegion(for track: Track) -> MKCoordinateRegion? {
        let points = track.points
        guard points.count > 1,
              let first = points.first?.position else { return nil }
        let bounds = points.reduce(
            into: (
                minLat: first.latitude,
                maxLat: first.latitude,
                minLon: first.longitude,
                maxLon: first.longitude
            )
        ) { result, point in
            result.minLat = min(result.minLat, point.position.latitude)
            result.maxLat = max(result.maxLat, point.position.latitude)
            result.minLon = min(result.minLon, point.position.longitude)
            result.maxLon = max(result.maxLon, point.position.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (bounds.minLat + bounds.maxLat) / 2,
            longitude: (bounds.minLon + bounds.maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (bounds.maxLat - bounds.minLat) * 2,
            longitudeDelta: (bounds.maxLon - bounds.minLon) * 2
        )
        
        let region = MKCoordinateRegion(center: center, span: span)
        return region
    }
}


extension TrackingMapView {

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(
            _ mapView: MKMapView,
            rendererFor overlay: MKOverlay
        ) -> MKOverlayRenderer {
            return overlay.renderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location
            guard !annotation.isKind(of: MKUserLocation.self) else { return nil }
            
            // Provide a custom view for StartPointAnnotation
            if let annotation = annotation as? FlagAnnotation {
                let identifier = "StartPointAnnotationView"
                let view: MKAnnotationView
                if let dequeued = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                    view = dequeued
                    view.annotation = annotation
                } else {
                    view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                let image = annotation.makeImage()
                view.image = image
                view.canShowCallout = true
                view.centerOffset = CGPoint(x: 0, y: 0)
                return view
            }
            return nil
        }
    }
}





#Preview {
    TrackingMapView(overlays: [ReplayTrackOverlay(track: .roadInSPB)],
                    markers: [StartPointAnnotation(coordinate: Track.filledTrack.points.first!.position),
                              StopPointAnnotation(coordinate: Track.filledTrack.points.last!.position)],
                    mapMode: .bounds(.filledTrack))
                .ignoresSafeArea()
}

