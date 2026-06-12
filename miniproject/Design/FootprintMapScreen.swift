//
//  FootprintMapScreen.swift
//  miniproject
//

import SwiftUI

struct MockFriend: Identifiable {
    let id = UUID()
    let name: String
    let initial: String
    let x: CGFloat
    let y: CGFloat
}

struct FootprintMapCampusScreen: View {
    var showBottomSheet: Bool = true

    private let friends: [MockFriend] = [
        .init(name: "민지", initial: "민", x: 0.28, y: 0.38),
        .init(name: "준호", initial: "준", x: 0.62, y: 0.52),
        .init(name: "서연", initial: "서", x: 0.48, y: 0.68),
    ]

    var body: some View {
        ZStack {
            mockMapBackground
            campusBoundaryOverlay
            footprintTrails
            ForEach(friends) { friend in
                friendMarker(friend)
            }
            topStatusBar
            if showBottomSheet {
                VStack {
                    Spacer()
                    FootprintFriendBottomSheet()
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.light)
    }

    private var mockMapBackground: some View {
        ZStack {
            FootprintTheme.background
            Canvas { context, size in
                let step: CGFloat = 28
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += step
                }
                context.stroke(path, with: .color(FootprintTheme.mapGrid), lineWidth: 0.5)
            }
            LinearGradient(
                colors: [FootprintTheme.backgroundTint.opacity(0.2), FootprintTheme.background.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var campusBoundaryOverlay: some View {
        RoundedRectangle(cornerRadius: 120, style: .continuous)
            .stroke(FootprintTheme.campusBoundary, lineWidth: 2)
            .background(FootprintTheme.neonCyan.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 120, style: .continuous))
            .padding(36)
            .padding(.top, 80)
    }

    private var footprintTrails: some View {
        GeometryReader { geo in
            ZStack {
                footprintTrail(at: CGPoint(x: geo.size.width * 0.35, y: geo.size.height * 0.42), count: 4, rotation: -30)
                footprintTrail(at: CGPoint(x: geo.size.width * 0.55, y: geo.size.height * 0.58), count: 5, rotation: 35)
                footprintTrail(at: CGPoint(x: geo.size.width * 0.45, y: geo.size.height * 0.72), count: 3, rotation: 8)
            }
        }
    }

    private func footprintTrail(at origin: CGPoint, count: Int, rotation: Double) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                Image(systemName: "shoeprints.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(FootprintTheme.neonCyan.opacity(0.15 + Double(i) * 0.12))
                    .rotationEffect(.degrees(rotation))
                    .offset(x: CGFloat(i) * 10, y: CGFloat(i) * -8)
            }
        }
        .position(origin)
    }

    private func friendMarker(_ friend: MockFriend) -> some View {
        GeometryReader { geo in
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(FootprintTheme.neonCyan.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Circle()
                        .stroke(FootprintTheme.neonCyan, lineWidth: 2)
                        .frame(width: 44, height: 44)
                    Text(friend.initial)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(FootprintTheme.textPrimary)
                }
                Text(friend.name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(FootprintTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(FootprintTheme.surface.opacity(0.9))
                    .clipShape(Capsule())
            }
            .position(x: geo.size.width * friend.x, y: geo.size.height * friend.y)
        }
    }

    private var topStatusBar: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(FootprintTheme.neonCyan)
                            .frame(width: 8, height: 8)
                        Text("캠퍼스 안 · 위치 공유 중")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FootprintTheme.neonCyan)
                    }
                    Text(FootprintConfig.campusBuildingName)
                        .font(.title3.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                }
                Spacer()
                Button {} label: {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(FootprintTheme.textPrimary)
                        .padding(12)
                        .background(FootprintTheme.surface.opacity(0.9))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .footprintCard(cornerRadius: 20)
            .padding(.horizontal, 16)
            .padding(.top, 56)
            Spacer()
        }
    }
}

struct FootprintFriendBottomSheet: View {
    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(FootprintTheme.textMuted.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 10)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(FootprintTheme.neonCyan.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Text("민")
                        .font(.title3.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("민지")
                        .font(.headline)
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("상상관 · 방금 전")
                        .font(.caption)
                        .foregroundStyle(FootprintTheme.textSecondary)
                }
                Spacer()
            }

            Text("원터치 텔레파시")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FootprintTheme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                quickMessage("거기서 뭐함?")
                quickMessage("학식 고?")
                quickMessage("같이 공부할?")
                quickMessage("5분 뒤 만나")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .footprintCard(cornerRadius: 24)
        .padding(.horizontal, 12)
    }

    private func quickMessage(_ text: String) -> some View {
        Button {} label: {
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FootprintTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FootprintTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(FootprintTheme.neonCyan.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct FootprintOffCampusScreen: View {
    var body: some View {
        ZStack {
            FootprintTheme.background.ignoresSafeArea()
            FootprintMapCampusScreen(showBottomSheet: false)
                .opacity(0.35)
                .blur(radius: 2)

            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(FootprintTheme.textMuted)
                VStack(spacing: 8) {
                    Text("캠퍼스 밖")
                        .font(.title2.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("한성대 캠퍼스에 들어오면\n그룹원에게 위치가 공유됩니다")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    Text("사생활 보호 모드")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(FootprintTheme.textMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(FootprintTheme.surface)
                .clipShape(Capsule())
                Spacer()
                Spacer()
            }
        }
        .preferredColorScheme(.light)
    }
}
