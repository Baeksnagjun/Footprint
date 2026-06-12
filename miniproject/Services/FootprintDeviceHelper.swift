//
//  FootprintDeviceHelper.swift
//  miniproject
//

import Foundation

enum FootprintDeviceHelper {
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    static func isLocalhostURL(_ urlString: String) -> Bool {
        let lower = urlString.lowercased()
        return lower.contains("127.0.0.1") || lower.contains("localhost")
    }

    static var recommendedServerURL: String {
        if isSimulator {
            return FootprintConfig.defaultServerURL
        }
        return "http://\(FootprintServerResolver.devMacIP):8000"
    }

    static var serverURLHint: String {
        if isSimulator {
            return "http://127.0.0.1:8000"
        }
        return "http://맥IP:8000 (맥 터미널: ipconfig getifaddr en0)"
    }

    static func normalizeServerURL(_ urlString: String) -> String {
        var trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        if !trimmed.isEmpty, !trimmed.contains("://"), trimmed.contains(":") {
            trimmed = "http://\(trimmed)"
        }
        return trimmed
    }

    static func validateServerURL(_ urlString: String) -> String? {
        let trimmed = normalizeServerURL(urlString)
        if trimmed.isEmpty {
            return "서버 주소를 입력하세요."
        }
        guard URL(string: trimmed) != nil else {
            return "주소 형식이 올바르지 않습니다."
        }
        if !isSimulator && isLocalhostURL(trimmed) {
            return "실기기에서는 127.0.0.1을 쓸 수 없습니다. 맥의 Wi‑Fi IP를 입력하세요."
        }
        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            return "http:// 로 시작해야 합니다."
        }
        return nil
    }
}
