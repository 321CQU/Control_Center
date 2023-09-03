//
//  File.swift
//  
//
//  Created by 朱子骏 on 2023/8/28.
//

import Foundation

extension HomepageQueryResponse.SavePos {
    func toGRPCPos() -> ControlCenter_HomepageResponse.HomepageInfo.ImgPos {
        switch self {
        case .local:
            return .local
        case .cos:
            return .cos
        }
    }
}

extension HomepageQueryResponse.JumpType {
    func toGRPCJumpType() -> ControlCenter_HomepageResponse.HomepageInfo.JumpType {
        switch self {
        case .none:
            return .none
        case .md:
            return .md
        case .url:
            return .url
        }
    }
}
