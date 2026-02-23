//
//  TrackTrimSlider.swift
//  DuckRunner
//
//  Created by vladukha on 23.02.2026.
//

// TrackTrimSlider.swift
// A SwiftUI view for trimming an array of TrackPoint with two draggable handles.
import SwiftUI
import MapKit

struct TrackTrimSlider: View {
    let points: [TrackPoint]
    @Binding var start: TrackPoint
    @Binding var stop: TrackPoint
    
    @GestureState private var dragOffset: CGSize = .zero
    
    @State private var startIndex: Int = 0
    @State private var stopIndex: Int = 0
    
    private var indices: Range<Int> {
        0..<points.count
    }
    
    public init(points: [TrackPoint], start: Binding<TrackPoint>, stop: Binding<TrackPoint>) {
        self.points = points
        self._start = start
        self._stop = stop
        // Default initial indices
        _startIndex = State(initialValue: points.firstIndex(where: { $0.date == start.wrappedValue.date }) ?? 0)
        _stopIndex = State(initialValue: points.firstIndex(where: { $0.date == stop.wrappedValue.date }) ?? (points.count > 0 ? points.count - 1 : 0))
    }
    
    private let lineHeight: CGFloat = 9
    private let handlesWidth: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        drawSpeedColoredTrimLine(lineHeight)
                    }
                    .frame(height: lineHeight)
                
                
                // Start Handle
                VStack(spacing: -1) {
                    Circle()
                        .fill(Color.blue.opacity(0.7))
//                        .overlay(Circle().stroke(Color.green, lineWidth: 3))
                    Capsule()
                        .fill(Color.gray)
                        .frame(width: 5)
                    
                }
                    .frame(width: handlesWidth)
                    .offset(x: handleX(for: startIndex, totalWidth: geo.size.width) - handlesWidth/2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let idx = index(for: value.location.x, totalWidth: geo.size.width)
                                if idx >= 0 && idx <= stopIndex {
                                    withAnimation(.bouncy(duration: 0.1)) {
                                        startIndex = idx
                                        self.start = points[startIndex]
                                    }
                                }
                            }
                    )
                    .accessibilityLabel("Trim Start")
                
                // Stop Handle
                VStack(spacing: -1) {
                    Circle()
                        .fill(Color.red.opacity(0.7))
//                        .overlay(Circle().stroke(Color.green, lineWidth: 3))
                    Capsule()
                        .fill(Color.gray)
                        .frame(width: 5)
                    
                }
                    .frame(width: handlesWidth)
                    .offset(x: handleX(for: stopIndex, totalWidth: geo.size.width) - handlesWidth/2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let idx = index(for: value.location.x, totalWidth: geo.size.width)
                                if idx <= points.count - 1 && idx >= startIndex {
                                    withAnimation(.bouncy(duration: 0.2)) {
                                        stopIndex = idx
                                        self.stop = points[stopIndex]
                                    }
                                }
                            }
                    )
                    .accessibilityLabel("Trim Stop")
            }
            
            
        }
        .frame(height: 50)
        .padding(.horizontal, handlesWidth)
        .onAppear {
            // Sync indices with passed-in points
            if let startIdx = points.firstIndex(where: { $0.date == start.date }) { startIndex = startIdx }
            if let stopIdx = points.firstIndex(where: { $0.date == stop.date }) { stopIndex = stopIdx }
        }
    }
    
    private func handleX(for idx: Int, totalWidth: CGFloat) -> CGFloat {
        guard points.count > 1 else { return 0 }
        return CGFloat(idx) / CGFloat(points.count - 1) * totalWidth
    }
    private func trimWidth(for totalWidth: CGFloat) -> CGFloat {
        guard stopIndex > startIndex else { return 0 }
        return (CGFloat(stopIndex - startIndex) / CGFloat(points.count - 1)) * totalWidth
    }
    private func index(for x: CGFloat, totalWidth: CGFloat) -> Int {
        guard points.count > 1 else { return 0 }
        let percent = min(max(x / totalWidth, 0), 1)
        return Int(round(percent * CGFloat(points.count - 1)))
    }
    
    @ViewBuilder
    private func drawSpeedColoredTrimLine(_ lineHeight: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack {
                ForEach(startIndex..<stopIndex, id: \.self) { idx in
                    // Guard to safely get segment speed
                    if idx + 1 < points.count {
                        let x1 = handleX(for: idx, totalWidth: geo.size.width)
                        let x2 = handleX(for: idx + 1, totalWidth: geo.size.width)
                        let midY = geo.size.height / 2
                        let segmentSpeed = points[idx].speed
                        let segmentColor = SpeedBucket(for: segmentSpeed).color()
                        
                        Path { path in
                            path.move(to: CGPoint(x: x1, y: midY))
                            path.addLine(to: CGPoint(x: x2, y: midY))
                        }
                        .stroke(Color(segmentColor), lineWidth: lineHeight)
                    }
                }
            }
        }
//        if points.count < 2 || stopIndex <= startIndex {
//            // Nothing to draw
//            EmptyView()
//        } else {
//
//        }
    }
}

#Preview {
    @Previewable @State var start = Track.filledTrack.points.first!
    @Previewable @State var stop = Track.filledTrack.points.last!
    return TrackTrimSlider(points: Track.filledTrack.points, start: $start, stop: $stop)
}

