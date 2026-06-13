//
//  FootprintOnboardingScreens.swift
//  Footprint
//

import SwiftUI

struct FootprintSplashScreen: View {
    var onContinue: () -> Void = {}

    var body: some View {
        ZStack {
            FootprintTheme.background.ignoresSafeArea()
            RadialGradient(
                colors: [FootprintTheme.neonCyan.opacity(0.35), FootprintTheme.background],
                center: .center,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(FootprintTheme.neonCyan.opacity(0.25), lineWidth: 2)
                        .frame(width: 120, height: 120)
                    Image(systemName: "shoeprints.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(FootprintTheme.neonCyan)
                        .rotationEffect(.degrees(-18))
                }
                VStack(spacing: 8) {
                    Text("Footprint")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("캠퍼스 안에서만, 그룹과 함께")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)
                }
                Spacer()
                VStack(spacing: 12) {
                    Button("시작하기", action: onContinue)
                        .buttonStyle(FootprintPrimaryButtonStyle())
                    Text("학교 선택 후 지도에서 발자국을 공유합니다")
                        .font(.caption)
                        .foregroundStyle(FootprintTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
    }
}

struct FootprintNameSetupScreen: View {
    @Binding var name: String
    var onContinue: () -> Void = {}

    var body: some View {
        ZStack {
            FootprintTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("이름 설정")
                        .font(.title.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("그룹원에게 보일 이름을 입력하세요")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 10) {
                    Text("닉네임")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FootprintTheme.textMuted)
                    TextField("예: 상준", text: $name)
                        .padding(14)
                        .background(FootprintTheme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(FootprintTheme.textPrimary)
                }

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(FootprintTheme.backgroundTint)
                            .frame(width: 56, height: 56)
                        Circle()
                            .stroke(FootprintTheme.neonCyan, lineWidth: 2)
                            .frame(width: 48, height: 48)
                        Text(name.isEmpty ? "?" : String(name.prefix(1)))
                            .font(.title2.bold())
                            .foregroundStyle(FootprintTheme.neonCyanDeep)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name.isEmpty ? "이름 미입력" : name)
                            .font(.headline)
                            .foregroundStyle(FootprintTheme.textPrimary)
                        Text("지도 마커에 이렇게 표시됩니다")
                            .font(.caption)
                            .foregroundStyle(FootprintTheme.textMuted)
                    }
                    Spacer()
                }
                .padding(16)
                .footprintCard()

                Spacer()

                Button("다음", action: onContinue)
                    .buttonStyle(FootprintPrimaryButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 ? 0.5 : 1)
            }
            .padding(20)
        }
        .preferredColorScheme(.light)
    }
}

struct FootprintUniversitySelectScreen: View {
    @State private var query = ""
    var onSelect: (String) -> Void = { _ in }

    private let schools: [(String, String)] = [
        (FootprintConfig.universityName, "서울 성북구"),
        ("서울대학교", "서울 관악구"),
        ("연세대학교", "서울 서대문구"),
        ("고려대학교", "서울 성북구"),
        ("성균관대학교", "서울 종로구"),
        ("한양대학교", "서울 성동구"),
        ("중앙대학교", "서울 동작구"),
        ("경희대학교", "서울 동대문구"),
        ("서강대학교", "서울 마포구"),
        ("이화여자대학교", "서울 서대문구"),
        ("건국대학교", "서울 광진구"),
        ("동국대학교", "서울 중구"),
        ("국민대학교", "서울 성북구"),
        ("숭실대학교", "서울 동작구"),
        ("아주대학교", "경기 수원시"),
        ("인하대학교", "인천 미추홀구"),
        ("부산대학교", "부산 금정구"),
        ("전남대학교", "광주 북구"),
    ]

