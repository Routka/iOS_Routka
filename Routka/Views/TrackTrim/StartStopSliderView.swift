//
//  StartStopSliderView.swift
//  Routka
//
//  Created by vladukha on 16.03.2026.
//

import SwiftUI

struct StartStopSliderView: View {
    @Binding var startIndex: Int
    @Binding var stopIndex: Int
    let maxIndex: Int

    private let metrics = StartStopSliderMetrics()
    private let style = StartStopSliderStyle()

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width, 0)

            ZStack(alignment: .leading) {
                StartStopSliderTrack(style: style)
                    .frame(height: metrics.trackHeight)
                
                StartStopSliderSelectedRange(
                    startOffset: xOffset(for: sanitizedStartIndex, width: availableWidth),
                    width: selectedRangeWidth(in: availableWidth),
                    style: style
                )
                .frame(height: metrics.trackHeight)

                StartStopSliderHandle(kind: .start, style: style, metrics: metrics)
                    .offset(x: xOffset(for: sanitizedStartIndex, width: availableWidth) - metrics.handleDiameter / 2)
                    .gesture(handleDragGesture(kind: .start, width: availableWidth))
                    .accessibilityLabel("Start point of a track")
                    .accessibilityIdentifier("startTag")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityValue("\(sanitizedStartIndex)")
                    .accessibilityAdjustableAction { direction in
                        adjustHandle(.start, direction: direction)
                    }

                StartStopSliderHandle(kind: .stop, style: style, metrics: metrics)
                    .offset(x: xOffset(for: sanitizedStopIndex, width: availableWidth) - metrics.handleDiameter / 2)
                    .gesture(handleDragGesture(kind: .stop, width: availableWidth))
                    .accessibilityLabel("Stop point of a track")
                    .accessibilityIdentifier("stopTag")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityValue("\(sanitizedStopIndex)")
                    .accessibilityAdjustableAction { direction in
                        adjustHandle(.stop, direction: direction)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: metrics.controlHeight)
        .padding(.horizontal, metrics.handleDiameter / 2)
        // normalize start/stop positions for incase of bad binding inputs
        .onAppear {
            enforceBounds()
        }
        .onChange(of: maxIndex) { _, _ in
            enforceBounds()
        }
        .onChange(of: startIndex) { _, _ in
            let clampedStart = clampedStartIndex(startIndex, stopIndex: stopIndex)
            if clampedStart != startIndex {
                startIndex = clampedStart
            }
        }
        .onChange(of: stopIndex) { _, _ in
            let clampedStop = clampedStopIndex(stopIndex, startIndex: startIndex)
            if clampedStop != stopIndex {
                stopIndex = clampedStop
            }
        }
    }

    private var sanitizedStartIndex: Int {
        clampedStartIndex(startIndex, stopIndex: stopIndex)
    }

    private var sanitizedStopIndex: Int {
        clampedStopIndex(stopIndex, startIndex: startIndex)
    }

    private var effectiveMaxIndex: Int {
        max(maxIndex, 1)
    }

    private func handleDragGesture(kind: StartStopSliderHandleKind, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let proposedIndex = index(for: value.location.x, width: width)

                withAnimation(.easeInOut(duration: 0.1)) {
                    switch kind {
                    case .start:
                        startIndex = clampedStartIndex(proposedIndex, stopIndex: stopIndex)
                    case .stop:
                        stopIndex = clampedStopIndex(proposedIndex, startIndex: startIndex)
                    }
                }
            }
    }

    private func adjustHandle(_ kind: StartStopSliderHandleKind, direction: AccessibilityAdjustmentDirection) {
        let delta: Int

        switch direction {
        case .increment:
            delta = 1
        case .decrement:
            delta = -1
        @unknown default:
            delta = 0
        }

        switch kind {
        case .start:
            startIndex = clampedStartIndex(startIndex + delta, stopIndex: stopIndex)
        case .stop:
            stopIndex = clampedStopIndex(stopIndex + delta, startIndex: startIndex)
        }
    }

    private func enforceBounds() {
        // Clamp both bindings in a stable order so the invariant start < stop always holds.
        let clampedStop = clampedStopIndex(stopIndex, startIndex: startIndex)
        let clampedStart = clampedStartIndex(startIndex, stopIndex: clampedStop)
        startIndex = clampedStart
        stopIndex = clampedStopIndex(clampedStop, startIndex: clampedStart)
    }

    private func clampedStartIndex(_ index: Int, stopIndex: Int) -> Int {
        // Start may touch zero, but it must always stay strictly before stop.
        let upperBound = max(min(stopIndex, effectiveMaxIndex) - 1, 0)
        return min(max(index, 0), upperBound)
    }

    private func clampedStopIndex(_ index: Int, startIndex: Int) -> Int {
        // Stop may reach maxIndex, but it must always stay strictly after start.
        let lowerBound = min(max(startIndex + 1, 1), effectiveMaxIndex)
        return min(max(index, lowerBound), effectiveMaxIndex)
    }

    private func normalizedPosition(for index: Int) -> Double {
        // Convert the integer index space into a 0...1 ratio to avoid large-value pixel math.
        guard effectiveMaxIndex > 0 else { return 0 }
        return Double(index) / Double(effectiveMaxIndex)
    }

    private func xOffset(for index: Int, width: CGFloat) -> CGFloat {
        CGFloat(normalizedPosition(for: index)) * width
    }

    private func selectedRangeWidth(in width: CGFloat) -> CGFloat {
        let distance = normalizedPosition(for: sanitizedStopIndex) - normalizedPosition(for: sanitizedStartIndex)
        return CGFloat(max(distance, 0)) * width
    }

    private func index(for xPosition: CGFloat, width: CGFloat) -> Int {
        // Map a drag location back into the discrete index domain with clamped bounds.
        guard width > 0 else { return 0 }

        let clampedX = min(max(xPosition, 0), width)
        let normalized = Double(clampedX / width)
        let rawIndex = Int((normalized * Double(effectiveMaxIndex)).rounded())
        return min(max(rawIndex, 0), effectiveMaxIndex)
    }
}

