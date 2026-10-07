import Foundation

public extension H3LatLng {
    var latitude: Measurement<UnitAngle> { Measurement(value: latitudeRads, unit: .radians) }
    var longitude: Measurement<UnitAngle> { Measurement(value: longitudeRads, unit: .radians) }

    /// Latitude in degrees.
    var latitudeDegs: Double { Self.degrees(fromRadians: latitudeRads) }

    /// Longitude in degrees.
    var longitudeDegs: Double { Self.degrees(fromRadians: longitudeRads) }
}

public extension H3LatLng {
    init(latitudeDegs: Double, longitudeDegs: Double) {
        self.init(latitudeRads: Self.radians(fromDegrees: latitudeDegs),
                  longitudeRads: Self.radians(fromDegrees: longitudeDegs))
    }
}

extension H3LatLng {
    /// Degrees in one radian: the coefficient of Foundation's `UnitAngle.radians`, whose base unit is the degree.
    static let degreesPerRadian = 180 / Double.pi

    /// Foundation's `Measurement<UnitAngle>` arithmetic without its Objective-C unit objects, so the bits are
    /// Foundation's and the cost is a division. A conversion goes into the base unit as `value × coefficient + 0`
    /// and out of it as `(base − 0) ÷ coefficient`; the `+ 0.0` turns −0 into +0, as Foundation does.
    @inline(__always)
    static func radians(fromDegrees degrees: Double) -> Double {
        (degrees + 0.0) / degreesPerRadian
    }

    /// Foundation's `Measurement<UnitAngle>` arithmetic for radians to degrees. See ``radians(fromDegrees:)``.
    @inline(__always)
    static func degrees(fromRadians radians: Double) -> Double {
        radians * degreesPerRadian + 0.0
    }
}
