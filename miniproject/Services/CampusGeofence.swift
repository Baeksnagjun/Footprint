//
//  CampusGeofence.swift
//  miniproject
//

import CoreLocation
import MapKit

enum CampusGeofence {
    static func isOnCampus(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let region = FootprintConfig.campusBoundaryRegion
        let halfLat = region.span.latitudeDelta / 2
        let halfLng = region.span.longitudeDelta / 2
        let lat = coordinate.latitude
        let lng = coordinate.longitude
        return lat >= region.center.latitude - halfLat
            && lat <= region.center.latitude + halfLat
            && lng >= region.center.longitude - halfLng
            && lng <= region.center.longitude + halfLng
    }
}
