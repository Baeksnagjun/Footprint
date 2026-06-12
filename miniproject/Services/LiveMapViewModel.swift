//
//  LiveMapViewModel.swift
//  miniproject
//

import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI

@MainActor
final class LiveMapViewModel: ObservableObject {
    @Published var peers: [PeerLocation] = []
    @Published var groupMembers: [GroupMemberDisplay] = []
    @Published var cameraPosition: MapCameraPosition = .region(FootprintConfig.campusBoundaryRegion)
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var footprintSteps: [FootprintStep] = []
    @Published var isOnCampus = false
    @Published var campusEntryBanner: String?
    @Published var mapHeading: Double = 0
    @Published private(set) var groupId: String
    @Published private(set) var joinedGroups: [JoinedGroupSummary] = []
    @Published private(set) var activeGroupName: String = ""
    @Published private(set) var serverURL: String

    let userId: String
    let displayName: String
    let initial: String

    let locationService = LocationService()

    private var api: FootprintAPI
    private var syncTask: Task<Void, Never>?
    private var footprintExpiryTask: Task<Void, Never>?
    private var bannerTask: Task<Void, Never>?
    private var didInitialCenter = false
    private let defaultSpan = FootprintConfig.campusBoundaryRegion.span
    private let footprintTrail = FootprintTrailStore()
    private var locationCancellable: AnyCancellable?
    private var seenEntryEventIds: Set<String> = []
    private var peerPresence: [String: (isOnline: Bool, isOnCampus: Bool)] = [:]
    private var registeredMembers: [GroupMember] = []

    init(
        userId: String,
        displayName: String,
        initial: String,
        groupId: String,
        serverURL: String
    ) {
        self.userId = userId
        self.displayName = displayName
        self.initial = initial
        let resolvedGroupId = groupId.isEmpty ? FootprintGroupStore.activeGroupId : groupId
        self.groupId = resolvedGroupId
        self.joinedGroups = FootprintGroupStore.joinedGroups
        self.activeGroupName = FootprintGroupStore.activeGroupName
        let trimmedServerURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        self.serverURL = trimmedServerURL
        self.api = Self.makeAPI(serverURL: trimmedServerURL)
        rebuildGroupMembers()
    }

    private static func makeAPI(serverURL: String) -> FootprintAPI {
        let urlString = FootprintDeviceHelper.normalizeServerURL(serverURL)
        let url = URL(string: urlString) ?? URL(string: FootprintConfig.defaultServerURL)!
        return FootprintAPI(baseURL: url)
    }

    func updateServerURL(_ raw: String) throws {
        let trimmed = FootprintDeviceHelper.normalizeServerURL(raw)
        if let warning = FootprintDeviceHelper.validateServerURL(trimmed) {
            throw FootprintAPIError.serverMessage(warning)
        }
        serverURL = trimmed
        FootprintSession.serverURL = trimmed
        api = Self.makeAPI(serverURL: trimmed)
    }

    func verifyServerConnection() async throws {
        let ok = try await api.checkHealth()
        if !ok {
            throw FootprintAPIError.serverMessage("서버 응답이 없습니다.")
        }
    }

    func autoConnectServer() async {
        let resolved = await FootprintServerResolver.resolveAndSave()
        try? updateServerURL(resolved)
        do {
            try await verifyServerConnection()
            isConnected = true
            connectionError = nil
        } catch {
            isConnected = false
            connectionError = error.localizedDescription
        }
    }

    func saveServerURL(_ raw: String) async throws {
        try updateServerURL(raw)
        try await verifyServerConnection()
        isConnected = true
        connectionError = nil
    }

