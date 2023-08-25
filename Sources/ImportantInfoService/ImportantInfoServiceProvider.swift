//
//  ImportantInfoServiceProvider.swift
//  ControlCenter
//
//  Created by 朱子骏 on 2023/8/22.
//

import Foundation
import NIOCore
import NIOConcurrencyHelpers
import GRPC
import SwiftProtobuf
import SQLKit

final class ImportantInfoServiceProvider: ControlCenter_ImportantInfoServiceAsyncProvider {
    private let urlPrefix: String
    private let getDatabase: @Sendable () async throws -> SQLDatabase
    
    init(urlPrefix: String, getDatabase: @escaping @Sendable () async throws -> SQLDatabase) throws {
        self.urlPrefix = urlPrefix
        self.getDatabase = getDatabase
    }
    
    func getHomepageInfos(request: SwiftProtobuf.Google_Protobuf_Empty, context: GRPC.GRPCAsyncServerCallContext) async throws -> ControlCenter_HomepageResponse {
        let db = try await getDatabase()
        return .init()
    }
}
