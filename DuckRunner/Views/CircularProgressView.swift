//
//  CircularProgressView.swift
//  DuckRunner
//
//  Created by vladukha on 05.03.2026.
//

import SwiftUI

struct CircularProgressView: View {
    // 0...1
    let progress: Double
    var trackColor: Color = .gray.opacity(0.25)
    var progressColor: Color = .green

    var body: some View {
        GeometryReader { geo in
            
            let lineWidth = geo.size.width * 0.3
            ZStack {
                
//                /// Background circle
                Circle()
                    .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
                // green base circle to receive shadow
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.progress, 0.5)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(progressColor)
                    .rotationEffect(Angle(degrees: 270.0))
                
                // point with shadow, clipped
                Circle()
                    .trim(from: CGFloat(abs((min(progress, 1.0))-0.001)), to: CGFloat(abs((min(progress, 1.0))-0.0005)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(progressColor)
                    .shadow(color: .black, radius: 10, x: 0, y: 0)
                    .rotationEffect(Angle(degrees: 270.0))
                    .clipShape(
                        Circle().stroke(lineWidth: lineWidth)
                    )
                    .opacity(progress < 1 ? 1 : 0)
                
                // green overlay circle to hide shadow on one side
                Circle()
                    .trim(from: progress > 0.5 ? 0.25 : 0, to: CGFloat(min(self.progress, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(progressColor)
                    .rotationEffect(Angle(degrees: 270.0))
                
                /// Fill Circle on 100%
                Circle()
                    .fill(progressColor)
                // THIS 0.71 SCALE IS CRUCIAL!!!
                // if glass effect is applied - stroke and fill colors mix in this
                // ZStack, which makes overlaps look darker even with the same color
                    .scaleEffect(progress < 1 ? 0 : 1)
                    .animation(.bouncy(duration: 0.25), value: progress)
 
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .bold()
                    .scaleEffect(0.6)
                                .foregroundColor(.white)
                                .symbolEffect(.drawOn, isActive: progress < 1)
                                .opacity(progress < 1 ? 0 : 1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.bouncy(duration: 0.25), value: progress)
        }
        .aspectRatio(1, contentMode: .fit)

    }
}

#Preview {
    @Previewable @State var progress: Double = 0.6
    
    VStack {
        Button("Full") {
            progress = 1
        }
        Slider(value: $progress)
        CircularProgressView(progress: progress)
//            .border(Color.red)
            .frame(width: 80)
    }
}
