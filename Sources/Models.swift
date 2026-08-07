import Foundation

// MARK: - 配置模型

struct CatVodConfig: Codable {
    let spider: String?
    let wallpaper: String?
    let sites: [Site]?
    let lives: [Live]?
    let rules: [Rule]?
    let hosts: [String]?
    let logo: String?
}

struct Site: Codable, Identifiable {
    var id: String { key }
    
    let key: String
    let name: String
    let type: Int?
    let api: String?
    let searchable: Int?
    let quickSearch: Int?
    let changeable: Int?
    let timeout: Int?
    let playerType: Int?
    let ext: ExtValue?
    let style: Style?
    let indexs: Int?
}

struct ExtValue: Codable {
    let rawValue: String?
    let objectValue: [String: String]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            rawValue = stringValue
            objectValue = nil
        } else if let dictValue = try? container.decode([String: String].self) {
            rawValue = nil
            objectValue = dictValue
        } else {
            rawValue = nil
            objectValue = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let rawValue = rawValue {
            try container.encode(rawValue)
        } else if let objectValue = objectValue {
            try container.encode(objectValue)
        }
    }
}

struct Style: Codable {
    let type: String?
    let ratio: Double?
}

struct Live: Codable, Identifiable {
    var id: String { name }
    
    let name: String
    let type: Int?
    let url: String
    let playerType: Int?
    let epg: String?
    let logo: String?
    let timeout: Int?
    let ua: String?
}

struct Rule: Codable {
    let name: String?
    let hosts: [String]?
    let regex: [String]?
}

// MARK: - 直播源解析

struct LiveChannel: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let logo: String?
}

class LiveParser {
    static func parseM3U(_ content: String) -> [LiveChannel] {
        var channels: [LiveChannel] = []
        let lines = content.components(separatedBy: "\n")
        
        var currentName = ""
        var currentLogo: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("#EXTINF:") {
                // 解析名称和 logo
                let parts = trimmed.dropFirst("#EXTINF:".count).components(separatedBy: ",")
                if parts.count >= 2 {
                    currentName = parts[1].trimmingCharacters(in: .whitespaces)
                    
                    // 解析 tvg-logo
                    if let logoRange = trimmed.range(of: "tvg-logo=\"") {
                        let start = logoRange.upperBound
                        if let end = trimmed[start...].range(of: "\"") {
                            currentLogo = String(trimmed[start..<end.lowerBound])
                        }
                    }
                }
            } else if trimmed.hasPrefix("http") || trimmed.hasPrefix("rtmp") {
                // 这是播放地址
                if !currentName.isEmpty {
                    channels.append(LiveChannel(name: currentName, url: trimmed, logo: currentLogo))
                    currentName = ""
                    currentLogo = nil
                }
            }
        }
        
        return channels
    }
    
    static func parseTxt(_ content: String) -> [LiveChannel] {
        var channels: [LiveChannel] = []
        let lines = content.components(separatedBy: "\n")
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // 格式：频道名,播放地址 或 频道名 播放地址
            if trimmed.contains(",") {
                let parts = trimmed.components(separatedBy: ",")
                if parts.count >= 2 {
                    let name = parts[0].trimmingCharacters(in: .whitespaces)
                    let url = parts[1].trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty && (url.hasPrefix("http") || url.hasPrefix("rtmp")) {
                        channels.append(LiveChannel(name: name, url: url, logo: nil))
                    }
                }
            } else if trimmed.contains(" ") {
                let parts = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
                if parts.count >= 2 {
                    let name = parts[0]
                    let url = parts[1]
                    if !name.isEmpty && (url.hasPrefix("http") || url.hasPrefix("rtmp")) {
                        channels.append(LiveChannel(name: name, url: url, logo: nil))
                    }
                }
            }
        }
        
        return channels
    }
}
