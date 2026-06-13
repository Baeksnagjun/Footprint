//
//  CampusGeofence.swift
//  Footprint
//

import CoreLocation
import MapKit

enum CampusGeofence {
    static func isOnCampus(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let center = CLLocation(
            latitude: FootprintConfig.campusCenter.latitude,
            longitude: FootprintConfig.campusCenter.longitude
        )
        let point = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return center.distance(from: point) <= FootprintConfig.campusRadiusMeters
    }
}
