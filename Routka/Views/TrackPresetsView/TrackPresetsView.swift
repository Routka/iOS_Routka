//
//  TrackPresetsView.swift
//  Routka
//
//  Created by vladukha on 04.03.2026.
//

import SwiftUI

struct TrackPresetsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var vm: any TrackPresetsViewModelProtocol
    
    init(vm: any TrackPresetsViewModelProtocol) {
        self._vm = .init(wrappedValue: vm)
    }
    
    @ViewBuilder
    func button(_ preset: (preset: RecordingAutoStopPolicy, time: TimeInterval?),
                action: @escaping () -> ()) -> some View {
            Button {
                action()
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack {
                    Image(systemName: preset.preset.image)
                        .foregroundStyle(Color.accentColor)
                        .font(.title)
                    Text(preset.preset.name)
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    if let time = preset.time {
                        HStack(spacing: 2) {
                            Text(TimeIntervalFormatter.string(from: time) ?? "")
                                .foregroundStyle(Color.primary)
                                .opacity(0.8)
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(Color.green)
                        }
                        .padding(8)
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.green, lineWidth: 1)
                        }
                    }
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .padding()
                        .foregroundStyle(Color.primary)
                        .glassEffect(.regular.interactive(),
                                     in: Circle())
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 0)
                }
                
                .padding(4)
            }
        
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Choose the measurement to record")
                    .font(.largeTitle)
                    .multilineTextAlignment(.leading)
                    .bold()
                    .fixedSize(horizontal: false, vertical: true)
                Text("measurements_presets_hint")
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .opacity(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(vm.presets, id: \.preset.name) { preset in
                    button(preset) {
                        self.vm.startTrack(preset.preset)
                    }
                    Divider()
                }
                
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.fraction(0.8)])
        .presentationDragIndicator(.visible)
    }
}


@Observable
private final class PreviewModel: TrackPresetsViewModelProtocol {
    func startTrack(_ mode: RecordingAutoStopPolicy) {
        
    }
    
    var presets: [(preset: RecordingAutoStopPolicy, time: TimeInterval?)] = TrackPresetsViewModel.allPresets.map({($0, nil)})
    
    init() {
        presets[2].time = 15
    }

}

#Preview {
    Color.white
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            TrackPresetsView(vm: PreviewModel())
        }
}
