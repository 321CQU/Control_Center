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
    
    enum JumpType: String, Codable {
        case none, md, url
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
