//
//  FootprintShowcaseView.swift
//  Footprint
//

import SwiftUI

enum FootprintScreen: String, CaseIterable, Identifiable {
    case userFlow = "사용자 흐름도"
    case splash = "스플래시"
    case university = "대학교 선택"
    case group = "그룹 설정"
    case map = "캠퍼스 지도 (메인)"
    case offCampus = "캠퍼스 밖"
    case bottomSheet = "퀵 메시지 시트"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .userFlow: return "저장용 · 스크린샷 / 문서"
        case .splash: return "앱 첫 진입"
        case .university: return "에브리타임 방식 검색"
        case .group: return "생성 / 코드 참여"
        case .map: return "발자국 + 실시간 마커"
        case .offCampus: return "위치 공유 꺼짐"
        case .bottomSheet: return "친구 마커 탭 시"
        }
    }
}

struct FootprintShowcaseView: View {
    @State private var flowStep = 0
    @State private var selectedScreen: FootprintScreen?

    private let flowScreens: [FootprintScreen] = [.splash, .university, .group, .map]

    var body: some View {
        NavigationStack {
            ZStack {
                FootprintTheme.background.ignoresSafeArea()
                if let selectedScreen {
                    screenPreview(selectedScreen)
                } else if flowStep > 0 && flowStep <= flowScreens.count {
                    flowPreview
                } else {
                    hubView
                }
            }
            .animation(.easeInOut(duration: 0.25), value: selectedScreen?.id)
            .animation(.easeInOut(duration: 0.25), value: flowStep)
            .toolbar {
                if selectedScreen != nil || flowStep > 0 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if flowStep > 0 {
                                flowStep = 0
                            } else {
                                selectedScreen = nil
                            }
                        } label: {
                            Label("목록", systemImage: "chevron.left")
                                .foregroundStyle(FootprintTheme.neonCyan)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var hubView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Footprint UI 시안")
                        .font(.largeTitle.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("기능 없이 화면만 미리보기 · 다크 + 네온 시안 #00F5D4")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)
                }
                .padding(.top, 8)

                Button {
                    selectedScreen = .userFlow
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("사용자 흐름도 보기")
                                .font(.headline)
                            Text("과제·발표용 저장 (앱 + docs/USER_FLOW.md)")
                                .font(.caption)
                                .foregroundStyle(FootprintTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundStyle(FootprintTheme.neonCyan)
                    }
                    .foregroundStyle(FootprintTheme.textPrimary)
                    .padding(18)
                    .background(FootprintTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(FootprintTheme.neonCyan.opacity(0.4), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    flowStep = 1
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("온보딩 플로우 체험")
                                .font(.headline)
                            Text("스플래시 → 학교 → 그룹 → 지도")
                                .font(.caption)
                                .foregroundStyle(FootprintTheme.buttonOnAccent.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "play.fill")
                    }
                    .foregroundStyle(FootprintTheme.buttonOnAccent)
                    .padding(18)
                    .background(FootprintTheme.neonCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Text("화면별 보기")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FootprintTheme.textMuted)

                ForEach(FootprintScreen.allCases) { screen in
                    Button {
                        selectedScreen = screen
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(screen.rawValue)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(FootprintTheme.textPrimary)
                                Text(screen.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(FootprintTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .foregroundStyle(FootprintTheme.neonCyan)
                        }
                        .padding(16)
                        .background(FootprintTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private var flowPreview: some View {
        let index = flowStep - 1
        switch flowScreens[index] {
        case .splash:
            FootprintSplashScreen { flowStep = 2 }
        case .university:
            FootprintUniversitySelectScreen { _ in flowStep = 3 }
        case .group:
            FootprintGroupSetupScreen(
                groupName: .constant("25학번 동기"),
                inviteCodeInput: .constant("HSD202"),
                onCreate: { flowStep = 4 },
                onJoin: { flowStep = 4 }
            )
        case .map:
            FootprintMapCampusScreen()
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func screenPreview(_ screen: FootprintScreen) -> some View {
        switch screen {
        case .userFlow:
            FootprintUserFlowScreen()
        case .splash:
            FootprintSplashScreen()
        case .university:
            FootprintUniversitySelectScreen()
        case .group:
            FootprintGroupSetupScreen(
                groupName: .constant("25학번 동기"),
                inviteCodeInput: .constant("HSD202")
            )
        case .map:
            FootprintMapCampusScreen()
        case .offCampus:
            FootprintOffCampusScreen()
        case .bottomSheet:
            ZStack {
                FootprintMapCampusScreen(showBottomSheet: false)
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack {
                    Spacer()
                    FootprintFriendBottomSheet()
                }
            }
        }
    }
}

#Preview {
    FootprintShowcaseView()
}
