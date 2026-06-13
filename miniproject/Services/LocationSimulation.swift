//
//  LocationSimulation.swift
//  Footprint
//

import CoreLocation
import Foundation

enum MapNudgeDirection {
    case north, south, east, west
}

enum LocationSimulation {
    static let defaultStepMeters: CLLocationDistance = 8

    static func offset(
        from coordinate: CLLocationCoordinate2D,
        direction: MapNudgeDirection,
        meters: CLLocationDistance = defaultStepMeters
    ) -> CLLocationCoordinate2D {
        let earthRadius = 6_371_000.0
        let latRad = coordinate.latitude * .pi / 180
        let deltaLat = (meters / earthRadius) * (180 / .pi)
        let deltaLng = (meters / (earthRadius * cos(latRad))) * (180 / .pi)

        switch direction {
        case .north:
            return CLLocationCoordinate2D(latitude: coordinate.latitude + deltaLat, longitude: coordinate.longitude)
        case .south:
            return CLLocationCoordinate2D(latitude: coordinate.latitude - deltaLat, longitude: coordinate.longitude)
        case .east:
            return CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude + deltaLng)
        case .west:
            return CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude - deltaLng)
        }
    }
}
