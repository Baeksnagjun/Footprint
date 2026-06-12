//
//  FootprintRootView.swift
//  miniproject
//

import SwiftUI

struct FootprintRootView: View {
    @AppStorage("footprint_server_url") private var serverURL = FootprintConfig.defaultServerURL
    @State private var selectedUserId = FootprintConfig.demoUsers[0].id
    @State private var showLiveMap = false
    @State private var showUIShowcase = false
    @State private var serverCheckMessage = ""
    @State private var showStartAlert = false
    @State private var startAlertMessage = ""

    private var serverURLWarning: String? {
        FootprintDeviceHelper.validateServerURL(serverURL)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FootprintTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        if !FootprintDeviceHelper.isSimulator {
                            deviceWarningCard
                        }
                        serverSection
                        userSection
                        startButton
                        showcaseLink
                        howToSection
                    }
                    .padding(20)
                }
            }
            .navigationDestination(isPresented: $showLiveMap) {
                if let user = FootprintConfig.demoUsers.first(where: { $0.id == selectedUserId }) {
                    FootprintLiveMapView(
                        userId: user.id,
                        displayName: user.name,
                        initial: user.initial,
                        groupId: FootprintSession.groupId,
                        serverURL: serverURL
                    )
                }
            }
            .navigationDestination(isPresented: $showUIShowcase) {
                FootprintShowcaseView()
            }
            .alert("시작 전 확인", isPresented: $showStartAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(startAlertMessage)
            }
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Footprint")
                .font(.largeTitle.bold())
                .foregroundStyle(FootprintTheme.textPrimary)
            Text("실시간 위치 데모 · \(FootprintConfig.demoUsers.count)명 지도 표시")
                .font(.subheadline)
                .foregroundStyle(FootprintTheme.textSecondary)
        }
    }

    private var deviceWarningCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("실기기 연결됨", systemImage: "iphone")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            Text("127.0.0.1은 폰 자신을 가리킵니다. 맥에서 서버를 켠 뒤, 맥의 Wi‑Fi IP로 바꿔야 합니다.")
                .font(.caption)
                .foregroundStyle(FootprintTheme.textSecondary)
                .lineSpacing(3)
            Text("맥 터미널: ipconfig getifaddr en0")
                .font(.caption.monospaced())
                .foregroundStyle(FootprintTheme.neonCyanDeep)
        }
        .padding(14)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }

    private var serverSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("서버 주소")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FootprintTheme.textMuted)
            TextField(FootprintDeviceHelper.isSimulator ? "http://127.0.0.1:8000" : "http://192.168.0.5:8000", text: $serverURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .padding(14)
                .background(FootprintTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(FootprintTheme.textPrimary)
            Text(FootprintDeviceHelper.serverURLHint)
                .font(.caption2)
                .foregroundStyle(FootprintTheme.textMuted)
            if let warning = serverURLWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Button("서버 연결 테스트") {
                Task { await testServer() }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(FootprintTheme.neonCyan)
            if !serverCheckMessage.isEmpty {
                Text(serverCheckMessage)
                    .font(.caption)
                    .foregroundStyle(serverCheckMessage.contains("성공") ? FootprintTheme.neonCyan : .orange)
            }
        }
    }

    private var userSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("이 기기 사용자 (폰마다 다르게 선택)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FootprintTheme.textMuted)
            ForEach(FootprintConfig.demoUsers, id: \.id) { user in
                Button {
                    selectedUserId = user.id
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(selectedUserId == user.id ? FootprintTheme.neonCyan.opacity(0.25) : FootprintTheme.surfaceElevated)
                                .frame(width: 44, height: 44)
                            Text(user.initial)
                                .font(.headline.bold())
                                .foregroundStyle(FootprintTheme.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(FootprintTheme.textPrimary)
                            Text(user.id)
                                .font(.caption)
                                .foregroundStyle(FootprintTheme.textMuted)
                        }
                        Spacer()
                        if selectedUserId == user.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(FootprintTheme.neonCyan)
                        }
                    }
                    .padding(14)
                    .background(FootprintTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selectedUserId == user.id ? FootprintTheme.neonCyan.opacity(0.5) : .clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var startButton: some View {
        Button {
            attemptStartMap()
        } label: {
            Text("지도 시작")
                .font(.headline.weight(.semibold))
                .foregroundStyle(FootprintTheme.buttonOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(FootprintTheme.neonCyan)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var showcaseLink: some View {
        Button {
            showUIShowcase = true
        } label: {
            HStack {
                Text("UI 시안 모음 보기")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(FootprintTheme.textSecondary)
            .padding(16)
            .background(FootprintTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var howToSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("실기기 체크리스트")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FootprintTheme.textMuted)
            Text("""
            1. 맥에서 서버 실행 (uvicorn)
            2. 폰·맥 같은 Wi‑Fi
            3. 서버 주소 = http://맥IP:8000
            4. 연결 테스트 성공 후 지도 시작
            5. 위치 권한 허용
            """)
                .font(.caption)
                .foregroundStyle(FootprintTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(FootprintTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func attemptStartMap() {
        if let warning = serverURLWarning {
            startAlertMessage = warning
            showStartAlert = true
            return
        }
        if !serverCheckMessage.contains("성공") {
            startAlertMessage = "먼저 「서버 연결 테스트」로 연결 성공을 확인하세요."
            showStartAlert = true
            return
        }
        showLiveMap = true
    }

    private func testServer() async {
        if let warning = FootprintDeviceHelper.validateServerURL(serverURL) {
            serverCheckMessage = warning
            return
        }
        let normalized = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: normalized) else {
            serverCheckMessage = "주소 형식이 잘못되었습니다"
            return
        }
        let api = FootprintAPI(baseURL: url)
        do {
            let ok = try await api.checkHealth()
            serverCheckMessage = ok ? "연결 성공" : "서버 응답 없음"
        } catch {
            serverCheckMessage = "연결 실패: \(error.localizedDescription)"
        }
    }
}

#Preview {
    FootprintRootView()
}
