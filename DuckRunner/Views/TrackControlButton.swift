//
//  TrackControlButton.swift
//  DuckRunner
//
//  Created by vladukha on 16.02.2026.
//

import SwiftUI
import CoreLocation
import Combine

/// A SwiftUI view representing a control button to start or stop a tracking session.
/// 
/// This button dynamically switches between a "Start" and "Stop" state depending on the current tracking status.
/// The generic `ViewModel` type must conform to `TrackControllerProtocol`, providing the current track state and control methods.
/// 
/// The button uses animation and custom transitions to smoothly switch between states, enhancing user experience.
/// 
/// - Note: The view observes the `ViewModel` to reactively update the UI when tracking state changes.
struct TrackControlButton<ViewModel: TrackControllerProtocol>: View {
    /// The observed view model providing the current track state and control methods.
    /// 
    /// This property is marked with `@ObservedObject` to automatically update the UI when `currentTrack` changes.
    private var vm: ViewModel
    
    /// Initializes the TrackControlButton with a given view model.
    ///
    /// - Parameter vm: The view model conforming to `TrackControllerProtocol` which controls tracking.
    init(vm: ViewModel) {
        self.vm = vm
    }
    
    /// The main body of the view, conditionally displaying a start or stop button.
    ///
    /// - Shows the `stopBigButton` if there is an ongoing track (`currentTrack` exists and `stopDate` is nil).
    /// - Otherwise, shows the `startBigButton`.
    /// 
    /// Both buttons animate using a custom asymmetric transition:
    /// - Insertion: move from bottom combined with opacity and scale from 0.1 near the bottom.
    /// - Removal: move to bottom combined with opacity and scale down similarly.
    ///
    /// The `.animation(.bouncy, value:)` modifier animates changes based on the `stopDate` of the current track.
    var body: some View {
        Group {
            // If there is a current active track without stopDate, show Stop button
            if vm.isReplayingTrack() {
                stopBigButton
                    .transition(.asymmetric(insertion: .move(edge: .bottom)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.1, anchor: .bottom)),
                                            removal: .move(edge: .bottom)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.1, anchor: .bottom))))
            } else {
                // Otherwise, show Start button
                startBigButton
                    .transition(.asymmetric(insertion: .move(edge: .bottom)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.1, anchor: .bottom)),
                                            removal: .move(edge: .bottom)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.1, anchor: .bottom))))
            }
        }
        // Animate changes when the stopDate of the current track changes using a bouncy animation
        .animation(.bouncy, value: vm.isReplayingTrack())
    }
    
    
    /// A styled button to start a tracking session.
    ///
    /// - On tap, triggers `vm.startTrack()`.
    /// - Displays the label "Start" with a title font, bold weight, and semi-transparent primary color.
    /// - Uses a custom `glassEffect` modifier with a green tint and interactive appearance inside a capsule shape.
    /// - Assigned an explicit id `"startbutton"` for SwiftUI identity during transitions.
    private var startBigButton: some View {
        Button {
            self.vm.startTrack()
        } label: {
            Text("Start")
                .font(.title)
                .bold()
                .foregroundStyle(Color.primary)
                .padding(8)
                .frame(maxWidth: .infinity)
        }
        .glassEffect(.regular.tint(.green.opacity(0.5)).interactive(), in: Capsule())
        .id("startbutton")
    }
    
    /// A styled button to stop the current tracking session.
    ///
    /// - On tap, tries to call `vm.stopTrack()`. Errors are ignored.
    /// - Displays the label "Stop" with a title font, bold weight, and semi-transparent primary color.
    /// - Uses a custom `glassEffect` modifier with a red tint and interactive appearance inside a capsule shape.
    /// - Assigned an explicit id `"stopbutton"` for SwiftUI identity during transitions.
    private var stopBigButton: some View {
        Button {
            Task {
                try? await self.vm.stopTrack()
            }
        } label: {
            Text("Stop")
                .font(.title)
                .bold()
                .foregroundStyle(Color.primary)
                .padding(8)
                .frame(maxWidth: .infinity)
        }
        .glassEffect(.regular.tint(.red.opacity(0.5)).interactive(), in: Capsule())
        .id("stopbutton")
    }
}

/// A private, final class used exclusively for SwiftUI previews of `TrackControlButton`.
@Observable
final private class PreviewModel: TrackControllerProtocol {
    func isReplayingTrack() -> Bool {
        return true
    }
    
    
    func startTrack() {
    }
    
    func stopTrack() {
    }
    
}

#Preview {
    TrackControlButton(vm: PreviewModel())
}
