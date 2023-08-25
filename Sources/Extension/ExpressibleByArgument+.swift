//
//  ExpressibleByArgument+.swift
//
//
//  Created by 朱子骏 on 2023/8/24.
//

import Foundation
import ArgumentParser
import Logging

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(string: argument)
    }
}

extension Logger.Level: EnumerableFlag {}
