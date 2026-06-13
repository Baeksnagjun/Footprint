//
//  CampusCircleScreenGeometry.swift
//  Footprint
//

import CoreLocation
import MapKit
import SwiftUI

enum CampusCircleScreenGeometry {
    static func screenMetrics(proxy: MapProxy) -> (center: CGPoint, radius: CGFloat)? {
        let center = FootprintConfig.campusCenter
        let eastEdge = LocationSimulation.offset(
            from: center,
            direction: .east,
            meters: FootprintConfig.campusRadiusMeters
        )
        guard
            let centerPoint = proxy.convert(center, to: .local),
            let eastPoint = proxy.convert(eastEdge, to: .local)
        else {
            return nil
        }

        let radius = hypot(eastPoint.x - centerPoint.x, eastPoint.y - centerPoint.y)
        guard radius > 0 else { return nil }
        return (centerPoint, radius)
    }

    /// 원이 화면을 가득 채우는 반경 (회색 여백 없음)
    static func targetFillRadius(for viewport: CGSize) -> CGFloat {
        min(viewport.width, viewport.height) * 0.5
    }

    static func viewportRadiusMeters(span: MKCoordinateSpan, latitude: Double) -> CLLocationDistance {
        let metersPerDegreeLat = 111_320.0
        let metersPerDegreeLng = 111_320.0 * cos(latitude * .pi / 180)
        let latMeters = span.latitudeDelta * metersPerDegreeLat / 2
        let lngMeters = span.longitudeDelta * metersPerDegreeLng / 2
        return min(latMeters, lngMeters)
    }

    static func maxPanOffsetMeters(span: MKCoordinateSpan) -> CLLocationDistance {
        let viewportRadius = viewportRadiusMeters(
            span: span,
            latitude: FootprintConfig.campusCenter.latitude
        )
        return max(0, FootprintConfig.campusRadiusMeters - viewportRadius)
    }

    static func clampedPanCenter(_ center: CLLocationCoordinate2D, span: MKCoordinateSpan) -> CLLocationCoordinate2D {
        let campus = FootprintConfig.campusCenter
        let maxOffset = maxPanOffsetMeters(span: span)
        guard maxOffset > 0 else { return campus }

        let campusLocation = CLLocation(latitude: campus.latitude, longitude: campus.longitude)
        let candidate = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let distance = campusLocation.distance(from: candidate)
        guard distance > maxOffset else { return center }

        let ratio = maxOffset / distance
        return CLLocationCoordinate2D(
            latitude: campus.latitude + (center.latitude - campus.latitude) * ratio,
            longitude: campus.longitude + (center.longitude - campus.longitude) * ratio
        )
    }

    static func isZoomedIn(span: MKCoordinateSpan, maxZoomOutSpan: MKCoordinateSpan) -> Bool {
        span.latitudeDelta < maxZoomOutSpan.latitudeDelta * 0.97
            || span.longitudeDelta < maxZoomOutSpan.longitudeDelta * 0.97
    }
}
