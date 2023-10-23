//
//  Homepage.swift
//
//
//  Created by 朱子骏 on 2023/8/27.
//

import Foundation

struct HomepageQueryResponse: Codable {
    enum SavePos: String, Codable {
        case local, cos
    }
    
    enum JumpType: String {
        case none, md, url, wechatMiniProgram
    }
    
    let saveUrl: String
    let savePos: SavePos
    let jumpType: JumpType
    let jumpParam: String?
    let forceShowPos: Int?
    
    enum CodingKeys: String, CodingKey {
        case saveUrl = "save_url"
        case savePos = "save_pos"
        case jumpType = "jump_type"
        case jumpParam = "jump_param"
        case forceShowPos = "force_show_pos"
    }
}

extension HomepageQueryResponse.JumpType: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue {
        case "none":
            self = .none
        case "md":
            self = .md
        case "url":
            self = .url
        case "wechat_mini_program", "wechatMiniProgram":
            self = .wechatMiniProgram
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid jump type: \(rawValue)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .none:
            try container.encode("none")
        case .md:
            try container.encode("md")
        case .url:
            try container.encode("url")
        case .wechatMiniProgram:
            try container.encode("wechat_mini_program")
        }
    }
}