    func start() {
        Task {
            await autoConnectServer()
            await refreshJoinedGroups()
        }
        locationService.requestPermissionAndStart()
        locationCancellable = locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self else { return }
                let onCampus = CampusGeofence.isOnCampus(location.coordinate)
                if self.isOnCampus != onCampus {
                    self.isOnCampus = onCampus
                    self.rebuildGroupMembers()
                }
                guard onCampus else { return }
                self.footprintSteps = self.footprintTrail.record(
                    userId: self.userId,
                    coordinate: location.coordinate,
                    course: location.course
                )
            }
        syncTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.syncOnce()
                try? await Task.sleep(for: .seconds(3))
            }
        }
        footprintExpiryTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self else { continue }
                self.footprintSteps = self.footprintTrail.pruneExpired()
            }
        }
    }

    func stop() {
        syncTask?.cancel()
        syncTask = nil
        footprintExpiryTask?.cancel()
        footprintExpiryTask = nil
        bannerTask?.cancel()
        bannerTask = nil
        locationCancellable?.cancel()
        locationCancellable = nil
        locationService.stop()
    }

    func clearFootprints() {
        footprintTrail.reset()
        footprintSteps = []
    }

    func applyGroupChange(_ response: GroupResponse) {
        let summary = JoinedGroupSummary(
            groupId: response.groupId,
            groupName: response.groupName,
            memberCount: response.members.count
        )
        FootprintGroupStore.upsert(summary)
        joinedGroups = FootprintGroupStore.joinedGroups
        selectActiveGroup(response.groupId)
        registeredMembers = response.members
        rebuildGroupMembers()
        Task { await syncOnce() }
    }

    func selectActiveGroup(_ newGroupId: String) {
        if newGroupId.isEmpty {
            clearActiveGroupContext()
            return
        }
        let groupChanged = groupId != newGroupId
        groupId = newGroupId
        FootprintGroupStore.setActive(groupId: newGroupId)
        FootprintSession.groupId = newGroupId
        activeGroupName = joinedGroups.first(where: { $0.groupId == newGroupId })?.groupName
            ?? FootprintGroupStore.activeGroupName
        if groupChanged {
            peers = []
            peerPresence = [:]
            clearFootprints()
        }
        rebuildGroupMembers()
        if groupChanged {
            Task { await syncOnce() }
        }
    }

    func refreshJoinedGroups() async {
        await autoConnectServer()
        do {
            try await verifyServerConnection()
            let groups = try await api.fetchUserGroups(userId: userId)
            FootprintGroupStore.replaceAll(groups)
            joinedGroups = groups
            if groups.isEmpty {
                if !groupId.isEmpty {
                    clearActiveGroupContext()
                }
            } else if groups.contains(where: { $0.groupId == groupId }) {
                activeGroupName = groups.first(where: { $0.groupId == groupId })?.groupName ?? activeGroupName
                FootprintGroupStore.setActive(groupId: groupId)
            } else {
                selectActiveGroup(groups[0].groupId)
            }
            reconcileGroupContext()
        } catch {
            joinedGroups = FootprintGroupStore.joinedGroups
            reconcileGroupContext()
        }
    }

    func fetchGroupDetail(groupId: String) async throws -> GroupResponse {
        await autoConnectServer()
        try await verifyServerConnection()
        return try await api.fetchGroupDetail(groupId: groupId)
    }

    func createGroup(name groupName: String) async throws -> GroupResponse {
        await autoConnectServer()
        try await verifyServerConnection()
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw FootprintAPIError.serverMessage("그룹 이름을 입력해주세요.")
        }
        return try await api.createGroup(
            userId: userId,
            userName: displayName,
            groupName: trimmed,
            university: FootprintSession.university
        )
    }

    func joinGroup(inviteCode code: String) async throws -> GroupResponse {
        await autoConnectServer()
        try await verifyServerConnection()
        return try await api.joinGroup(
            inviteCode: code,
            userId: userId,
            name: displayName
        )
    }

    func generateInvite(for groupId: String) async throws -> String {
        await autoConnectServer()
        try await verifyServerConnection()
        let response = try await api.issueInvite(groupId: groupId, userId: userId)
        return response.inviteCode
    }

    var onCampusPeers: [PeerLocation] {
        guard !groupId.isEmpty else { return [] }
        let memberIds = Set(groupMembers.map(\.id))
        return peers.filter { peer in
            peer.isOnCampusByCoordinate && memberIds.contains(peer.userId)
        }
    }

    func recenterOnUser() {
        guard let location = locationService.currentLocation else { return }
        let span = lastKnownSpan ?? defaultSpan
        let region = FootprintConfig.clampedMapRegion(
            MKCoordinateRegion(center: location.coordinate, span: span)
        )
        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(region)
        }
    }

    func updateSpanFromCamera(_ span: MKCoordinateSpan) {
        lastKnownSpan = span
    }

    func applyCameraRegion(_ region: MKCoordinateRegion, heading: CLLocationDirection = 0) {
        mapHeading = heading
        let clamped = FootprintConfig.clampedMapRegion(region)
        lastKnownSpan = clamped.span

        let centerMoved = abs(clamped.center.latitude - region.center.latitude) > 0.000001
            || abs(clamped.center.longitude - region.center.longitude) > 0.000001
        let spanChanged = abs(clamped.span.latitudeDelta - region.span.latitudeDelta) > 0.000001
            || abs(clamped.span.longitudeDelta - region.span.longitudeDelta) > 0.000001

        if centerMoved || spanChanged {
            cameraPosition = .region(clamped)
        }
    }

    private var lastKnownSpan: MKCoordinateSpan?

    private func centerOnUserIfNeeded(_ coordinate: CLLocationCoordinate2D) {
        guard !didInitialCenter else { return }
        didInitialCenter = true
        cameraPosition = .region(
            MKCoordinateRegion(center: coordinate, span: defaultSpan)
        )
    }

    private func clearActiveGroupContext() {
        groupId = ""
        activeGroupName = ""
        FootprintGroupStore.setActive(groupId: "")
        FootprintSession.groupId = ""
        peers = []
        peerPresence = [:]
        registeredMembers = []
        rebuildGroupMembers()
    }

    private func reconcileGroupContext() {
        let storeGroupId = FootprintGroupStore.activeGroupId
        if !storeGroupId.isEmpty, groupId != storeGroupId {
            groupId = storeGroupId
        }
        if !groupId.isEmpty {
            activeGroupName = joinedGroups.first(where: { $0.groupId == groupId })?.groupName
                ?? FootprintGroupStore.activeGroupName
        }
    }

    private func syncOnce() async {
        reconcileGroupContext()

        if let location = locationService.currentLocation {
            isOnCampus = CampusGeofence.isOnCampus(location.coordinate)
        }

        guard !groupId.isEmpty else {
            peers = []
            peerPresence = [:]
            registeredMembers = []
            rebuildGroupMembers()
            footprintTrail.keepOnly(userIds: isOnCampus ? [userId] : [])
            footprintSteps = footprintTrail.steps
            return
        }

        do {
            let healthy = try await api.checkHealth()
            isConnected = healthy
            connectionError = nil
            if !healthy { return }

            if let location = locationService.currentLocation {
                try await api.uploadLocation(
                    userId: userId,
                    name: displayName,
                    coordinate: location.coordinate,
                    groupId: groupId
                )
                centerOnUserIfNeeded(location.coordinate)
            }

            let sync = try await api.fetchLocationSync(exceptUserId: userId, groupId: groupId)
            peers = sync.peers
            if !sync.members.isEmpty {
                registeredMembers = sync.members
            }
            updatePeerPresence(from: sync.peers)
            rebuildGroupMembers()

            for peer in sync.peers where peer.isOnCampusByCoordinate {
                footprintSteps = footprintTrail.record(userId: peer.userId, coordinate: peer.coordinate)
            }

            var visibleUserIds = Set(sync.peers.filter(\.isOnCampusByCoordinate).map(\.userId))
            if isOnCampus {
                visibleUserIds.insert(userId)
            }
            footprintTrail.keepOnly(userIds: visibleUserIds)
            footprintSteps = footprintTrail.steps

            handleCampusEntries(sync.campusEntries)
        } catch {
            isConnected = false
            connectionError = error.localizedDescription
        }
    }

    private func updatePeerPresence(from peers: [PeerLocation]) {
        var next: [String: (isOnline: Bool, isOnCampus: Bool)] = [:]
        for peer in peers {
            next[peer.userId] = (true, peer.isOnCampusByCoordinate)
        }
        peerPresence = next
    }

    private func rebuildGroupMembers() {
        var roster = registeredMembers
        if !roster.contains(where: { $0.userId == userId }) {
            roster.append(GroupMember(userId: userId, name: displayName))
        }

        groupMembers = roster.map { member in
            let isMe = member.userId == userId
            if isMe {
                return GroupMemberDisplay(
                    id: member.userId,
                    name: member.name,
                    initial: String(member.name.prefix(1)),
                    isOnCampus: isOnCampus,
                    isOnline: locationService.currentLocation != nil,
                    isMe: true
                )
            }
            if let presence = peerPresence[member.userId], presence.isOnline {
                return GroupMemberDisplay(
                    id: member.userId,
                    name: member.name,
                    initial: String(member.name.prefix(1)),
                    isOnCampus: presence.isOnCampus,
                    isOnline: true,
                    isMe: false
                )
            }
            return GroupMemberDisplay(
                id: member.userId,
                name: member.name,
                initial: String(member.name.prefix(1)),
                isOnCampus: false,
                isOnline: false,
                isMe: false
            )
        }
        .sorted { lhs, rhs in
            if lhs.isMe != rhs.isMe { return lhs.isMe }
            return lhs.name < rhs.name
        }
    }

    private func handleCampusEntries(_ entries: [CampusEntryEvent]) {
        guard let newest = entries
            .filter({ !seenEntryEventIds.contains($0.eventId) })
            .sorted(by: { $0.enteredAt > $1.enteredAt })
            .first else { return }

        seenEntryEventIds.insert(newest.eventId)
        for entry in entries {
            seenEntryEventIds.insert(entry.eventId)
        }

        campusEntryBanner = newest.message
        bannerTask?.cancel()
        bannerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.campusEntryBanner = nil
        }
    }
}
