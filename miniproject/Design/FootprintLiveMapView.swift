//
//  FootprintLiveMapView.swift
//  Footprint
//

import MapKit
import SwiftUI

struct FootprintLiveMapView: View {
    @StateObject private var viewModel: LiveMapViewModel
    @State private var showLocationSimulation = false
    @State private var showGroupManage = false
    @State private var showServerSettings = false

    init(
        userId: String,
        displayName: String,
        initial: String,
        groupId: String,
        serverURL: String
    ) {
        _viewModel = StateObject(
            wrappedValue: LiveMapViewModel(
                userId: userId,
                displayName: displayName,
                initial: initial,
                groupId: groupId,
                serverURL: serverURL
            )
        )
    }

    var body: some View {
        ZStack {
            MapReader { proxy in
                GeometryReader { geo in
                    ZStack {
                        mapContent(proxy: proxy, viewportSize: geo.size)
                        CampusCircleOutsideMask(proxy: proxy, revision: viewModel.mapCameraRevision)
                    }
                }
            }

            VStack {
                if let chatBanner = viewModel.chatNotificationBanner {
                    chatNotificationBannerView(chatBanner)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if let banner = viewModel.campusEntryBanner {
                    campusEntryBannerView(banner)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                statusBar
                if !viewModel.isConnected {
                    connectionWarning
                }
                Spacer()
                HStack(alignment: .bottom) {
                    simulateButton
                    serverButton
                    Spacer()
                    recenterButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                peerListCard
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .sheet(isPresented: $showLocationSimulation) {
            LocationSimulationSheet(locationService: viewModel.locationService)
        }
        .sheet(isPresented: $showGroupManage) {
            FootprintGroupManageSheet(viewModel: viewModel)
        }
        .sheet(item: $viewModel.activeChatDestination) { destination in
            NavigationStack {
                FootprintGroupChatView(
                    viewModel: viewModel,
                    groupId: destination.groupId,
                    peerUserId: destination.peerUserId,
                    peerName: destination.peerName
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("닫기") {
                            viewModel.closeActiveChat()
                        }
                        .foregroundStyle(FootprintTheme.neonCyanDeep)
                    }
                }
            }
            .preferredColorScheme(.light)
        }
        .sheet(isPresented: $showServerSettings) {
            FootprintServerSettingsSheet(
                initialURL: viewModel.serverURL,
                onSave: { url in try await viewModel.saveServerURL(url) }
            )
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.campusEntryBanner)
        .animation(.easeInOut(duration: 0.25), value: viewModel.chatNotificationBanner)
        .preferredColorScheme(.light)
    }

    private func mapContent(proxy: MapProxy, viewportSize: CGSize) -> some View {
        Map(position: $viewModel.cameraPosition, interactionModes: viewModel.mapInteractionModes) {
            MapCircle(center: FootprintConfig.campusCenter, radius: FootprintConfig.campusRadiusMeters)
                .foregroundStyle(FootprintTheme.neonCyan.opacity(0.06))
                .stroke(FootprintTheme.neonCyan.opacity(0.45), lineWidth: 2)
            ForEach(viewModel.footprintSteps) { step in
                Annotation("", coordinate: step.coordinate) {
                    footprintIcon(step: step)
                }
            }
            if viewModel.locationService.isSimulating,
               let simulated = viewModel.locationService.currentLocation {
                Annotation("나", coordinate: simulated.coordinate) {
                    simulatedUserMarker
                }
            } else if let location = viewModel.locationService.currentLocation {
                Annotation("나", coordinate: location.coordinate) {
                    simulatedUserMarker
                }
            }
            ForEach(viewModel.onCampusPeers) { peer in
                Annotation(peer.name, coordinate: peer.coordinate) {
                    Button {
                        viewModel.openChat(peerUserId: peer.userId, peerName: peer.name)
                    } label: {
                        mapMarker(
                            name: peer.name,
                            initial: String(peer.name.prefix(1)),
                            inactive: false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .automatic))
        .onMapCameraChange(frequency: .continuous) { context in
            viewModel.trackMapCamera(heading: context.camera.heading, region: context.region)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.lockCampusMapView(
                context.region,
                viewportSize: viewportSize,
                proxy: proxy
            )
        }
        .onAppear {
            viewModel.lockCampusMapView(
                FootprintConfig.campusBoundaryRegion,
                viewportSize: viewportSize,
                proxy: proxy
            )
        }
        .ignoresSafeArea()
    }

    private func chatNotificationBannerView(_ banner: ChatNotificationBanner) -> some View {
        Button {
            viewModel.openChatFromNotification()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "message.fill")
                    .foregroundStyle(FootprintTheme.neonCyanDeep)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(banner.peerName)님의 메시지")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FootprintTheme.textMuted)
                    Text(banner.previewText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FootprintTheme.textPrimary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(FootprintTheme.neonCyanDeep)
            }
            .padding(14)
            .footprintCard(cornerRadius: 14)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(FootprintTheme.neonCyan.opacity(0.35), lineWidth: 1.5)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(banner.peerName)님의 새 메시지, 탭해서 채팅 열기")
    }

    private func campusEntryBannerView(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .foregroundStyle(FootprintTheme.neonCyanDeep)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FootprintTheme.textPrimary)
            Spacer()
        }
        .padding(14)
        .footprintCard(cornerRadius: 14)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var simulateButton: some View {
        Button {
            showLocationSimulation = true
        } label: {
            Image(systemName: "figure.walk")
                .font(.body.weight(.semibold))
                .foregroundStyle(FootprintTheme.neonCyanDeep)
                .frame(width: 48, height: 48)
                .background(FootprintTheme.surface)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                .overlay(
                    Circle()
                        .stroke(
                            viewModel.locationService.isSimulating ? FootprintTheme.neonCyan : FootprintTheme.cardStroke,
                            lineWidth: viewModel.locationService.isSimulating ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("위치 테스트")
    }

    private var serverButton: some View {
        Button {
            showServerSettings = true
        } label: {
            Image(systemName: viewModel.isConnected ? "server.rack" : "server.rack")
                .font(.body.weight(.semibold))
                .foregroundStyle(viewModel.isConnected ? FootprintTheme.neonCyanDeep : .orange)
                .frame(width: 48, height: 48)
                .background(FootprintTheme.surface)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                .overlay(
                    Circle()
                        .stroke(viewModel.isConnected ? FootprintTheme.cardStroke : Color.orange.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("서버 연결")
    }

    private var connectionWarning: some View {
        Button {
            showServerSettings = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Label("서버 연결 안 됨 · 탭해서 설정", systemImage: "wifi.exclamationmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                Text(viewModel.connectionError ?? "왼쪽 아래 서버 버튼을 눌러주세요")
                    .font(.caption2)
                    .foregroundStyle(FootprintTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                if !FootprintDeviceHelper.isSimulator {
                    Text("실기기: \(FootprintDeviceHelper.recommendedServerURL)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(FootprintTheme.neonCyanDeep)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private var statusBar: some View {
        HStack {
            Text(viewModel.displayName)
                .font(.title3.bold())
                .foregroundStyle(FootprintTheme.textPrimary)
            Spacer()
            profileAvatar(initial: viewModel.initial, inactive: !viewModel.isOnCampus, size: 44)
        }
        .padding(16)
        .footprintCard(cornerRadius: 20)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var simulatedUserMarker: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.25))
                .frame(width: 28, height: 28)
            Circle()
                .fill(Color.blue)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 2)
                )
        }
    }

    private var recenterButton: some View {
        Button {
            viewModel.recenterOnUser()
        } label: {
            Image(systemName: "location.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(FootprintTheme.neonCyanDeep)
                .frame(width: 48, height: 48)
                .background(FootprintTheme.surface)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                .overlay(
                    Circle()
                        .stroke(FootprintTheme.cardStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("캠퍼스 전체 보기")
    }

    private var peerListCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("그룹원")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FootprintTheme.textMuted)
                Spacer()
                Button {
                    showGroupManage = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                            .font(.caption.weight(.semibold))
                        Text(viewModel.activeGroupName.isEmpty ? "그룹" : viewModel.activeGroupName)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(FootprintTheme.neonCyanDeep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(FootprintTheme.neonCyan.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            ForEach(viewModel.groupMembers) { member in
                HStack(spacing: 12) {
                    mapMarker(
                        name: member.name,
                        initial: member.initial,
                        compact: true,
                        inactive: member.isOffCampus
                    )
                    HStack(spacing: 6) {
                        Text(member.isMe ? "\(member.name) (나)" : member.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(member.isOffCampus ? Color.gray : FootprintTheme.textPrimary)
                        if member.isOffCampus {
                            Text("학교 밖")
                                .font(.caption2)
                                .foregroundStyle(Color.gray)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .footprintCard()
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    private func footprintIcon(step: FootprintStep) -> some View {
        Image(systemName: "shoeprints.fill")
            .font(.system(size: step.userId == viewModel.userId ? 13 : 11))
            .foregroundStyle(footprintColor(for: step.userId).opacity(step.opacity))
            .rotationEffect(.degrees(footprintDisplayAngle(for: step)))
            .shadow(color: footprintColor(for: step.userId).opacity(0.25), radius: 2, y: 1)
    }

    private func footprintDisplayAngle(for step: FootprintStep) -> Double {
        step.heading - viewModel.mapHeading + FootprintTrail.iconBaseOffset
    }

    private func footprintColor(for userId: String) -> Color {
        userId == viewModel.userId ? FootprintTheme.neonCyan : FootprintTheme.neonCyanDeep
    }

    private func profileAvatar(initial: String, inactive: Bool, size: CGFloat) -> some View {
        memberAvatar(initial: initial, compact: false, inactive: inactive, size: size)
    }

    private func memberAvatar(
        initial: String,
        compact: Bool,
        inactive: Bool,
        size: CGFloat? = nil
    ) -> some View {
        let outer = size ?? (compact ? 36 : 52)
        let inner = size.map { $0 - 6 } ?? (compact ? 30 : 44)
        return ZStack {
            Circle()
                .fill(inactive ? Color.gray.opacity(0.22) : FootprintTheme.backgroundTint)
                .frame(width: outer, height: outer)
            Circle()
                .stroke(inactive ? Color.gray.opacity(0.45) : FootprintTheme.neonCyan, lineWidth: compact ? 2 : 2.5)
                .frame(width: inner, height: inner)
            Text(initial)
                .font(compact ? .caption.bold() : .headline.bold())
                .foregroundStyle(inactive ? Color.gray : FootprintTheme.neonCyanDeep)
        }
    }

    private func mapMarker(
        name: String,
        initial: String,
        compact: Bool = false,
        inactive: Bool = false
    ) -> some View {
        VStack(spacing: 4) {
            memberAvatar(initial: initial, compact: compact, inactive: inactive)
            if !compact {
                Text(name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(inactive ? Color.gray : FootprintTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(FootprintTheme.surface)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
        }
    }
}

private struct CampusCircleOutsideMask: View {
    let proxy: MapProxy
    let revision: Int

    var body: some View {
        GeometryReader { _ in
            if let metrics = CampusCircleScreenGeometry.screenMetrics(proxy: proxy) {
                Canvas { context, size in
                    var path = Path(CGRect(origin: .zero, size: size))
                    path.addEllipse(in: CGRect(
                        x: metrics.center.x - metrics.radius,
                        y: metrics.center.y - metrics.radius,
                        width: metrics.radius * 2,
                        height: metrics.radius * 2
                    ))
                    context.fill(path, with: .color(FootprintTheme.background), style: FillStyle(eoFill: true))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .id(revision)
    }
}
