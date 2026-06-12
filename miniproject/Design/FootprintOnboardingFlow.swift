//
//  FootprintOnboardingFlow.swift
//  miniproject
//

import SwiftUI

private enum OnboardingStep {
    case splash
    case university
    case name
    case group
    case map
}

struct FootprintAppEntry: View {
    @AppStorage(FootprintSession.onboardingDoneKey) private var onboardingDone = false

    var body: some View {
        Group {
            if onboardingDone {
                FootprintMainView()
            } else {
                FootprintOnboardingFlow()
            }
        }
        .preferredColorScheme(.light)
    }
}

struct FootprintOnboardingFlow: View {
    @State private var step: OnboardingStep = .splash
    @State private var university = FootprintSession.university
    @State private var displayName = FootprintSession.displayName
    @State private var groupName = ""
    @State private var inviteCodeInput = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        Group {
            switch step {
            case .splash:
                FootprintSplashScreen {
                    step = .university
                }
            case .university:
                FootprintUniversitySelectScreen { selected in
                    university = selected
                    FootprintSession.university = selected
                    step = .name
                }
            case .name:
                FootprintNameSetupScreen(name: $displayName) {
                    let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                    FootprintSession.displayName = trimmed
                    _ = FootprintSession.userId
                    step = .group
                }
            case .group:
                FootprintGroupSetupScreen(
                    groupName: $groupName,
                    inviteCodeInput: $inviteCodeInput,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    onCreate: { Task { await createGroup() } },
                    onJoin: { Task { await joinGroup() } },
                    onSkip: {
                        finishOnboarding()
                        step = .map
                    }
                )
            case .map:
                FootprintLiveMapView(
                    userId: FootprintSession.userId,
                    displayName: FootprintSession.displayName,
                    initial: FootprintSession.initial,
                    groupId: FootprintSession.groupId,
                    serverURL: FootprintSession.serverURL
                )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: stepLabel)
    }

    private var stepLabel: String {
        switch step {
        case .splash: return "splash"
        case .university: return "university"
        case .name: return "name"
        case .group: return "group"
        case .map: return "map"
        }
    }

    private func api() async -> FootprintAPI? {
        let resolved = await FootprintServerResolver.resolveAndSave()
        guard let url = URL(string: resolved) else { return nil }
        return FootprintAPI(baseURL: url)
    }

    private func persistProfile() {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        FootprintSession.displayName = trimmed
        _ = FootprintSession.userId
    }

    private func createGroup() async {
        persistProfile()
        guard let api = await api() else {
            errorMessage = "서버에 연결할 수 없습니다. 맥에서 서버를 켜주세요."
            return
        }
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            let healthy = try await api.checkHealth()
            guard healthy else {
                errorMessage = "서버에 연결할 수 없습니다. 맥에서 서버를 켜주세요."
                return
            }
            let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                errorMessage = "그룹 이름을 입력해주세요."
                return
            }
            let response = try await api.createGroup(
                userId: FootprintSession.userId,
                userName: FootprintSession.displayName,
                groupName: trimmedName,
                university: university
            )
            FootprintGroupStore.upsert(
                JoinedGroupSummary(
                    groupId: response.groupId,
                    groupName: response.groupName,
                    memberCount: response.members.count
                )
            )
            FootprintSession.groupId = response.groupId
            finishOnboarding()
            step = .map
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func joinGroup() async {
        persistProfile()
        guard let api = await api() else {
            errorMessage = "서버에 연결할 수 없습니다. 맥에서 서버를 켜주세요."
            return
        }
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            let healthy = try await api.checkHealth()
            guard healthy else {
                errorMessage = "서버에 연결할 수 없습니다. 맥에서 서버를 켜주세요."
                return
            }
            let response = try await api.joinGroup(
                inviteCode: inviteCodeInput,
                userId: FootprintSession.userId,
                name: FootprintSession.displayName
            )
            FootprintGroupStore.upsert(
                JoinedGroupSummary(
                    groupId: response.groupId,
                    groupName: response.groupName,
                    memberCount: response.members.count
                )
            )
            FootprintSession.groupId = response.groupId
            finishOnboarding()
            step = .map
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finishOnboarding() {
        FootprintSession.completeOnboarding()
    }
}

struct FootprintMainView: View {
    @AppStorage(FootprintSession.onboardingDoneKey) private var onboardingDone = true

    var body: some View {
        FootprintLiveMapView(
            userId: FootprintSession.userId,
            displayName: FootprintSession.displayName,
            initial: FootprintSession.initial,
            groupId: FootprintSession.groupId,
            serverURL: FootprintSession.serverURL
        )
    }
}
