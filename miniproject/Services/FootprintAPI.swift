//
//  FootprintAPI.swift
//  Footprint
//

import CoreLocation
import Foundation
import MapKit

struct CampusEntryEvent: Identifiable, Codable, Equatable {
    let eventId: String
    let userId: String
    let name: String
    let message: String
    let enteredAt: Double

    var id: String { eventId }

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case userId = "user_id"
        case name
        case message
        case enteredAt = "entered_at"
    }
}

struct GroupMember: Identifiable, Codable, Equatable {
    let userId: String
    let name: String

    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
    }
}

struct GroupResponse: Codable {
    let groupId: String
    let groupName: String
    let inviteCode: String?
    let members: [GroupMember]

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case groupName = "group_name"
        case inviteCode = "invite_code"
        case members
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        groupId = try container.decode(String.self, forKey: .groupId)
        groupName = try container.decodeIfPresent(String.self, forKey: .groupName) ?? "그룹"
        inviteCode = try container.decodeIfPresent(String.self, forKey: .inviteCode)
        members = try container.decode([GroupMember].self, forKey: .members)
    }
}

struct UserGroupsResponse: Codable {
    let groups: [JoinedGroupSummary]
}

struct InviteResponse: Codable {
    let groupId: String
    let groupName: String
    let inviteCode: String

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case groupName = "group_name"
        case inviteCode = "invite_code"
    }
}

struct LocationSyncResponse: Codable {
    let peers: [PeerLocation]
    let campusEntries: [CampusEntryEvent]
    let members: [GroupMember]

    enum CodingKeys: String, CodingKey {
        case peers
        case campusEntries = "campus_entries"
        case members
    }

    init(peers: [PeerLocation], campusEntries: [CampusEntryEvent], members: [GroupMember]) {
        self.peers = peers
        self.campusEntries = campusEntries
        self.members = members
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        peers = try container.decode([PeerLocation].self, forKey: .peers)
        campusEntries = try container.decode([CampusEntryEvent].self, forKey: .campusEntries)
        members = try container.decodeIfPresent([GroupMember].self, forKey: .members) ?? []
    }
}

struct PeerLocation: Identifiable, Codable, Equatable {
    let userId: String
    let name: String
    let lat: Double
    let lng: Double
    let updatedAt: Double
    let isOnCampus: Bool

    var id: String { userId }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// 서버 플래그와 무관하게 좌표로 캠퍼스 안 여부 판단
    var isOnCampusByCoordinate: Bool {
        CampusGeofence.isOnCampus(coordinate)
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case lat
        case lng
        case updatedAt = "updated_at"
        case isOnCampus = "is_on_campus"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        lat = try container.decode(Double.self, forKey: .lat)
        lng = try container.decode(Double.self, forKey: .lng)
        updatedAt = try container.decode(Double.self, forKey: .updatedAt)
        isOnCampus = try container.decodeIfPresent(Bool.self, forKey: .isOnCampus)
            ?? CampusGeofence.isOnCampus(
                CLLocationCoordinate2D(latitude: lat, longitude: lng)
            )
    }
}

struct GroupMemberDisplay: Identifiable, Equatable {
    let id: String
    let name: String
    let initial: String
    let isOnCampus: Bool
    let isOnline: Bool
    let isMe: Bool

    var isOffCampus: Bool {
        isOnline && !isOnCampus
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let messageId: String
    let fromUserId: String
    let toUserId: String
    let text: String
    let sentAt: Double

    var id: String { messageId }

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case text
        case sentAt = "sent_at"
    }
}

struct MessagesResponse: Codable {
    let messages: [ChatMessage]
}

struct ChatInboxMessage: Identifiable, Codable, Equatable {
    let messageId: String
    let fromUserId: String
    let toUserId: String
    let text: String
    let sentAt: Double
    let fromName: String

    var id: String { messageId }

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case text
        case sentAt = "sent_at"
        case fromName = "from_name"
    }
}

struct ChatInboxResponse: Codable {
    let messages: [ChatInboxMessage]
}

enum FootprintAPIError: LocalizedError {
    case invalidURL
    case badResponse(Int)
    case decodingFailed
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "서버 주소가 올바르지 않습니다."
        case .badResponse(let code): return "서버 오류 (\(code))"
        case .decodingFailed: return "응답을 읽을 수 없습니다."
        case .serverMessage(let message): return message
        }
    }
}

