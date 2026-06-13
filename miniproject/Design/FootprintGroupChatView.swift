//
//  FootprintGroupChatView.swift
//  Footprint
//

import SwiftUI

struct FootprintGroupChatView: View {
    @ObservedObject var viewModel: LiveMapViewModel
    let groupId: String
    let peerUserId: String
    let peerName: String

    @State private var messages: [ChatMessage] = []
    @State private var draftText = ""
    @State private var isSending = false
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var pollTask: Task<Void, Never>?

    private let quickMessages = [
        "거기서 뭐함?",
        "학식 고?",
        "같이 공부할?",
        "5분 뒤 만나",
    ]

    var body: some View {
        ZStack {
            FootprintTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                quickMessageSection
                composer
            }
        }
        .navigationTitle(peerName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMessages()
            startPolling()
        }
        .onDisappear {
            pollTask?.cancel()
            pollTask = nil
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36))
                .foregroundStyle(FootprintTheme.textMuted)
            Text("첫 메시지를 내보세요")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FootprintTheme.textSecondary)
            Text("아래 빠른 메시지나 직접 입력할 수 있어요")
                .font(.caption)
                .foregroundStyle(FootprintTheme.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }

    private var quickMessageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("원터치 텔레파시")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FootprintTheme.textMuted)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickMessages, id: \.self) { text in
                        Button {
                            Task { await send(text) }
                        } label: {
                            Text(text)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(FootprintTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(FootprintTheme.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(FootprintTheme.neonCyan.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isSending)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 10)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("메시지 입력", text: $draftText, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(FootprintTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                Task { await send(draftText) }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(canSend ? FootprintTheme.buttonOnAccent : FootprintTheme.textMuted)
                    .frame(width: 42, height: 42)
                    .background(canSend ? FootprintTheme.neonCyan : FootprintTheme.surfaceElevated)
                    .clipShape(Circle())
            }
            .disabled(!canSend || isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FootprintTheme.background)
    }

    private var canSend: Bool {
        !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        let isMine = message.fromUserId == viewModel.userId
        return HStack {
            if isMine { Spacer(minLength: 48) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(isMine ? FootprintTheme.buttonOnAccent : FootprintTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMine ? FootprintTheme.neonCyan : FootprintTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        if !isMine {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(FootprintTheme.cardStroke, lineWidth: 1)
                        }
                    }
                Text(Self.timeLabel(for: message.sentAt))
                    .font(.caption2)
                    .foregroundStyle(FootprintTheme.textMuted)
            }
            if !isMine { Spacer(minLength: 48) }
        }
    }

    private func loadMessages() async {
        isLoading = messages.isEmpty
        errorMessage = ""
        do {
            let fetched = try await viewModel.fetchChatMessages(
                groupId: groupId,
                withUserId: peerUserId
            )
            messages = fetched.sorted { $0.sentAt < $1.sentAt }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { break }
                await refreshMessages()
            }
        }
    }

    private func refreshMessages() async {
        do {
            let fetched = try await viewModel.fetchChatMessages(
                groupId: groupId,
                withUserId: peerUserId
            )
            let sorted = fetched.sorted { $0.sentAt < $1.sentAt }
            if sorted != messages {
                messages = sorted
            }
            if !errorMessage.isEmpty {
                errorMessage = ""
            }
        } catch {
            // 폴링 중 일시적 오류는 조용히 무시
        }
    }

    private func send(_ rawText: String) async {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        isSending = true
        errorMessage = ""
        defer { isSending = false }

        do {
            let sent = try await viewModel.sendChatMessage(
                groupId: groupId,
                toUserId: peerUserId,
                text: text
            )
            if draftText == rawText {
                draftText = ""
            }
            if !messages.contains(where: { $0.id == sent.id }) {
                messages.append(sent)
                messages.sort { $0.sentAt < $1.sentAt }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let last = messages.last else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private static func timeLabel(for timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}
