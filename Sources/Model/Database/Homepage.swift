//
//  Homepage.swift
//
//
//  Created by 朱子骏 on 2023/8/27.
//

import Foundation

struct HomepageQueryResponse: Codable {
    enum HomepageType: String, Codable {
        case normal, random
    }
    
    enum JumpType: String {
        case none, md, url, wechatMiniProgram
    }
    
    let homepageType: HomepageType
    let homepageParam: String
    let jumpType: JumpType
    let jumpParam: String?
    let forceShowPos: Int?
    
    enum CodingKeys: String, CodingKey {
        case homepageType = "homepage_type"
        case homepageParam = "homepage_param"
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
        case "wechatMiniProgram":
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

extension HomepageQueryResponse {
    func toGRPC() -> ControlCenter_HomepageResponse.HomepageInfo? {
        var temp = ControlCenter_HomepageResponse.HomepageInfo()
        let decoder = JSONDecoder()
        
        switch homepageType {
        case .normal:
            guard let dictionary = try? decoder.decode([String: String].self, from: homepageParam.data(using: .utf8)!) else { return nil }
            switch dictionary["pos"] {
            case "cos":
                temp.imgPos = .cos
            case "local":
                temp.imgPos = .local
            default:
                return nil
            }
            guard let url = dictionary["url"] else  { return nil }
            temp.imgURL = url
        case .random:
            guard let dictionary = try? decoder.decode([[String: String]].self, from: homepageParam.data(using: .utf8)!) else { return nil }
            guard let target = dictionary.randomElement() else { return nil }
            switch target["pos"] {
            case "cos":
                temp.imgPos = .cos
            case "local":
                temp.imgPos = .local
            default:
                return nil
            }
            guard let url = target["url"] else  { return nil }
            temp.imgURL = url
        }
        
        
        temp.jumpType = jumpType.toGRPCJumpType()
        
        if let jumpParam = jumpParam {
            temp.jumpParam = jumpParam
        }
        
        return temp
    }
}