struct FootprintAPI {
    let baseURL: URL

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw FootprintAPIError.serverMessage(Self.friendlyNetworkMessage(for: error))
        }
    }

    private static func friendlyNetworkMessage(for error: URLError) -> String {
        switch error.code {
        case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost, .timedOut:
            if FootprintDeviceHelper.isSimulator {
                return "서버에 연결할 수 없습니다. 맥에서 uvicorn을 실행했는지 확인하세요. (http://127.0.0.1:8000)"
            }
            return "서버에 연결할 수 없습니다. 맥 Wi‑Fi IP(예: http://192.168.x.x:8000)와 같은 Wi‑Fi인지 확인하세요."
        case .notConnectedToInternet:
            return "인터넷/Wi‑Fi 연결을 확인하세요."
        default:
            return "네트워크 오류: \(error.localizedDescription)"
        }
    }

    func uploadLocation(
        userId: String,
        name: String,
        coordinate: CLLocationCoordinate2D,
        groupId: String
    ) async throws {
        guard !groupId.isEmpty else {
            throw FootprintAPIError.serverMessage("그룹에 참여한 후 위치를 공유할 수 있습니다.")
        }
        let url = baseURL.appending(path: "location")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "user_id": userId,
            "name": name,
            "lat": coordinate.latitude,
            "lng": coordinate.longitude,
            "group_id": groupId,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await performRequest(request)
        try validateResponse(data: data, response: response)
    }

    func fetchUserGroups(userId: String) async throws -> [JoinedGroupSummary] {
        let url = baseURL.appending(path: "users/\(userId)/groups")
        var request = URLRequest(url: url)
        let (data, response) = try await performRequest(request)
        try validateResponse(data: data, response: response)
        guard let decoded = try? JSONDecoder().decode(UserGroupsResponse.self, from: data) else {
            throw FootprintAPIError.decodingFailed
        }
        return decoded.groups
    }

    func fetchGroupDetail(groupId: String) async throws -> GroupResponse {
        let url = baseURL.appending(path: "groups/\(groupId)")
        var request = URLRequest(url: url)
        let (data, response) = try await performRequest(request)
        try validateResponse(data: data, response: response)
        guard let decoded = try? JSONDecoder().decode(GroupResponse.self, from: data) else {
            throw FootprintAPIError.decodingFailed
        }
        return decoded
    }

    func createGroup(
        userId: String,
        userName: String,
        groupName: String,
        university: String
    ) async throws -> GroupResponse {
        let url = baseURL.appending(path: "groups")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "user_id": userId,
            "user_name": userName,
            "group_name": groupName,
            "university": university,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await performRequest(request)
        try validateResponse(data: data, response: response)
        guard let decoded = try? JSONDecoder().decode(GroupResponse.self, from: data) else {
            throw FootprintAPIError.decodingFailed
        }
        return decoded
    }

    func issueInvite(groupId: String, userId: String) async throws -> InviteResponse {
        let url = baseURL.appending(path: "groups/\(groupId)/invite")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["user_id": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await performRequest(request)
        try validateResponse(data: data, response: response)
        guard let decoded = try? JSONDecoder().decode(InviteResponse.self, from: data) else {
            throw FootprintAPIError.decodingFailed
        }
        return decoded
    }

    func joinGroup(inviteCode: String, userId: String, name: String) async throws -> GroupResponse {
        let url = baseURL.appending(path: "groups/join")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "invite_code": inviteCode.uppercased(),
            "user_id": userId,
            "name": name,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await performRequest(request)
        try validateResponse(data: data, response: response)
        guard let decoded = try? JSONDecoder().decode(GroupResponse.self, from: data) else {
            throw FootprintAPIError.decodingFailed
        }
        return decoded
    }

    func sendMessage(
        groupId: String,
        fromUserId: String,
        toUserId: String,
        text: String
    ) async throws -> ChatMessage {
        let url = baseURL.appending(path: "groups/\(groupId)/messages")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "from_user_id": fromUserId,
            "to_user_id": toUserId,
            "text": text,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await performRequest(request)
        try validateResponse(data: data, response: response)
        guard let decoded = try? JSONDecoder().decode(ChatMessage.self, from: data) else {
            throw FootprintAPIError.decodingFailed
        }
        return decoded
    }

    func fetchMessages(
        groupId: String,
        userId: String,
        withUserId: String,
        since: Double? = nil
    ) async throws -> [ChatMessage] {
        var components = URLComponents(
            url: baseURL.appending(path: "groups/\(groupId)/messages"),
            resolvingAgainstBaseURL: false
        )
        var items = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "with_user", value: withUserId),
        ]
        if let since {
            items.append(URLQueryItem(name: "since", value: String(since)))
        }
        components?.queryItems = items
        guard let url = components?.url else { throw FootprintAPIError.invalidURL }

        var request = URLRequest(url: url)
        let (data, response) = try await performRequest(request)
        try validateResponse(data: data, response: response)
        guard let decoded = try? JSONDecoder().decode(MessagesResponse.self, from: data) else {
            throw FootprintAPIError.decodingFailed
        }
        return decoded.messages
    }

    func fetchMessageInbox(
        groupId: String,
        userId: String,
        since: Double? = nil
    ) async throws -> [ChatInboxMessage] {
        var components = URLComponents(
            url: baseURL.appending(path: "groups/\(groupId)/messages/inbox"),
            resolvingAgainstBaseURL: false
        )
        var items = [URLQueryItem(name: "user_id", value: userId)]
        if let since {
            items.append(URLQueryItem(name: "since", value: String(since)))
        }
        components?.queryItems = items
        guard let url = components?.url else { throw FootprintAPIError.invalidURL }

        var request = URLRequest(url: url)
        let (data, response) = try await performRequest(request)
        try validateResponse(data: data, response: response)
        guard let decoded = try? JSONDecoder().decode(ChatInboxResponse.self, from: data) else {
            throw FootprintAPIError.decodingFailed
        }
        return decoded.messages
    }

    func fetchLocationSync(exceptUserId: String, groupId: String) async throws -> LocationSyncResponse {
        guard !groupId.isEmpty else {
            return LocationSyncResponse(peers: [], campusEntries: [], members: [])
        }
        var components = URLComponents(url: baseURL.appending(path: "locations"), resolvingAgainstBaseURL: false)
        let items = [
            URLQueryItem(name: "except_user", value: exceptUserId),
            URLQueryItem(name: "group_id", value: groupId),
        ]
        components?.queryItems = items
        guard let url = components?.url else { throw FootprintAPIError.invalidURL }

        var request = URLRequest(url: url)
        let (data, response) = try await performRequest(request)
        try validateResponse(data: data, response: response)

        guard let decoded = try? JSONDecoder().decode(LocationSyncResponse.self, from: data) else {
            throw FootprintAPIError.decodingFailed
        }
        return decoded
    }

    private func validateResponse(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw FootprintAPIError.badResponse(-1)
        }
        guard (200...299).contains(http.statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] {
                if let message = detail as? String {
                    if http.statusCode == 404 && message == "Not Found" {
                        throw FootprintAPIError.serverMessage(
                            "채팅 API를 찾을 수 없습니다. 맥에서 backend/start-server.sh 로 서버를 재시작해주세요."
                        )
                    }
                    throw FootprintAPIError.serverMessage(message)
                }
                if let items = detail as? [[String: Any]] {
                    let message = items.compactMap { item -> String? in
                        if let msg = item["msg"] as? String {
                            return msg
                        }
                        return nil
                    }.joined(separator: "\n")
                    if !message.isEmpty {
                        throw FootprintAPIError.serverMessage(
                            http.statusCode == 422
                                ? "요청 형식 오류 · 서버를 재시작했는지 확인해주세요.\n\(message)"
                                : message
                        )
                    }
                }
            }
            throw FootprintAPIError.badResponse(http.statusCode)
        }
    }

    func checkHealth() async throws -> Bool {
        let url = baseURL.appending(path: "health")
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await performRequest(request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw FootprintAPIError.serverMessage("서버 응답이 없습니다.")
        }
        struct Health: Codable { let status: String }
        return (try? JSONDecoder().decode(Health.self, from: data))?.status == "ok"
    }
}

