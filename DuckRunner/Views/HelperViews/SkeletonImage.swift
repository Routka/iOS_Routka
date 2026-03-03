//
//  SkeletonView.swift
//  DuckRunner
//
//  Created by vladukha on 03.03.2026.
//


import SwiftUI

struct SkeletonImage: View {
    @State private var animate1: Double = 0
    @State private var animate2: Double = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let schemeBase = (colorScheme == .dark ? 0 : 0.7)
        let schemeModifier: Double = (colorScheme == .dark ? 1 : 2.2)
        LinearGradient(
            colors: [Color(white: schemeBase + 0.2 - (animate1 * schemeModifier)),
                     Color(white: schemeBase + 0.13 + (animate2 * schemeModifier)),
                     Color(white: schemeBase + 0.15 ),
                     Color(white: schemeBase + 0.23 - (animate1 * schemeModifier)),
                     Color(white: schemeBase + 0.13 + (animate2 * schemeModifier))],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(Animation.easeIn(duration: 2.5).repeatForever(autoreverses: true), value: animate1)
        .animation(Animation.easeIn(duration: 4).delay(0.8).repeatForever(autoreverses: true), value: animate2)

        .onAppear {
            animate1 = 0.1
            animate2 = 0.08
            
        }
    }
}

#Preview {
    SkeletonImage()
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
}
