//
//  FootprintGroupManageSheet.swift
//  Footprint
//

import SwiftUI

private enum GroupSheetRoute: Hashable {
    case create
    case join
    case detail(String)
    case chat(groupId: String, peerUserId: String, peerName: String)
}

struct FootprintGroupManageSheet: View {
    @ObservedObject var viewModel: LiveMapViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                FootprintTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if viewModel.joinedGroups.isEmpty {
                                emptyGroupsCard
                            } else {
                                Text("참여 중인 그룹")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(FootprintTheme.textMuted)
                                    .padding(.horizontal, 4)

                                ForEach(viewModel.joinedGroups) { group in
                                    groupRow(
                                        group,
                                        onSelect: {
                                            viewModel.selectActiveGroup(group.groupId)
                                        },
                                        onShowDetail: {
                                            path.append(GroupSheetRoute.detail(group.groupId))
                                        }
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .padding(.bottom, 8)
                    }

                    bottomActions
                }
            }
            .navigationTitle("그룹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(FootprintTheme.neonCyanDeep)
                }
            }
            .navigationDestination(for: GroupSheetRoute.self) { route in
                switch route {
                case .create:
                    GroupCreateView(viewModel: viewModel, path: $path)
                case .join:
                    GroupJoinView(viewModel: viewModel, path: $path)
                case .detail(let groupId):
                    GroupDetailView(viewModel: viewModel, groupId: groupId, path: $path)
                case .chat(let groupId, let peerUserId, let peerName):
                    FootprintGroupChatView(
                        viewModel: viewModel,
                        groupId: groupId,
                        peerUserId: peerUserId,
                        peerName: peerName
                    )
                }
            }
        }
        .preferredColorScheme(.light)
        .task {
            isRefreshing = true
            await viewModel.refreshJoinedGroups()
            isRefreshing = false
        }
    }

    private var emptyGroupsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("아직 참여한 그룹이 없어요")
                .font(.body.weight(.semibold))
                .foregroundStyle(FootprintTheme.textPrimary)
            Text("아래에서 그룹을 만들거나 초대 코드로 참여해보세요")
                .font(.subheadline)
                .foregroundStyle(FootprintTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .footprintCard()
    }

    private func groupRow(
        _ group: JoinedGroupSummary,
        onSelect: @escaping () -> Void,
        onShowDetail: @escaping () -> Void
    ) -> some View {
        let isActive = viewModel.groupId == group.groupId
        return HStack(spacing: 0) {
            Button(action: onSelect) {
                HStack(spacing: 14) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isActive ? FootprintTheme.neonCyanDeep : FootprintTheme.textMuted)

                    Image(systemName: "person.3.fill")
                        .font(.title3)
                        .foregroundStyle(isActive ? FootprintTheme.neonCyanDeep : FootprintTheme.neonCyan)
                        .frame(width: 44, height: 44)
                        .background(FootprintTheme.neonCyan.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.groupName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(FootprintTheme.textPrimary)
                        HStack(spacing: 6) {
                            Text("\(group.memberCount)명")
                                .font(.caption)
                                .foregroundStyle(FootprintTheme.textSecondary)
                            if isActive {
                                Text("선택됨")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(FootprintTheme.neonCyanDeep)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(FootprintTheme.neonCyan.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.leading, 16)
                .padding(.vertical, 16)
                .padding(.trailing, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(group.groupName), 지도에 표시할 그룹 선택")

            Rectangle()
                .fill(FootprintTheme.cardStroke)
                .frame(width: 1)
                .padding(.vertical, 12)

            Button(action: onShowDetail) {
                VStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(FootprintTheme.neonCyanDeep)
                .frame(width: 52)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(group.groupName) 그룹원 보기")
        }
        .footprintCard()
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(FootprintTheme.neonCyan.opacity(0.45), lineWidth: 1.5)
            }
        }
    }

    private var bottomActions: some View {
        VStack(spacing: 10) {
            Divider()
            HStack(spacing: 10) {
                Button {
                    path.append(GroupSheetRoute.create)
                } label: {
                    Label("그룹 만들기", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(FootprintSecondaryButtonStyle())

                Button {
                    path.append(GroupSheetRoute.join)
                } label: {
                    Label("그룹 참여하기", systemImage: "link")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(FootprintPrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 8)
        }
        .background(FootprintTheme.background)
    }
}

// MARK: - Create

private struct GroupCreateView: View {
    @ObservedObject var viewModel: LiveMapViewModel
    @Binding var path: NavigationPath

    @State private var groupName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            FootprintTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("새 그룹 만들기")
                        .font(.title2.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("동아리, 동기, 절친 등 함께 위치를 공유할 그룹 이름을 정해주세요")
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
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Button("그룹 만들기") {
                    Task { await create() }
                }
                .buttonStyle(FootprintPrimaryButtonStyle())
                .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .opacity(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? 0.5 : 1)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .navigationTitle("그룹 만들기")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func create() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        do {
            let response = try await viewModel.createGroup(name: groupName)
            viewModel.applyGroupChange(response)
            await viewModel.refreshJoinedGroups()
            path.removeLast(path.count)
            path.append(GroupSheetRoute.detail(response.groupId))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Join

private struct GroupJoinView: View {
    @ObservedObject var viewModel: LiveMapViewModel
    @Binding var path: NavigationPath

    @State private var joinCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            FootprintTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("그룹 참여하기")
                        .font(.title2.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)
                    Text("친구에게 받은 6자리 초대 코드를 입력하세요")
                        .font(.subheadline)
                        .foregroundStyle(FootprintTheme.textSecondary)
                }

                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { i in
                        Text(codeCharacter(at: i))
                            .font(.title3.monospaced().weight(.bold))
                            .foregroundStyle(FootprintTheme.neonCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(FootprintTheme.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                TextField("6자리 코드 입력", text: $joinCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(FootprintTheme.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onChange(of: joinCode) { _, newValue in
                        joinCode = String(newValue.uppercased().prefix(6))
                    }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Button("참여하기") {
                    Task { await join() }
                }
                .buttonStyle(FootprintPrimaryButtonStyle())
                .disabled(joinCode.count < 4 || isLoading)
                .opacity(joinCode.count < 4 || isLoading ? 0.5 : 1)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .navigationTitle("그룹 참여")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func codeCharacter(at index: Int) -> String {
        guard index < joinCode.count else { return "·" }
        let i = joinCode.index(joinCode.startIndex, offsetBy: index)
        return String(joinCode[i])
    }

    private func join() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        do {
            let response = try await viewModel.joinGroup(inviteCode: joinCode)
            viewModel.applyGroupChange(response)
            await viewModel.refreshJoinedGroups()
            path.removeLast(path.count)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Detail

private struct GroupDetailView: View {
    @ObservedObject var viewModel: LiveMapViewModel
    let groupId: String
    @Binding var path: NavigationPath

    @State private var groupName = ""
    @State private var members: [GroupMember] = []
    @State private var isLoading = true
    @State private var isInviting = false
    @State private var inviteCode = ""
    @State private var showInviteCode = false
    @State private var didCopy = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            FootprintTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    Spacer()
                    ProgressView()
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    Text(groupName)
                        .font(.title2.bold())
                        .foregroundStyle(FootprintTheme.textPrimary)

                    Text("멤버 \(members.count)명")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FootprintTheme.textMuted)

                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(members) { member in
                                if member.userId == viewModel.userId {
                                    memberRow(member, showsChatHint: false)
                                } else {
                                    Button {
                                        path.append(
                                            GroupSheetRoute.chat(
                                                groupId: groupId,
                                                peerUserId: member.userId,
                                                peerName: member.name
                                            )
                                        )
                                    } label: {
                                        memberRow(member, showsChatHint: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if showInviteCode {
                        inviteCodeCard
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Button {
                        Task { await invite() }
                    } label: {
                        Label("초대하기", systemImage: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(FootprintPrimaryButtonStyle())
                    .disabled(isInviting)
                    .opacity(isInviting ? 0.6 : 1)
                }
            }
            .padding(20)
        }
        .navigationTitle("그룹 상세")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDetail() }
    }

    private func memberRow(_ member: GroupMember, showsChatHint: Bool) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(FootprintTheme.neonCyan.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(String(member.name.prefix(1)))
                        .font(.subheadline.bold())
                        .foregroundStyle(FootprintTheme.neonCyanDeep)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(member.userId == viewModel.userId ? "\(member.name) (나)" : member.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(FootprintTheme.textPrimary)
                if showsChatHint {
                    Text("탭해서 채팅하기")
                        .font(.caption2)
                        .foregroundStyle(FootprintTheme.textMuted)
                }
            }
            Spacer()
            if showsChatHint {
                Image(systemName: "bubble.left.fill")
                    .font(.caption)
                    .foregroundStyle(FootprintTheme.neonCyanDeep)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(FootprintTheme.textMuted)
            }
        }
        .padding(14)
        .footprintCard(cornerRadius: 14)
        .contentShape(Rectangle())
    }

    private var inviteCodeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("초대 코드")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FootprintTheme.textMuted)
            HStack {
                Text(inviteCode)
                    .font(.title2.monospaced().bold())
                    .foregroundStyle(FootprintTheme.neonCyanDeep)
                Spacer()
                Button(didCopy ? "복사됨" : "복사") {
                    UIPasteboard.general.string = inviteCode
                    didCopy = true
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(FootprintTheme.neonCyanDeep)
            }
            Text("이 코드를 친구에게 주면 같은 그룹에 참여할 수 있어요")
                .font(.caption)
                .foregroundStyle(FootprintTheme.textSecondary)
        }
        .padding(16)
        .footprintCard()
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        if let summary = viewModel.joinedGroups.first(where: { $0.groupId == groupId }) {
            groupName = summary.groupName
        }
        do {
            let detail = try await viewModel.fetchGroupDetail(groupId: groupId)
            groupName = detail.groupName
            members = detail.members
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func invite() async {
        isInviting = true
        errorMessage = ""
        defer { isInviting = false }
        do {
            inviteCode = try await viewModel.generateInvite(for: groupId)
            showInviteCode = true
            didCopy = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
