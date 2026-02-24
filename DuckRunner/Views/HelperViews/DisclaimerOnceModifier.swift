//
//  DisclaimerOnceModifier.swift
//  DuckRunner
//
//  Created by vladukha on 24.02.2026.
//
import SwiftUI

/// A view modifier that presents a one-time disclaimer overlay on top of the content.
///
/// The disclaimer appears the first time the view is shown (based on the `disclaimerShown`
/// value stored in `UserDefaults` via `@AppStorage`). The "Understood" button is disabled
/// for 5 seconds with a linear progress indicator before the user can dismiss the overlay.
/// Once dismissed, the modifier saves the flag so the disclaimer won't be shown again.
struct DisclaimerOnceModifier: ViewModifier {
    /// Persists whether the disclaimer has already been shown to the user.
    @AppStorage("disclaimerShown") private var disclaimerShown: Bool = false
    /// Controls whether the overlay is currently visible.
    @State private var isPresenting: Bool = false
    /// Countdown progress (0...1) that drives the progress view and button enabling.
    @State private var countdownProgress: Double = 0 // 0..1
    /// Becomes true after the countdown finishes, enabling the "Understood" button.
    @State private var isButtonEnabled: Bool = false
    
    /// Optional initializer that allows overriding the stored `disclaimerShown` value.
    /// - Parameter disclaimerShown: When provided, sets the initial persisted value for previews or testing.
    init(disclaimerShown: Bool? = nil) {
        if let disclaimerShown {
            self.disclaimerShown = disclaimerShown
        }
    }
    
    /// Starts a 5-second countdown that updates `countdownProgress` and enables the button when complete.
    func startTimer() {
        Task {
            let total: Double = 5.0
            let start = Date()
            while countdownProgress < 1 {
                let elapsed = Date().timeIntervalSince(start)
                let progress = min(elapsed / total, 1)
                await MainActor.run {
                    withAnimation {
                        countdownProgress = progress
                        if progress >= 1 { isButtonEnabled = true }
                    }
                }
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms tick
            }
        }
    }

    /// Applies the disclaimer overlay logic to the modified content.
    func body(content: Content) -> some View {
        content
            .disabled(isPresenting)
            .onAppear {
                if !disclaimerShown {
                    isPresenting = true
                    countdownProgress = 0
                    isButtonEnabled = false
                    startTimer()
                }
            }
            .overlay(alignment: .center) {
                if isPresenting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        VStack(spacing: 30) {
                            Text("Disclaimer")
                                .font(.largeTitle)
                                .bold()
                                .opacity(0.8)
                            ScrollView {
                                Text("""
                                     Safety Warning
                                     
                                     By accessing or using this application, you represent, acknowledge, and agree that you are solely responsible for operating your vehicle safely and in full compliance with all applicable traffic laws and regulations.

                                     Do not use your mobile device while the vehicle is in motion.
                                     Always obey posted speed limits.
                                     Avoid aggressive or reckless maneuvers.

                                     Failure to comply with traffic laws may result in serious injury, death, or legal consequences.

                                     If you wish to engage in high-speed or competitive driving, please do so only at authorized racing facilities.
                                     """)
                                    .multilineTextAlignment(.center)
                                    .font(.body)
                                    .padding(.horizontal)
                            }
                            .scrollIndicators(.hidden)
                            .scrollBounceBehavior(.basedOnSize)
                            understoodButton
                        }
                        .padding()
                        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                        .padding()
                    }
                    .transition(.opacity)
                }
            }
            .animation(.bouncy, value: isPresenting)
            .animation(.bouncy, value: isButtonEnabled)
    }
    
    /// The confirmation button that dismisses the disclaimer once enabled.
    private var understoodButton: some View {
        Button {
            disclaimerShown = true
            withAnimation {
                isPresenting = false
            }
        } label: {
            VStack(spacing: 1) {
                Text("Understood")
                    .foregroundStyle(Color.primary)
                    .font(.title)
                    .frame(maxWidth: .infinity)
                if !isButtonEnabled {
                    ProgressView(value: countdownProgress)
                        .progressViewStyle(.linear)
                        .tint(.gray)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
            }
            .padding()
            .glassEffect(.regular.tint(isButtonEnabled ?
                                       Color.green.opacity(0.3) :
                                        Color.gray.opacity(0.3)
            ),
                         in: Capsule())
                
        }
        .disabled(!isButtonEnabled)
        .opacity(isButtonEnabled ? 1 : 0.6)
        
    }
}

/// Convenience API for applying the disclaimer overlay to any view.
extension View {
    /// Presents a one-time disclaimer overlay on the receiving view.
    /// - Parameter disclaimerShown: Optional override for previews/testing to force show/hide.
    /// - Returns: A view that conditionally overlays a disclaimer until acknowledged.
    func disclaimerOnce(disclaimerShown: Bool? = nil) -> some View {
        self.modifier(DisclaimerOnceModifier(disclaimerShown: disclaimerShown))
    }
}


#Preview {
    Color.blue
        .disclaimerOnce(disclaimerShown: false)
}

