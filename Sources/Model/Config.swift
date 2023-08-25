//
//  Config.swift
//
//
//  Created by 朱子骏 on 2023/8/25.
//

import Foundation
import ArgumentParser

extension Int {
    struct DefaultDBPort: DefaultCodableStrategy {
        static var defaultValue: Int = 3306
    }
}

struct DatabaseConfig: Codable {
    var host: String
    @DefaultCodable<Int.DefaultDBPort> var port: Int
    var username: String
    var password: String
    var database: String
}

struct ImportantInfoServiceConfig: Codable {
    var homepagePrefix: String
}
