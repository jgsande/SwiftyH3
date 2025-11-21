
#if canImport(SwiftUI)
#if canImport(MapKit)

import SwiftUI
import MapKit

extension H3Cell: MapContent {
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public var body: some MapContent {
        try? MapPolygon(coordinates: boundary.map { $0.coordinates })
    }
}

extension H3Polygon: MapContent {
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public var body: some MapContent {
        MapPolygon(MKPolygon(self))
    }
}

extension H3DirectedEdge: MapContent {
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public var body: some MapContent {
        try? MapPolyline(coordinates: boundary.map { $0.coordinates })
    }
}

#endif
#endif