enum FootprintConfig {
    static let defaultServerURL = "http://127.0.0.1:8000"

    static let demoUsers: [(id: String, name: String, initial: String)] = [
        ("user_a", "민지", "민"),
        ("user_b", "준호", "준"),
        ("user_c", "서연", "서"),
    ]

    static let universityName = "한성대학교"
    static let campusBuildingName = "상상관"

    // 한성대학교 상상관 (사용자 지정 WGS84)
    static let campusCenter = CLLocationCoordinate2D(latitude: 37.58261, longitude: 127.01054)

    /// 캠퍼스 원형 경계 반경 (기존 사각형과 비슷한 크기, 약 330m)
    static let campusRadiusMeters: CLLocationDistance = 330

    /// 한성대 캠퍼스 주변만 보이도록 하는 지도 범위
    static var campusBoundaryRegion: MKCoordinateRegion {
        let metersPerDegreeLat = 111_320.0
        let metersPerDegreeLng = 111_320.0 * cos(campusCenter.latitude * .pi / 180)
        let latDelta = (campusRadiusMeters * 2) / metersPerDegreeLat
        let lngDelta = (campusRadiusMeters * 2) / metersPerDegreeLng
        return MKCoordinateRegion(
            center: campusCenter,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        )
    }

    static func clampedMapRegion(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        let bound = campusBoundaryRegion
        var span = region.span
        span.latitudeDelta = min(span.latitudeDelta, bound.span.latitudeDelta)
        span.longitudeDelta = min(span.longitudeDelta, bound.span.longitudeDelta)

        let halfLat = span.latitudeDelta / 2
        let halfLng = span.longitudeDelta / 2
        let boundHalfLat = bound.span.latitudeDelta / 2
        let boundHalfLng = bound.span.longitudeDelta / 2

        let minLat = bound.center.latitude - boundHalfLat + halfLat
        let maxLat = bound.center.latitude + boundHalfLat - halfLat
        let minLng = bound.center.longitude - boundHalfLng + halfLng
        let maxLng = bound.center.longitude + boundHalfLng - halfLng

        var center = region.center
        if minLat <= maxLat {
            center.latitude = min(max(center.latitude, minLat), maxLat)
        } else {
            center.latitude = bound.center.latitude
        }
        if minLng <= maxLng {
            center.longitude = min(max(center.longitude, minLng), maxLng)
        } else {
            center.longitude = bound.center.longitude
        }

        return MKCoordinateRegion(center: center, span: span)
    }
}
