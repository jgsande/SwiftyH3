import Foundation
import Testing

@testable import SwiftyH3

/// `H3LatLng`'s degree conversions: the same bits as Foundation's `Measurement<UnitAngle>`, at the cost of plain
/// arithmetic.
///
/// The bits matter because a cell is computed from the radians: a conversion that differed in the last bit could
/// move a point that sits on a cell edge into the neighboring cell. The cost matters because every coordinate a
/// caller turns into a cell goes through this conversion.
struct DegreeConversionTests {

    /// Degrees to radians gives exactly the radians Foundation's `Measurement` gives, signed zero and
    /// non-finite values included.
    @Test func degreesToRadiansMatchFoundationBitForBit() {
        for degrees in Self.samples {
            let point = H3LatLng(latitudeDegs: degrees, longitudeDegs: -degrees)
            let latitude = Measurement<UnitAngle>(value: degrees, unit: .degrees).converted(to: .radians).value
            let longitude = Measurement<UnitAngle>(value: -degrees, unit: .degrees).converted(to: .radians).value
            #expect(Self.same(point.latitudeRads, latitude), "latitude \(degrees)°")
            #expect(Self.same(point.longitudeRads, longitude), "longitude \(-degrees)°")
        }
    }

    /// Radians to degrees gives exactly the degrees Foundation's `Measurement` gives, signed zero and
    /// non-finite values included.
    @Test func radiansToDegreesMatchFoundationBitForBit() {
        for degrees in Self.samples {
            let radians = degrees / 57.0
            let point = H3LatLng(latitudeRads: radians, longitudeRads: -radians)
            let latitude = Measurement<UnitAngle>(value: radians, unit: .radians).converted(to: .degrees).value
            let longitude = Measurement<UnitAngle>(value: -radians, unit: .radians).converted(to: .degrees).value
            #expect(Self.same(point.latitudeDegs, latitude), "latitude \(radians) rad")
            #expect(Self.same(point.longitudeDegs, longitude), "longitude \(-radians) rad")
        }
    }

    /// A point built from degrees costs plain arithmetic. Foundation's `Measurement` costs hundreds of
    /// nanoseconds per conversion and takes a lock that every thread shares.
    @Test func degreesToRadiansCostPlainArithmetic() {
        let count = 1_000_000
        var sink = 0.0
        var i = 0
        let start = ContinuousClock.now
        while i < count {
            let point = H3LatLng(latitudeDegs: Double(i % 180) - 89.5, longitudeDegs: Double(i % 360) - 179.75)
            sink += point.latitudeRads + point.longitudeRads
            i += 1
        }
        let perPoint = Self.nanoseconds(ContinuousClock.now - start) / Double(count)
        #expect(sink.isFinite)
        #expect(perPoint < Self.budgetNanoseconds, "\(perPoint) ns per point built from degrees")
    }

    /// Reading a point's degrees costs plain arithmetic.
    @Test func radiansToDegreesCostPlainArithmetic() {
        let count = 1_000_000
        var sink = 0.0
        var i = 0
        let start = ContinuousClock.now
        while i < count {
            let point = H3LatLng(latitudeRads: Double(i % 3) - 1.5, longitudeRads: Double(i % 6) - 3.0)
            sink += point.latitudeDegs + point.longitudeDegs
            i += 1
        }
        let perPoint = Self.nanoseconds(ContinuousClock.now - start) / Double(count)
        #expect(sink.isFinite)
        #expect(perPoint < Self.budgetNanoseconds, "\(perPoint) ns per point read in degrees")
    }

    // MARK: - Helpers

    /// Two conversions per point. Plain arithmetic stays well under it even unoptimized; `Measurement` is
    /// several times over it.
    static let budgetNanoseconds = 100.0

    /// Edge values, then a deterministic sweep across every latitude and longitude.
    static let samples: [Double] = {
        var values: [Double] = [0, -0.0, 90, -90, 180, -180, 360, 1e-320, -1e-320, .leastNormalMagnitude,
                                .greatestFiniteMagnitude, -.greatestFiniteMagnitude, .infinity, -.infinity, .nan,
                                45.123456789, -0.0000001]
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        for _ in 0..<20_000 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            values.append(Double(state >> 11) / Double(1 << 53) * 360 - 180)
        }
        return values
    }()

    static func same(_ a: Double, _ b: Double) -> Bool {
        a.bitPattern == b.bitPattern || (a.isNaN && b.isNaN)
    }

    static func nanoseconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) * 1e9 + Double(duration.components.attoseconds) / 1e9
    }
}
