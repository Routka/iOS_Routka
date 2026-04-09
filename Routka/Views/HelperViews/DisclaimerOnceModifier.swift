//
//  DisclaimerOnceModifier.swift
//  Routka
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
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms tick
            }
        }
    }
    
    private var bottomMaskColors: [Color] {
        Array(repeating: Color.black, count: 8) +
        Array(repeating: Color.clear, count: 2)
    }
    private var topMaskColors: [Color] {
        Array(repeating: Color.black, count: 19) +
        Array(repeating: Color.clear, count: 1)
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
                        VStack {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                    .background(
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundStyle(.white)
                                    )
                                Text("Safety Warning")
                                    .foregroundStyle(Color.white)
                                    .shadow(radius: 5)
                                    .multilineTextAlignment(.center)
                            }
                            .font(.title)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .glassEffect(.regular
                                .tint(Color.black.opacity(0.8)),
                                         in: RoundedRectangle(cornerRadius: 26))
                            VStack {
                                ScrollView {
                                    Text("disclaimer_body")
                                        .multilineTextAlignment(.center)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.white)
                                }
                                .scrollIndicators(.hidden)
                                .scrollBounceBehavior(.basedOnSize)
                                .contentMargins(.bottom, 100, for: .scrollContent)
                                .contentMargins(.top, 25, for: .scrollContent)
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(colors: bottomMaskColors),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(colors: topMaskColors),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .overlay(alignment: .bottom) {
                                    understoodButton
                                }
                            }
                            .padding([.horizontal, .bottom])
                            .glassEffect(.regular
                                .tint(Color.black.opacity(0.8)),
                                         in: RoundedRectangle(cornerRadius: 26))
                        }
                        
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
                    .foregroundStyle(Color.white)
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
            .glassEffect(.regular
                .interactive()
                .tint(isButtonEnabled ?
                      Color.green.opacity(0.5) :
                        Color.gray.opacity(0.3)
                     ),
                         in: Capsule())
                
        }
        .disabled(!isButtonEnabled)
        .opacity(isButtonEnabled ? 1 : 0.6)
        .accessibilityIdentifier("DismissDisclaimerButton")
        
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

import MapKit
#Preview {
    Map()
        .ignoresSafeArea()
        .disclaimerOnce(disclaimerShown: false)
}

