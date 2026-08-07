import Foundation

// MARK: - 灵活类型（影视仓 JSON 字段类型不固定，需容错）

/// ext 字段：可能是字符串、对象或数组
enum ExtValue: Decodable {
    case string(String)
    case dict([String: String])
    case array([String])
    case none

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) {
            self = .string(s)
        } else if let d = try? c.decode([String: String].self) {
            self = .dict(d)
        } else if let a = try? c.decode([String].self) {
            self = .array(a)
        } else {
            self = .none
        }
    }

    var displayText: String {
        switch self {
        case .string(let s): return s
        case .dict(let d): return d.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        case .array(let a): return a.joined(separator: "\n")
        case .none: return ""
        }
    }
}

// MARK: - 配置模型

struct CatVodConfig: Decodable {
    let spider: String?
    let wallpaper: String?
    let sites: [Site]?
    let lives: [LiveItem]?
    let rules: [Rule]?
    let hosts: [String]?
    let logo: String?
}

struct Site: Decodable, Identifiable {
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
    let indexs: Int?
    let ext: ExtValue?

    enum CodingKeys: String, CodingKey {
        case key, name, type, api, searchable, quickSearch, changeable, timeout, playerType, indexs, ext
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(String.self, forKey: .key)
        name = try c.decode(String.self, forKey: .name)
        type = try c.decodeIfPresent(Int.self, forKey: .type)
        api = try c.decodeIfPresent(String.self, forKey: .api)
        searchable = try c.decodeIfPresent(Int.self, forKey: .searchable)
        quickSearch = try c.decodeIfPresent(Int.self, forKey: .quickSearch)
        changeable = try c.decodeIfPresent(Int.self, forKey: .changeable)
        timeout = try c.decodeIfPresent(Int.self, forKey: .timeout)
        indexs = try c.decodeIfPresent(Int.self, forKey: .indexs)
        ext = try c.decodeIfPresent(ExtValue.self, forKey: .ext)
        // playerType 可能是 Int 也可能是 String
        if let pt = try? c.decodeIfPresent(Int.self, forKey: .playerType) {
            playerType = pt
        } else if let pts = try? c.decodeIfPresent(String.self, forKey: .playerType),
                  let pi = Int(pts) {
            playerType = pi
        } else {
            playerType = nil
        }
    }
}

struct LiveItem: Decodable, Identifiable {
    var id: String { name }
    let name: String
    let type: Int?
    let url: String
    let playerType: Int?
    let epg: String?
    let logo: String?
    let timeout: Int?
    let ua: String?

    enum CodingKeys: String, CodingKey {
        case name, type, url, playerType, epg, logo, timeout, ua
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        type = try c.decodeIfPresent(Int.self, forKey: .type)
        // url 可能是字符串或字符串数组
        if let u = try? c.decodeIfPresent(String.self, forKey: .url), !u.isEmpty {
            url = u
        } else if let arr = try? c.decodeIfPresent([String].self, forKey: .url),
                  let first = arr.first {
            url = first
        } else {
            url = ""
        }
        if let pt = try? c.decodeIfPresent(Int.self, forKey: .playerType) {
            playerType = pt
        } else if let pts = try? c.decodeIfPresent(String.self, forKey: .playerType),
                  let pi = Int(pts) {
            playerType = pi
        } else {
            playerType = nil
        }
        epg = try c.decodeIfPresent(String.self, forKey: .epg)
        logo = try c.decodeIfPresent(String.self, forKey: .logo)
        timeout = try c.decodeIfPresent(Int.self, forKey: .timeout)
        ua = try c.decodeIfPresent(String.self, forKey: .ua)
    }
}

struct Rule: Decodable {
    let name: String?
    let hosts: [String]?
    let regex: [String]?
}

// MARK: - 直播频道（解析 m3u 后得到）

struct Channel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: String
}
