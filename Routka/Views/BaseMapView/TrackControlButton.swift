//
//  TrackControlButton.swift
//  Routka
//
//  Created by vladukha on 16.02.2026.
//

import SwiftUI
import CoreLocation
import Combine

/// A capsule-styled control used to start or stop track recording.
///
/// Configure the button with a ``ButtonType`` to control its label, tint, and
/// transition direction, and provide an action to run when the user taps it.
struct TrackControlButton: View {
    let buttonType: ButtonType
    let action: () -> Void
    
    init(buttonType: ButtonType,
         action: @escaping () -> Void) {
        self.buttonType = buttonType
        self.action = action
    }
    
    /// Builds the button label and applies the visual treatment for the current
    /// ``buttonType``.
    ///
    /// Changes to `buttonType` animate with a bouncy transition so the control
    /// can smoothly switch between recording states.
    var body: some View {
        Group {
            Button {
                self.action()
            } label: {
                Text(LocalizedStringKey(buttonType.text))
                    .font(.title)
                    .bold()
                    .shadow(radius: 5)
                    .foregroundStyle(Color.white)
                    .padding(8)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .id(buttonType.text)
                    .transition(.asymmetric(insertion: .move(edge: buttonType.insertion)
                        .combined(with: .opacity)
                        .combined(with: .scale),
                                            removal: .move(edge: buttonType.insertion)
                        .combined(with: .opacity)
                        .combined(with: .scale)
                    ))
            }
            .accessibilityIdentifier(buttonType.accessibilityIdentifier)
            .glassEffect(.regular.tint(buttonType.tint)
                .interactive(),
                         in: Capsule())
            .id("TrackControlButton")
        }
        .animation(.bouncy, value: self.buttonType)
    }
    
    
    /// Describes the supported control states and their presentation details.
    enum ButtonType {
        case start
        case stop
        
        var text: String {
            switch self {
            case .start:
                "Start Recording"
            case .stop:
                "Stop Recording"
            }
        }
        
        var image: Image? {
            switch self {
            case .start:
                    nil
            case .stop:
                    .init(systemName: "stop.circle")
            }
        }
        
        var tint: Color {
            switch self {
            case .start:
                    .green
                    .mix(with: .primary, by: 0.1)
                    .opacity(0.6)
            case .stop:
                    .red
                    .mix(with: .primary, by: 0.1)
                    .opacity(0.6)
            }
        }
        
        var insertion: Edge {
            switch self {
            case .start:
                    .bottom
            case .stop:
                    .top
            }
        }
        
        var removal: Edge {
            switch self {
            case .start:
                    .top
            case .stop:
                    .bottom
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .start:
                "startRecordingButton"
            case .stop:
                "stopRecordingButton"
            }
        }
    }
}



#Preview {
    @Previewable @State var buttonType: TrackControlButton.ButtonType = .start
    VStack {
        TrackControlButton(buttonType: .start, action: {})
        TrackControlButton(buttonType: .stop, action: {})
        TrackControlButton(buttonType: buttonType, action: {
            switch buttonType {
            case .start: buttonType = .stop
            case .stop: buttonType = .start
            }
        })
    }
}
