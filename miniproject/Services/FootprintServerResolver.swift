//
//  FootprintServerResolver.swift
//  miniproject
//

import Foundation

enum FootprintServerResolver {
    /// 실기기 테스트용 맥 IP (바뀌면 여기만 수정)
    static let devMacIP = "192.168.200.137"

    static func candidateURLs() -> [String] {
        var urls: [String] = []
        let saved = UserDefaults.standard.string(forKey: FootprintSession.serverURLKey) ?? ""
        if !saved.isEmpty {
            urls.append(FootprintDeviceHelper.normalizeServerURL(saved))
        }
        urls.append(FootprintDeviceHelper.recommendedServerURL)
        if !FootprintDeviceHelper.isSimulator {
            urls.append("http://\(devMacIP):8000")
        }
        if FootprintDeviceHelper.isSimulator {
            urls.append(FootprintConfig.defaultServerURL)
        }
        var seen = Set<String>()
        return urls.filter { seen.insert($0).inserted }
    }

    static func firstReachableURL() async -> String? {
        for urlString in candidateURLs() {
            if FootprintDeviceHelper.isLocalhostURL(urlString),
               !FootprintDeviceHelper.isSimulator {
                continue
            }
            guard let url = URL(string: urlString) else { continue }
            let api = FootprintAPI(baseURL: url)
            if (try? await api.checkHealth()) == true {
                return urlString
            }
        }
        return nil
    }

    static func resolveAndSave() async -> String {
        if let reachable = await firstReachableURL() {
            FootprintSession.serverURL = reachable
            return reachable
        }
        let fallback = FootprintDeviceHelper.recommendedServerURL
        FootprintSession.serverURL = fallback
        return fallback
    }
}
