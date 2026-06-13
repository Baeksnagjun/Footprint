//
//  FootprintTrail.swift
//  Footprint
//

import CoreLocation
import Foundation

struct FootprintStep: Identifiable, Equatable {
    let id: UUID
    let userId: String
    let coordinate: CLLocationCoordinate2D
    /// 이동 방향 (북=0°, 시계 방향)
    let heading: Double
    let createdAt: Date
    var opacity: Double

    static func == (lhs: FootprintStep, rhs: FootprintStep) -> Bool {
        lhs.id == rhs.id
    }
}

enum FootprintTrail {
    /// shoeprints.fill 기본 방향 보정 (지도 북쪽 기준)
    static let iconBaseOffset: Double = -25
    /// 발자국 표시 유지 시간
    static let stepLifetime: TimeInterval = 60
}

@MainActor
final class FootprintTrailStore {
    private(set) var steps: [FootprintStep] = []
    private var lastCoordinates: [String: CLLocationCoordinate2D] = [:]
    private var lastHeadings: [String: Double] = [:]

    private let maxStepsPerUser = 40
    private let minDistanceMeters: CLLocationDistance = 2

    func reset() {
        steps = []
        lastCoordinates = [:]
        lastHeadings = [:]
    }

    func keepOnly(userIds: Set<String>) {
        steps = steps.filter { userIds.contains($0.userId) }
        lastCoordinates = lastCoordinates.filter { userIds.contains($0.key) }
        lastHeadings = lastHeadings.filter { userIds.contains($0.key) }
    }

    func pruneExpired(now: Date = Date()) -> [FootprintStep] {
        let cutoff = now.addingTimeInterval(-FootprintTrail.stepLifetime)
        steps = steps.filter { $0.createdAt > cutoff }
        steps = refreshOpacity(for: steps)
        return steps
    }

    func record(
        userId: String,
        coordinate: CLLocationCoordinate2D,
        course: CLLocationDirection = -1
    ) -> [FootprintStep] {
        _ = pruneExpired()
        let heading = resolveHeading(
            userId: userId,
            coordinate: coordinate,
            course: course
        )

        if let last = lastCoordinates[userId] {
            let from = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            guard from.distance(from: to) >= minDistanceMeters else {
                return steps
            }
        }

        let placement = lastCoordinates[userId].map {
            midpoint(from: $0, to: coordinate)
        } ?? coordinate

        lastCoordinates[userId] = coordinate
        lastHeadings[userId] = heading

        var userSteps = steps.filter { $0.userId == userId }
        let newStep = FootprintStep(
            id: UUID(),
            userId: userId,
            coordinate: placement,
            heading: heading,
            createdAt: Date(),
            opacity: 1
        )
        userSteps.append(newStep)
        if userSteps.count > maxStepsPerUser {
            userSteps.removeFirst(userSteps.count - maxStepsPerUser)
        }
        userSteps = applyOpacityFade(userSteps)

        steps.removeAll { $0.userId == userId }
        steps.append(contentsOf: userSteps)
        return steps
    }

    private func resolveHeading(
        userId: String,
        coordinate: CLLocationCoordinate2D,
        course: CLLocationDirection
    ) -> Double {
        if course >= 0 {
            return course
        }
        if let last = lastCoordinates[userId] {
            return bearing(from: last, to: coordinate)
        }
        return lastHeadings[userId] ?? 0
    }

    private func refreshOpacity(for allSteps: [FootprintStep]) -> [FootprintStep] {
        let userIds = Set(allSteps.map(\.userId))
        return userIds.flatMap { userId in
            let userSteps = allSteps
                .filter { $0.userId == userId }
                .sorted { $0.createdAt < $1.createdAt }
            return applyOpacityFade(userSteps)
        }
    }

    private func applyOpacityFade(_ userSteps: [FootprintStep]) -> [FootprintStep] {
        let count = userSteps.count
        return userSteps.enumerated().map { index, step in
            var updated = step
            let t = count <= 1 ? 1.0 : Double(index) / Double(count - 1)
            updated.opacity = 0.18 + t * 0.72
            return updated
        }
    }

    private func midpoint(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (from.latitude + to.latitude) / 2,
            longitude: (from.longitude + to.longitude) / 2
        )
    }

    private func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radians = atan2(y, x)
        let degrees = radians * 180 / .pi
        return degrees >= 0 ? degrees : degrees + 360
    }
}
