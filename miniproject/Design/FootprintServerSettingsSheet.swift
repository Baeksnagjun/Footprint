//
//  FootprintServerSettingsSheet.swift
//  Footprint
//

import SwiftUI

struct FootprintServerSettingsSheet: View {
    let initialURL: String
    let onSave: (String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var serverURL = ""
    @State private var statusMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                FootprintTheme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    Text("맥에서 서버(uvicorn)를 켠 뒤 아래 주소로 연결합니다.")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("서버 주소")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FootprintTheme.textMuted)
                        TextField(FootprintDeviceHelper.recommendedServerURL, text: $serverURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .padding(14)
                            .background(FootprintTheme.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if FootprintDeviceHelper.isSimulator {
                        Label("시뮬레이터는 127.0.0.1 사용", systemImage: "desktopcomputer")
                            .font(.caption)
                            .foregroundStyle(FootprintTheme.textMuted)
                    } else {
                        Label("실기기는 맥과 같은 Wi‑Fi 필요", systemImage: "wifi")
                            .font(.caption)
                            .foregroundStyle(FootprintTheme.textMuted)
                        Text("추천: \(FootprintDeviceHelper.recommendedServerURL)")
                            .font(.caption.monospaced())
                            .foregroundStyle(FootprintTheme.neonCyanDeep)
                    }

                    Button {
                        serverURL = FootprintDeviceHelper.recommendedServerURL
                    } label: {
                        Text("추천 주소로 채우기")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FootprintTheme.neonCyanDeep)
                    }

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(statusMessage.contains("성공") ? FootprintTheme.neonCyanDeep : .orange)
                    }

                    Spacer()

                    Button("연결 테스트 후 저장") {
                        Task { await save() }
                    }
                    .buttonStyle(FootprintPrimaryButtonStyle())
                    .disabled(isLoading)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
            }
            .navigationTitle("서버 연결")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(FootprintTheme.neonCyanDeep)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            serverURL = initialURL.isEmpty
                ? FootprintDeviceHelper.recommendedServerURL
                : initialURL
        }
    }

    private func save() async {
        isLoading = true
        statusMessage = ""
        defer { isLoading = false }
        do {
            try await onSave(serverURL)
            statusMessage = "연결 성공 · 저장됨"
            try? await Task.sleep(for: .milliseconds(600))
            dismiss()
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
