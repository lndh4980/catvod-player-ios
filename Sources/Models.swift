import Foundation

// MARK: - 配置模型

struct CatVodConfig: Codable {
    let spider: String?
    let wallpaper: String?
    let sites: [Site]?
    let lives: [LiveItem]?
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
    let ext: String?
}

struct LiveItem: Codable, Identifiable {
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
    let rule: String?
}
