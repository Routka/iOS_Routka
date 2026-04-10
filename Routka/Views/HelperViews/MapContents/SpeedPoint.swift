//
//  StopPointView.swift
//  Routka
//
//  Created by vladukha on 10.04.2026.
//


import SwiftUI
import MapKit

//extension MapContents {
//    /// Start point of a track
//    @MapContentBuilder
//    static public func speedPoint(_ trackPoint: TrackPoint) -> some MapContent {
//        
//        Annotation(coordinate: trackPoint.position,
//                   anchor: .bottom) {
//            SpeedPointView(trackPoint)
//        } label: {
//        }
//
//    }
//}

struct SpeedPointView: View {
    @AppStorage("speedunit") var speedUnit: String = "km/h"
    let point: TrackPoint
    init(_ point: TrackPoint) {
        self.point = point
    }
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            let unit = UnitSpeed.byName(speedUnit)
            let speed = SpeedConverter(speed: point.speed).getSpeed(unit)
            // Reserve space for cool layout
            Text(verbatim: "\(speed.description) \(unit.symbol)")
                .opacity(0)
            Triangle()
                .fill(.orange.gradient)
                .frame(width: 15, height: 12)
                .stroke(color: .teal)
            Text(verbatim: "\(speed.description) \(unit.symbol)")
            
        }
        .font(.headline)
        
    }
}

#Preview("Inside View") {
    VStack {
        ForEach([Color.red, .yellow, .teal, .green, .orange, .mint], id: \.hashValue) { color in
            color
                .overlay {
                    SpeedPointView(Track.filledTrack.points.last!)
                }
        }
    }
}
