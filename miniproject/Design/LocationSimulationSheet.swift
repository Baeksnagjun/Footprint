//
//  LocationSimulationSheet.swift
//  Footprint
//

import CoreLocation
import SwiftUI

struct LocationSimulationSheet: View {
    @ObservedObject var locationService: LocationService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("실제로 걷지 않고 위치를 옮겨 발자국·서버 전송을 테스트합니다.")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)
                    if locationService.isSimulating {
                        Label("시뮬레이션 켜짐", systemImage: "figure.walk.motion")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FootprintTheme.neonCyanDeep)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                nudgePad

                VStack(spacing: 10) {
                    Button {
                        locationService.startSimulation()
                    } label: {
                        Text("현재 위치에서 시뮬레이션 시작")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FootprintPrimaryButtonStyle())

                    Button {
                        locationService.startSimulation(from: FootprintConfig.campusCenter)
                    } label: {
                        Text("\(FootprintConfig.campusBuildingName) (\(FootprintConfig.universityName))")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FootprintSecondaryButtonStyle())

                    Button {
                        // 캠퍼스 밖 (지오펜스 테스트)
                        locationService.startSimulation(
                            from: CLLocationCoordinate2D(latitude: 37.5760, longitude: 127.01054)
                        )
                    } label: {
                        Text("캠퍼스 밖으로 이동 (테스트)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FootprintSecondaryButtonStyle())

                    if locationService.isSimulating {
                        Button {
                            locationService.stopSimulation()
                        } label: {
                            Text("실제 GPS로 복귀")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FootprintSecondaryButtonStyle())
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(FootprintTheme.background.ignoresSafeArea())
            .navigationTitle("위치 테스트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(FootprintTheme.neonCyanDeep)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var nudgePad: some View {
        VStack(spacing: 10) {
            Text("방향 이동 (약 8m)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FootprintTheme.textMuted)
            Button { locationService.nudge(.north) } label: {
                nudgeButton("북", icon: "arrow.up")
            }
            HStack(spacing: 10) {
                Button { locationService.nudge(.west) } label: {
                    nudgeButton("서", icon: "arrow.left")
                }
                Button { locationService.nudge(.east) } label: {
                    nudgeButton("동", icon: "arrow.right")
                }
            }
            Button { locationService.nudge(.south) } label: {
                nudgeButton("남", icon: "arrow.down")
            }
        }
        .padding(16)
        .footprintCard()
    }

    private func nudgeButton(_ label: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(FootprintTheme.neonCyanDeep)
        .frame(width: 100, height: 44)
        .background(FootprintTheme.backgroundTint)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct FootprintSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.medium))
            .foregroundStyle(FootprintTheme.neonCyanDeep)
            .padding(.vertical, 14)
            .background(FootprintTheme.neonCyan.opacity(configuration.isPressed ? 0.15 : 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(FootprintTheme.cardStroke, lineWidth: 1)
            )
    }
}
