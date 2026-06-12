//
//  FootprintSession.swift
//  miniproject
//

import Foundation
import SwiftUI

enum FootprintSession {
    static let userIdKey = "footprint_user_id"
    static let displayNameKey = "footprint_display_name"
    static let universityKey = "footprint_university"
    static let groupIdKey = "footprint_group_id"
    static let inviteCodeKey = "footprint_invite_code"
    static let onboardingDoneKey = "footprint_onboarding_done"
    static let serverURLKey = "footprint_server_url"

    static var isOnboardingComplete: Bool {
        UserDefaults.standard.bool(forKey: onboardingDoneKey)
    }

    static var userId: String {
        get {
            let stored = UserDefaults.standard.string(forKey: userIdKey) ?? ""
            if !stored.isEmpty { return stored }
            let created = UUID().uuidString.lowercased()
            UserDefaults.standard.set(created, forKey: userIdKey)
            return created
        }
        set { UserDefaults.standard.set(newValue, forKey: userIdKey) }
    }

    static var displayName: String {
        get { UserDefaults.standard.string(forKey: displayNameKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: displayNameKey) }
    }

    static var university: String {
        get { UserDefaults.standard.string(forKey: universityKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: universityKey) }
    }

    static var groupId: String {
        get {
            let active = FootprintGroupStore.activeGroupId
            if !active.isEmpty { return active }
            return UserDefaults.standard.string(forKey: groupIdKey) ?? ""
        }
        set {
            FootprintGroupStore.setActive(groupId: newValue)
            UserDefaults.standard.set(newValue, forKey: groupIdKey)
        }
    }

    static var inviteCode: String {
        get { UserDefaults.standard.string(forKey: inviteCodeKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: inviteCodeKey) }
    }

    static var activeGroupName: String {
        FootprintGroupStore.activeGroupName
    }

    static var serverURL: String {
        get {
            let stored = UserDefaults.standard.string(forKey: serverURLKey) ?? ""
            if stored.isEmpty {
                return FootprintDeviceHelper.recommendedServerURL
            }
            if !FootprintDeviceHelper.isSimulator,
               FootprintDeviceHelper.isLocalhostURL(stored) {
                return FootprintDeviceHelper.recommendedServerURL
            }
            return stored
        }
        set {
            let normalized = FootprintDeviceHelper.normalizeServerURL(newValue)
            UserDefaults.standard.set(normalized, forKey: serverURLKey)
        }
    }

    static var initial: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first)
    }

    static func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingDoneKey)
    }

    static func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: onboardingDoneKey)
        UserDefaults.standard.removeObject(forKey: groupIdKey)
        UserDefaults.standard.removeObject(forKey: inviteCodeKey)
        FootprintGroupStore.replaceAll([])
        FootprintGroupStore.setActive(groupId: "")
    }
}
