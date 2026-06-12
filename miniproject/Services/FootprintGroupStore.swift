//
//  FootprintGroupStore.swift
//  miniproject
//

import Foundation

struct JoinedGroupSummary: Identifiable, Codable, Equatable {
    let groupId: String
    let groupName: String
    let memberCount: Int

    var id: String { groupId }

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case groupName = "group_name"
        case memberCount = "member_count"
    }
}

enum FootprintGroupStore {
    private static let joinedGroupsKey = "footprint_joined_groups"
    private static let activeGroupIdKey = "footprint_active_group_id"

    static var joinedGroups: [JoinedGroupSummary] {
        get {
            guard let data = UserDefaults.standard.data(forKey: joinedGroupsKey),
                  let decoded = try? JSONDecoder().decode([JoinedGroupSummary].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: joinedGroupsKey)
        }
    }

    static var activeGroupId: String {
        get { UserDefaults.standard.string(forKey: activeGroupIdKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: activeGroupIdKey) }
    }

    static var activeGroupName: String {
        joinedGroups.first(where: { $0.groupId == activeGroupId })?.groupName ?? ""
    }

    static func upsert(_ group: JoinedGroupSummary) {
        var list = joinedGroups.filter { $0.groupId != group.groupId }
        list.append(group)
        list.sort { $0.groupName < $1.groupName }
        joinedGroups = list
        if activeGroupId.isEmpty {
            activeGroupId = group.groupId
        }
    }

    static func setActive(groupId: String) {
        activeGroupId = groupId
    }

    static func replaceAll(_ groups: [JoinedGroupSummary]) {
        joinedGroups = groups.sorted { $0.groupName < $1.groupName }
        if !activeGroupId.isEmpty, !groups.contains(where: { $0.groupId == activeGroupId }) {
            activeGroupId = groups.first?.groupId ?? ""
        }
        if activeGroupId.isEmpty {
            activeGroupId = groups.first?.groupId ?? ""
        }
    }
}