    var body: some View {
        ZStack {
            FootprintTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("대학교 선택")
                        .font(.title.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("에브리타임처럼 학교를 검색해 선택하세요")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)
                }
                .padding(.top, 8)

                FootprintSearchField(placeholder: "학교 이름 검색", text: $query)

                ScrollView {
                    VStack(spacing: 10) {
                        if trimmedQuery.isEmpty {
                            searchPrompt
                        } else if filteredSchools.isEmpty {
                            emptyResult
                        } else {
                            ForEach(filteredSchools, id: \.0) { school in
                                schoolRow(school)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.light)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchPrompt: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(FootprintTheme.textMuted)
            Text("학교 이름을 검색해 주세요")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FootprintTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var emptyResult: some View {
        VStack(spacing: 8) {
            Text("검색 결과가 없어요")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FootprintTheme.textSecondary)
            Text("다른 키워드로 다시 검색해 보세요")
                .font(.caption)
                .foregroundStyle(FootprintTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func schoolRow(_ school: (String, String)) -> some View {
        Button {
            onSelect(school.0)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(school.0)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text(school.1)
                        .font(.caption)
                        .foregroundStyle(FootprintTheme.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FootprintTheme.textMuted)
            }
            .padding(16)
            .background(FootprintTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var filteredSchools: [(String, String)] {
        guard !trimmedQuery.isEmpty else { return [] }
        return schools.filter { school in
            school.0.localizedCaseInsensitiveContains(trimmedQuery)
                || school.1.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }
}

struct FootprintGroupSetupScreen: View {
    @Binding var groupName: String
    @Binding var inviteCodeInput: String
    var isLoading: Bool = false
    var errorMessage: String = ""
    var onCreate: () -> Void = {}
    var onJoin: () -> Void = {}
    var onSkip: () -> Void = {}

    var body: some View {
        ZStack {
            FootprintTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("그룹 설정")
                        .font(.title.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("지금 만들거나 참여할 수 있어요 · 나중에도 가능합니다")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("그룹 이름")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FootprintTheme.textMuted)
                    TextField("예: 25학번 동기", text: $groupName)
                        .padding(14)
                        .background(FootprintTheme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Button("그룹 만들기", action: onCreate)
                        .buttonStyle(FootprintPrimaryButtonStyle())
                        .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .opacity(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? 0.5 : 1)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("초대 코드로 참여")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FootprintTheme.textMuted)
                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { i in
                            Text(codeCharacter(at: i))
                                .font(.title2.monospaced().weight(.bold))
                                .foregroundStyle(FootprintTheme.neonCyan)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(FootprintTheme.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    TextField("6자리 코드 입력", text: $inviteCodeInput)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: inviteCodeInput) { _, newValue in
                            inviteCodeInput = String(newValue.uppercased().prefix(6))
                        }
                    Button("참여하기", action: onJoin)
                        .buttonStyle(FootprintSecondaryOutlineButtonStyle())
                        .disabled(inviteCodeInput.count < 4 || isLoading)
                        .opacity(inviteCodeInput.count < 4 || isLoading ? 0.5 : 1)
                }

                Text("서버는 자동 연결됩니다 · 맥에서 uvicorn 실행 필요")
                    .font(.caption)
                    .foregroundStyle(FootprintTheme.textMuted)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Button("나중에 하기", action: onSkip)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FootprintTheme.textSecondary)
                    .frame(maxWidth: .infinity)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .preferredColorScheme(.light)
    }

    private func codeCharacter(at index: Int) -> String {
        guard index < inviteCodeInput.count else { return "·" }
        let i = inviteCodeInput.index(inviteCodeInput.startIndex, offsetBy: index)
        return String(inviteCodeInput[i])
    }
}

private struct FootprintSecondaryOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(FootprintTheme.neonCyanDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(FootprintTheme.neonCyan.opacity(configuration.isPressed ? 0.18 : 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct FootprintInviteCodeScreen: View {
    let inviteCode: String
    var onContinue: () -> Void = {}

    var body: some View {
        ZStack {
            FootprintTheme.background.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "person.3.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(FootprintTheme.neonCyan)
                VStack(spacing: 8) {
                    Text("그룹이 만들어졌어요")
                        .font(.title2.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("친구에게 아래 코드를 공유하세요")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)
                }
                Text(inviteCode)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(FootprintTheme.neonCyanDeep)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(FootprintTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Spacer()
                Button("지도 시작", action: onContinue)
                    .buttonStyle(FootprintPrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
    }
}
