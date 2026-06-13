//
//  LocationService.swift
//  Footprint
//

import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentLocation: CLLocation?
    @Published var errorMessage: String?
    @Published var isSimulating = false

    private let manager = CLLocationManager()
    private var gpsLocation: CLLocation?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2
    }

    func requestPermissionAndStart() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            errorMessage = "설정에서 위치 권한을 허용해 주세요."
        @unknown default:
            break
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    func startSimulation(from coordinate: CLLocationCoordinate2D? = nil) {
        isSimulating = true
        let base = coordinate ?? currentLocation?.coordinate ?? gpsLocation?.coordinate ?? FootprintConfig.campusCenter
        currentLocation = CLLocation(latitude: base.latitude, longitude: base.longitude)
    }

    func stopSimulation() {
        isSimulating = false
        currentLocation = gpsLocation
    }

    func nudge(_ direction: MapNudgeDirection, meters: CLLocationDistance = LocationSimulation.defaultStepMeters) {
        if !isSimulating {
            startSimulation()
        }
        let base = currentLocation?.coordinate ?? FootprintConfig.campusCenter
        let moved = LocationSimulation.offset(from: base, direction: direction, meters: meters)
        currentLocation = CLLocation(latitude: moved.latitude, longitude: moved.longitude)
    }

    var authorizationDescription: String {
        if isSimulating {
            return "위치: 시뮬레이션 모드 (가짜 이동)"
        }
        switch authorizationStatus {
        case .notDetermined: return "위치 권한: 요청 전"
        case .restricted: return "위치 권한: 제한됨"
        case .denied: return "위치 권한: 거부됨 → 설정에서 허용"
        case .authorizedAlways: return "위치 권한: 항상 허용"
        case .authorizedWhenInUse: return "위치 권한: 사용 중 허용"
        @unknown default: return "위치 권한: 알 수 없음"
        }
    }

    var isAuthorized: Bool {
        isSimulating || authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            gpsLocation = location
            if !isSimulating {
                currentLocation = location
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
}
