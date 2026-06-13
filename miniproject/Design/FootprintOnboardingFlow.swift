//
//  FootprintOnboardingFlow.swift
//  Footprint
//

import SwiftUI

private enum OnboardingStep {
    case splash
    case university
    case name
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
    @State private var displayName = FootprintSession.displayName

    var body: some View {
        Group {
            switch step {
            case .splash:
                FootprintSplashScreen {
                    step = .university
                }
            case .university:
                FootprintUniversitySelectScreen { selected in
                    FootprintSession.university = selected
                    step = .name
                }
            case .name:
                FootprintNameSetupScreen(name: $displayName) {
                    let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                    FootprintSession.displayName = trimmed
                    _ = FootprintSession.userId
                    finishOnboarding()
                    step = .map
                }
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
        case .map: return "map"
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
