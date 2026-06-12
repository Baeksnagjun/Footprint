//
//  FootprintUserFlowScreen.swift
//  miniproject
//

import SwiftUI

struct FlowStep: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    var branch: String?
}

struct FootprintUserFlowScreen: View {
    private let steps: [FlowStep] = [
        .init(id: 1, title: "앱 실행", subtitle: "Footprint 스플래시", icon: "app.fill"),
        .init(id: 2, title: "대학교 선택", subtitle: "검색 후 한성대 등 선택", icon: "building.columns.fill"),
        .init(id: 3, title: "그룹 설정", subtitle: "생성 또는 초대 코드 참여", icon: "person.3.fill"),
        .init(id: 4, title: "메인 지도", subtitle: "캠퍼스 상태에 따라 분기", icon: "map.fill", branch: "지오펜싱"),
        .init(id: 5, title: "캠퍼스 밖", subtitle: "위치 비공개 · 사생활 보호", icon: "location.slash.fill"),
        .init(id: 6, title: "캠퍼스 안", subtitle: "발자국 + 그룹원 마커", icon: "shoeprints.fill"),
        .init(id: 7, title: "건물 자동 표시", subtitle: "예: 상상관, 학술정보관", icon: "mappin.circle.fill"),
        .init(id: 8, title: "친구 마커 탭", subtitle: "하단 시트 열림", icon: "hand.tap.fill"),
        .init(id: 9, title: "퀵 메시지", subtitle: "거기서 뭐함? / 학식 고? 등", icon: "bubble.left.fill"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("사용자 흐름도")
                        .font(.largeTitle.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("스크린샷으로 저장하거나 docs/USER_FLOW.md 참고")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)
                }

                flowDiagram

                Text("캠퍼스 진입 시")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FootprintTheme.textMuted)

                HStack(spacing: 12) {
                    miniNode("밖", icon: "lock.fill", muted: true)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(FootprintTheme.neonCyan)
                    miniNode("푸시 알림", icon: "bell.badge.fill", muted: false)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(FootprintTheme.neonCyan)
                    miniNode("안", icon: "location.fill", muted: false)
                }

                Text("상세 단계")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FootprintTheme.textMuted)

                ForEach(steps) { step in
                    stepRow(step)
                }
            }
            .padding(20)
        }
        .background(FootprintTheme.background.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private var flowDiagram: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                node("시작", icon: "play.circle.fill")
                arrow
                node("온보딩", icon: "1.circle.fill")
                arrow
                node("지도", icon: "map.fill")
            }
            .padding(.bottom, 16)

            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 8) {
                    Text("캠퍼스 밖")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(FootprintTheme.textMuted)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(FootprintTheme.textMuted.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .frame(height: 80)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "eye.slash.fill")
                                Text("비공개")
                                    .font(.caption2)
                            }
                            .foregroundStyle(FootprintTheme.textMuted)
                        )
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    Text("캠퍼스 안")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(FootprintTheme.neonCyan)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(FootprintTheme.neonCyan.opacity(0.5), lineWidth: 1.5)
                        .frame(height: 80)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "shoeprints.fill")
                                Text("공유 ON")
                                    .font(.caption2)
                            }
                            .foregroundStyle(FootprintTheme.neonCyan)
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(FootprintTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func node(_ label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(FootprintTheme.neonCyan)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(FootprintTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(FootprintTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var arrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.bold))
            .foregroundStyle(FootprintTheme.textMuted)
    }

    private func miniNode(_ label: String, icon: String, muted: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(muted ? FootprintTheme.textMuted : FootprintTheme.neonCyan)
            Text(label)
                .font(.caption2)
                .foregroundStyle(FootprintTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepRow(_ step: FlowStep) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(step.id)")
                .font(.caption.weight(.bold))
                .foregroundStyle(FootprintTheme.buttonOnAccent)
                .frame(width: 24, height: 24)
                .background(FootprintTheme.neonCyan)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: step.icon)
                        .foregroundStyle(FootprintTheme.neonCyan)
                        .font(.caption)
                    Text(step.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(FootprintTheme.textPrimary)
                    if let branch = step.branch {
                        Text(branch)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(FootprintTheme.neonCyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(FootprintTheme.neonCyan.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(step.subtitle)
                    .font(.caption)
                    .foregroundStyle(FootprintTheme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(FootprintTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    FootprintUserFlowScreen()
}
