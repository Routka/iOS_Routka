//
//  MapRendererDecoder.swift
//  DuckRunner
//
//  Created by vladukha on 20.02.2026.
//

import Foundation
import MapKit

extension MKOverlay {
    /// Returns correct Renderer for this concrete overlay
    public func renderer() -> MKOverlayRenderer {
        if self is SpeedTrackOverlay {
            return SpeedTrackRenderer(overlay: self)
        }
        if self is ReplayTrackOverlay {
            return ReplayTrackRenderer(overlay: self)
        }
        if self is FantomTrackOverlay {
            return FantomTrackRenderer(overlay: self)
        }
        return MKOverlayRenderer(overlay: self)
    }
}