private struct StartStopSliderMetrics {
    let controlHeight: CGFloat
    let trackHeight: CGFloat
    let handleDiameter: CGFloat
    let handleStrokeWidth: CGFloat
    init() {
        
        self.trackHeight = 8
        self.handleDiameter = 45
        self.handleStrokeWidth = 3
        self.controlHeight = handleDiameter * 2.5 + handleStrokeWidth // double handle height + a stick + stroke
    }
}

private struct StartStopSliderStyle {
    let trackColor: Color = .gray.opacity(0.2)
    let selectedRangeColor: Color = .accentColor
    let startHandleColor: Color = .mint
    let handleFillColor: Color = .clear
    let stopHandleColor: Color = .red
    let handleShadowColor: Color = .black.opacity(0.14)
    let startHandleIcon: Image = .init(systemName: "play")
    let stopHandleIcon: Image = .init(systemName: "stop")
}

private enum StartStopSliderHandleKind {
    case start
    case stop

    var colorKeyPath: KeyPath<StartStopSliderStyle, Color> {
        switch self {
        case .start:
            return \.startHandleColor
        case .stop:
            return \.stopHandleColor
        }
    }
    
    var iconKeyPath: KeyPath<StartStopSliderStyle, Image> {
        switch self {
        case .start:
            return \.startHandleIcon
        case .stop:
            return \.stopHandleIcon
        }
    }
}

private struct StartStopSliderTrack: View {
    let style: StartStopSliderStyle

    var body: some View {
        Capsule()
            .fill(style.trackColor)
    }
}

private struct StartStopSliderSelectedRange: View {
    let startOffset: CGFloat
    let width: CGFloat
    let style: StartStopSliderStyle

    var body: some View {
        Capsule()
            .fill(style.selectedRangeColor)
            .frame(width: width)
            .offset(x: startOffset)
    }
}

private struct StartStopSliderHandle: View {
    let kind: StartStopSliderHandleKind
    let style: StartStopSliderStyle
    let metrics: StartStopSliderMetrics

    var body: some View {
        
            switch kind {
            case .start:
                VStack(spacing: 0) {
                    line
                    circle
                }
                .offset(y: metrics.handleDiameter/2)
                .shadow(color: style.handleShadowColor, radius: 3, y: 1)
            case .stop:
                VStack(spacing: 0) {
                    circle
                    line
                }
                .offset(y: -metrics.handleDiameter/2)
                .shadow(color: style.handleShadowColor, radius: 3, y: 1)
            }
        
        
    }
    
    private var line: some View {
        Rectangle()
            .fill(style[keyPath: kind.colorKeyPath])
            .frame(width: metrics.handleStrokeWidth, height: metrics.handleDiameter / 2)
    }
    
    private var circle: some View {
        Circle()
            .fill(style.handleFillColor)
            .stroke(style[keyPath: kind.colorKeyPath], lineWidth: metrics.handleStrokeWidth)
            
            .frame(width: metrics.handleDiameter, height: metrics.handleDiameter)
            .contentShape(Rectangle())
            .overlay {
                style[keyPath: kind.iconKeyPath]
                    .foregroundStyle(style[keyPath: kind.colorKeyPath])
            }
    }
}

#Preview {
    @Previewable @State var startIndex = 0
    @Previewable @State var stopIndex = 800_000

    StartStopSliderView(startIndex: $startIndex, stopIndex: $stopIndex, maxIndex: 800_000)
        .border(Color.red)
        .padding()
}
