//
//  MapSnapshotGenerator.swift
//  Routka
//
//  Created by vladukha on 18.02.2026.
//


import MapKit

/**
 A protocol defining an interface for generating map snapshot images from a given track.

 Implementations of this protocol asynchronously generate a snapshot image of a map region containing the track,
 including any relevant overlays or annotations.
 */
protocol MapSnapshotGeneratorProtocol {
    /**
     Asynchronously generates a snapshot image for the specified track and output size.

     - Parameters:
       - track: The Track object containing geographic points and related data to visualize on the snapshot.
       - size: The desired size (in points) of the resulting snapshot image.

     - Returns: A `UIImage` representing the snapshot of the map region with the track overlay, or `nil` if generation is cancelled or fails.
     
     - Throws: Propagates errors thrown during snapshot generation.
     */
    func generateSnapshot(track: Track,
                          size: CGSize
    ) async throws -> UIImage? 
}

/**
 A concrete implementation of `MapSnapshotGeneratorProtocol` that generates map snapshots for a given track.

 This class specializes in creating a snapshot image of a map region covering the track's points, drawing colored paths to represent speed segments,
 and marking start, stop, and fastest points on the snapshot.
 */
final class MapSnapshotGenerator: MapSnapshotGeneratorProtocol {
    init() {
    }
    // Source - https://stackoverflow.com/a/35321619
    // Retrieved 2026-02-18, License - CC BY-SA 4.0

    func MKMapRectForCoordinateRegion(region:MKCoordinateRegion) -> MKMapRect {
        let topLeft = CLLocationCoordinate2D(latitude: region.center.latitude + (region.span.latitudeDelta/2), longitude: region.center.longitude - (region.span.longitudeDelta/2))
        let bottomRight = CLLocationCoordinate2D(latitude: region.center.latitude - (region.span.latitudeDelta/2), longitude: region.center.longitude + (region.span.longitudeDelta/2))

        let a = MKMapPoint(topLeft)
        let b = MKMapPoint(bottomRight)
        
        return MKMapRect(origin: MKMapPoint(x:min(a.x,b.x), y:min(a.y,b.y)), size: MKMapSize(width: abs(a.x-b.x), height: abs(a.y-b.y)))
    }
    
    /**
     Represents a normalized track point transformed into snapshot coordinate space.

     Contains the CGPoint position within the snapshot image, speed at that point, and the timestamp of the record.
     */
    struct NormalizedTrackPoint {
        /// The geographic coordinate for this track point.
        let position: CGPoint
        /// The speed measured at this point.
        let speed: CLLocationSpeed
        /// The date and time this point was recorded.
        let date: Date
        /// Initializes a new TrackPoint with the given location, speed, and timestamp.
        init(position: CGPoint, speed: CLLocationSpeed, date: Date) {
            self.position = position
            self.speed = speed
            self.date = date
        }
    }

    /**
     Generates a snapshot image for the given track and size, drawing the track path with speed-based colored segments.

     Marks the start and stop points and visually highlights the fastest point with an emoji.

     - Parameters:
       - track: The track data containing geographic points to be rendered on the snapshot.
       - size: The desired size of the output image.

     - Returns: A `UIImage` snapshot with the track path and markers drawn, or `nil` if cancelled.
     
     - Throws: Errors encountered during snapshot generation.
     */
    func generateSnapshot(track: Track,
                          size: CGSize
    ) async throws -> UIImage? {
//        if let cachedImage = await cache?.getSnippet(for: track, size: size) {
//            return cachedImage
//        }
        //  Configure snapshot options
        let options = MKMapSnapshotter.Options()
        let region = track.points.regionOfATrack()
        options.region = region
        options.size = size
        options.mapType = .standard
        options.traitCollection = .init(userInterfaceStyle: .dark)
        guard !Task.isCancelled else { return nil }
        //  Create snapshotter
        let snapshotter = MKMapSnapshotter(options: options)
        let snapshot = try await snapshotter.start()
        guard !Task.isCancelled else { return nil }
        let normalizedPoints = track.points.map { point in
            NormalizedTrackPoint(position: snapshot.point(for: point.position),
                                 speed: point.speed,
                                 date: point.date)
        }
        let fastestPoint: NormalizedTrackPoint?
        if let fastestTrackPoint = track.points.topSpeedPoint() {
            fastestPoint = NormalizedTrackPoint(position: snapshot.point(for: fastestTrackPoint.position),
                                                    speed: fastestTrackPoint.speed,
                                                    date: fastestTrackPoint.date)
        } else {
            fastestPoint = nil
        }
        let paths = makeColoredPaths(from: normalizedPoints)
        guard !Task.isCancelled else { return nil }
        let finalImage = drawColoredPaths(on: snapshot.image,
                                          segments: paths,
                                          lineWidth: 3,
                                          startPoint: normalizedPoints.first?.position,
                                          stopPoint: normalizedPoints.last?.position,
                                          fastestPoint: fastestPoint?.position)
        return finalImage
    }

    // MARK: - Helpers
    
    /**
     Represents a single segment of a path with an associated color for rendering.

     Used to draw segments of the track path with colors representing speed buckets.
     */
    struct ColoredPathSegment {
        let path: UIBezierPath
        let color: UIColor
    }
    
