//
//  LocationAccessControlView.swift
//  Routka
//
//  Created by vladukha on 25.02.2026.
//

import SwiftUI
import UIKit

struct LocationAccessControlView: View {
    var vm: any LocationAccessViewModelProtocol
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    init(vm: any LocationAccessViewModelProtocol) {
        self.vm = vm
    }
    
    var body: some View {
        VStack {
            switch vm.locationAccess {
            case .authorizedWhenInUse, .authorizedAlways:
                EmptyView()
            case .notDetermined:
                notDeterminedAccess
            case .restricted, .denied:
                restrictedAccess
            @unknown default:
                EmptyView()
            }
        }
        .animation(.bouncy, value: vm.locationAccess)
    }
    
    private func title(_ text: String) -> some View {
        Text(LocalizedStringKey(text),
             tableName: "LocationAccess")
        .font(.headline)
        .multilineTextAlignment(.leading)
    }
    
    private func button(_ text: String,
                        icon: String,
                        action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(LocalizedStringKey(text),
                     tableName: "LocationAccess")
                .bold()
                .underline()
                .font(.title3)
            }
        }
        .buttonStyle(.glassProminent)
        .accessibilityIdentifier("ProvideLocationButton")
    }
    
    private var restrictedAccess: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.slash")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .tertiary)
                    .font(.title)
                title("Location access was denied. To enable access, open Settings.")
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            button("Open App Settings",
                   icon: "gear",
                   action: openAppSettings)
        }
    }
    
    private var notDeterminedAccess: some View {
        VStack {
            HStack {
                Image(systemName: "location.viewfinder")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.secondary, .orange)
                    .font(.title)
                title("We are not receiving your location right now")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            button("Provide location",
                   icon: "location.viewfinder",
                   action: vm.requestLocation)
        }
    }
    
    
}

import Combine
import CoreLocation
fileprivate final class PreviewModel: LocationAccessViewModelProtocol {
    var locationAccess: CLAuthorizationStatus = .notDetermined
    
    func requestLocation() {
        
    }
    init(locationAccess: CLAuthorizationStatus) {
        self.locationAccess = locationAccess
    }
    
}

import MapKit
#Preview {
    ZStack(alignment: .bottom) {
        Map()
        VStack {
            LocationAccessControlView(vm: PreviewModel(locationAccess: .authorizedWhenInUse))
            Divider()
            LocationAccessControlView(vm: PreviewModel(locationAccess: .authorizedAlways))
            Divider()
            LocationAccessControlView(vm: PreviewModel(locationAccess: .notDetermined))
            Divider()
            LocationAccessControlView(vm: PreviewModel(locationAccess: .restricted))
            Divider()
            LocationAccessControlView(vm: PreviewModel(locationAccess: .denied))
        }
    }
    
}
