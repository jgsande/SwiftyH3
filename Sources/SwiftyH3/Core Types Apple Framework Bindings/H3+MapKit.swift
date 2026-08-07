
#if canImport(MapKit)

import MapKit

public extension MKPolygon {
    convenience init(_ loop: H3Loop) {
        var coordinateLoop = loop.map { h3latlng in h3latlng.coordinates }
        self.init(coordinates: &coordinateLoop, count: loop.count)
    }
}

public extension MKPolygon {
    convenience init(_ polygon: H3Polygon) {
        var boundaryCoordinateLoop = polygon.boundary.map { h3latlng in h3latlng.coordinates }
        let holePolygons = !polygon.holes.isEmpty ? polygon.holes.map { hole in MKPolygon(hole) } : nil

        self.init(coordinates: &boundaryCoordinateLoop, count: boundaryCoordinateLoop.count, interiorPolygons: holePolygons)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
public extension MKMultiPolygon {
    convenience init(from multipolygon: H3MultiPolygon) {
        let mkpolygons = multipolygon.map { polygon in MKPolygon(polygon) }
        self.init(mkpolygons)
    }
}

public extension H3Loop {
    init?(from multipoint: MKMultiPoint) {
        var coordLoop: [CLLocationCoordinate2D] = .init(
            repeating: .init(),
            count: multipoint.pointCount
        )

        let gotCoordinates = coordLoop.withUnsafeMutableBufferPointer { pointer in
            if let baseAddress = pointer.baseAddress {
                multipoint.getCoordinates(
                    baseAddress,
                    range: NSRange(location: 0, length: multipoint.pointCount)
                )

                return true
            } else { return false }
        }

        if gotCoordinates {
            self = coordLoop.map { $0.h3LatLng } 
        } else {
            return nil
        }
    }
}

public extension H3Polygon {
    init(from polygon: MKPolygon) {
        self.boundary = H3Loop(from: polygon) ?? []
        
        if let interiorPolygons = polygon.interiorPolygons {
            self.holes = interiorPolygons.map { H3Loop(from: $0) ?? [] }
        } else {
            self.holes = []
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
public extension H3MultiPolygon {
    init(from multipolygon: MKMultiPolygon) {
        self = multipolygon.polygons.map { H3Polygon(from: $0) }
    }
}

#endif