    /**
     Draws multiple colored path segments and markers on top of a base image.

     - Parameters:
       - baseImage: The UIImage to draw upon.
       - segments: An array of `ColoredPathSegment` representing the track segments to draw.
       - lineWidth: The width of the path stroke.
       - startPoint: Optional point to mark the start of the track.
       - stopPoint: Optional point to mark the end of the track.
       - fastestPoint: Optional point to mark the fastest location with an emoji.

     - Returns: A new UIImage combining the base image and the drawn paths and markers.
     */
    func drawColoredPaths(
        on baseImage: UIImage,
        segments: [ColoredPathSegment],
        lineWidth: CGFloat,
        startPoint: CGPoint?,
        stopPoint: CGPoint?,
        fastestPoint: CGPoint?
    ) -> UIImage {

        let format = UIGraphicsImageRendererFormat()
        format.scale = baseImage.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(
            size: baseImage.size,
            format: format
        )

        return renderer.image { context in
            let cg = context.cgContext

            // Draw base image
            baseImage.draw(
                in: CGRect(origin: .zero, size: baseImage.size)
            )

            // ---- Draw path segments ----
            cg.setLineWidth(lineWidth)
            cg.setLineCap(.round)
            cg.setLineJoin(.round)
            cg.setBlendMode(.normal)

            for segment in segments {
                cg.addPath(segment.path.cgPath)
                cg.setStrokeColor(segment.color.cgColor)
                cg.strokePath()
            }

            // ---- Draw markers ----
            if let startPoint {
                drawMarker(
                    at: startPoint,
                    title: "Start",
                    in: context
                )
            }

            if let stopPoint {
                drawMarker(
                    at: stopPoint,
                    title: "Stop",
                    in: context
                )
            }
            
            // ---- Draw fastest point fire emoji ----
            if let fastest = fastestPoint {
                let emoji = "🔥" as NSString
                let font = UIFont.systemFont(ofSize: 14)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font
                ]
                // Center the emoji over the point
                let size = emoji.size(withAttributes: attrs)
                let drawPoint = CGPoint(x: fastest.x - size.width/2, y: fastest.y - size.height/2)
                emoji.draw(at: drawPoint, withAttributes: attrs)
            }
        }
    }
    private func drawMarker(
        at point: CGPoint,
        title: String,
        in context: UIGraphicsImageRendererContext
    ) {

        let pinSize: CGFloat = 22
        let textOffset: CGFloat = 4
        let strokeWidth: CGFloat = 8

        let fillColor = UIColor.white
        let strokeColor = UIColor.black

        // ---- Draw SF Symbol pin ----
        let config = UIImage.SymbolConfiguration(paletteColors: [UIColor.black, UIColor.systemMint])
        let sizeConfig = UIImage.SymbolConfiguration(pointSize: pinSize, weight: .bold)
        config.applying(sizeConfig)
        if let pinImage = UIImage( systemName: "mappin.circle.fill",
                                   withConfiguration: config ){
            let pinOrigin = CGPoint( x: point.x - pinSize / 2, y: point.y - pinSize )
            pinImage.draw(in: CGRect(origin: pinOrigin, size: CGSize(width: pinSize, height: pinSize)) )
        }

        let font = UIFont.systemFont(ofSize: 15, weight: .bold)

        // ---- Stroke pass ----
        let strokeAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.clear,
            .strokeColor: strokeColor,
            .strokeWidth: strokeWidth   // POSITIVE = stroke only
        ]

        // ---- Fill pass ----
        let fillAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: fillColor
        ]

        let textSize = title.size(withAttributes: fillAttributes)

        let textPoint = CGPoint(
            x: point.x - textSize.width / 2,
            y: point.y + textOffset
        )

        // Draw stroke first
        title.draw(at: textPoint, withAttributes: strokeAttributes)

        // Draw fill on top
        title.draw(at: textPoint, withAttributes: fillAttributes)
    }


    /**
     Converts an array of normalized track points into an array of colored path segments.

     Each segment represents a line between two consecutive points colored according to the speed bucket of the starting point.

     - Parameter points: The array of normalized track points.

     - Returns: An array of `ColoredPathSegment` ready for rendering.
     */
    func makeColoredPaths(from points: [NormalizedTrackPoint]) -> [ColoredPathSegment] {
        guard points.count >= 2 else { return [] }

        var result: [ColoredPathSegment] = []

        for i in 0..<(points.count - 1) {
            let start = points[i]
            let end = points[i + 1]

            let bucket = SpeedBucket(for: start.speed)

            let path = UIBezierPath()
            path.move(to: start.position)
            path.addLine(to: end.position)

            result.append(
                ColoredPathSegment(
                    path: path,
                    color: bucket.color()
                )
            )
        }

        return result
    }

}

import SwiftUI

#Preview {
    MapSnippetView(mapSnippetCache: DependencyManager.MockTrackMapSnippetCache(),
                   mapSnapshotGenerator: MapSnapshotGenerator(),
                   track: .filledTrack)
    .frame(height: 250)
}

